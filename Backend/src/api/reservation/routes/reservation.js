// src/api/reservation/routes/reservation.js
'use strict';

module.exports = {
  routes: [
    // ── READ ──────────────────────────────────────────────────────────────────
    {
      method: 'GET',
      path: '/reservations',
      handler: 'reservation.find',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },
    {
      method: 'GET',
      path: '/reservations/:id',
      handler: 'reservation.findOne',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },

    // ── CREATE (players only) ─────────────────────────────────────────────────
    {
      method: 'POST',
      path: '/reservations',
      handler: 'reservation.create',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] },
    },

    // ── REQUEST CANCEL (player — submits reason, sets cancel_requested) ───────
    {
      method: 'PUT',
      path: '/reservations/:id/request-cancel',
      handler: 'reservation.requestCancel',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },

    // ── CONFIRM (worker | manager | admin) ────────────────────────────────────
    {
      method: 'PUT',
      path: '/reservations/:id/confirm',
      handler: 'reservation.confirm',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },

    // ── REJECT (worker | manager | admin) ─────────────────────────────────────
    {
      method: 'PUT',
      path: '/reservations/:id/reject',
      handler: 'reservation.reject',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },

    // ── CANCEL — approve the cancel request (worker | manager | admin) ────────
    {
      method: 'PUT',
      path: '/reservations/:id/cancel',
      handler: 'reservation.cancel',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },

    // ── COMPLETE (worker | manager | admin) ───────────────────────────────────
    {
      method: 'PUT',
      path: '/reservations/:id/complete',
      handler: 'reservation.complete',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },

    // ── DELETE (manager | admin) ──────────────────────────────────────────────
    {
      method: 'DELETE',
      path: '/reservations/:id',
      handler: 'reservation.delete',
      config: { auth: false, policies: ['global::authMiddleware'] },
    },
  ],
};

















/*// src/api/reservation/routes/reservation.js
'use strict';

module.exports = {
  routes: [
    { method: 'GET',    path: '/reservations',         handler: 'reservation.find',     config: { auth: false, policies: ['global::authMiddleware'] } },
    { method: 'GET',    path: '/reservations/:id',     handler: 'reservation.findOne',  config: { auth: false, policies: ['global::authMiddleware'] } },
    { method: 'POST',   path: '/reservations',         handler: 'reservation.create',   config: { auth: false, policies: ['global::authMiddleware', 'global::isPlayer'] } },
    { method: 'PUT',    path: '/reservations/:id/confirm',  handler: 'reservation.confirm',  config: { auth: false, policies: ['global::authMiddleware', 'global::isManager'] } },
    { method: 'PUT',    path: '/reservations/:id/cancel',   handler: 'reservation.cancel',   config: { auth: false, policies: ['global::authMiddleware'] } },
    { method: 'PUT',    path: '/reservations/:id/complete', handler: 'reservation.complete', config: { auth: false, policies: ['global::authMiddleware', 'global::isManager'] } },
    { method: 'DELETE', path: '/reservations/:id',     handler: 'reservation.delete',   config: { auth: false, policies: ['global::authMiddleware', 'global::isManager'] } },
  ],
};*/





//***********************






















/*'use strict';

module.exports = {
  routes: [
    // ─────────────────────────────────────────────────────────────────────────
    // GET all reservations (manager sees all, player sees only theirs)
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'GET',
      path: '/reservations',
      handler: 'reservation.find',
      config: {
        auth: false,
        policies: ['global::authMiddleware']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // GET single reservation by ID
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'GET',
      path: '/reservations/:id',
      handler: 'reservation.findOne',
      config: {
        auth: false,
        policies: ['global::authMiddleware']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // CREATE reservation (player books a time slot)
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'POST',
      path: '/reservations',
      handler: 'reservation.create',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isPlayer']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // CONFIRM reservation (manager confirms pending reservation)
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'PUT',
      path: '/reservations/:id/confirm',
      handler: 'reservation.confirm',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // CANCEL reservation (player or manager can cancel)
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'PUT',
      path: '/reservations/:id/cancel',
      handler: 'reservation.cancel',
      config: {
        auth: false,
        policies: ['global::authMiddleware']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // COMPLETE reservation (manager marks as completed)
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'PUT',
      path: '/reservations/:id/complete',
      handler: 'reservation.complete',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // DELETE reservation (manager only hard delete)
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'DELETE',
      path: '/reservations/:id',
      handler: 'reservation.delete',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },


    // In routes file, add:
{
  method: 'PUT',
  path: '/reservations/:id/needed-players',
  handler: 'reservation.updateNeededPlayers',
  config: {
    auth: false,
    policies: ['global::authMiddleware'],
  },
},
{
  method: 'DELETE',
  path: '/reservations/:id/announcement',
  handler: 'reservation.deleteAnnouncement',
  config: {
    auth: false,
    policies: ['global::authMiddleware'],
  },
},
  ]

  
};*/