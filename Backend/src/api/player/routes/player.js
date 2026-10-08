// src/api/player/routes/player.js
// @ts-nocheck
'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

// Keep the default CRUD routes and add custom ones
const defaultRouter = createCoreRouter('api::player.player');

module.exports = {
  routes: [
    // ── Custom: PATCH /players/me/firebase ─────────────────────────────────
    {
      method: 'PATCH',
      path: '/players/me/firebase',
      handler: 'player.updateFirebase',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
    // ── Custom: GET /players/user/:userType/:userId/photo ─────────────────
    {
      method: 'GET',
      path: '/players/user/:userType/:userId/photo',
      handler: 'player.getUserPhoto',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
  ],
};

