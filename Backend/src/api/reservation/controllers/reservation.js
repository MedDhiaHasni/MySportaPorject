// src/api/reservation/controllers/reservation.js
// @ts-nocheck
'use strict';
                                                                                  
const { createCoreController } = require('@strapi/strapi').factories;
const { nanoid }        = require('nanoid');
const firebaseService   = require('../../../firebase/firebase.service');


const playerUidFor  = p => p?.firebaseUid?.trim() || `sporta_player_${p.id}`;
const managerUidFor = m => m?.firebaseUid?.trim() || `sporta_manager_${m.id}`;
const workerUidFor  = w => {
  if (w?.firebaseUid?.trim()) return w.firebaseUid;
  return `sporta_worker_${w.worker?.id ?? w.id}`;
};

function absUrl(strapi, path) {
  if (!path) return null;
  if (path.startsWith('http')) return path;
  return `${strapi.config.get('server.url') || ''}${path}`;
}


async function resolveWorkerProfile(strapi, userId) {
  try {
    const ws = await strapi.entityService.findMany('api::worker.worker', {
      filters: { worker: userId },
      populate: { courts: true },
      limit: 1,
    });
    return ws?.[0] ?? null;
  } catch { return null; }
}

async function resolveManagerProfile(strapi, userId) {
  try {
    const ms = await strapi.entityService.findMany('api::manager.manager', {
      filters: { manager: userId },
      limit: 1,
    });
    return ms?.[0] ?? null;
  } catch { return null; }
}

async function courtBelongsToManager(strapi, courtId, managerId) {
  try {
    const court = await strapi.db.query('api::court.court').findOne({
      where:    { id: courtId },
      populate: { venue: { populate: ['manager'] } },
    });
    return court?.venue?.manager?.id === managerId;
  } catch { return false; }
}

function courtAssignedToWorker(reservation, workerProfile) {
  const courtId = reservation.court?.id;
  if (!courtId || !workerProfile?.courts) return false;
  return workerProfile.courts.some(c => c.id === courtId);
}

// Central permission check
async function canActOnReservation(strapi, user, reservation, action) {
  const role = user?.user_role;
  if (role === 'admin') return { allowed: true };

  if (role === 'player') {
    // Players just ynajem ycancel
    if (action !== 'request_cancel') {
      return { allowed: false, reason: 'Players can only request a cancellation' };
    }
    const players = await strapi.entityService.findMany('api::player.player', {
      filters: { player: user.id }, limit: 1,
    });
    if (reservation.player?.id !== players?.[0]?.id) {
      return { allowed: false, reason: 'You can only cancel your own reservations' };
    }
    return { allowed: true };
  }

  if (role === 'worker') {
    const workerProfile = await resolveWorkerProfile(strapi, user.id);
    if (!workerProfile) return { allowed: false, reason: 'Worker profile not found' };
    if (!courtAssignedToWorker(reservation, workerProfile)) {
      return { allowed: false, reason: 'You are not assigned to the court for this reservation' };
    }
    return { allowed: true, workerProfile };
  }

  if (role === 'manager') {
    const managerProfile = await resolveManagerProfile(strapi, user.id);
    if (!managerProfile) return { allowed: false, reason: 'Manager profile not found' };
    const ok = await courtBelongsToManager(strapi, reservation.court?.id, managerProfile.id);
    if (!ok) return { allowed: false, reason: 'This reservation is not for one of your venues' };
    return { allowed: true, managerProfile };
  }

  return { allowed: false, reason: 'Unknown role' };
}


async function getCourtWorker(strapi, courtId) {
  if (!courtId) return null;
  try {
    const court = await strapi.db.query('api::court.court').findOne({
      where:    { id: courtId },
      populate: { worker: { populate: { worker: true } } },
    });
    return court?.worker ?? null;
  } catch { return null; }
}

