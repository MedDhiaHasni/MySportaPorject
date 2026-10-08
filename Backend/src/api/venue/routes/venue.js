// @ts-nocheck
'use strict';

module.exports = {
  routes: [

    // ─────────────────────────────────────────────────────────────────────────
    // GET ALL VENUES - Manager sees their own
    // ─────────────────────────────────────────────────────────────────────────
    {
      method:  'GET',
      path:    '/venues',
      handler: 'venue.getVenues',
      config:  {
        auth:     false,
        policies: ['global::authMiddleware', 'global::isManager'],
      },
    },

    // ─────────────────────────────────────────────────────────────────────────
    // GET SINGLE VENUE
    // ─────────────────────────────────────────────────────────────────────────
    {
      method:  'GET',
      path:    '/venues/:id',
      handler: 'venue.getVenue',
      config:  {
        auth:     false,
        policies: ['global::authMiddleware', 'global::isManager'],
      },
    },

    // ─────────────────────────────────────────────────────────────────────────
    // CREATE VENUE
    // ─────────────────────────────────────────────────────────────────────────
    {
      method:  'POST',
      path:    '/venues',
      handler: 'venue.createVenue',
      config:  {
        auth:     false,
        policies: ['global::authMiddleware', 'global::isManager'],
      },
    },

    // ─────────────────────────────────────────────────────────────────────────
    // UPDATE VENUE
    // ─────────────────────────────────────────────────────────────────────────
    {
      method:  'PUT',
      path:    '/venues/:id',
      handler: 'venue.updateVenue',
      config:  {
        auth:     false,
        policies: ['global::authMiddleware', 'global::isManager'],
      },
    },

    // ─────────────────────────────────────────────────────────────────────────
    // DELETE VENUE
    // ─────────────────────────────────────────────────────────────────────────
    {
      method:  'DELETE',
      path:    '/venues/:id',
      handler: 'venue.deleteVenue',
      config:  {
        auth:     false,
        policies: ['global::authMiddleware', 'global::isManager'],
      },
    },

    // ─────────────────────────────────────────────────────────────────────────
    // GET VENUE COURTS
    // ─────────────────────────────────────────────────────────────────────────
    {
      method:  'GET',
      path:    '/venues/:id/courts',
      handler: 'venue.getVenueCourts',
      config:  {
        auth:     false,
        policies: ['global::authMiddleware', 'global::isManager'],
      },
    },

    // ─────────────────────────────────────────────────────────────────────────
    // TOGGLE ACTIVE STATUS
    // ─────────────────────────────────────────────────────────────────────────
    {
      method:  'PUT',
      path:    '/venues/:id/toggle-active',
      handler: 'venue.toggleActive',
      config:  {
        auth:     false,
        policies: ['global::authMiddleware', 'global::isManager'],
      },
    },

    // ─────────────────────────────────────────────────────────────────────────
// GET PUBLIC VENUES - For players (no authentication required)
// ─────────────────────────────────────────────────────────────────────────
{
  method: 'GET',
  path: '/public/venues',
  handler: 'venue.getPublicVenues',
  config: {
    auth: false,
  },
},

  ],
};