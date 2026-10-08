// @ts-nocheck
'use strict';

module.exports = {

  // ─────────────────────────────────────────────────────────────────────────
  // Get all venues for a manager
  // ─────────────────────────────────────────────────────────────────────────
  async getManagerVenues(managerId) {
    return strapi.db.query('api::venue.venue').findMany({
      where:    { manager: { id: managerId } },
      populate: ['photo', 'courts', 'manager'],
      orderBy:  { createdAt: 'desc' },
    });
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Get single venue by ID — verifies ownership
  // ─────────────────────────────────────────────────────────────────────────
  async getVenueById(venueId, managerId) {
    const venue = await strapi.db.query('api::venue.venue').findOne({
      where:    { id: venueId },
      populate: ['photo', 'courts', 'manager'],
    });

    if (!venue) throw new Error('Venue not found');
    if (venue.manager?.id !== managerId) throw new Error("You don't have permission to access this venue");

    return venue;
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Create a new venue
  // ─────────────────────────────────────────────────────────────────────────
  async createVenue(data, managerId) {
    const {
      name, location, description, openTime, closeTime,
      photo, sports, amenities, isActive, lat, lng,
    } = data;

    return strapi.db.query('api::venue.venue').create({
      data: {
        name,
        location,
        description:  description  || null,
        openTime,
        closeTime,
        photo:        photo        || null,
        sports:       sports       || null,
        amenities:    amenities    || null,
        isActive:     isActive     !== undefined ? isActive : true,
        lat:          lat          ? parseFloat(lat)  : null,
        lng:          lng          ? parseFloat(lng)  : null,
        manager:      managerId,
        publishedAt:  new Date(),
      },
    });
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Update a venue — verifies ownership, only updates provided fields
  // ─────────────────────────────────────────────────────────────────────────
  async updateVenue(venueId, managerId, data) {
    const existing = await strapi.db.query('api::venue.venue').findOne({
      where:    { id: venueId },
      populate: ['manager'],
    });

    if (!existing) throw new Error('Venue not found');
    if (existing.manager?.id !== managerId) throw new Error("You don't have permission to update this venue");

    const {
      name, location, description, openTime, closeTime,
      photo, sports, amenities, isActive, lat, lng,
    } = data;

    return strapi.db.query('api::venue.venue').update({
      where: { id: venueId },
      data:  {
        ...(name        !== undefined && { name }),
        ...(location    !== undefined && { location }),
        ...(description !== undefined && { description }),
        ...(openTime    !== undefined && { openTime }),
        ...(closeTime   !== undefined && { closeTime }),
        ...(photo       !== undefined && { photo }),
        ...(sports      !== undefined && { sports }),
        ...(amenities   !== undefined && { amenities }),
        ...(isActive    !== undefined && { isActive }),
        ...(lat         !== undefined && { lat: lat ? parseFloat(lat) : null }),
        ...(lng         !== undefined && { lng: lng ? parseFloat(lng) : null }),
      },
    });
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Delete a venue and all its courts — verifies ownership
  // ─────────────────────────────────────────────────────────────────────────
  async deleteVenue(venueId, managerId) {
    const existing = await strapi.db.query('api::venue.venue').findOne({
      where:    { id: venueId },
      populate: ['manager'],
    });

    if (!existing) throw new Error('Venue not found');
    if (existing.manager?.id !== managerId) throw new Error("You don't have permission to delete this venue");

    const courts = await strapi.db.query('api::court.court').findMany({
      where: { venue: venueId },
    });

    for (const court of courts) {
      await strapi.db.query('api::court.court').delete({ where: { id: court.id } });
    }

    await strapi.db.query('api::venue.venue').delete({ where: { id: venueId } });

    return { message: 'Venue and its courts deleted successfully' };
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Get all courts for a venue — verifies ownership
  // ✅ FIX: populate worker, court_img, photos — previously only had 'photo','venue'
  // ─────────────────────────────────────────────────────────────────────────
  async getVenueCourts(venueId, managerId) {
    const venue = await strapi.db.query('api::venue.venue').findOne({
      where:    { id: venueId },
      populate: ['manager'],
    });

    if (!venue) throw new Error('Venue not found');
    if (venue.manager?.id !== managerId) throw new Error("You don't have permission to view courts for this venue");

    const courts = await strapi.db.query('api::court.court').findMany({
      where:   { venue: venueId },
      // ✅ FIXED populate — added worker, court_img, photos
      populate: ['venue', 'court_img', 'photos', 'worker'],
      orderBy: { createdAt: 'desc' },
    });

    const baseUrl = strapi.config.get('server.url') || '';

    // Transform to match what Flutter's ManagedCourt.fromJson expects
    return courts.map(court => ({
      ...court,
      // Flatten court_img for Flutter
      court_img: court.court_img
        ? {
            id:  court.court_img.id,
            url: court.court_img.url?.startsWith('http')
                   ? court.court_img.url
                   : `${baseUrl}${court.court_img.url}`,
          }
        : null,
      // Flatten photos array for Flutter
      photos: (court.photos || []).map(p => ({
        id:  p.id,
        url: p.url?.startsWith('http') ? p.url : `${baseUrl}${p.url}`,
      })),
      // ✅ Flatten worker — Flutter reads worker.id, worker.nom, worker.phone
      worker: court.worker
        ? {
            id:    court.worker.id,
            nom:   court.worker.nom   ?? null,
            phone: court.worker.phone ?? null,
          }
        : null,
    }));
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Toggle isActive for a venue — verifies ownership
  // ─────────────────────────────────────────────────────────────────────────
  async toggleVenueActive(venueId, managerId) {
    const existing = await strapi.db.query('api::venue.venue').findOne({
      where:    { id: venueId },
      populate: ['manager'],
    });

    if (!existing) throw new Error('Venue not found');
    if (existing.manager?.id !== managerId) throw new Error("You don't have permission to update this venue");

    return strapi.db.query('api::venue.venue').update({
      where: { id: venueId },
      data:  { isActive: !existing.isActive },
    });
  },
};

