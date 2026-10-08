// src/firebase/firebase.service.js
// @ts-nocheck
'use strict';

const admin = require('firebase-admin');

let firebaseApp = null;

function getFirebaseApp() {
  if (firebaseApp) return firebaseApp;
  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert({
      projectId:   process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey:  process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
  return firebaseApp;
}

function getFirestore() {
  return getFirebaseApp().firestore();
}

// ─────────────────────────────────────────────────────────────────────────────
// SEND PUSH NOTIFICATION via FCM
// ─────────────────────────────────────────────────────────────────────────────
async function sendPushNotification(fcmToken, title, body, data = {}) {
  if (!fcmToken) {
    console.log('[firebase] No FCM token provided, skipping notification');
    return null;
  }

  try {
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: data,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'sporta_notifications',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log(`[firebase] Push notification sent: ${response}`);
    return response;
  } catch (error) {
    console.error('[firebase] Error sending push notification:', error);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEND BOOKING STATUS NOTIFICATION TO PLAYER
// ─────────────────────────────────────────────────────────────────────────────
async function sendBookingStatusNotification({
  playerFcmToken,
  bookingReference,
  courtName,
  venueName,
  date,
  time,
  status, // confirmed, cancelled, completed, rejected
  price,
}) {
  let title = '';
  let body = '';
  let color = '';
  
  switch (status) {
    case 'confirmed':
      title = '✅ Booking Confirmed!';
      body = `Your booking at ${courtName} (${venueName}) for ${date} at ${time} has been confirmed.`;
      color = '#4CAF50';
      break;
    case 'cancelled':
      title = '❌ Booking Cancelled';
      body = `Your booking at ${courtName} (${venueName}) for ${date} at ${time} has been cancelled.`;
      color = '#F44336';
      break;
    case 'completed':
      title = '🏆 Booking Completed';
      body = `Your booking at ${courtName} (${venueName}) for ${date} at ${time} is complete. Rate your experience!`;
      color = '#2196F3';
      break;
    case 'rejected':
      title = '⚠️ Booking Rejected';
      body = `Your booking request at ${courtName} (${venueName}) for ${date} at ${time} was rejected.`;
      color = '#FF9800';
      break;
    default:
      title = 'Booking Update';
      body = `Your booking ${bookingReference} status has been updated to ${status}.`;
      color = '#9E9E9E';
  }

  return sendPushNotification(playerFcmToken, title, body, {
    type: 'booking_status_update',
    booking_reference: bookingReference,
    status: status,
    court_name: courtName,
    venue_name: venueName,
    date: date,
    time: time,
    price: price?.toString() || '',
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    screen: 'bookings',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SEND MESSAGE NOTIFICATION (when someone sends a chat message)
// ─────────────────────────────────────────────────────────────────────────────
async function sendMessageNotification({
  recipientFcmToken,
  senderName,
  messageText,
  conversationId,
  conversationType,
}) {
  const title = `💬 New message from ${senderName}`;
  const body = messageText.length > 100 ? messageText.substring(0, 100) + '...' : messageText;
  
  return sendPushNotification(recipientFcmToken, title, body, {
    type: 'new_message',
    conversation_id: conversationId,
    conversation_type: conversationType,
    sender_name: senderName,
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    screen: 'chat',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SEND REMINDER NOTIFICATION (before a booking)
// ─────────────────────────────────────────────────────────────────────────────
async function sendBookingReminder({
  playerFcmToken,
  bookingReference,
  courtName,
  venueName,
  date,
  time,
  hoursBefore,
}) {
  const title = '⏰ Booking Reminder';
  const body = `Your booking at ${courtName} starts in ${hoursBefore} hour${hoursBefore > 1 ? 's' : ''} (${date} at ${time}). See you there!`;
  
  return sendPushNotification(playerFcmToken, title, body, {
    type: 'booking_reminder',
    booking_reference: bookingReference,
    court_name: courtName,
    venue_name: venueName,
    date: date,
    time: time,
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    screen: 'bookings',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION 1 — Player ↔ Manager
// docId: "reservation_{reservationId}"
// ─────────────────────────────────────────────────────────────────────────────
async function createConversation({
  reservationId,
  playerUid,
  managerUid,
  playerId,
  managerId,
  playerName,
  managerName,
}) {
  const db  = getFirestore();
  const ref = db.collection('conversations').doc(`reservation_${reservationId}`);
  const snap = await ref.get();

  if (snap.exists) {
    console.log(`[firebase] player↔manager conversation for reservation ${reservationId} already exists.`);
    return ref;
  }

  await ref.set({
    type:          'player_manager',
    reservationId: String(reservationId),
    participants:  [playerUid, managerUid],
    participantIds: {
      player:  String(playerId),
      manager: String(managerId),
    },
    playerName:    playerName  || 'Player',
    managerName:   managerName || 'Manager',
    lastMessage:   null,
    lastMessageAt: null,
    status:        'active',
    createdAt:     admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`[firebase] ✅ player↔manager conversation created: reservation_${reservationId}`);
  return ref;
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION 2 — Player ↔ Worker
// docId: "player_worker_{reservationId}"
// ─────────────────────────────────────────────────────────────────────────────
async function createPlayerWorkerConversation({
  reservationId,
  playerUid,
  workerUid,
  playerId,
  workerId,
  playerName,
  workerName,
}) {
  const db  = getFirestore();
  const ref = db.collection('conversations').doc(`player_worker_${reservationId}`);
  const snap = await ref.get();

  if (snap.exists) {
    console.log(`[firebase] player↔worker conversation for reservation ${reservationId} already exists.`);
    return ref;
  }

  await ref.set({
    type:          'player_worker',
    reservationId: String(reservationId),
    participants:  [playerUid, workerUid],
    participantIds: {
      player: String(playerId),
      worker: String(workerId),
    },
    playerName: playerName || 'Player',
    workerName: workerName || 'Worker',
    lastMessage:   null,
    lastMessageAt: null,
    status:        'active',
    createdAt:     admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`[firebase] ✅ player↔worker conversation created: player_worker_${reservationId}`);
  return ref;
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION 3 — Worker ↔ Manager
// docId: "worker_manager_{workerId}"
// ─────────────────────────────────────────────────────────────────────────────
async function createWorkerManagerConversation({
  workerId,
  managerId,
  workerUid,
  managerUid,
  workerName,
  managerName,
}) {
  const db  = getFirestore();
  const ref = db.collection('conversations').doc(`worker_manager_${workerId}`);
  const snap = await ref.get();

  if (snap.exists) {
    console.log(`[firebase] worker↔manager conversation for worker ${workerId} already exists.`);
    return ref;
  }

  await ref.set({
    type:        'worker_manager',
    participants: [workerUid, managerUid],
    participantIds: {
      worker:  String(workerId),
      manager: String(managerId),
    },
    workerName:  workerName  || 'Worker',
    managerName: managerName || 'Manager',
    lastMessage:   null,
    lastMessageAt: null,
    status:        'active',
    createdAt:     admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`[firebase] ✅ worker↔manager conversation created: worker_manager_${workerId}`);
  return ref;
}

// ─────────────────────────────────────────────────────────────────────────────
// GET USER FCM TOKEN - Helper function to get player's FCM token
// ─────────────────────────────────────────────────────────────────────────────
async function getUserFcmToken(userId, userType) {
  try {
    if (userType === 'player') {
      const player = await strapi.db.query('api::player.player').findOne({
        where: { player: userId },
        select: ['fcmToken', 'firebaseUid'],
      });
      return player?.fcmToken;
    }
    if (userType === 'manager') {
      const manager = await strapi.db.query('api::manager.manager').findOne({
        where: { manager: userId },
        select: ['fcmToken', 'firebaseUid'],
      });
      return manager?.fcmToken;
    }
    if (userType === 'worker') {
      const worker = await strapi.db.query('api::worker.worker').findOne({
        where: { worker: userId },
        select: ['fcmToken', 'firebaseUid'],
      });
      return worker?.fcmToken;
    }
    return null;
  } catch (error) {
    console.error('[firebase] Error getting user FCM token:', error);
    return null;
  }
}

module.exports = {
  getFirestore,
  createConversation,
  createPlayerWorkerConversation,
  createWorkerManagerConversation,
  sendPushNotification,
  sendBookingStatusNotification,
  sendMessageNotification,
  sendBookingReminder,
  getUserFcmToken,
};













/*// src/firebase/firebase.service.js
// @ts-nocheck
'use strict';

const admin = require('firebase-admin');

let firebaseApp = null;

function getFirebaseApp() {
  if (firebaseApp) return firebaseApp;
  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert({
      projectId:   process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey:  process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
  return firebaseApp;
}

function getFirestore() {
  return getFirebaseApp().firestore();
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION 1 — Player ↔ Manager
// docId: "reservation_{reservationId}"
// Opens when a player makes a reservation (pay_now → confirmed immediately,
// pay_at_venue → confirmed when manager confirms).
// ─────────────────────────────────────────────────────────────────────────────
async function createConversation({
  reservationId,
  playerUid,
  managerUid,
  playerId,
  managerId,
  playerName,
  managerName,
}) {
  const db  = getFirestore();
  const ref = db.collection('conversations').doc(`reservation_${reservationId}`);
  const snap = await ref.get();

  if (snap.exists) {
    console.log(`[firebase] player↔manager conversation for reservation ${reservationId} already exists.`);
    return ref;
  }

  await ref.set({
    type:          'player_manager',
    reservationId: String(reservationId),
    participants:  [playerUid, managerUid],
    participantIds: {
      player:  String(playerId),
      manager: String(managerId),
    },
    playerName:    playerName  || 'Player',
    managerName:   managerName || 'Manager',
    lastMessage:   null,
    lastMessageAt: null,
    status:        'active',
    createdAt:     admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`[firebase] ✅ player↔manager conversation created: reservation_${reservationId}`);
  return ref;
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION 2 — Player ↔ Worker
// docId: "player_worker_{reservationId}"
// Opens when a player makes a reservation in a court that has a worker assigned.
// ─────────────────────────────────────────────────────────────────────────────
async function createPlayerWorkerConversation({
  reservationId,
  playerUid,
  workerUid,
  playerId,
  workerId,
  playerName,
  workerName,
}) {
  const db  = getFirestore();
  const ref = db.collection('conversations').doc(`player_worker_${reservationId}`);
  const snap = await ref.get();

  if (snap.exists) {
    console.log(`[firebase] player↔worker conversation for reservation ${reservationId} already exists.`);
    return ref;
  }

  await ref.set({
    type:          'player_worker',
    reservationId: String(reservationId),
    participants:  [playerUid, workerUid],
    participantIds: {
      player: String(playerId),
      worker: String(workerId),
    },
    playerName: playerName || 'Player',
    workerName: workerName || 'Worker',
    lastMessage:   null,
    lastMessageAt: null,
    status:        'active',
    createdAt:     admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`[firebase] ✅ player↔worker conversation created: player_worker_${reservationId}`);
  return ref;
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION 3 — Worker ↔ Manager
// docId: "worker_manager_{workerId}"
// Permanent channel — one doc per worker, created when a worker is assigned
// to any court. If it already exists it is NOT recreated.
// ─────────────────────────────────────────────────────────────────────────────
async function createWorkerManagerConversation({
  workerId,
  managerId,
  workerUid,
  managerUid,
  workerName,
  managerName,
}) {
  const db  = getFirestore();
  const ref = db.collection('conversations').doc(`worker_manager_${workerId}`);
  const snap = await ref.get();

  if (snap.exists) {
    console.log(`[firebase] worker↔manager conversation for worker ${workerId} already exists.`);
    return ref;
  }

  await ref.set({
    type:        'worker_manager',
    participants: [workerUid, managerUid],
    participantIds: {
      worker:  String(workerId),
      manager: String(managerId),
    },
    workerName:  workerName  || 'Worker',
    managerName: managerName || 'Manager',
    lastMessage:   null,
    lastMessageAt: null,
    status:        'active',
    createdAt:     admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`[firebase] ✅ worker↔manager conversation created: worker_manager_${workerId}`);
  return ref;
}

async function notifyConversationCreated() {
  console.log('[firebase] Notification (à implémenter)');
}

module.exports = {
  getFirestore,
  createConversation,                  // player ↔ manager (existing)
  createPlayerWorkerConversation,      // player ↔ worker  (new)
  createWorkerManagerConversation,     // worker ↔ manager (new)
  notifyConversationCreated,
};*/






//*********************************************************








/*// @ts-nocheck
const admin = require('firebase-admin');
let firebaseApp = null;
function getFirebaseApp() {
if (firebaseApp) return firebaseApp;
firebaseApp = admin.initializeApp({
credential: admin.credential.cert({
projectId: process.env.FIREBASE_PROJECT_ID,
clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
}),
});
return firebaseApp;
}

function getFirestore() {
return getFirebaseApp().firestore();
}

async function createConversation({
reservationId,
playerUid,
managerUid,
playerId,
managerId
}) {
const db = getFirestore();
const ref = db.collection('conversations').doc(String(reservationId));
const snap = await ref.get();
if (snap.exists) {
console.log(`Conversation ${reservationId} already exists.`);
return ref;
}
await ref.set({
reservationId: String(reservationId),
participants: [playerUid, managerUid],
participantIds: {
player: String(playerId),
manager: String(managerId),
},
lastMessage: null,
lastMessageAt: null,
createdAt: admin.firestore.FieldValue.serverTimestamp(),
});
return ref;
}

async function notifyConversationCreated() {
console.log(" Notification (à implémenter)");
}

module.exports = {
createConversation,
notifyConversationCreated,
getFirestore,
};*/