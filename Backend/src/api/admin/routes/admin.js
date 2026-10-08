// src/api/admin/routes/admin.js
// @ts-nocheck
'use strict';

module.exports = {
  routes: [

    //  MANAGERS 
    {
      method: 'POST',
      path: '/admin/managers',
      handler: 'admin.registerManager',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'GET',
      path: '/admin/managers',
      handler: 'admin.getManagers',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'PUT',
      path: '/admin/managers/:id',
      handler: 'admin.updateManager',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'DELETE',
      path: '/admin/managers/:id',
      handler: 'admin.deleteManager',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },

    //  PLAYERS 
    {
      method: 'POST',
      path: '/admin/players',
      handler: 'admin.registerPlayer',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'GET',
      path: '/admin/players',
      handler: 'admin.getPlayers',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'PUT',
      path: '/admin/players/:id',
      handler: 'admin.updatePlayer',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'DELETE',
      path: '/admin/players/:id',
      handler: 'admin.deletePlayer',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },

    //  WORKERS 
    {
      method: 'POST',
      path: '/admin/workers',
      handler: 'admin.registerWorker',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'GET',
      path: '/admin/workers',
      handler: 'admin.getWorkers',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'PUT',
      path: '/admin/workers/:id',
      handler: 'admin.updateWorker',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'DELETE',
      path: '/admin/workers/:id',
      handler: 'admin.deleteWorker',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },

    //  TOGGLE STATUS (block / unblock any user) 
    {
      method: 'PUT',
      path: '/admin/users/:id/toggle-status',
      handler: 'admin.toggleUserStatus',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },

    //  ADMIN PROFILE 
    {
      method: 'GET',
      path: '/admin/profile',
      handler: 'admin.getAdminProfile',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'PUT',
      path: '/admin/profile',
      handler: 'admin.updateAdminProfile',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },

    // PLATFORM STATS 
    {
      method: 'GET',
      path: '/admin/stats',
      handler: 'admin.getPlatformStats',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },

    // Routes nest7a9hom ken sar probleme
    {
      method: 'POST',
      path: '/admin/register-manager',
      handler: 'admin.registerManager',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'PUT',
      path: '/admin/manager/:id',
      handler: 'admin.updateManager',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'DELETE',
      path: '/admin/manager/:id',
      handler: 'admin.deleteManager',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
    {
      method: 'POST',
      path: '/admin/register-worker',
      handler: 'admin.registerWorker',
      config: { auth: false, policies: ['global::authMiddleware', 'global::isAdmin'] },
    },
  ],
};


















/*module.exports = {
    routes: [
        {   
            method: "POST",
            path: "/admin/register-manager",
            handler: "admin.registermanager",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isAdmin"]
            }
        },
        {   
            method: "PUT",
            path: "/admin/manager/:id",
            handler: "admin.updatemanager",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isAdmin"]
            }
        },
        {   
            method: "DELETE",
            path: "/admin/manager/:id",
            handler: "admin.deletemanager",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isAdmin"]
            }
        },
        {   
            method: "GET",
            path: "/admin/managers",
            handler: "admin.getManagers",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isAdmin"]
            }
        },
        // ADDED: Get all players
        {   
            method: "GET",
            path: "/admin/players",
            handler: "admin.getPlayers",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isAdmin"]
            }
        },

        // ─────────────────────────────────────────────────────────────────────
        // WORKER MANAGEMENT (Admin only)
        // ─────────────────────────────────────────────────────────────────────
        {   
            method: "POST",
            path: "/admin/register-worker",
            handler: "admin.registerWorker",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isAdmin"]
            }
        },
        {   
            method: "GET",
            path: "/admin/workers",
            handler: "admin.getWorkers",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isAdmin"]
            }
        },
        {   
            method: "DELETE",
            path: "/admin/workers/:id",
            handler: "admin.deleteWorker",
            config: {
                auth: false,
                policies: ["global::authMiddleware", "global::isAdmin"]
            }
        },

        {
             method: "GET",
             path: "/admin/debug/manager/:id",
             handler: "admin.debugManager",
             config: {
             auth: false,
             policies: ["global::authMiddleware", "global::isAdmin"]
           }
 },
    ]
};
*/