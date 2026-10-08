// src/api/announcement/routes/announcement.js
// CRITICAL: /mine and /my-requests MUST be before /:id
// Otherwise Strapi treats "mine" and "my-requests" as an :id param value
'use strict';

module.exports = {
  routes: [
    // ── Specific named paths FIRST (before /:id) ──────────────────────────────
    {
      method: 'GET',
      path: '/announcements/mine',
      handler: 'announcement.mine',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    {
      method: 'GET',
      path: '/announcements/my-requests',
      handler: 'announcement.myRequests',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },

    // ── Generic routes ─────────────────────────────────────────────────────────
    {
      method: 'GET',
      path: '/announcements',
      handler: 'announcement.find',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },
    {
      method: 'GET',
      path: '/announcements/:id',
      handler: 'announcement.findOne',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },
    {
      method: 'POST',
      path: '/announcements',
      handler: 'announcement.create',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    {
      method: 'PUT',
      path: '/announcements/:id',
      handler: 'announcement.update',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    {
      method: 'DELETE',
      path: '/announcements/:id',
      handler: 'announcement.delete',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    {
      method: 'POST',
      path: '/announcements/:id/requests',
      handler: 'announcement.requestJoin',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    {
      method: 'PUT',
      path: '/announcements/:id/requests/:requestId',
      handler: 'announcement.respondToRequest',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
  ],
};














/*// src/api/announcement/routes/announcement.js
'use strict';

module.exports = {
  routes: [
    // ── GET /announcements/mine — current player's own announcements
    {
      method: 'GET',
      path: '/announcements/mine',
      handler: 'announcement.mine',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    // ── GET /announcements/my-requests — current player's own join requests (NEW)
    {
      method: 'GET',
      path: '/announcements/my-requests',
      handler: 'announcement.myRequests',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    // ── GET /announcements — public feed (all open announcements)
    {
      method: 'GET',
      path: '/announcements',
      handler: 'announcement.find',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },
    // ── GET /announcements/:id
    {
      method: 'GET',
      path: '/announcements/:id',
      handler: 'announcement.findOne',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },
    // ── POST /announcements — player creates after booking
    {
      method: 'POST',
      path: '/announcements',
      handler: 'announcement.create',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    // ── PUT /announcements/:id — player updates their own
    {
      method: 'PUT',
      path: '/announcements/:id',
      handler: 'announcement.update',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    // ── DELETE /announcements/:id — player deletes their own
    {
      method: 'DELETE',
      path: '/announcements/:id',
      handler: 'announcement.delete',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    // ── POST /announcements/:id/requests — player requests to join
    {
      method: 'POST',
      path: '/announcements/:id/requests',
      handler: 'announcement.requestJoin',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    // ── PUT /announcements/:id/requests/:requestId — host accepts/declines
    {
      method: 'PUT',
      path: '/announcements/:id/requests/:requestId',
      handler: 'announcement.respondToRequest',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
  ],
};









****************************













'use strict';

module.exports = {
  routes: [
    // ── GET /announcements/mine — MUST BE FIRST (most specific routes first)
    {
      method: 'GET',
      path: '/announcements/mine',
      handler: 'announcement.mine',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isPlayer'],
      },
    },
    // ── GET /announcements — public feed (all open announcements)
    {
      method: 'GET',
      path: '/announcements',
      handler: 'announcement.find',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
    // ── GET /announcements/:id
    {
      method: 'GET',
      path: '/announcements/:id',
      handler: 'announcement.findOne',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
    // ── POST /announcements — player creates after booking
    {
      method: 'POST',
      path: '/announcements',
      handler: 'announcement.create',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isPlayer'],
      },
    },
    // ── PUT /announcements/:id — player updates their own
    {
      method: 'PUT',
      path: '/announcements/:id',
      handler: 'announcement.update',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isPlayer'],
      },
    },
    // ── DELETE /announcements/:id — player deletes their own
    {
      method: 'DELETE',
      path: '/announcements/:id',
      handler: 'announcement.delete',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isPlayer'],
      },
    },
    // ── POST /announcements/:id/requests — player requests to join
    {
      method: 'POST',
      path: '/announcements/:id/requests',
      handler: 'announcement.requestJoin',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isPlayer'],
      },
    },
    // ── PUT /announcements/:id/requests/:requestId — host accepts/declines
    {
      method: 'PUT',
      path: '/announcements/:id/requests/:requestId',
      handler: 'announcement.respondToRequest',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isPlayer'],
      },
    },
  ],
};


******************************************


// src/api/announcement/routes/announcement.js
'use strict';

module.exports = {
  routes: [
    // ── GET /announcements — public feed (all open announcements)
    {
      method: 'GET',
      path: '/announcements',
      handler: 'announcement.find',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },
    // ── GET /announcements/:id
    {
      method: 'GET',
      path: '/announcements/:id',
      handler: 'announcement.findOne',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },
    // ── POST /announcements — player creates after booking
    {
      method: 'POST',
      path: '/announcements',
      handler: 'announcement.create',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    // ── PUT /announcements/:id — player updates their own
    {
      method: 'PUT',
      path: '/announcements/:id',
      handler: 'announcement.update',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    // ── DELETE /announcements/:id — player deletes their own
    {
      method: 'DELETE',
      path: '/announcements/:id',
      handler: 'announcement.delete',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    // ── GET /announcements/mine — current player's own announcements
    {
      method: 'GET',
      path: '/announcements/mine',
      handler: 'announcement.mine',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    // ── POST /announcements/:id/requests — player requests to join
    {
      method: 'POST',
      path: '/announcements/:id/requests',
      handler: 'announcement.requestJoin',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
    // ── PUT /announcements/:id/requests/:requestId — host accepts/declines
    {
      method: 'PUT',
      path: '/announcements/:id/requests/:requestId',
      handler: 'announcement.respondToRequest',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },
  ],
};*/