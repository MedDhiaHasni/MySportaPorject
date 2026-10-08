// src/api/reservation/content-types/reservation/lifecycles.js
// @ts-nocheck
'use strict';

const firebaseService = require('../../../../firebase/firebase.service');

module.exports = {
  // ── afterCreate ─────────────────────────────────────────────────────────────
  async afterCreate(event) {
    const { result } = event;
    console.log('[lifecycle] afterCreate | id:', result.id, '| status:', result.booking_status);

    if (result.booking_status !== 'confirmed') {
      console.log('[lifecycle] afterCreate — skipping, status is not confirmed');
      return;
    }

    await handleConfirmed(result.id);
  },

  // ── afterUpdate ─────────────────────────────────────────────────────────────
  async afterUpdate(event) {
    const { result } = event;
    console.log('[lifecycle] afterUpdate | id:', result.id, '| status:', result.booking_status);

    if (result.booking_status !== 'confirmed') {
      console.log('[lifecycle] afterUpdate — skipping, status is not confirmed');
      return;
    }

    await handleConfirmed(result.id);
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// handleConfirmed
// Creates:
//   1. player ↔ manager  conversation  (reservation_{id})
//   2. player ↔ worker   conversation  (player_worker_{id})  — if court has a worker
// Note: worker ↔ manager conversation is created at assignment time in court.service.js
// ─────────────────────────────────────────────────────────────────────────────
async function handleConfirmed(reservationId) {
  console.log('[lifecycle] handleConfirmed — reservationId:', reservationId);

  try {
    // Re-fetch with all needed relations
    // ✅ FIX: populate court.worker.worker (the linked Strapi user) to get user id
    const reservation = await strapi.db.query('api::reservation.reservation').findOne({
      where: { id: reservationId },
      populate: {
        player:  true,
        manager: true,
        court:   {
          populate: {
            worker: {
              populate: { worker: true }, // worker profile → linked user
            },
          },
        },
      },
    });

    if (!reservation) {
      console.error('[lifecycle] reservation not found for id', reservationId);
      return;
    }

    const { player, manager, court } = reservation;

    if (!player) {
      console.warn('[lifecycle] player relation missing on reservation', reservationId);
      return;
    }

    // ── Resolve UIDs ──────────────────────────────────────────────────────────
    const playerUid = player.firebaseUid?.trim()
      ? player.firebaseUid
      : `sporta_player_${player.id}`;

    const managerUid = manager?.firebaseUid?.trim()
      ? manager.firebaseUid
      : (manager ? `sporta_manager_${manager.id}` : null);

    // ── 1. Player ↔ Manager ───────────────────────────────────────────────────
    if (manager && managerUid) {
      try {
        await firebaseService.createConversation({
          reservationId,
          playerUid,
          managerUid,
          playerId:   player.id,
          managerId:  manager.id,
          playerName:  player.nom  || 'Player',
          managerName: manager.nom || 'Manager',
        });
        console.log(`[lifecycle] ✅ player↔manager conversation created for reservation ${reservationId}`);
      } catch (err) {
        console.error('[lifecycle] player↔manager error:', err.message);
      }
    }

    // ── 2. Player ↔ Worker ────────────────────────────────────────────────────
    const worker = court?.worker ?? null;
    if (worker) {
      try {
        // ✅ FIX: use worker.worker.id (linked user id) — same as Flutter getMe returns
        const workerUserId = worker.worker?.id ?? worker.id;
        const workerUid = worker.firebaseUid?.trim()
          ? worker.firebaseUid
          : `sporta_worker_${workerUserId}`;

        await firebaseService.createPlayerWorkerConversation({
          reservationId,
          playerUid,
          workerUid,
          playerId:   player.id,
          workerId:   workerUserId,  // store user id, not profile id
          playerName: player.nom || 'Player',
          workerName: worker.nom || 'Worker',
        });
        console.log(`[lifecycle] ✅ player↔worker conversation created for reservation ${reservationId}`);
      } catch (err) {
        console.error('[lifecycle] player↔worker error:', err.message);
      }
    } else {
      console.log(`[lifecycle] no worker assigned to court ${court?.id} — skipping player↔worker conversation`);
    }

  } catch (err) {
    console.error('[lifecycle] ❌ handleConfirmed error for reservation', reservationId);
    console.error(err);
  }
}

















/*// src/api/reservation/content-types/reservation/lifecycles.js
// @ts-nocheck
'use strict';

const firebaseService = require('../../../../firebase/firebase.service');

module.exports = {
  // ── afterCreate ────────────────────────────────────────────────────────────
  // Fires when a reservation row is first inserted.
  // pay_now → reservation controller now writes booking_status = 'confirmed'
  //           directly, so this hook catches it.
  // pay_at_venue → status is 'pending' on create, skipped here.
  async afterCreate(event) {
    const { result } = event;
    console.log('[lifecycle] afterCreate | id:', result.id, '| status:', result.booking_status);

    if (result.booking_status !== 'confirmed') {
      console.log('[lifecycle] afterCreate — skipping, status is not confirmed');
      return;
    }

    await handleConfirmed(result.id);
  },

  // ── afterUpdate ────────────────────────────────────────────────────────────
  // Fires when manager calls PUT /reservations/:id/confirm
  // which sets booking_status = 'confirmed' on a pay_at_venue reservation.
  async afterUpdate(event) {
    const { result } = event;
    console.log('[lifecycle] afterUpdate | id:', result.id, '| status:', result.booking_status);

    if (result.booking_status !== 'confirmed') {
      console.log('[lifecycle] afterUpdate — skipping, status is not confirmed');
      return;
    }

    await handleConfirmed(result.id);
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// handleConfirmed
// ─────────────────────────────────────────────────────────────────────────────
async function handleConfirmed(reservationId) {
  console.log('[lifecycle] handleConfirmed — reservationId:', reservationId);

  try {
    // ── Use strapi global (always available inside lifecycle callbacks in v4) ──
    // We re-query here to guarantee we have the full populated object,
    // because afterCreate/afterUpdate result may not include relations.
    const reservation = await strapi.db
      .query('api::reservation.reservation')
      .findOne({
        where: { id: reservationId },
        populate: {
          player:  { select: ['id', 'firebaseUid', 'fcmToken', 'nom'] },
          manager: { select: ['id', 'firebaseUid', 'fcmToken', 'nom'] },
        },
      });

    if (!reservation) {
      console.error('[lifecycle] reservation not found in DB for id', reservationId);
      return;
    }

    console.log('[lifecycle] reservation.player  =', reservation.player);
    console.log('[lifecycle] reservation.manager =', reservation.manager);

    const { player, manager } = reservation;

    if (!player) {
      console.warn('[lifecycle] player relation missing on reservation', reservationId);
      return;
    }
    if (!manager) {
      console.warn('[lifecycle] manager relation missing on reservation', reservationId);
      return;
    }

    // Use firebaseUid if set, otherwise fall back to a deterministic UID
    // so you can still identify both parties even before they log in with Firebase.
    const playerUid  = player.firebaseUid  || `player_${player.id}`;
    const managerUid = manager.firebaseUid || `manager_${manager.id}`;

    console.log('[lifecycle] creating conversation:', { reservationId, playerUid, managerUid });

    await firebaseService.createConversation({
      reservationId,
      playerUid,
      managerUid,
      playerId:  player.id,
      managerId: manager.id,
    });

    console.log(`[lifecycle] ✅ Conversation created for reservation ${reservationId}`);

  } catch (err) {
    // Log the full error so you can see the stack trace in your Strapi terminal
    console.error('[lifecycle] ❌ Firebase error for reservation', reservationId);
    console.error(err);
  }
}*/