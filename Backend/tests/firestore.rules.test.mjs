// @ts-ignore
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const projectId = 'sporta-firestore-rules-tests';
const conversationId = 'reservation_42';
const playerUid = 'sporta_player_7';
const managerUid = 'sporta_manager_3';
const outsiderUid = 'sporta_player_99';
const createdAt = new Date('2026-01-01T12:00:00.000Z');

// @ts-ignore
let testEnv;

async function seedConversation(id = conversationId, participants = [playerUid, managerUid]) {
  // @ts-ignore
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await setDoc(doc(firestore, 'conversations', id), {
      type: 'player_manager',
      reservationId: '42',
      participants,
      participantIds: { player: '7', manager: '3' },
      playerName: 'Player',
      managerName: 'Manager',
      lastMessage: null,
      lastMessageAt: null,
      status: 'active',
      createdAt,
    });
    await setDoc(
      doc(firestore, 'conversations', id, 'messages', 'existing-message'),
      {
        text: 'Existing message',
        senderId: managerUid,
        type: 'text',
        createdAt,
      },
    );
  });
}

before(async () => {
  const rules = await readFile(
    new URL('../../firestore.rules', import.meta.url),
    'utf8',
  );
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

beforeEach(async () => {
  // @ts-ignore
  await testEnv.clearFirestore();
  await seedConversation();
});

after(async () => {
  // @ts-ignore
  await testEnv?.cleanup();
});

test('a participant can read their conversation and messages and send a message', async () => {
  // @ts-ignore
  const firestore = testEnv.authenticatedContext(playerUid).firestore();
  const conversationRef = doc(firestore, 'conversations', conversationId);
  const messagesRef = collection(conversationRef, 'messages');

  await assertSucceeds(getDoc(conversationRef));
  await assertSucceeds(getDocs(messagesRef));
  await assertSucceeds(
    setDoc(doc(messagesRef, 'new-message'), {
      text: 'Hello',
      senderId: playerUid,
      type: 'text',
      createdAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    updateDoc(conversationRef, {
      lastMessage: 'Hello',
      lastMessageAt: serverTimestamp(),
    }),
  );
});

test('a non-participant cannot read or write another conversation', async () => {
  // @ts-ignore
  const firestore = testEnv.authenticatedContext(outsiderUid).firestore();
  const conversationRef = doc(firestore, 'conversations', conversationId);

  await assertFails(getDoc(conversationRef));
  await assertFails(getDocs(collection(firestore, 'conversations')));
  await assertFails(
    setDoc(doc(conversationRef, 'messages', 'intrusion'), {
      text: 'Not a participant',
      senderId: outsiderUid,
      type: 'text',
      createdAt: serverTimestamp(),
    }),
  );
});

test('message senderId must equal the authenticated Firebase UID', async () => {
  // @ts-ignore
  const firestore = testEnv.authenticatedContext(playerUid).firestore();
  const messagesRef = collection(
    firestore,
    'conversations',
    conversationId,
    'messages',
  );

  await assertFails(
    setDoc(doc(messagesRef, 'spoofed-message'), {
      text: 'Impersonating the manager',
      senderId: managerUid,
      type: 'text',
      createdAt: serverTimestamp(),
    }),
  );
});

test('clients cannot create a conversation or add themselves as participants', async () => {
  // @ts-ignore
  const firestore = testEnv.authenticatedContext(outsiderUid).firestore();
  const newConversation = doc(firestore, 'conversations', 'self-added');

  await assertFails(
    setDoc(newConversation, {
      type: 'player_manager',
      participants: [outsiderUid, managerUid],
      createdAt: serverTimestamp(),
    }),
  );
  await assertFails(
    updateDoc(doc(firestore, 'conversations', conversationId), {
      participants: [playerUid, managerUid, outsiderUid],
    }),
  );
  // @ts-ignore
  const playerFirestore = testEnv.authenticatedContext(playerUid).firestore();
  await assertFails(
    updateDoc(doc(playerFirestore, 'conversations', conversationId), {
      participants: [playerUid, managerUid, outsiderUid],
    }),
  );
});

test('unauthenticated users cannot read or write conversations or messages', async () => {
  // @ts-ignore
  const firestore = testEnv.unauthenticatedContext().firestore();
  const conversationRef = doc(firestore, 'conversations', conversationId);

  await assertFails(getDoc(conversationRef));
  await assertFails(
    getDocs(collection(conversationRef, 'messages')),
  );
  await assertFails(
    setDoc(doc(conversationRef, 'messages', 'anonymous-message'), {
      text: 'Anonymous',
      senderId: playerUid,
      type: 'text',
      createdAt: serverTimestamp(),
    }),
  );
});

test('both listed worker and manager participants can read their team channel', async () => {
  const workerUid = 'sporta_worker_5';
  const teamConversationId = 'worker_manager_5';
  await seedConversation(teamConversationId, [workerUid, managerUid]);

  for (const uid of [workerUid, managerUid]) {
    // @ts-ignore
    const firestore = testEnv.authenticatedContext(uid).firestore();
    await assertSucceeds(
      getDoc(doc(firestore, 'conversations', teamConversationId)),
    );
    await assertSucceeds(
      setDoc(
        doc(
          firestore,
          'conversations',
          teamConversationId,
          'messages',
          `message-${uid}`,
        ),
        {
          text: 'Team update',
          senderId: uid,
          type: 'text',
          createdAt: serverTimestamp(),
        },
      ),
    );
  }
});
