'use strict';

module.exports = {
  routes: [
    // ─────────────────────────────────────────────────────────────────────────
    // GET all day plans (filter by weekAgendaId or dayType)
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'GET',
      path: '/day-plans',
      handler: 'day-plan.find',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // GET single day plan by ID (with week agenda and time slots)
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'GET',
      path: '/day-plans/:id',
      handler: 'day-plan.findOne',
      config: {
        auth: false,
        policies: ['global::authMiddleware']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // GET day plan availability (time slots with booking status)
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'GET',
      path: '/day-plans/:id/availability',
      handler: 'day-plan.availability',
      config: {
        auth: false,
        policies: ['global::authMiddleware']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // CREATE new day plan
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'POST',
      path: '/day-plans',
      handler: 'day-plan.create',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // UPDATE day plan
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'PUT',
      path: '/day-plans/:id',
      handler: 'day-plan.update',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // DELETE day plan
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'DELETE',
      path: '/day-plans/:id',
      handler: 'day-plan.delete',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    }
  ]
};