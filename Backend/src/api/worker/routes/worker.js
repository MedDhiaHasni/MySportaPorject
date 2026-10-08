// src/api/worker/routes/worker.js
'use strict';

module.exports = {
  routes: [
    // Get worker's own profile
    {
      method: 'GET',
      path: '/workers/me',
      handler: 'worker.getMe',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // ── NEW: Update worker profile (nom, phone, username) ─────────────────
    {
      method: 'PATCH',
      path: '/workers/me/profile',
      handler: 'worker.updateProfile',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Get all courts assigned to this worker
    {
      method: 'GET',
      path: '/workers/me/courts',
      handler: 'worker.getMyCourts',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Get all reservations for worker's assigned courts
    {
      method: 'GET',
      path: '/workers/me/reservations',
      handler: 'worker.getMyReservations',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Get upcoming reservations
    {
      method: 'GET',
      path: '/workers/me/reservations/upcoming',
      handler: 'worker.getUpcomingReservations',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Confirm a reservation
    {
      method: 'PUT',
      path: '/workers/me/reservations/:id/confirm',
      handler: 'worker.confirmReservation',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Cancel a reservation
    {
      method: 'PUT',
      path: '/workers/me/reservations/:id/cancel',
      handler: 'worker.cancelReservation',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Get time slots for worker's assigned courts
    {
      method: 'GET',
      path: '/workers/me/time-slots',
      handler: 'worker.getMyTimeSlots',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Update a time slot (toggle isActive)
    {
      method: 'PUT',
      path: '/workers/me/time-slots/:id',
      handler: 'worker.updateTimeSlot',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Update Firebase UID / FCM token
    {
      method: 'PATCH',
      path: '/workers/me/firebase',
      handler: 'worker.updateFirebase',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Get user photo for chat (player or manager)
    {
      method: 'GET',
      path: '/workers/user/:userType/:userId/photo',
      handler: 'worker.getUserPhoto',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
  ],
};








/*'use strict';

module.exports = {
  routes: [
    // ─────────────────────────────────────────────────────────────────────────
    // WORKER SELF-SERVICE ENDPOINTS (require isWorker policy)
    // ─────────────────────────────────────────────────────────────────────────

    // Get worker's own profile
    {
      method: 'GET',
      path: '/workers/me',
      handler: 'worker.getMe',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Get all courts assigned to this worker
    {
      method: 'GET',
      path: '/workers/me/courts',
      handler: 'worker.getMyCourts',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Get all reservations for worker's assigned courts
    {
      method: 'GET',
      path: '/workers/me/reservations',
      handler: 'worker.getMyReservations',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Get upcoming reservations
    {
      method: 'GET',
      path: '/workers/me/reservations/upcoming',
      handler: 'worker.getUpcomingReservations',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Confirm a reservation
    {
      method: 'PUT',
      path: '/workers/me/reservations/:id/confirm',
      handler: 'worker.confirmReservation',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Cancel a reservation
    {
      method: 'PUT',
      path: '/workers/me/reservations/:id/cancel',
      handler: 'worker.cancelReservation',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Get time slots for worker's assigned courts
    {
      method: 'GET',
      path: '/workers/me/time-slots',
      handler: 'worker.getMyTimeSlots',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Update a time slot (toggle isActive)
    {
      method: 'PUT',
      path: '/workers/me/time-slots/:id',
      handler: 'worker.updateTimeSlot',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },

    // Update Firebase UID / FCM token
    {
      method: 'PATCH',
      path: '/workers/me/firebase',
      handler: 'worker.updateFirebase',
      config: {
        auth: false,
        policies: ['global::authMiddleware', 'global::isWorker'],
      },
    },
      {
      method: 'GET',
      path: '/workers/user/:userType/:userId/photo',
      handler: 'worker.getUserPhoto',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
  ],
};*/