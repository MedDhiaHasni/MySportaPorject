// src/api/rating/routes/rating.js
// @ts-nocheck
'use strict';

module.exports = {
  routes: [
    // Submit or update rating (player only)
    {
      method: 'POST',
      path: '/ratings/submit',
      handler: 'rating.submitRating',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
    // Delete rating (player only)
    {
      method: 'DELETE',
      path: '/ratings/:id',
      handler: 'rating.deleteRating',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
    // Get player's rating for a specific venue
    {
      method: 'GET',
      path: '/ratings/user/venue/:venueId',
      handler: 'rating.getUserRating',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
    // Get all ratings for a venue (public)
    {
      method: 'GET',
      path: '/ratings/venue/:venueId',
      handler: 'rating.getVenueRatings',
      config: {
        auth: false,
      },
    },
  ],
};