async function openReservationConversations(strapi, {
  reservationId, courtId, player, playerUserName, managerId, managerRecord,
}) {
  // Player wel Manager
  if (managerId && managerRecord) {
    try {
      await firebaseService.createConversation({
        reservationId,
        playerUid:   playerUidFor(player),
        managerUid:  managerUidFor(managerRecord),
        playerId:    player.id,
        managerId,
        playerName:  playerUserName || player.nom || 'Player',
        managerName: managerRecord.nom || 'Manager',
      });
    } catch (e) {
      strapi.log.error('[reservation] player↔manager conversation error:', e.message);
    }
  }

  // Player wel Worker
  try {
    const worker = await getCourtWorker(strapi, courtId);
    if (worker) {
      await firebaseService.createPlayerWorkerConversation({
        reservationId,
        playerUid:  playerUidFor(player),
        workerUid:  workerUidFor(worker),
        playerId:   player.id,
        workerId:   worker.worker?.id ?? worker.id,
        playerName: playerUserName || player.nom || 'Player',
        workerName: worker.nom || 'Worker',
      });
    }
  } catch (e) {
    strapi.log.error('[reservation] player↔worker conversation error:', e.message);
  }
}

// Send FCM notification to the player
async function sendBookingNotification(strapi, reservationId, status, extraData = {}) {
  try {
    const reservation = await strapi.db.query('api::reservation.reservation').findOne({
      where:    { id: reservationId },
      populate: {
        player: { populate: ['player'] },
        court:  { populate: ['venue'] },
        time_slot: true,
      },
    });

    if (!reservation?.player?.fcmToken) return;

    await firebaseService.sendBookingStatusNotification({
      playerFcmToken:   reservation.player.fcmToken,
      bookingReference: reservation.booking_reference,
      courtName:        reservation.court?.name        || 'Court',
      venueName:        reservation.court?.venue?.name || 'Venue',
      date:             reservation.booking_date_play,
      time:             reservation.start_time
          ? `${reservation.start_time} - ${reservation.end_time}`
          : '',
      status,
      price: reservation.total_price,
      ...extraData,
    });
    strapi.log.info(`[reservation] Notification sent → player, status=${status}`);
  } catch (e) {
    strapi.log.error('[reservation] sendBookingNotification error:', e.message);
  }
}

async function updateFirestoreStatus(strapi, reservationId, status) {
  try {
    const db   = firebaseService.getFirestore();
    const docs = [`reservation_${reservationId}`, `player_worker_${reservationId}`];
    for (const docId of docs) {
      const ref  = db.collection('conversations').doc(docId);
      const snap = await ref.get();
      if (snap.exists) await ref.update({ status, updatedAt: new Date() });
    }
  } catch (_) {}
}


