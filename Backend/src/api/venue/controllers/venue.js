// @ts-nocheck
'use strict';

const venueService = require('../services/venue');

module.exports = {

  async getVenues(ctx) {
    try {
      const managerId = ctx.state.user.managerId;
      if (!managerId) return ctx.badRequest('Manager profile not found');
      const result = await venueService.getManagerVenues(managerId);
      ctx.send(result);
    } catch (error) {
      console.error('Error getVenues:', error.message);
      ctx.badRequest(error.message);
    }
  },

  async getVenue(ctx) {
    try {
      const { id }    = ctx.params;
      const managerId = ctx.state.user.managerId;
      if (!managerId) return ctx.badRequest('Manager profile not found');
      const result = await venueService.getVenueById(parseInt(id), managerId);
      ctx.send(result);
    } catch (error) {
      console.error('Error getVenue:', error.message);
      ctx.badRequest(error.message);
    }
  },

  async createVenue(ctx) {
    try {
      const managerId = ctx.state.user.managerId;
      if (!managerId) return ctx.badRequest('Manager profile not found');
      let body = ctx.request.body;
      if (body.data) body = body.data;
      const required = ['name', 'location', 'openTime', 'closeTime'];
      for (const field of required) {
        if (!body[field]) return ctx.badRequest(`Missing required field: ${field}`);
      }
      const result = await venueService.createVenue(body, managerId);
      ctx.send({ message: 'Venue created successfully', venue: result });
    } catch (error) {
      console.error('Error createVenue:', error.message);
      ctx.badRequest(error.message);
    }
  },

  async updateVenue(ctx) {
    try {
      const { id }    = ctx.params;
      const managerId = ctx.state.user.managerId;
      if (!managerId) return ctx.badRequest('Manager profile not found');
      let body = ctx.request.body;
      if (body.data) body = body.data;
      const result = await venueService.updateVenue(parseInt(id), managerId, body);
      ctx.send({ message: 'Venue updated successfully', venue: result });
    } catch (error) {
      console.error('Error updateVenue:', error.message);
      ctx.badRequest(error.message);
    }
  },

  async deleteVenue(ctx) {
    try {
      const { id }    = ctx.params;
      const managerId = ctx.state.user.managerId;
      if (!managerId) return ctx.badRequest('Manager profile not found');
      const result = await venueService.deleteVenue(parseInt(id), managerId);
      ctx.send(result);
    } catch (error) {
      console.error('Error deleteVenue:', error.message);
      ctx.badRequest(error.message);
    }
  },

  async getVenueCourts(ctx) {
    try {
      const { id }    = ctx.params;
      const managerId = ctx.state.user.managerId;
      if (!managerId) return ctx.badRequest('Manager profile not found');
      const result = await venueService.getVenueCourts(parseInt(id), managerId);
      ctx.send(result);
    } catch (error) {
      console.error('Error getVenueCourts:', error.message);
      ctx.badRequest(error.message);
    }
  },

  async toggleActive(ctx) {
    try {
      const { id }    = ctx.params;
      const managerId = ctx.state.user.managerId;
      if (!managerId) return ctx.badRequest('Manager profile not found');
      const result = await venueService.toggleVenueActive(parseInt(id), managerId);
      ctx.send({ message: `Venue ${result.isActive ? 'activated' : 'deactivated'} successfully`, venue: result });
    } catch (error) {
      console.error('Error toggleActive:', error.message);
      ctx.badRequest(error.message);
    }
  },

  // ─────────────────────────────────────────────────────────────────────────
  // GET PUBLIC VENUES — for players
  // FIX: courts now populated with court_img (correct field name from schema)
  //      instead of 'photo' which doesn't exist on courts.
  //      Also adds court_img_url as a flat string so Flutter can read it
  //      without navigating nested objects.
  // ─────────────────────────────────────────────────────────────────────────
  async getPublicVenues(ctx) {
    try {
      const venues = await strapi.db.query('api::venue.venue').findMany({
        where: { isActive: true },
        populate: {
          photo: true,
          courts: {
            populate: {
              court_img: true,
              photos: true,
            },
          },
          manager: {
            populate: ['manager']
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      const baseUrl = strapi.config.get('server.url') || '';

      const transformedVenues = venues.map(venue => {
        // ── Manager details ──────────────────────────────────────────
        let managerData = null;
        if (venue.manager) {
          managerData = {
            id: venue.manager.id,
            phone: venue.manager.phone || '',
            // ✅ FIX: Use username from the nested manager.manager relation
            username: venue.manager.manager?.username || venue.manager.username || '',
          };
        }

        // Flatten courts
        const courts = (venue.courts || []).map(court => ({
          ...court,
          court_img_url: court.court_img?.url 
            ? (court.court_img.url.startsWith('http') ? court.court_img.url : `${baseUrl}${court.court_img.url}`)
            : null,
          photos_urls: (court.photos || []).map(p => 
            p.url ? (p.url.startsWith('http') ? p.url : `${baseUrl}${p.url}`) : null
          ).filter(Boolean),
        }));

        return {
          ...venue,
          manager: managerData,
          courts,
          avg_rating: venue.avg_rating || 0,
          total_rating: venue.total_rating || 0,
        };
      });

      ctx.send(transformedVenues);
    } catch (error) {
      console.error('Error getPublicVenues:', error.message);
      ctx.badRequest(error.message);
    }
  },
};
