'use strict';

const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const BATCH_SIZE = 500;

const ACCOUNT_UID_QUERY = `
  SELECT u.id AS userId, u.user_role AS role, p.id AS profileId, p.firebase_uid AS storedUid
  FROM up_users u
  INNER JOIN players_player_lnk l ON l.user_id = u.id
  INNER JOIN players p ON p.id = l.player_id
  WHERE u.user_role = 'player'
  UNION ALL
  SELECT u.id AS userId, u.user_role AS role, m.id AS profileId, m.firebase_uid AS storedUid
  FROM up_users u
  INNER JOIN managers_manager_lnk l ON l.user_id = u.id
  INNER JOIN managers m ON m.id = l.manager_id
  WHERE u.user_role = 'manager'
  UNION ALL
  SELECT u.id AS userId, u.user_role AS role, w.id AS profileId, w.firebase_uid AS storedUid
  FROM up_users u
  INNER JOIN workers_worker_lnk l ON l.user_id = u.id
  INNER JOIN workers w ON w.id = l.worker_id
  WHERE u.user_role = 'worker'
  UNION ALL
  SELECT u.id AS userId, u.user_role AS role, NULL AS profileId, NULL AS storedUid
  FROM up_users u
  WHERE u.user_role = 'admin'
`;

function firebaseUidFor(account) {
  const storedUid = account.storedUid?.trim();
  if (storedUid) return storedUid;
  if (account.role === 'worker') return `sporta_worker_${account.userId}`;
  if (account.role === 'admin') return `sporta_admin_${account.userId}`;
  return `sporta_${account.role}_${account.profileId}`;
}

function createAccountRecords(rows) {
  return rows.map((row) => ({
    role: row.role,
    userId: String(row.userId),
    profileId: row.profileId === null ? null : String(row.profileId),
    uid: firebaseUidFor(row),
  }));
}

function identifyLockedOutRoles(conversation, participants, accounts) {
  const participantIds = conversation.participantIds;
  if (!participantIds || typeof participantIds !== 'object') return [];

  const lockedOutRoles = new Set();
  for (const [role, relatedId] of Object.entries(participantIds)) {
    if (relatedId === null || relatedId === undefined) continue;

    const id = String(relatedId);
    const account = accounts.find((candidate) =>
      candidate.role === role
      && (candidate.profileId === id || candidate.userId === id)
    );

    if (!account || !participants.includes(account.uid)) {
      lockedOutRoles.add(role);
    }
  }

  return [...lockedOutRoles].sort();
}

async function loadAccountIdentities() {
  const client = process.env.DATABASE_CLIENT || 'sqlite';
  if (!['mysql', 'mysql2'].includes(client)) {
    throw new Error('The UID audit requires the configured MySQL database');
  }

  const mysql = require('mysql2/promise');
  const connection = await mysql.createConnection({
    host: process.env.DATABASE_HOST || 'localhost',
    port: Number(process.env.DATABASE_PORT || 3306),
    database: process.env.DATABASE_NAME,
    user: process.env.DATABASE_USERNAME,
    password: process.env.DATABASE_PASSWORD,
    ssl: process.env.DATABASE_SSL === 'true'
      ? {
        key: process.env.DATABASE_SSL_KEY || undefined,
        cert: process.env.DATABASE_SSL_CERT || undefined,
        ca: process.env.DATABASE_SSL_CA || undefined,
        capath: process.env.DATABASE_SSL_CAPATH || undefined,
        ciphers: process.env.DATABASE_SSL_CIPHER || undefined,
        rejectUnauthorized: process.env.DATABASE_SSL_REJECT_UNAUTHORIZED !== 'false',
      }
      : undefined,
  });

  let transactionStarted = false;
  try {
    await connection.query('START TRANSACTION READ ONLY');
    transactionStarted = true;
    const [rows] = await connection.query(ACCOUNT_UID_QUERY);
    return createAccountRecords(rows);
  } finally {
    if (transactionStarted) await connection.query('ROLLBACK');
    await connection.end();
  }
}

async function readConversationDocuments(db) {
  const admin = require('firebase-admin');
  const documentId = admin.firestore.FieldPath.documentId();
  const documents = [];
  let query = db.collection('conversations')
    .orderBy(documentId)
    .limit(BATCH_SIZE);

  while (true) {
    const snapshot = await query.get();
    if (snapshot.empty) return documents;

    documents.push(...snapshot.docs);
    if (snapshot.size < BATCH_SIZE) return documents;

    query = db.collection('conversations')
      .orderBy(documentId)
      .startAfter(snapshot.docs[snapshot.docs.length - 1])
      .limit(BATCH_SIZE);
  }
}

async function main() {
  const accounts = await loadAccountIdentities();
  const knownUids = new Set(accounts.map((account) => account.uid));
  const firebaseService = require('../src/firebase/firebase.service');
  const conversations = await readConversationDocuments(firebaseService.getFirestore());

  const report = conversations.map((document) => {
    const conversation = document.data();
    const participantListValid = Array.isArray(conversation.participants)
      && conversation.participants.length > 0
      && conversation.participants.every((participant) => typeof participant === 'string');
    const participants = participantListValid ? conversation.participants : [];
    const lockedOutRoles = identifyLockedOutRoles(conversation, participants, accounts);
    if (!participantListValid || (
      participants.some((participant) => !knownUids.has(participant))
      && lockedOutRoles.length === 0
    )) {
      lockedOutRoles.push('unresolved');
    }
    const everyParticipantMatches = participantListValid
      && participants.every((participant) => knownUids.has(participant))
      && lockedOutRoles.length === 0;

    return {
      conversationId: document.id,
      everyParticipantMatchesTokenUid: everyParticipantMatches,
      lockedOutRoles,
    };
  });

  console.log(JSON.stringify({
    conversationsChecked: report.length,
    mismatchedConversations: report.filter((entry) => !entry.everyParticipantMatchesTokenUid).length,
    conversations: report,
  }, null, 2));
}

main().catch((error) => {
  const code = error.code ? ` (${error.code})` : '';
  console.error(`Chat UID audit failed: ${error.name || 'Error'}${code}.`);
  console.error('Check the Strapi and Firebase configuration, then retry.');
  process.exitCode = 1;
});
