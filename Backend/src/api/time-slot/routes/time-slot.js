'use strict';

module.exports = {
  routes: [
    // ─────────────────────────────────────────────────────────────────────────
    // GET all time slots (filter by dayPlanId or isActive)
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'GET',
      path: '/time-slots',
      handler: 'time-slot.find',
      config: {
        auth: false,
        policies: ['global::authMiddleware']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // GET single time slot by ID
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'GET',
      path: '/time-slots/:id',
      handler: 'time-slot.findOne',
      config: {
        auth: false,
        policies: ['global::authMiddleware']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // CREATE new time slot
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'POST',
      path: '/time-slots',
      handler: 'time-slot.create',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // BULK CREATE time slots (create multiple at once for a day plan)
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'POST',
      path: '/time-slots/bulk',
      handler: 'time-slot.bulkCreate',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // UPDATE time slot (toggle isActive, etc.)
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'PUT',
      path: '/time-slots/:id',
      handler: 'time-slot.update',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    },
    
    // ─────────────────────────────────────────────────────────────────────────
    // DELETE time slot
    // ─────────────────────────────────────────────────────────────────────────
    {
      method: 'DELETE',
      path: '/time-slots/:id',
      handler: 'time-slot.delete',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isManager']
      }
    }
  ]
};