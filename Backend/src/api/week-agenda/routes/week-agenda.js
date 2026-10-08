'use strict';

module.exports = {
  routes: [
    // ─────────────────────────────────────────────────────────────────────────
    // PUBLIC (player-accessible) — get published agenda for a court
    // Players need this to discover day plans → then fetch /availability
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'GET',
      path: '/week-agendas/court/:courtId',
      handler: 'week-agenda.findByCourt',
      config: {
        auth: false,
        policies: ['global::authMiddleware'] // any authenticated user
      }
    },

    // ─────────────────────────────────────────────────────────────────────────
    // MANAGER ONLY — full CRUD
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'GET',
      path: '/week-agendas',
      handler: 'week-agenda.find',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },
    {
      method: 'GET',
      path: '/week-agendas/:id',
      handler: 'week-agenda.findOne',
      config: {
        auth: false,
        policies: ['global::authMiddleware']
      }
    },
    {
      method: 'POST',
      path: '/week-agendas',
      handler: 'week-agenda.create',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },
    {
      method: 'PUT',
      path: '/week-agendas/:id',
      handler: 'week-agenda.update',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },
    {
      method: 'DELETE',
      path: '/week-agendas/:id',
      handler: 'week-agenda.delete',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },
    {
      method: 'POST',
      path: '/week-agendas/:id/publish',
      handler: 'week-agenda.publish',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    }
  ]
};