module.exports = createCoreController('api::reservation.reservation', ({ strapi }) => ({

  // FIND 
  async find(ctx) {
    const user    = ctx.state.user;
    const filters = {};

    if (user?.user_role === 'player') {
      const players = await strapi.entityService.findMany('api::player.player', {
        filters: { player: user.id }, limit: 1,
      });
      if (!players?.[0]) return ctx.unauthorized('Player profile not found');
      filters.player = players[0].id;

    } else if (user?.user_role === 'worker') {
      const wp = await resolveWorkerProfile(strapi, user.id);
      if (!wp) return ctx.unauthorized('Worker profile not found');
      const courtIds = (wp.courts || []).map(c => c.id);
      if (!courtIds.length) return ctx.send(this.transformResponse([]));
      filters.court = { id: { $in: courtIds } };

    } else if (user?.user_role === 'manager') {
      const mp = await resolveManagerProfile(strapi, user.id);
      if (!mp) return ctx.unauthorized('Manager profile not found');
      const courts = await strapi.db.query('api::court.court').findMany({
        where: { venue: { manager: { id: mp.id } } },
      });
      const courtIds = courts.map(c => c.id);
      if (!courtIds.length) return ctx.send(this.transformResponse([]));
      filters.court = { id: { $in: courtIds } };
    }

    const entities = await strapi.service('api::reservation.reservation').findMany({
      filters,
      populate: ['court', 'player', 'player.player', 'time_slot',
                 'court.court_img', 'court.photos', 'court.venue'],
      sort: { booking_date_play: 'desc' },
    });

    const transformed = entities.map(e => {
      if (e.court) {
        e.court.court_img_url = absUrl(strapi, e.court.court_img?.url ?? null);
        e.court.photos_urls   = (e.court.photos || []).map(p => absUrl(strapi, p.url)).filter(Boolean);
      }
      return e;
    });
    return this.transformResponse(transformed);
  },

  // FIND ONE 
  async findOne(ctx) {
    const { id }  = ctx.params;
    const user    = ctx.state.user;
    const entity  = await strapi.service('api::reservation.reservation').findOne(id, {
      populate: ['court', 'player', 'player.player', 'time_slot',
                 'court.court_img', 'court.photos', 'court.venue'],
    });
    if (!entity) return ctx.notFound('Reservation not found');

    if (user?.user_role === 'player') {
      const players = await strapi.entityService.findMany('api::player.player', {
        filters: { player: user.id }, limit: 1,
      });
      if (entity.player?.id !== players?.[0]?.id) return ctx.forbidden();
    }

    if (entity.court) {
      entity.court.court_img_url = absUrl(strapi, entity.court.court_img?.url ?? null);
      entity.court.photos_urls   = (entity.court.photos || []).map(p => absUrl(strapi, p.url)).filter(Boolean);
    }
    return this.transformResponse(entity);
  },

  // CREATE 
  async create(ctx) {
    try {
      const user = ctx.state.user;
      if (user?.user_role !== 'player') return ctx.forbidden('Only players can make reservations');

      let requestData = ctx.request.body;
      if (requestData.data) requestData = requestData.data;

      const players = await strapi.entityService.findMany('api::player.player', {
        filters: { player: user.id }, limit: 1,
      });
      if (!players?.[0]) return ctx.badRequest('No player profile linked to your account');
      const player = players[0];

      if (!requestData.time_slot) return ctx.badRequest('time_slot is required');

      const slot = await strapi.entityService.findOne('api::time-slot.time-slot', requestData.time_slot, {
        populate: ['reservation', 'day_plan'],
      });
      if (!slot)            return ctx.notFound('Time slot not found');
      if (!slot.isActive)   return ctx.badRequest('This time slot is not available');
      if (slot.reservation) return ctx.badRequest('This time slot is already booked');
      if (slot.day_plan?.dayType === 'day_off') return ctx.badRequest('Cannot book on a day-off');

      const booking_reference = `SPT-${nanoid(8).toUpperCase()}`;

      let totalPrice = requestData.total_price;
      if (!totalPrice && requestData.court) {
        const court = await strapi.entityService.findOne('api::court.court', requestData.court, {});
        if (court?.pricePerHour) totalPrice = court.pricePerHour * (requestData.duration_hours || 1);
      }

      const entity = await strapi.service('api::reservation.reservation').create({
        data: {
          time_slot:         requestData.time_slot,
          court:             requestData.court,
          booking_date_play: requestData.booking_date_play,
          start_time:        requestData.start_time,
          end_time:          requestData.end_time,
          duration_hours:    requestData.duration_hours || 1,
          total_price:       totalPrice || 0,
          payment_method:    requestData.payment_method || 'pay_at_venue',
          player:            player.id,
          booking_reference,
          booking_date:      new Date().toISOString(),
          booking_status:    'pending',
        },
        populate: ['court', 'player', 'time_slot'],
      });

      await strapi.entityService.update('api::time-slot.time-slot', requestData.time_slot, {
        data: { isActive: false },
      });

      strapi.log.info(`[reservation] Created ${booking_reference} for player ${player.id}`);
      return ctx.send({ data: entity }, 201);
    } catch (error) {
      strapi.log.error('[reservation] create error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

 
 
  async requestCancel(ctx) {
    try {
      const { id }    = ctx.params;
      const user      = ctx.state.user;
      const { reason } = ctx.request.body ?? {};

      const existing = await strapi.entityService.findOne('api::reservation.reservation', id, {
        populate: ['player', 'court', 'time_slot'],
      });
      if (!existing) return ctx.notFound('Reservation not found');

      const perm = await canActOnReservation(strapi, user, existing, 'request_cancel');
      if (!perm.allowed) return ctx.forbidden(perm.reason);

      // Can only request cancel on active reservations
      if (['cancelled', 'completed', 'rejected', 'cancel_requested'].includes(existing.booking_status)) {
        return ctx.badRequest(`Cannot request cancellation for a reservation with status "${existing.booking_status}"`);
      }

      // Check play date mafetch wa9tou
      const playDate = new Date(existing.booking_date_play);
      playDate.setHours(23, 59, 59);
      if (playDate < new Date()) {
        return ctx.badRequest('Cannot cancel a past reservation');
      }

      const entity = await strapi.service('api::reservation.reservation').update(id, {
        data: {
          booking_status:       'cancel_requested',
          cancellation_reason:  reason?.trim() || null,
        },
        populate: ['court', 'player', 'time_slot'],
      });

      // Notify worker/manager that player wants to cancel
      await sendBookingNotification(strapi, id, 'cancel_requested', {
        cancellationReason: reason?.trim() || '',
      });

      strapi.log.info(`[reservation] Cancel requested for ${id} by player. Reason: ${reason}`);
      return this.transformResponse(entity);
    } catch (error) {
      strapi.log.error('[reservation] requestCancel error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  
  async confirm(ctx) {
    try {
      const { id } = ctx.params;
      const user   = ctx.state.user;

      const existing = await strapi.entityService.findOne('api::reservation.reservation', id, {
        populate: ['player', 'player.player', 'court', 'court.venue', 'court.venue.manager', 'time_slot'],
      });
      if (!existing) return ctx.notFound('Reservation not found');

      const perm = await canActOnReservation(strapi, user, existing, 'confirm');
      if (!perm.allowed) return ctx.forbidden(perm.reason);

      if (existing.booking_status !== 'pending') {
        return ctx.badRequest(`Can only confirm pending reservations (current: "${existing.booking_status}")`);
      }

      
      let managerId = null, managerRecord = null;
      const venueManager = existing.court?.venue?.manager;
      if (venueManager?.id) {
        managerId     = venueManager.id;
        managerRecord = await strapi.db.query('api::manager.manager').findOne({ where: { id: managerId } });
      }

      const entity = await strapi.service('api::reservation.reservation').update(id, {
        data:     { booking_status: 'confirmed', manager: managerId },
        populate: ['court', 'player', 'time_slot', 'manager'],
      });

      // conversation tet7al
      const playerProfile = await strapi.db.query('api::player.player').findOne({
        where: { id: existing.player.id }, populate: { player: true },
      });
      const playerUser = playerProfile?.player
          ? await strapi.entityService.findOne('plugin::users-permissions.user', playerProfile.player.id, {}).catch(() => null)
          : null;

      await openReservationConversations(strapi, {
        reservationId:  id,
        courtId:        existing.court?.id,
        player:         playerProfile || { id: existing.player.id },
        playerUserName: playerUser?.username,
        managerId,
        managerRecord,
      });

      await sendBookingNotification(strapi, id, 'confirmed');
      strapi.log.info(`[reservation] ${id} confirmed by ${user.user_role}`);
      return this.transformResponse(entity);
    } catch (error) {
      strapi.log.error('[reservation] confirm error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  
  async reject(ctx) {
    try {
      const { id }    = ctx.params;
      const user      = ctx.state.user;
      const { reason } = ctx.request.body ?? {};

      const existing = await strapi.entityService.findOne('api::reservation.reservation', id, {
        populate: ['player', 'court', 'court.venue', 'time_slot'],
      });
      if (!existing) return ctx.notFound('Reservation not found');

      const perm = await canActOnReservation(strapi, user, existing, 'reject');
      if (!perm.allowed) return ctx.forbidden(perm.reason);

      if (!['pending', 'confirmed'].includes(existing.booking_status)) {
        return ctx.badRequest(`Cannot reject a reservation with status "${existing.booking_status}"`);
      }

      // Free the time slot
      if (existing.time_slot?.id) {
        await strapi.entityService.update('api::time-slot.time-slot', existing.time_slot.id, {
          data: { isActive: true },
        });
      }

      const entity = await strapi.service('api::reservation.reservation').update(id, {
        data: {
          booking_status:   'rejected',
          rejection_reason: reason?.trim() || null,
        },
        populate: ['court', 'player', 'time_slot'],
      });

      await updateFirestoreStatus(strapi, id, 'rejected');
      await sendBookingNotification(strapi, id, 'rejected', {
        rejectionReason: reason?.trim() || '',
      });

      strapi.log.info(`[reservation] ${id} rejected by ${user.user_role}. Reason: ${reason}`);
      return this.transformResponse(entity);
    } catch (error) {
      strapi.log.error('[reservation] reject error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

 
  async cancel(ctx) {
    try {
      const { id } = ctx.params;
      const user   = ctx.state.user;

      const existing = await strapi.entityService.findOne('api::reservation.reservation', id, {
        populate: ['player', 'court', 'court.venue', 'time_slot'],
      });
      if (!existing) return ctx.notFound('Reservation not found');

      const perm = await canActOnReservation(strapi, user, existing, 'cancel');
      if (!perm.allowed) return ctx.forbidden(perm.reason);

      if (['cancelled', 'completed', 'rejected'].includes(existing.booking_status)) {
        return ctx.badRequest(`Reservation is already "${existing.booking_status}"`);
      }

      // Free the time slot
      if (existing.time_slot?.id) {
        await strapi.entityService.update('api::time-slot.time-slot', existing.time_slot.id, {
          data: { isActive: true },
        });
      }

      const entity = await strapi.service('api::reservation.reservation').update(id, {
        data: { booking_status: 'cancelled' },
        populate: ['court', 'player', 'time_slot'],
      });

      await updateFirestoreStatus(strapi, id, 'cancelled');
      await sendBookingNotification(strapi, id, 'cancelled');

      strapi.log.info(`[reservation] ${id} cancelled by ${user.user_role}`);
      return this.transformResponse(entity);
    } catch (error) {
      strapi.log.error('[reservation] cancel error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  
  async complete(ctx) {
    try {
      const { id } = ctx.params;
      const user   = ctx.state.user;

      const existing = await strapi.entityService.findOne('api::reservation.reservation', id, {
        populate: ['player', 'court', 'court.venue', 'time_slot'],
      });
      if (!existing) return ctx.notFound('Reservation not found');

      const perm = await canActOnReservation(strapi, user, existing, 'complete');
      if (!perm.allowed) return ctx.forbidden(perm.reason);

      if (existing.booking_status !== 'confirmed') {
        return ctx.badRequest(`Only confirmed reservations can be completed (current: "${existing.booking_status}")`);
      }

      const entity = await strapi.service('api::reservation.reservation').update(id, {
        data: { booking_status: 'completed' },
        populate: ['court', 'player', 'time_slot'],
      });

      await updateFirestoreStatus(strapi, id, 'completed');
      await sendBookingNotification(strapi, id, 'completed');

      strapi.log.info(`[reservation] ${id} completed by ${user.user_role}`);
      return this.transformResponse(entity);
    } catch (error) {
      strapi.log.error('[reservation] complete error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  async delete(ctx) {
    try {
      const { id } = ctx.params;
      const user   = ctx.state.user;

      if (user?.user_role !== 'manager' && user?.user_role !== 'admin') {
        return ctx.forbidden('Only managers and admins can delete reservations');
      }

      await updateFirestoreStatus(strapi, id, 'deleted').catch(() => {});
      const entity = await strapi.service('api::reservation.reservation').delete(id);
      return this.transformResponse(entity);
    } catch (error) {
      strapi.log.error('[reservation] delete error:', error.message);
      return ctx.badRequest(error.message);
    }
  },
}));

