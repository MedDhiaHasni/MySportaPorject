// src/api/announcement/controllers/announcement.js
// @ts-nocheck
'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::announcement.announcement', ({ strapi }) => ({

  // GET /announcements
  async find(ctx) {
    try {
      const user = ctx.state.user;
      const player = await strapi.service('api::announcement.announcement').resolvePlayer(user.id);

      const announcements = await strapi.service('api::announcement.announcement').findOpenAnnouncements(player?.id);
      return ctx.send({ data: announcements });
    } catch (e) {
      strapi.log.error('[announcement.find]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  //  GET /announcements/mine 
  async mine(ctx) {
    try {
      const user = ctx.state.user;
      const player = await strapi.service('api::announcement.announcement').resolvePlayer(user.id);
      if (!player) return ctx.unauthorized('Player profile not found');

      const announcements = await strapi.service('api::announcement.announcement').findAnnouncementsByPlayer(player.id);
      return ctx.send({ data: announcements });
    } catch (e) {
      strapi.log.error('[announcement.mine]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  // GET /announcements/my-requests
  async myRequests(ctx) {
    try {
      const user = ctx.state.user;
      const player = await strapi.service('api::announcement.announcement').resolvePlayer(user.id);
      if (!player) return ctx.unauthorized('Player profile not found');

      const requests = await strapi.service('api::announcement.announcement').getJoinRequestsByPlayer(player.id);
      return ctx.send({ data: requests });
    } catch (e) {
      strapi.log.error('[announcement.myRequests]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  //  GET /announcements/:id 
  async findOne(ctx) {
    try {
      const announcement = await strapi.service('api::announcement.announcement').findAnnouncementById(ctx.params.id);
      if (!announcement) return ctx.notFound();
      return ctx.send({ data: announcement });
    } catch (e) {
      strapi.log.error('[announcement.findOne]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  //  POST /announcements 
  async create(ctx) {
    try {
      const user = ctx.state.user;
      const player = await strapi.service('api::announcement.announcement').resolvePlayer(user.id);
      if (!player) return ctx.unauthorized('Player profile not found');

      let data = ctx.request.body;
      if (data.data) data = data.data;

      const { reservation_id, description, players_needed } = data;
      if (!reservation_id) return ctx.badRequest('reservation_id is required');
      if (!description?.trim()) return ctx.badRequest('description is required');
      if (!players_needed || players_needed < 1) return ctx.badRequest('players_needed must be >= 1');

      // Verify reservation belongs to player
      const reservation = await strapi.service('api::announcement.announcement').getReservationWithPlayer(reservation_id);
      if (!reservation) return ctx.notFound('Reservation not found');
      if (String(reservation.player?.id) !== String(player.id)) return ctx.forbidden('Not your reservation');

      // Check for existing active announcement
      const hasActive = await strapi.service('api::announcement.announcement').hasActiveAnnouncement(reservation_id);
      if (hasActive) {
        return ctx.badRequest('An active announcement already exists for this reservation');
      }

      const announcement = await strapi.service('api::announcement.announcement').createAnnouncement(data, player.id);
      return ctx.send({ data: announcement }, 201);
    } catch (e) {
      strapi.log.error('[announcement.create]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  //  PUT /announcements/:id 
  async update(ctx) {
    try {
      const user = ctx.state.user;
      const player = await strapi.service('api::announcement.announcement').resolvePlayer(user.id);
      if (!player) return ctx.unauthorized();

      const existing = await strapi.service('api::announcement.announcement').findAnnouncementById(ctx.params.id);
      if (!existing) return ctx.notFound();
      if (String(existing.player?.id) !== String(player.id)) return ctx.forbidden('Not your announcement');

      let data = ctx.request.body;
      if (data.data) data = data.data;

      const updateData = {};
      if (data.description !== undefined) updateData.description = data.description;
      if (data.players_needed !== undefined) updateData.players_needed = parseInt(data.players_needed);
      if (data.status !== undefined) updateData.status = data.status;

      const announcement = await strapi.service('api::announcement.announcement').updateAnnouncement(ctx.params.id, updateData);
      return ctx.send({ data: announcement });
    } catch (e) {
      strapi.log.error('[announcement.update]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  //  DELETE /announcements/:id 
  async delete(ctx) {
    try {
      const user = ctx.state.user;
      const player = await strapi.service('api::announcement.announcement').resolvePlayer(user.id);
      if (!player) return ctx.unauthorized();

      const existing = await strapi.service('api::announcement.announcement').deleteAnnouncement(ctx.params.id);
      if (!existing) return ctx.notFound();
      if (String(existing.player?.id) !== String(player.id)) return ctx.forbidden('Not your announcement');

      return ctx.send({ message: 'Announcement deleted' });
    } catch (e) {
      strapi.log.error('[announcement.delete]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  //  POST /announcements/:id/requests 
  async requestJoin(ctx) {
    try {
      const user = ctx.state.user;
      const player = await strapi.service('api::announcement.announcement').resolvePlayer(user.id);
      if (!player) return ctx.unauthorized('Player profile not found');

      const announcement = await strapi.service('api::announcement.announcement').findAnnouncementById(ctx.params.id);
      if (!announcement) return ctx.notFound('Announcement not found');
      if (announcement.status !== 'open') return ctx.badRequest('This announcement is no longer open');
      if (String(announcement.player?.id) === String(player.id)) {
        return ctx.badRequest('You cannot join your own announcement');
      }

      const hasExisting = await strapi.service('api::announcement.announcement').hasExistingJoinRequest(ctx.params.id, player.id);
      if (hasExisting) return ctx.badRequest('You have already requested to join this announcement');

      let data = ctx.request.body;
      if (data.data) data = data.data;

      const joinRequest = await strapi.service('api::announcement.announcement').createJoinRequest(
        announcement.id,
        player.id,
        data.message || ''
      );

      return ctx.send({ data: joinRequest }, 201);
    } catch (e) {
      strapi.log.error('[announcement.requestJoin]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  //  PUT /announcements/:id/requests/:requestId 
  async respondToRequest(ctx) {
    try {
      const user = ctx.state.user;
      const player = await strapi.service('api::announcement.announcement').resolvePlayer(user.id);
      if (!player) return ctx.unauthorized();

      const announcement = await strapi.service('api::announcement.announcement').findAnnouncementById(ctx.params.id);
      if (!announcement) return ctx.notFound('Announcement not found');
      if (String(announcement.player?.id) !== String(player.id)) {
        return ctx.forbidden('Only the host can respond');
      }

      const { status } = ctx.request.body;
      if (!['accepted', 'declined'].includes(status)) {
        return ctx.badRequest('status must be "accepted" or "declined"');
      }

      const joinRequest = await strapi.service('api::announcement.announcement').updateJoinRequestStatus(ctx.params.requestId, status);

      // Auto-close when all spots filled
      if (status === 'accepted') {
        const acceptedCount = await strapi.service('api::announcement.announcement').getAcceptedCount(announcement.id);
        if (acceptedCount >= announcement.players_needed) {
          await strapi.service('api::announcement.announcement').closeAnnouncement(announcement.id);
        }
      }

      return ctx.send({ data: joinRequest });
    } catch (e) {
      strapi.log.error('[announcement.respondToRequest]', e.message);
      return ctx.badRequest(e.message);
    }
  },
}));
















/*// src/api/announcement/controllers/announcement.js
// Changes from previous version:
//   - join_requests now populate player.phone so host can see requester's phone
//   - player (host) populate also includes phone
// @ts-nocheck
'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

async function resolvePlayer(strapi, userId) {
  const players = await strapi.entityService.findMany('api::player.player', {
    filters: { player: userId },
    limit: 1,
  });
  return players?.[0] ?? null;
}

function absUrl(strapi, path) {
  if (!path) return null;
  if (path.startsWith('http')) return path;
  return `${strapi.config.get('server.url') || 'http://localhost:1337'}${path}`;
}

function enrichAnnouncement(ann, strapi) {
  if (!ann) return ann;
  const court = ann.reservation?.court;
  if (court) {
    court.court_img_url = absUrl(strapi, court.court_img?.url ?? null);
    court.photos_urls   = (court.photos || []).map(p => absUrl(strapi, p.url)).filter(Boolean);
  }
  return ann;
}

// Full populate — now includes phone on player profiles
const FULL_POPULATE = {
  // Host player
  player: {
    populate: {
      player: true, // auth user (for username, email, phone)
    },
  },
  // Reservation → court → venue + time slot
  reservation: {
    populate: {
      court:     { populate: ['court_img', 'photos', 'venue'] },
      time_slot: true,
    },
  },
  // Join requests — include phone so host can call the requester
  join_requests: {
    populate: {
      player: {
        populate: {
          player: true, // auth user — has phone, email, username
        },
      },
    },
  },
};

module.exports = createCoreController('api::announcement.announcement', ({ strapi }) => ({

  // ── GET /announcements ─────────────────────────────────────────────────────
  async find(ctx) {
    try {
      const user   = ctx.state.user;
      const player = await resolvePlayer(strapi, user.id);

      const filters = { status: 'open' };
      if (player) filters.player = { $ne: player.id };

      const entities = await strapi.entityService.findMany('api::announcement.announcement', {
        filters,
        populate:  FULL_POPULATE,
        sort:      { createdAt: 'desc' },
      });

      return ctx.send({ data: entities.map(e => enrichAnnouncement(e, strapi)) });
    } catch (e) {
      strapi.log.error('[announcement.find]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  // ── GET /announcements/mine ────────────────────────────────────────────────
  async mine(ctx) {
    try {
      const user   = ctx.state.user;
      const player = await resolvePlayer(strapi, user.id);
      if (!player) return ctx.unauthorized('Player profile not found');

      const entities = await strapi.entityService.findMany('api::announcement.announcement', {
        filters:  { player: player.id },
        populate:  FULL_POPULATE,
        sort:      { createdAt: 'desc' },
      });

      return ctx.send({ data: entities.map(e => enrichAnnouncement(e, strapi)) });
    } catch (e) {
      strapi.log.error('[announcement.mine]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  // ── GET /announcements/my-requests ─────────────────────────────────────────
  async myRequests(ctx) {
    try {
      const user   = ctx.state.user;
      const player = await resolvePlayer(strapi, user.id);
      if (!player) return ctx.unauthorized('Player profile not found');

      const requests = await strapi.entityService.findMany('api::join-request.join-request', {
        filters: { player: player.id },
        populate: {
          player: { populate: { player: true } },
          announcement: {
            populate: {
              player: { populate: { player: true } },
              reservation: {
                populate: {
                  court:     { populate: ['court_img', 'photos', 'venue'] },
                  time_slot: true,
                },
              },
            },
          },
        },
        sort: { createdAt: 'desc' },
      });

      const enriched = requests.map(req => {
        const court = req.announcement?.reservation?.court;
        if (court) {
          court.court_img_url = absUrl(strapi, court.court_img?.url ?? null);
          court.photos_urls   = (court.photos || []).map(p => absUrl(strapi, p.url)).filter(Boolean);
        }
        return req;
      });

      return ctx.send({ data: enriched });
    } catch (e) {
      strapi.log.error('[announcement.myRequests]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  // ── GET /announcements/:id ─────────────────────────────────────────────────
  async findOne(ctx) {
    try {
      const entity = await strapi.entityService.findOne(
        'api::announcement.announcement', ctx.params.id, { populate: FULL_POPULATE },
      );
      if (!entity) return ctx.notFound();
      return ctx.send({ data: enrichAnnouncement(entity, strapi) });
    } catch (e) {
      strapi.log.error('[announcement.findOne]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  // ── POST /announcements ────────────────────────────────────────────────────
  async create(ctx) {
    try {
      const user   = ctx.state.user;
      const player = await resolvePlayer(strapi, user.id);
      if (!player) return ctx.unauthorized('Player profile not found');

      let data = ctx.request.body;
      if (data.data) data = data.data;

      const { reservation_id, description, players_needed } = data;
      if (!reservation_id)               return ctx.badRequest('reservation_id is required');
      if (!description?.trim())          return ctx.badRequest('description is required');
      if (!players_needed || players_needed < 1) return ctx.badRequest('players_needed must be >= 1');

      const res = await strapi.entityService.findOne('api::reservation.reservation', reservation_id, {
        populate: ['player', 'court'],
      });
      if (!res) return ctx.notFound('Reservation not found');
      if (String(res.player?.id) !== String(player.id)) return ctx.forbidden('Not your reservation');

      const existing = await strapi.entityService.findMany('api::announcement.announcement', {
        filters: { reservation: reservation_id, status: { $ne: 'closed' } },
        limit: 1,
      });
      if (existing.length > 0) {
        return ctx.badRequest('An active announcement already exists for this reservation');
      }

      const entity = await strapi.entityService.create('api::announcement.announcement', {
        data: {
          description:    description.trim(),
          players_needed: parseInt(players_needed),
          status:         'open',
          reservation:    reservation_id,
          player:         player.id,
        },
        populate: FULL_POPULATE,
      });

      strapi.log.info(`[announcement.create] Created ${entity.id} for reservation ${reservation_id}`);
      return ctx.send({ data: enrichAnnouncement(entity, strapi) }, 201);
    } catch (e) {
      strapi.log.error('[announcement.create]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  // ── PUT /announcements/:id ─────────────────────────────────────────────────
  async update(ctx) {
    try {
      const user   = ctx.state.user;
      const player = await resolvePlayer(strapi, user.id);
      if (!player) return ctx.unauthorized();

      const existing = await strapi.entityService.findOne(
        'api::announcement.announcement', ctx.params.id, { populate: ['player'] },
      );
      if (!existing) return ctx.notFound();
      if (String(existing.player?.id) !== String(player.id)) return ctx.forbidden('Not your announcement');

      let data = ctx.request.body;
      if (data.data) data = data.data;

      const updateData = {};
      if (data.description   !== undefined) updateData.description    = data.description;
      if (data.players_needed !== undefined) updateData.players_needed = parseInt(data.players_needed);
      if (data.status         !== undefined) updateData.status         = data.status;

      const entity = await strapi.entityService.update(
        'api::announcement.announcement', ctx.params.id,
        { data: updateData, populate: FULL_POPULATE },
      );
      return ctx.send({ data: enrichAnnouncement(entity, strapi) });
    } catch (e) {
      strapi.log.error('[announcement.update]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  // ── DELETE /announcements/:id ──────────────────────────────────────────────
  async delete(ctx) {
    try {
      const user   = ctx.state.user;
      const player = await resolvePlayer(strapi, user.id);
      if (!player) return ctx.unauthorized();

      const existing = await strapi.entityService.findOne(
        'api::announcement.announcement', ctx.params.id,
        { populate: ['player', 'join_requests'] },
      );
      if (!existing) return ctx.notFound();
      if (String(existing.player?.id) !== String(player.id)) return ctx.forbidden('Not your announcement');

      for (const jr of (existing.join_requests || [])) {
        await strapi.entityService.delete('api::join-request.join-request', jr.id);
      }
      await strapi.entityService.delete('api::announcement.announcement', ctx.params.id);

      return ctx.send({ message: 'Announcement deleted' });
    } catch (e) {
      strapi.log.error('[announcement.delete]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  // ── POST /announcements/:id/requests ──────────────────────────────────────
  async requestJoin(ctx) {
    try {
      const user   = ctx.state.user;
      const player = await resolvePlayer(strapi, user.id);
      if (!player) return ctx.unauthorized('Player profile not found');

      const ann = await strapi.entityService.findOne(
        'api::announcement.announcement', ctx.params.id,
        { populate: ['player', 'join_requests'] },
      );
      if (!ann) return ctx.notFound('Announcement not found');
      if (ann.status !== 'open') return ctx.badRequest('This announcement is no longer open');
      if (String(ann.player?.id) === String(player.id)) return ctx.badRequest('You cannot join your own announcement');

      const already = await strapi.entityService.findMany('api::join-request.join-request', {
        filters: { announcement: ctx.params.id, player: player.id },
        limit: 1,
      });
      if (already.length > 0) return ctx.badRequest('You have already requested to join this announcement');

      let data = ctx.request.body;
      if (data.data) data = data.data;

      const jr = await strapi.entityService.create('api::join-request.join-request', {
        data: {
          message:      data.message || '',
          status:       'pending',
          announcement: ann.id,
          player:       player.id,
        },
        populate: {
          player: { populate: { player: true } },
          announcement: true,
        },
      });

      strapi.log.info(`[announcement.requestJoin] Created request ${jr.id} for announcement ${ann.id}`);
      return ctx.send({ data: jr }, 201);
    } catch (e) {
      strapi.log.error('[announcement.requestJoin]', e.message);
      return ctx.badRequest(e.message);
    }
  },

  // ── PUT /announcements/:id/requests/:requestId ─────────────────────────────
  async respondToRequest(ctx) {
    try {
      const user   = ctx.state.user;
      const player = await resolvePlayer(strapi, user.id);
      if (!player) return ctx.unauthorized();

      const ann = await strapi.entityService.findOne(
        'api::announcement.announcement', ctx.params.id,
        { populate: ['player', 'join_requests'] },
      );
      if (!ann) return ctx.notFound('Announcement not found');
      if (String(ann.player?.id) !== String(player.id)) return ctx.forbidden('Only the host can respond');

      const { status } = ctx.request.body;
      if (!['accepted', 'declined'].includes(status)) {
        return ctx.badRequest('status must be "accepted" or "declined"');
      }

      const jr = await strapi.entityService.update(
        'api::join-request.join-request', ctx.params.requestId,
        {
          data:    { status },
          populate: { player: { populate: { player: true } } },
        },
      );

      // Auto-close when all spots filled
      if (status === 'accepted') {
        const accepted = await strapi.entityService.findMany('api::join-request.join-request', {
          filters: { announcement: ann.id, status: 'accepted' },
        });
        if (accepted.length >= ann.players_needed) {
          await strapi.entityService.update('api::announcement.announcement', ann.id, {
            data: { status: 'full' },
          });
          strapi.log.info(`[announcement] ${ann.id} is now full`);
        }
      }

      return ctx.send({ data: jr });
    } catch (e) {
      strapi.log.error('[announcement.respondToRequest]', e.message);
      return ctx.badRequest(e.message);
    }
  },
}));
*/