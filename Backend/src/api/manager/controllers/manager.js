// src/api/manager/controllers/manager.js
// @ts-nocheck
'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::manager.manager', ({ strapi }) => ({

  //  PATCH /managers/me/firebase 
  async updateFirebase(ctx) {
    try {
      const user = ctx.state.user;
      if (!user) return ctx.unauthorized();

      const { firebaseUid, fcmToken } = ctx.request.body;

      const managers = await strapi.entityService.findMany('api::manager.manager', {
        filters: { manager: user.id },
        limit: 1,
      });

      if (!managers?.[0]) {
        return ctx.notFound('Manager profile not found');
      }

      const manager = managers[0];

      const updated = await strapi.entityService.update('api::manager.manager', manager.id, {
        data: {
          firebaseUid: firebaseUid || manager.firebaseUid,
          fcmToken:    fcmToken    || manager.fcmToken,
        },
      });

      console.log(`[manager] Firebase identity updated for manager ${manager.id}: uid=${firebaseUid}`);

      return ctx.send({ data: { id: updated.id, firebaseUid: updated.firebaseUid, fcmToken: updated.fcmToken } });

    } catch (err) {
      console.error('[manager] updateFirebase error:', err);
      return ctx.badRequest(err.message);
    }
  },

  // 
  // WORKER MANAGEMENT
  // 

  async getMyWorkers(ctx) {
    try {
      const user = ctx.state.user;
      const managerId = user.managerId;

      if (!managerId) {
        return ctx.badRequest('Manager profile not found');
      }

      const workers = await strapi.db.query('api::worker.worker').findMany({
        where: { manager: { id: managerId } },
        populate: {
          courts: {
            populate: {
              court_img: true,
              venue: true,
            },
          },
          photo: true,
          worker: {
            select: ['id', 'username', 'email'],
          },
        },
        orderBy: { joinedAt: 'desc' },
      });

      const baseUrl = strapi.config.get('server.url') || '';

      const transformed = workers.map(worker => ({
        id: worker.id,
        nom: worker.nom,
        phone: worker.phone,
        isActive: worker.isActive,
        joinedAt: worker.joinedAt,
        firebaseUid: worker.firebaseUid,
        photo_url: worker.photo?.url
          ? (worker.photo.url.startsWith('http') ? worker.photo.url : `${baseUrl}${worker.photo.url}`)
          : null,
        user: worker.worker,
        courts: (worker.courts || []).map(court => ({
          id: court.id,
          name: court.name,
          venue: court.venue,
          court_img_url: court.court_img?.url
            ? (court.court_img.url.startsWith('http') ? court.court_img.url : `${baseUrl}${court.court_img.url}`)
            : null,
        })),
      }));

      return ctx.send({ workers: transformed });
    } catch (error) {
      console.error('[manager] getMyWorkers error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  async assignWorkerCourts(ctx) {
    try {
      const { id } = ctx.params;
      const { courtIds } = ctx.request.body;
      const user = ctx.state.user;
      const managerId = user.managerId;

      if (!managerId) return ctx.badRequest('Manager profile not found');
      if (!courtIds || !Array.isArray(courtIds)) return ctx.badRequest('courtIds array is required');

      const worker = await strapi.db.query('api::worker.worker').findOne({
        where: { id: id, manager: { id: managerId } },
      });

      if (!worker) return ctx.notFound('Worker not found or not under your management');

      for (const courtId of courtIds) {
        const court = await strapi.db.query('api::court.court').findOne({
          where: { id: courtId },
          populate: ['venue', 'venue.manager'],
        });
        if (!court) return ctx.badRequest(`Court ${courtId} not found`);
        if (court.venue?.manager?.id !== managerId) return ctx.forbidden(`Court ${courtId} does not belong to your venues`);
      }

      const currentCourts = await strapi.db.query('api::court.court').findMany({
        where: { worker: id },
      });
      for (const court of currentCourts) {
        await strapi.db.query('api::court.court').update({ where: { id: court.id }, data: { worker: null } });
      }
      for (const courtId of courtIds) {
        await strapi.db.query('api::court.court').update({ where: { id: courtId }, data: { worker: id } });
      }

      return ctx.send({ message: 'Worker assigned to courts successfully', workerId: id, courtIds });
    } catch (error) {
      console.error('[manager] assignWorkerCourts error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  async removeWorkerFromCourt(ctx) {
    try {
      const { id, courtId } = ctx.params;
      const user = ctx.state.user;
      const managerId = user.managerId;

      if (!managerId) return ctx.badRequest('Manager profile not found');

      const worker = await strapi.db.query('api::worker.worker').findOne({
        where: { id: id, manager: { id: managerId } },
      });
      if (!worker) return ctx.notFound('Worker not found or not under your management');

      const court = await strapi.db.query('api::court.court').findOne({
        where: { id: courtId },
        populate: ['venue', 'venue.manager'],
      });
      if (!court) return ctx.notFound('Court not found');
      if (court.venue?.manager?.id !== managerId) return ctx.forbidden('This court does not belong to your venues');
      if (court.worker !== parseInt(id)) return ctx.badRequest('This worker is not assigned to this court');

      await strapi.db.query('api::court.court').update({ where: { id: courtId }, data: { worker: null } });

      return ctx.send({ message: 'Worker removed from court successfully', workerId: id, courtId });
    } catch (error) {
      console.error('[manager] removeWorkerFromCourt error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  async getWorkerById(ctx) {
    try {
      const { id } = ctx.params;
      const user = ctx.state.user;
      const managerId = user.managerId;

      if (!managerId) return ctx.badRequest('Manager profile not found');

      const worker = await strapi.db.query('api::worker.worker').findOne({
        where: { id: id, manager: { id: managerId } },
        populate: {
          courts: { populate: { court_img: true, venue: true } },
          photo: true,
          worker: { select: ['id', 'username', 'email'] },
        },
      });

      if (!worker) return ctx.notFound('Worker not found or not under your management');

      const baseUrl = strapi.config.get('server.url') || '';

      return ctx.send({
        worker: {
          id: worker.id,
          nom: worker.nom,
          phone: worker.phone,
          isActive: worker.isActive,
          joinedAt: worker.joinedAt,
          firebaseUid: worker.firebaseUid,
          photo_url: worker.photo?.url
            ? (worker.photo.url.startsWith('http') ? worker.photo.url : `${baseUrl}${worker.photo.url}`)
            : null,
          user: worker.worker,
          courts: (worker.courts || []).map(court => ({
            id: court.id,
            name: court.name,
            description: court.description,
            sport: court.sport,
            pricePerHour: court.pricePerHour,
            capacity: court.capacity,
            isActive: court.isActive,
            venue: court.venue,
            court_img_url: court.court_img?.url
              ? (court.court_img.url.startsWith('http') ? court.court_img.url : `${baseUrl}${court.court_img.url}`)
              : null,
          })),
        },
      });
    } catch (error) {
      console.error('[manager] getWorkerById error:', error.message);
      return ctx.badRequest(error.message);
    }
  },

  // 
  // GET /managers/user/:userType/:userId/photo
  // ─────────────────────────────────────────────────────────────────────────
  async getUserPhoto(ctx) {
    try {
      const { userType, userId } = ctx.params;
      // Always parse to integer — URL params are strings, Strapi relations need numbers
      const userIdInt = parseInt(userId, 10);

      if (isNaN(userIdInt)) {
        return ctx.badRequest('Invalid userId');
      }

      const baseUrl = strapi.config.get('server.url') || '';
      let photoUrl = null;

      // ── Helper: resolve a raw photo object to a URL string ───────────────
      function resolvePhotoUrl(photo) {
        if (!photo) return null;
        // Direct url on object (db.query style)
        if (photo.url) {
          return photo.url.startsWith('http') ? photo.url : `${baseUrl}${photo.url}`;
        }
        // Nested data.attributes (REST API style)
        if (photo.data?.attributes?.url) {
          const u = photo.data.attributes.url;
          return u.startsWith('http') ? u : `${baseUrl}${u}`;
        }
        // Nested data.url
        if (photo.data?.url) {
          const u = photo.data.url;
          return u.startsWith('http') ? u : `${baseUrl}${u}`;
        }
        return null;
      }

      if (userType === 'player') {
        // ── Strategy 1: find player profile by the linked user id ───────────
        // The 'player' field on the player content-type is a relation to users-permissions.user
        const playerProfile = await strapi.db.query('api::player.player').findOne({
          where: { player: { id: userIdInt } },
          populate: { photo: true },
        });

        console.log(`[getUserPhoto] player profile for userId=${userIdInt}:`, playerProfile ? `id=${playerProfile.id}` : 'NOT FOUND');

        if (playerProfile) {
          photoUrl = resolvePhotoUrl(playerProfile.photo);
          console.log(`[getUserPhoto] photo from playerProfile:`, photoUrl);
        }

        // ── Strategy 2: query by player.id directly (in case userId IS the player id) ──
        if (!photoUrl) {
          const playerById = await strapi.db.query('api::player.player').findOne({
            where: { id: userIdInt },
            populate: { photo: true },
          });
          if (playerById) {
            photoUrl = resolvePhotoUrl(playerById.photo);
            console.log(`[getUserPhoto] photo from playerById:`, photoUrl);
          }
        }

        // ── Strategy 3: walk through entityService with deep populate ───────
        if (!photoUrl) {
          const players = await strapi.entityService.findMany('api::player.player', {
            filters: { player: { id: userIdInt } },
            populate: { photo: true },
            limit: 1,
          });
          if (players?.[0]) {
            photoUrl = resolvePhotoUrl(players[0].photo);
            console.log(`[getUserPhoto] photo from entityService:`, photoUrl);
          }
        }

        // ── Strategy 4: fetch via upload plugin — find media owned by user ──
        if (!photoUrl) {
          // Look up the user's avatar if stored directly on the user record
          const userRecord = await strapi.db.query('plugin::users-permissions.user').findOne({
            where: { id: userIdInt },
            populate: { avatar: true, photo: true },
          });
          if (userRecord) {
            photoUrl = resolvePhotoUrl(userRecord.avatar) || resolvePhotoUrl(userRecord.photo);
            console.log(`[getUserPhoto] photo from userRecord:`, photoUrl);
          }
        }

      } else if (userType === 'worker') {
        // ── Worker: same multi-strategy approach ─────────────────────────────
        const workerProfile = await strapi.db.query('api::worker.worker').findOne({
          where: { worker: { id: userIdInt } },
          populate: { photo: true },
        });

        console.log(`[getUserPhoto] worker profile for userId=${userIdInt}:`, workerProfile ? `id=${workerProfile.id}` : 'NOT FOUND');

        if (workerProfile) {
          photoUrl = resolvePhotoUrl(workerProfile.photo);
        }

        if (!photoUrl) {
          const workerById = await strapi.db.query('api::worker.worker').findOne({
            where: { id: userIdInt },
            populate: { photo: true },
          });
          if (workerById) {
            photoUrl = resolvePhotoUrl(workerById.photo);
          }
        }
      }

      console.log(`[getUserPhoto] FINAL result — userType=${userType}, userId=${userIdInt}, photoUrl=${photoUrl}`);

      return ctx.send({
        userId: userIdInt,
        userType,
        photoUrl,
      });

    } catch (error) {
      console.error('[manager] getUserPhoto error:', error.message, error.stack);
      return ctx.badRequest(error.message);
    }
  },

  // ── GET /managers/player/:playerId/username ─────────────────────────────────
// Get username of a player by their user ID
// Add this method to the existing manager controller
async getPlayerUsername(ctx) {
  try {
    const { playerId } = ctx.params;
    console.log('[manager] getPlayerUsername called for playerId:', playerId);
    
    // First find the player profile
    const playerProfile = await strapi.db.query('api::player.player').findOne({
      where: { id: parseInt(playerId) },
      populate: ['player'], // This gets the linked user
    });
    
    console.log('[manager] Player profile found:', playerProfile ? `id=${playerProfile.id}` : 'NOT FOUND');
    
    if (!playerProfile) {
      return ctx.notFound('Player profile not found');
    }
    
    // Get the user from the player profile
    const userId = playerProfile.player?.id;
    if (!userId) {
      return ctx.notFound('User not found for this player');
    }
    
    // Get the user
    const user = await strapi.db.query('plugin::users-permissions.user').findOne({
      where: { id: userId },
    });
    
    console.log('[manager] User found:', user ? `id=${user.id}, username=${user.username}` : 'NOT FOUND');
    
    if (!user) {
      return ctx.notFound('User not found');
    }
    
    return ctx.send({
      id: user.id,
      username: user.username,
      email: user.email,
    });
  } catch (error) {
    console.error('[manager] getPlayerUsername error:', error.message);
    return ctx.badRequest(error.message);
  }
},

}));

