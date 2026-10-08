// src/api/worker/controllers/worker.js
// @ts-nocheck
'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::worker.worker', ({ strapi }) => ({

  // ── GET /workers/me/courts ──────────────────────────────────────────────
  async getMyCourts(ctx) {
    try {
      const user = ctx.state.user;
      if (!user || user.user_role !== 'worker') {
        return ctx.unauthorized('Only workers can access this endpoint');
      }

      const workers = await strapi.entityService.findMany('api::worker.worker', {
        filters: { worker: user.id },
        populate: {
          courts: {
            populate: {
              court_img: true,
              photos: true,
              venue: true,
              worker: true,
            },
          },
        },
        limit: 1,
      });

      if (!workers || workers.length === 0) {
        return ctx.notFound('Worker profile not found');
      }

      const worker = workers[0];
      const baseUrl = strapi.config.get('server.url') || '';

      const transformedCourts = (worker.courts || []).map(court => ({
        ...court,
        court_img_url: court.court_img?.url
          ? (court.court_img.url.startsWith('http') ? court.court_img.url : `${baseUrl}${court.court_img.url}`)
          : null,
        photos_urls: (court.photos || []).map(p =>
          p.url ? (p.url.startsWith('http') ? p.url : `${baseUrl}${p.url}`) : null
        ).filter(Boolean),
        worker: court.worker ? {
          id: court.worker.id,
          nom: court.worker.nom,
          phone: court.worker.phone
        } : null,
      }));

      return ctx.send({ courts: transformedCourts });
    } catch (error) {
      console.error('[worker] getMyCourts error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  // ── GET /workers/me/reservations ─────────────────────────────────────────
  async getMyReservations(ctx) {
    try {
      const user = ctx.state.user;
      if (!user || user.user_role !== 'worker') {
        return ctx.unauthorized('Only workers can access this endpoint');
      }

      const workers = await strapi.entityService.findMany('api::worker.worker', {
        filters: { worker: user.id },
        populate: { courts: true },
        limit: 1,
      });

      if (!workers || workers.length === 0) {
        return ctx.notFound('Worker profile not found');
      }

      const worker = workers[0];
      const courtIds = (worker.courts || []).map(c => c.id);

      if (courtIds.length === 0) {
        return ctx.send({ reservations: [] });
      }

      const reservations = await strapi.entityService.findMany('api::reservation.reservation', {
        filters: { court: { id: { $in: courtIds } } },
        populate: {
          court: { populate: ['court_img', 'photos', 'venue'] },
          player: { populate: ['player'] },
          time_slot: true,
        },
        sort: { booking_date_play: 'desc' },
      });

      const baseUrl = strapi.config.get('server.url') || '';
      const transformed = reservations.map(res => {
        if (res.court) {
          res.court.court_img_url = res.court.court_img?.url
            ? (res.court.court_img.url.startsWith('http') ? res.court.court_img.url : `${baseUrl}${res.court.court_img.url}`)
            : null;
        }
        return res;
      });

      return ctx.send({ reservations: transformed });
    } catch (error) {
      console.error('[worker] getMyReservations error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  // ── GET /workers/me/reservations/upcoming ─────────────────────────────────
  async getUpcomingReservations(ctx) {
    try {
      const user = ctx.state.user;
      if (!user || user.user_role !== 'worker') {
        return ctx.unauthorized('Only workers can access this endpoint');
      }

      const workers = await strapi.entityService.findMany('api::worker.worker', {
        filters: { worker: user.id },
        populate: { courts: true },
        limit: 1,
      });

      if (!workers || workers.length === 0) {
        return ctx.notFound('Worker profile not found');
      }

      const worker = workers[0];
      const courtIds = (worker.courts || []).map(c => c.id);

      if (courtIds.length === 0) {
        return ctx.send({ reservations: [] });
      }

      const today = new Date().toISOString().split('T')[0];

      const reservations = await strapi.entityService.findMany('api::reservation.reservation', {
        filters: {
          court: { id: { $in: courtIds } },
          booking_date_play: { $gte: today },
          booking_status: { $ne: 'cancelled' },
        },
        populate: {
          court: { populate: ['court_img', 'photos', 'venue'] },
          player: { populate: ['player'] },
          time_slot: true,
        },
        sort: { booking_date_play: 'asc', start_time: 'asc' },
      });

      const baseUrl = strapi.config.get('server.url') || '';
      const transformed = reservations.map(res => {
        if (res.court) {
          res.court.court_img_url = res.court.court_img?.url
            ? (res.court.court_img.url.startsWith('http') ? res.court.court_img.url : `${baseUrl}${res.court.court_img.url}`)
            : null;
        }
        return res;
      });

      return ctx.send({ reservations: transformed });
    } catch (error) {
      console.error('[worker] getUpcomingReservations error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  // ── PUT /workers/me/reservations/:id/confirm ──────────────────────────────
  async confirmReservation(ctx) {
    try {
      const { id } = ctx.params;
      const user = ctx.state.user;

      if (!user || user.user_role !== 'worker') {
        return ctx.unauthorized('Only workers can access this endpoint');
      }

      const workers = await strapi.entityService.findMany('api::worker.worker', {
        filters: { worker: user.id },
        populate: { courts: true },
        limit: 1,
      });

      if (!workers || workers.length === 0) {
        return ctx.notFound('Worker profile not found');
      }

      const worker = workers[0];
      const courtIds = (worker.courts || []).map(c => c.id);

      const reservation = await strapi.entityService.findOne('api::reservation.reservation', id, {
        populate: ['court', 'player', 'time_slot'],
      });

      if (!reservation) return ctx.notFound('Reservation not found');
      if (!courtIds.includes(reservation.court?.id)) {
        return ctx.forbidden('You are not assigned to the court for this reservation');
      }
      if (reservation.booking_status !== 'pending') {
        return ctx.badRequest(`Reservation cannot be confirmed (current status: ${reservation.booking_status})`);
      }

      const updated = await strapi.entityService.update('api::reservation.reservation', id, {
        data: { booking_status: 'confirmed' },
      });

      try {
        const firebaseService = require('../../../firebase/firebase.service');
        const db = firebaseService.getFirestore();
        const ref = db.collection('conversations').doc(String(id));
        const snap = await ref.get();

        if (!snap.exists) {
          const playerProfile = await strapi.entityService.findOne('api::player.player', reservation.player.id, {});
          const playerUser = await strapi.entityService.findOne('plugin::users-permissions.user', playerProfile?.player?.id || reservation.player.id, {});

          const pUid = playerProfile?.firebaseUid || `sporta_player_${reservation.player.id}`;
          const wUid = worker.firebaseUid || `sporta_worker_${worker.id}`;

          await ref.set({
            reservationId: Number(id),
            participants: [pUid, wUid],
            participantIds: { player: String(reservation.player.id), worker: String(worker.id) },
            playerId: reservation.player.id,
            workerId: worker.id,
            playerName: playerUser?.username || playerProfile?.nom || 'Player',
            workerName: worker.nom || 'Worker',
            status: 'active',
            createdAt: new Date(),
            lastMessage: null,
            lastMessageAt: null,
          });
        }
      } catch (err) {
        console.error('[worker] Firebase error:', err.message);
      }

      return ctx.send({ message: 'Reservation confirmed successfully', reservation: updated });
    } catch (error) {
      console.error('[worker] confirmReservation error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  // ── PUT /workers/me/reservations/:id/cancel ───────────────────────────────
  async cancelReservation(ctx) {
    try {
      const { id } = ctx.params;
      const user = ctx.state.user;

      if (!user || user.user_role !== 'worker') {
        return ctx.unauthorized('Only workers can access this endpoint');
      }

      const workers = await strapi.entityService.findMany('api::worker.worker', {
        filters: { worker: user.id },
        populate: { courts: true },
        limit: 1,
      });

      if (!workers || workers.length === 0) {
        return ctx.notFound('Worker profile not found');
      }

      const worker = workers[0];
      const courtIds = (worker.courts || []).map(c => c.id);

      const reservation = await strapi.entityService.findOne('api::reservation.reservation', id, {
        populate: ['court', 'time_slot'],
      });

      if (!reservation) return ctx.notFound('Reservation not found');
      if (!courtIds.includes(reservation.court?.id)) {
        return ctx.forbidden('You are not assigned to the court for this reservation');
      }
      if (['completed', 'cancelled'].includes(reservation.booking_status)) {
        return ctx.badRequest(`Reservation is already ${reservation.booking_status}`);
      }

      if (reservation.time_slot?.id) {
        await strapi.entityService.update('api::time-slot.time-slot', reservation.time_slot.id, {
          data: { isActive: true },
        });
      }

      const updated = await strapi.entityService.update('api::reservation.reservation', id, {
        data: { booking_status: 'cancelled' },
      });

      try {
        const firebaseService = require('../../../firebase/firebase.service');
        const db = firebaseService.getFirestore();
        await db.collection('conversations').doc(String(id)).update({
          status: 'cancelled',
          updatedAt: new Date(),
        });
      } catch (err) {}

      return ctx.send({ message: 'Reservation cancelled successfully', reservation: updated });
    } catch (error) {
      console.error('[worker] cancelReservation error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  // ── GET /workers/me/time-slots ────────────────────────────────────────────
  async getMyTimeSlots(ctx) {
    try {
      const user = ctx.state.user;
      const { date, dayPlanId } = ctx.query;

      if (!user || user.user_role !== 'worker') {
        return ctx.unauthorized('Only workers can access this endpoint');
      }

      const workers = await strapi.entityService.findMany('api::worker.worker', {
        filters: { worker: user.id },
        populate: { courts: true },
        limit: 1,
      });

      if (!workers || workers.length === 0) {
        return ctx.notFound('Worker profile not found');
      }

      const worker = workers[0];
      const courtIds = (worker.courts || []).map(c => c.id);

      if (courtIds.length === 0) return ctx.send({ timeSlots: [] });

      if (date) {
        const dayPlans = await strapi.entityService.findMany('api::day-plan.day-plan', {
          filters: { date },
          populate: { time_slots: true, week_agend: { populate: ['court'] } },
        });

        const relevantDayPlans = dayPlans.filter(dp => courtIds.includes(dp.week_agend?.court?.id));
        const allTimeSlots = relevantDayPlans.flatMap(dp =>
          (dp.time_slots || []).map(ts => ({
            ...ts,
            dayPlanId: dp.id,
            dayPlanDate: dp.date,
            courtId: dp.week_agend?.court?.id,
            courtName: dp.week_agend?.court?.name,
          }))
        );

        return ctx.send({ timeSlots: allTimeSlots });
      }

      if (dayPlanId) {
        const dayPlan = await strapi.entityService.findOne('api::day-plan.day-plan', dayPlanId, {
          populate: { time_slots: true, week_agend: { populate: ['court'] } },
        });

        if (!dayPlan) return ctx.send({ timeSlots: [] });
        if (!courtIds.includes(dayPlan.week_agend?.court?.id)) {
          return ctx.forbidden('You are not assigned to the court for this day plan');
        }

        const timeSlots = (dayPlan.time_slots || []).map(ts => ({
          ...ts,
          dayPlanDate: dayPlan.date,
        }));

        return ctx.send({ timeSlots });
      }

      return ctx.send({ timeSlots: [] });
    } catch (error) {
      console.error('[worker] getMyTimeSlots error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  // ── PUT /workers/me/time-slots/:id ────────────────────────────────────────
  async updateTimeSlot(ctx) {
    try {
      const { id } = ctx.params;
      const user = ctx.state.user;
      const { isActive } = ctx.request.body;

      if (!user || user.user_role !== 'worker') {
        return ctx.unauthorized('Only workers can access this endpoint');
      }

      const workers = await strapi.entityService.findMany('api::worker.worker', {
        filters: { worker: user.id },
        populate: { courts: true },
        limit: 1,
      });

      if (!workers || workers.length === 0) {
        return ctx.notFound('Worker profile not found');
      }

      const worker = workers[0];
      const courtIds = (worker.courts || []).map(c => c.id);

      const timeSlot = await strapi.entityService.findOne('api::time-slot.time-slot', id, {
        populate: { day_plan: { populate: { week_agend: { populate: ['court'] } } }, reservation: true },
      });

      if (!timeSlot) return ctx.notFound('Time slot not found');

      const court = timeSlot.day_plan?.week_agend?.court;
      if (!court || !courtIds.includes(court.id)) {
        return ctx.forbidden('You are not assigned to the court for this time slot');
      }

      if (isActive === false && timeSlot.reservation) {
        return ctx.badRequest('Cannot deactivate a time slot that has an active reservation');
      }

      const updated = await strapi.entityService.update('api::time-slot.time-slot', id, {
        data: { isActive: isActive !== undefined ? isActive : !timeSlot.isActive },
      });

      return ctx.send({ message: 'Time slot updated successfully', timeSlot: updated });
    } catch (error) {
      console.error('[worker] updateTimeSlot error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  // ── GET /workers/me ───────────────────────────────────────────────────────
  async getMe(ctx) {
    try {
      const user = ctx.state.user;
      if (!user || user.user_role !== 'worker') {
        return ctx.unauthorized('Only workers can access this endpoint');
      }

      const workers = await strapi.entityService.findMany('api::worker.worker', {
        filters: { worker: user.id },
        populate: {
          courts: {
            populate: { court_img: true, venue: true, worker: true },
          },
          manager: { populate: ['manager'] },
          photo: true,
        },
        limit: 1,
      });

      if (!workers || workers.length === 0) {
        return ctx.notFound('Worker profile not found');
      }

      const worker = workers[0];
      const baseUrl = strapi.config.get('server.url') || '';

      return ctx.send({
        worker: {
          ...worker,
          // Expose the linked user's email for the profile form
          email: user.email,
          photo_url: worker.photo?.url
            ? (worker.photo.url.startsWith('http') ? worker.photo.url : `${baseUrl}${worker.photo.url}`)
            : null,
          courts: (worker.courts || []).map(court => ({
            id: court.id,
            name: court.name,
            court_img_url: court.court_img?.url
              ? (court.court_img.url.startsWith('http') ? court.court_img.url : `${baseUrl}${court.court_img.url}`)
              : null,
            venue: court.venue,
            worker: court.worker ? { id: court.worker.id, nom: court.worker.nom } : null,
          })),
        },
      });
    } catch (error) {
      console.error('[worker] getMe error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  // ── PATCH /workers/me/profile ─────────────────────────────────────────────
  // Update nom and phone on the worker content-type record.
  // Optionally also updates username on the linked user if provided.
  async updateProfile(ctx) {
    try {
      const user = ctx.state.user;
      if (!user || user.user_role !== 'worker') {
        return ctx.unauthorized('Only workers can access this endpoint');
      }

      const { nom, phone, username } = ctx.request.body;

      // Find the worker profile
      const workers = await strapi.entityService.findMany('api::worker.worker', {
        filters: { worker: user.id },
        limit: 1,
      });

      if (!workers || workers.length === 0) {
        return ctx.notFound('Worker profile not found');
      }

      const worker = workers[0];

      // Build the worker update payload — only include fields that were sent
      const workerData = {};
      if (nom !== undefined && nom !== null && nom.toString().trim() !== '') {
        workerData.nom = nom.toString().trim();
      }
      if (phone !== undefined && phone !== null) {
        workerData.phone = phone.toString().trim();
      }

      // Update the worker content-type record
      let updatedWorker = worker;
      if (Object.keys(workerData).length > 0) {
        updatedWorker = await strapi.entityService.update('api::worker.worker', worker.id, {
          data: workerData,
        });
        console.log(`[worker] Profile updated for worker ${worker.id}:`, workerData);
      }

      // Optionally update the username on the users-permissions user
      if (username !== undefined && username !== null && username.toString().trim() !== '') {
        await strapi.entityService.update('plugin::users-permissions.user', user.id, {
          data: { username: username.toString().trim() },
        });
        console.log(`[worker] Username updated for user ${user.id}: ${username}`);
      }

      return ctx.send({
        message: 'Profile updated successfully',
        worker: {
          id: updatedWorker.id,
          nom: updatedWorker.nom,
          phone: updatedWorker.phone,
        },
      });
    } catch (error) {
      console.error('[worker] updateProfile error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  // ── PATCH /workers/me/firebase ────────────────────────────────────────────
  async updateFirebase(ctx) {
    try {
      const user = ctx.state.user;
      if (!user || user.user_role !== 'worker') {
        return ctx.unauthorized('Only workers can access this endpoint');
      }

      const { firebaseUid, fcmToken } = ctx.request.body;

      const workers = await strapi.entityService.findMany('api::worker.worker', {
        filters: { worker: user.id },
        limit: 1,
      });

      if (!workers?.[0]) return ctx.notFound('Worker profile not found');

      const worker = workers[0];

      const updated = await strapi.entityService.update('api::worker.worker', worker.id, {
        data: {
          firebaseUid: firebaseUid || worker.firebaseUid,
          fcmToken: fcmToken || worker.fcmToken,
        },
      });

      console.log(`[worker] Firebase identity updated for worker ${worker.id}: uid=${firebaseUid}`);

      return ctx.send({ data: { id: updated.id, firebaseUid: updated.firebaseUid, fcmToken: updated.fcmToken } });
    } catch (err) {
      console.error('[worker] updateFirebase error:', err);
      return ctx.badRequest(err.message);
    }
  },

  // ── GET /workers/user/:userType/:userId/photo ─────────────────────────────
  async getUserPhoto(ctx) {
    try {
      const { userType, userId } = ctx.params;
      const userIdInt = parseInt(userId, 10);

      if (isNaN(userIdInt)) return ctx.badRequest('Invalid userId');

      const baseUrl = strapi.config.get('server.url') || '';
      let photoUrl = null;

      function resolvePhotoUrl(photo) {
        if (!photo) return null;
        if (photo.url) {
          return photo.url.startsWith('http') ? photo.url : `${baseUrl}${photo.url}`;
        }
        if (photo.data?.attributes?.url) {
          const u = photo.data.attributes.url;
          return u.startsWith('http') ? u : `${baseUrl}${u}`;
        }
        if (photo.data?.url) {
          const u = photo.data.url;
          return u.startsWith('http') ? u : `${baseUrl}${u}`;
        }
        return null;
      }

      if (userType === 'manager') {
        const managerProfile = await strapi.db.query('api::manager.manager').findOne({
          where: { manager: { id: userIdInt } },
          populate: { photo: true },
        });
        if (managerProfile) photoUrl = resolvePhotoUrl(managerProfile.photo);

        if (!photoUrl) {
          const managerById = await strapi.db.query('api::manager.manager').findOne({
            where: { id: userIdInt },
            populate: { photo: true },
          });
          if (managerById) photoUrl = resolvePhotoUrl(managerById.photo);
        }

        if (!photoUrl) {
          const managers = await strapi.entityService.findMany('api::manager.manager', {
            filters: { manager: userIdInt },
            populate: { photo: true },
            limit: 1,
          });
          if (managers?.[0]) photoUrl = resolvePhotoUrl(managers[0].photo);
        }

      } else if (userType === 'player') {
        const playerProfile = await strapi.db.query('api::player.player').findOne({
          where: { player: { id: userIdInt } },
          populate: { photo: true },
        });
        if (playerProfile) photoUrl = resolvePhotoUrl(playerProfile.photo);

        if (!photoUrl) {
          const playerById = await strapi.db.query('api::player.player').findOne({
            where: { id: userIdInt },
            populate: { photo: true },
          });
          if (playerById) photoUrl = resolvePhotoUrl(playerById.photo);
        }
      }

      console.log(`[worker/getUserPhoto] FINAL — userType=${userType}, userId=${userIdInt}, photoUrl=${photoUrl}`);

      return ctx.send({ userId: userIdInt, userType, photoUrl });
    } catch (error) {
      console.error('[worker] getUserPhoto error:', error.message, error.stack);
      return ctx.badRequest(error.message);
    }
  },

}));
