// src/api/player/controllers/player.js
// @ts-nocheck
'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::player.player', ({ strapi }) => ({

  //  PATCH /players/me/firebase 
 
  async updateFirebase(ctx) {
    try {
      const user = ctx.state.user;
      if (!user) return ctx.unauthorized();

      const { firebaseUid, fcmToken } = ctx.request.body;

      
      const players = await strapi.entityService.findMany('api::player.player', {
        filters: { player: user.id },
        limit: 1,
      });

      if (!players?.[0]) {
        return ctx.notFound('Player profile not found');
      }

      const player = players[0];

     
      const updated = await strapi.entityService.update('api::player.player', player.id, {
        data: {
          firebaseUid: firebaseUid || player.firebaseUid,
          fcmToken:    fcmToken    || player.fcmToken,
        },
      });

      console.log(`[player] Firebase identity updated for player ${player.id}: uid=${firebaseUid}`);

      return ctx.send({ data: { id: updated.id, firebaseUid: updated.firebaseUid, fcmToken: updated.fcmToken } });

    } catch (err) {
      console.error('[player] updateFirebase error:', err);
      return ctx.badRequest(err.message);
    }
  },

  // GET /players/user/:userType/:userId/photo 
  // Returns the photo URL for a manager or worker (for player chat)
  async getUserPhoto(ctx) {
    try {
      const { userType, userId } = ctx.params;
      // strapi realations lazemha number tkoun
      const userIdInt = parseInt(userId, 10);

      if (isNaN(userIdInt)) {
        return ctx.badRequest('Invalid userId');
      }

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
          where: { manager: userIdInt },
          populate: { photo: true },
        });

        console.log(`[player/getUserPhoto] manager profile for userId=${userIdInt}:`, managerProfile ? `id=${managerProfile.id}` : 'NOT FOUND');

        if (managerProfile) {
          photoUrl = resolvePhotoUrl(managerProfile.photo);
          console.log(`[player/getUserPhoto] photo from managerProfile:`, photoUrl);
        }

        
        if (!photoUrl) {
          const managerById = await strapi.db.query('api::manager.manager').findOne({
            where: { id: userIdInt },
            populate: { photo: true },
          });
          if (managerById) {
            photoUrl = resolvePhotoUrl(managerById.photo);
            console.log(`[player/getUserPhoto] photo from managerById:`, photoUrl);
          }
        }

        
        if (!photoUrl) {
          const managers = await strapi.entityService.findMany('api::manager.manager', {
            filters: { manager: userIdInt },
            populate: { photo: true },
            limit: 1,
          });
          if (managers?.[0]) {
            photoUrl = resolvePhotoUrl(managers[0].photo);
            console.log(`[player/getUserPhoto] photo from entityService:`, photoUrl);
          }
        }

      } else if (userType === 'worker') {
       
        const workerProfile = await strapi.db.query('api::worker.worker').findOne({
          where: { worker: userIdInt },
          populate: { photo: true },
        });

        console.log(`[player/getUserPhoto] worker profile for userId=${userIdInt}:`, workerProfile ? `id=${workerProfile.id}` : 'NOT FOUND');

        if (workerProfile) {
          photoUrl = resolvePhotoUrl(workerProfile.photo);
          console.log(`[player/getUserPhoto] photo from workerProfile:`, photoUrl);
        }

        if (!photoUrl) {
          const workerById = await strapi.db.query('api::worker.worker').findOne({
            where: { id: userIdInt },
            populate: { photo: true },
          });
          if (workerById) {
            photoUrl = resolvePhotoUrl(workerById.photo);
            console.log(`[player/getUserPhoto] photo from workerById:`, photoUrl);
          }
        }
      }

      console.log(`[player/getUserPhoto] FINAL result — userType=${userType}, userId=${userIdInt}, photoUrl=${photoUrl}`);

      return ctx.send({
        userId: userIdInt,
        userType,
        photoUrl,
      });

    } catch (error) {
      console.error('[player] getUserPhoto error:', error.message, error.stack);
      return ctx.badRequest(error.message);
    }
  },

}));

