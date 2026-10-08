// src/api/admin/controllers/admin.js
// @ts-nocheck
const adminService = require('../services/admin');

module.exports = {

  // lahnee lcrud mta3 l'admin lkol w stats , " wsolt kamelt stats saye ""


  // Managers
  async registerManager(ctx) {
    try {
      const { username, email, password, phone } = ctx.request.body;
      const user = await adminService.registerManager({ username, email, password, phone });
      ctx.send({ message: 'Manager registered successfully', user });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  async updateManager(ctx) {
    try {
      const { id } = ctx.params;
      const data   = ctx.request.body;
      const result = await adminService.updateManager(id, data);
      ctx.send({ message: 'Manager updated successfully', result });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  async deleteManager(ctx) {
    try {
      const { id } = ctx.params;
      const result  = await adminService.deleteManager(id);
      ctx.send({ message: 'Manager deleted successfully', result });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  async getManagers(ctx) {
    try {
      const result = await adminService.getManagers();
      ctx.send(result);
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  //  PLAYERS

  async getPlayers(ctx) {
    try {
      const result = await adminService.getPlayers();
      ctx.send(result);
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  async registerPlayer(ctx) {
    try {
      const { username, email, password, phone } = ctx.request.body;
      const result = await adminService.registerPlayer({ username, email, password, phone });
      ctx.send({ message: 'Player registered successfully', result });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  async updatePlayer(ctx) {
    try {
      const { id } = ctx.params;
      const data   = ctx.request.body;
      const result = await adminService.updatePlayer(id, data);
      ctx.send({ message: 'Player updated successfully', result });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  async deletePlayer(ctx) {
    try {
      const { id } = ctx.params;
      const result  = await adminService.deletePlayer(id);
      ctx.send({ message: 'Player deleted successfully', result });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  //  WORKERS 

  async registerWorker(ctx) {
    try {
      const { username, email, password, phone, nom, managerId } = ctx.request.body;
      if (!managerId) return ctx.badRequest('managerId is required');
      const result = await adminService.registerWorker({ username, email, password, phone, nom, managerId });
      ctx.send({ message: 'Worker registered successfully', result });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  async getWorkers(ctx) {
    try {
      const result = await adminService.getWorkers();
      ctx.send(result);
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  async updateWorker(ctx) {
    try {
      const { id } = ctx.params;
      const data   = ctx.request.body;
      const result = await adminService.updateWorker(id, data);
      ctx.send({ message: 'Worker updated successfully', result });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  async deleteWorker(ctx) {
    try {
      const { id } = ctx.params;
      const result  = await adminService.deleteWorker(id);
      ctx.send({ message: 'Worker deleted successfully', result });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  //  haka najem nblocki ay user waela najem na7ilou lblock zeda

  async toggleUserStatus(ctx) {
    try {
      const { id } = ctx.params;
      const result  = await adminService.toggleUserStatus(id);
      ctx.send({ message: `User ${result.blocked ? 'blocked' : 'unblocked'} successfully`, result });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  // profile l'admin

  async getAdminProfile(ctx) {
    try {
      const user = ctx.state.user;
      if (!user || user.user_role !== 'admin') return ctx.unauthorized('Admin only');
      const profile = await strapi.db.query('plugin::users-permissions.user').findOne({
        where: { id: user.id },
        select: ['id', 'username', 'email', 'createdAt'],
      });
      ctx.send({ profile });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  async updateAdminProfile(ctx) {
    try {
      const user = ctx.state.user;
      if (!user || user.user_role !== 'admin') return ctx.unauthorized('Admin only');

      const { username, email, password } = ctx.request.body;

      const updateData = {};
      if (username && username.trim()) updateData.username = username.trim();
      if (email    && email.trim())    updateData.email    = email.trim();

      // Password change goes through users-permissions service (hashes automatically)
      if (password && password.trim().length >= 8) {
        await strapi.plugins['users-permissions'].services.user.edit(user.id, { password: password.trim() });
      }

      if (Object.keys(updateData).length > 0) {
        await strapi.db.query('plugin::users-permissions.user').update({
          where: { id: user.id },
          data:  updateData,
        });
      }

      const updated = await strapi.db.query('plugin::users-permissions.user').findOne({
        where:  { id: user.id },
        select: ['id', 'username', 'email', 'createdAt'],
      });

      ctx.send({ message: 'Profile updated successfully', profile: updated });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },

  //  PLATFORM STATS 
  // endpoint wa7da lel admin bech n5arrej beha stats , 9bal kont n5arrej fihom men barcha blayes 

  async getPlatformStats(ctx) {
    try {
      const user = ctx.state.user;
      if (!user || user.user_role !== 'admin') return ctx.unauthorized('Admin only');

      const [playerCount, managerCount, workerCount, venueCount, reservationCount] = await Promise.all([
        strapi.db.query('plugin::users-permissions.user').count({ where: { user_role: 'player' } }),
        strapi.db.query('plugin::users-permissions.user').count({ where: { user_role: 'manager' } }),
        strapi.db.query('plugin::users-permissions.user').count({ where: { user_role: 'worker' } }),
        strapi.db.query('api::venue.venue').count({}),
        strapi.db.query('api::reservation.reservation').count({}),
      ]);

      // el revenue
      const completedReservations = await strapi.db.query('api::reservation.reservation').findMany({
        where: { booking_status: { $in: ['confirmed', 'completed'] } },
        select: ['total_price'],
      });
      const totalRevenue = completedReservations.reduce((sum, r) => sum + (r.total_price || 0), 0);

      ctx.send({ playerCount, managerCount, workerCount, venueCount, reservationCount, totalRevenue });
    } catch (error) {
      ctx.badRequest(error.message);
    }
  },
};






























/*// @ts-nocheck
const adminService = require('../services/admin');

module.exports = { 


    async registermanager(ctx) {
        try {
            const {username, email, password, phone} = ctx.request.body;
            const user = await adminService.registerManager({username, email, password, phone}); 
            ctx.send({message: "Manager registered successfully", user});
        } catch (error) {
            console.error("Error in register Manager :", error.message);
            ctx.badRequest(error.message);
        }
    },

    async updatemanager(ctx) {
        try {   
            const {id} = ctx.params;
            const data = ctx.request.body;
            const result = await adminService.updateManager(id,data); 
            ctx.send({message: "Manager updated successfully", result});
        } catch (error) {
            console.error("Error in updating Manager :", error.message);
            ctx.badRequest(error.message);
        }
    },

    async deletemanager(ctx) {
        try {
            const {id} = ctx.params;    
            const result = await adminService.deleteManager(id); 
            ctx.send({message: "Manager deleted successfully", result});
        } catch (error) {
            console.error("Error in deleting Manager :", error.message);
            ctx.badRequest(error.message);
        }
    },

    
    async getManagers(ctx) {
        try {   
            const result = await adminService.getManagers(); 
            ctx.send(result);
        } catch (error) {
            console.error("Error getManagers :", error.message);
            ctx.badRequest(error.message);
        }
    },

    // ADDED: Get all players
    async getPlayers(ctx) {
        try {   
            const result = await adminService.getPlayers(); 
            ctx.send(result);
        } catch (error) {
            console.error("Error getPlayers :", error.message);
            ctx.badRequest(error.message);
        }
    },

    // ─────────────────────────────────────────────────────────────────────────
    // WORKER MANAGEMENT (Admin only)
    // ─────────────────────────────────────────────────────────────────────────

    async registerWorker(ctx) {
        try {
            const { username, email, password, phone, nom, managerId } = ctx.request.body;
            
            if (!managerId) {
                return ctx.badRequest("managerId is required");
            }
            
            const result = await adminService.registerWorker({ 
                username, 
                email, 
                password, 
                phone, 
                nom, 
                managerId 
            });
            
            ctx.send({ message: "Worker registered successfully", result });
        } catch (error) {
            console.error("Error in registerWorker:", error.message);
            ctx.badRequest(error.message);
        }
    },

    async getWorkers(ctx) {
        try {
            const result = await adminService.getWorkers();
            ctx.send(result);
        } catch (error) {
            console.error("Error getWorkers:", error.message);
            ctx.badRequest(error.message);
        }
    },

    async deleteWorker(ctx) {
        try {
            const { id } = ctx.params;
            const result = await adminService.deleteWorker(id);
            ctx.send({ message: "Worker deleted successfully", result });
        } catch (error) {
            console.error("Error deleteWorker:", error.message);
            ctx.badRequest(error.message);
        }
    },


// Add this to your admin controller (src/api/admin/controllers/admin.js)
async debugManager(ctx) {
    try {
        const userId = ctx.params.id;
        
        // Get user
        const user = await strapi.db.query("plugin::users-permissions.user").findOne({ 
            where: { id: userId, user_role: "manager" } 
        });
        
        if (!user) {
            return ctx.send({ error: "Manager not found" });
        }
        
        // Get profile
        const profile = await strapi.db.query("api::manager.manager").findOne({ 
            where: { manager: user.id }
        });
        
        // Get venues
        const venues = await strapi.db.query("api::venue.venue").findMany({
            where: { manager: profile?.id }
        });
        
        // Get courts
        let allCourts = [];
        for (const venue of venues) {
            const courts = await strapi.db.query("api::court.court").findMany({
                where: { venue: venue.id }
            });
            allCourts = [...allCourts, ...courts];
        }
        
        // Get reservations
        let reservations = [];
        for (const court of allCourts) {
            const res = await strapi.db.query("api::reservation.reservation").findMany({
                where: { court: court.id }
            });
            reservations = [...reservations, ...res];
        }
        
        ctx.send({
            user: { id: user.id, username: user.username, email: user.email },
            profile: profile,
            venues: venues.map(v => ({ id: v.id, name: v.name })),
            venuesCount: venues.length,
            courts: allCourts.map(c => ({ id: c.id, name: c.name })),
            courtsCount: allCourts.length,
            reservations: reservations.map(r => ({ id: r.id, court: r.court, status: r.booking_status, price: r.total_price })),
            reservationsCount: reservations.length,
            totalRevenue: reservations.reduce((sum, r) => sum + (r.total_price || 0), 0)
        });
        
    } catch (error) {
        console.error("Debug error:", error);
        ctx.send({ error: error.message });
    }
}

};
*/