// src/api/announcement/services/announcement.js
// @ts-nocheck
'use strict';

const { createCoreService } = require('@strapi/strapi').factories;

function absUrl(strapi, path) {
  if (!path) return null;
  if (path.startsWith('http')) return path;
  return `${strapi.config.get('server.url') || 'http://localhost:1337'}${path}`;
}

function enrichCourtImages(court, strapi) {
  if (!court) return court;
  court.court_img_url = absUrl(strapi, court.court_img?.url ?? null);
  court.photos_urls = (court.photos || []).map(p => absUrl(strapi, p.url)).filter(Boolean);
  return court;
}

module.exports = createCoreService('api::announcement.announcement', ({ strapi }) => ({

  //  nlawej 3al profile mta3 joueur
  async resolvePlayer(userId) {
    const players = await strapi.entityService.findMany('api::player.player', {
      filters: { player: userId },
      limit: 1,
    });
    return players?.[0] ?? null;   // dima haka 5ir 7atta lel securité
  },

  // n3ayet lel populate marra wa7da 5ir melli n3aytelha kol marra  
  getFullPopulate() {
    return {
      player: { populate: { player: true } },
      reservation: {
        populate: {
          court: { populate: ['court_img', 'photos', 'venue'] },
          time_slot: true,
        },
      },
      join_requests: {
        populate: {
          player: { populate: { player: true } },
        },
      },
    };
  },

  //  nzid l'image mta3 l'announcement w l'court mta3ha f response
  enrichAnnouncement(ann) {
    if (!ann) return ann;
    const court = ann.reservation?.court;
    if (court) enrichCourtImages(court, strapi);
    return ann;
  },

  //  nlawej 3la les annonces mta3 joueret lo5rin ( li 3mal l'annonce maychoufhech akeka 5ir) , tw nzidha mba3ed ywalli ychoufha fi blasa o5ra
  async findOpenAnnouncements(excludePlayerId) {
    const filters = { status: 'open' };
    if (excludePlayerId) filters.player = { $ne: excludePlayerId }; // hedhika not equal 3maltha bel != ma5edmetlich

    const entities = await strapi.entityService.findMany('api::announcement.announcement', {
      filters,
      populate: this.getFullPopulate(),
      sort: { createdAt: 'desc' },
    });

    return entities.map(e => this.enrichAnnouncement(e));
  },

  // Find announcement lel player bech nzidha mba3ed fi my announcements  
  async findAnnouncementsByPlayer(playerId) {
    const entities = await strapi.entityService.findMany('api::announcement.announcement', {
      filters: { player: playerId },
      populate: this.getFullPopulate(),
      sort: { createdAt: 'desc' },
    });

    return entities.map(e => this.enrichAnnouncement(e));
  },

  // nlawej 3al announcement bel id 
  async findAnnouncementById(id) {
    const entity = await strapi.entityService.findOne(
      'api::announcement.announcement',
      id,
      { populate: this.getFullPopulate() }
    );
    return entity ? this.enrichAnnouncement(entity) : null;
  },

  // reservation feha ken announcement wa7da
  async hasActiveAnnouncement(reservationId) {
    const existing = await strapi.entityService.findMany('api::announcement.announcement', {
      filters: { reservation: reservationId, status: { $ne: 'closed' } },
      limit: 1,
    });
    return existing.length > 0; // traja3 true wala false 
  },

  //  Create announcement 
  async createAnnouncement(data, playerId) {
    const entity = await strapi.entityService.create('api::announcement.announcement', {
      data: {
        description: data.description.trim(),
        players_needed: parseInt(data.players_needed),
        status: 'open',
        reservation: data.reservation_id,
        player: playerId,
      },
      populate: this.getFullPopulate(),
    });

    strapi.log.info(`[announcement.service] Created ${entity.id} for reservation ${data.reservation_id}`);
    return this.enrichAnnouncement(entity);
  },

  // menich sure n7otha wala man7othech  
  async updateAnnouncement(id, updateData) {
    const entity = await strapi.entityService.update(
      'api::announcement.announcement',
      id,
      { data: updateData, populate: this.getFullPopulate() }
    );
    return this.enrichAnnouncement(entity);
  },

  //  Delete announcement and its join requests 
  async deleteAnnouncement(id) {
    // Get announcement with its join requests
    const existing = await strapi.entityService.findOne(
      'api::announcement.announcement',
      id,
      { populate: ['join_requests'] }
    );

    if (!existing) return null;

    // Delete all associated join requests
    for (const jr of (existing.join_requests || [])) {
      await strapi.entityService.delete('api::join-request.join-request', jr.id);
    }

    // Delete the announcement
    await strapi.entityService.delete('api::announcement.announcement', id);
    return existing;
  },

  //  Get join requests by player 
  async getJoinRequestsByPlayer(playerId) {
    const requests = await strapi.entityService.findMany('api::join-request.join-request', {
      filters: { player: playerId },
      populate: {
        player: { populate: { player: true } },
        announcement: {
          populate: {
            player: { populate: { player: true } },
            reservation: {
              populate: {
                court: { populate: ['court_img', 'photos', 'venue'] },
                time_slot: true,
              },
            },
          },
        },
      },
      sort: { createdAt: 'desc' },
    });

    // Enrich court images
    for (const req of requests) {
      const court = req.announcement?.reservation?.court;
      if (court) enrichCourtImages(court, strapi);
    }

    return requests;
  },

  // bech nchecki 
  async getReservationWithPlayer(reservationId) {
    return await strapi.entityService.findOne('api::reservation.reservation', reservationId, {
      populate: ['player', 'court'],
    });
  },

  // Create join request 
  async createJoinRequest(announcementId, playerId, message = '') {
    const jr = await strapi.entityService.create('api::join-request.join-request', {
      data: {
        message: message || '',
        status: 'pending',
        announcement: announcementId,
        player: playerId,
      },
      populate: {
        player: { populate: { player: true } },
        announcement: true,
      },
    });

    strapi.log.info(`[announcement.service] Created request ${jr.id} for announcement ${announcementId}`);
    return jr;
  },

  //  Check if player already requested to join 
  async hasExistingJoinRequest(announcementId, playerId) {
    const existing = await strapi.entityService.findMany('api::join-request.join-request', {
      filters: { announcement: announcementId, player: playerId },
      limit: 1,
    });
    return existing.length > 0;
  },

  //  Get join requests for an announcement bech mba3ed nwalli n'incrimenti elli yjoiniw 
  async getAcceptedCount(announcementId) {
    const accepted = await strapi.entityService.findMany('api::join-request.join-request', {
      filters: { announcement: announcementId, status: 'accepted' },
    });
    return accepted.length;
  },

  // Update join request status hnee bech n'accepti wala nrefuzi joueret
  async updateJoinRequestStatus(requestId, status) {
    const jr = await strapi.entityService.update(
      'api::join-request.join-request',
      requestId,
      {
        data: { status },
        populate: { player: { populate: { player: true } } },
      }
    );
    return jr;
  },

  // Close announcement 
  async closeAnnouncement(announcementId) {
    await strapi.entityService.update('api::announcement.announcement', announcementId, {
      data: { status: 'full' },
    });
    strapi.log.info(`[announcement.service] ${announcementId} is now full`);
  },
}));