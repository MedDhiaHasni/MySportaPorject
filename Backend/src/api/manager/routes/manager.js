// src/api/manager/routes/manager.js
// @ts-nocheck
'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

const defaultRouter = createCoreRouter('api::manager.manager');

module.exports = {
  routes: [
    // ── Custom: PATCH /managers/me/firebase ────────────────────────────────
    {
      method: 'PATCH',
      path: '/managers/me/firebase',
      handler: 'manager.updateFirebase',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },

    // ─────────────────────────────────────────────────────────────────────────
    // WORKER MANAGEMENT (Manager only - assign workers to their courts)
    // ─────────────────────────────────────────────────────────────────────────

    // GET /managers/me/workers — Get all workers under this manager
    {
      method: 'GET',
      path: '/managers/me/workers',
      handler: 'manager.getMyWorkers',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager'],
      },
    },

    // GET /managers/workers/:id — Get a specific worker's details
    {
      method: 'GET',
      path: '/managers/workers/:id',
      handler: 'manager.getWorkerById',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager'],
      },
    },

    // PUT /managers/workers/:id/assign-courts — Assign worker to courts
    {
      method: 'PUT',
      path: '/managers/workers/:id/assign-courts',
      handler: 'manager.assignWorkerCourts',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager'],
      },
    },

    // DELETE /managers/workers/:id/courts/:courtId — Remove worker from a specific court
    {
      method: 'DELETE',
      path: '/managers/workers/:id/courts/:courtId',
      handler: 'manager.removeWorkerFromCourt',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager'],
      },
    },

    // Add this route
{
    method: 'GET',
    path: '/managers/user/:userType/:userId/photo',
    handler: 'manager.getUserPhoto',
    config: {
        auth: false,
        policies: ['global::authMiddleware'], // Only requires authentication, not admin
    },
},

{
  method: 'GET',
  path: '/managers/player/:playerId/username',
  handler: 'manager.getPlayerUsername',
  config: {
    auth: false,
    policies: ['global::authMiddleware'],
  },
},
  ],
};














/*// src/api/manager/routes/manager.js
// @ts-nocheck
'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

const defaultRouter = createCoreRouter('api::manager.manager');

module.exports = {
  routes: [
    // ── Custom: PATCH /managers/me/firebase ────────────────────────────────
    {
      method: 'PATCH',
      path: '/managers/me/firebase',
      handler: 'manager.updateFirebase',
      config: {
        auth: false,
        policies: ['global::authMiddleware' ],
      },
    },

    
  ],
};*/