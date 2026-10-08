// src/api/admin/services/admin.js
// @ts-nocheck
const { sendEmail } = require('../../../utils/email');

module.exports = {

  // les services li mawjoudin lkol 

  // MANAGERS 

  async registerManager({ username, email, password, phone }) {
    const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
    if (existing) throw new Error('User already exists');

    const role = await strapi.db.query('plugin::users-permissions.role').findOne({ where: { type: 'authenticated' } });
    const user = await strapi.plugins['users-permissions'].services.user.add({
      username, email, password, role: role.id, user_role: 'manager',
    });

    try {
      await strapi.db.query('api::manager.manager').create({
        data: { phone: phone || null, manager: user.id, publishedAt: new Date() },
      });
    } catch (e) {
      strapi.log.error('[admin] create manager profile error:', e.message);
    }

    try {
      await sendEmail(
        email,
        'Sporta — Your Manager Account',
        `<p>Hi <strong>${username}</strong>,</p>
         <p>Your manager account has been created.</p>
         <p>Email: <strong>${email}</strong><br/>Password: <strong>${password}</strong></p>
         <p>Please log in and change your password immediately.</p>
         <p>— Sporta Team</p>`,
        `Hi ${username},\n\nYour manager account:\nEmail: ${email}\nPassword: ${password}\n\nPlease change your password after logging in.`,
      );
    } catch (e) {
      strapi.log.error('[admin] welcome email error:', e.message);
    }

    return user;
  },

  async updateManager(userId, { username, email, phone }) {
    const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
    if (!user)                         throw new Error('Manager not found');
    if (user.user_role !== 'manager')  throw new Error('User is not a manager');

    if (email && email !== user.email) {
      const dup = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
      if (dup) throw new Error('Email already in use');
    }

    const updateData = {};
    if (username) updateData.username = username;
    if (email)    updateData.email    = email;

    const updatedUser = await strapi.db.query('plugin::users-permissions.user').update({
      where: { id: userId }, data: updateData,
    });

    if (phone !== undefined) {
      const profile = await strapi.db.query('api::manager.manager').findOne({ where: { manager: userId } });
      if (profile) {
        await strapi.db.query('api::manager.manager').update({ where: { id: profile.id }, data: { phone } });
      }
    }

    return updatedUser;
  },

  async deleteManager(userId) {
    const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
    if (!user)                        throw new Error('Manager not found');
    if (user.user_role !== 'manager') throw new Error('User is not a manager');

    const profile = await strapi.db.query('api::manager.manager').findOne({ where: { manager: userId } });
    if (profile) {
      await strapi.db.query('api::manager.manager').delete({ where: { id: profile.id } });
    }
    await strapi.db.query('plugin::users-permissions.user').delete({ where: { id: userId } });
    return { message: 'Manager deleted' };
  },

  async getManagers() {
    const users = await strapi.db.query('plugin::users-permissions.user').findMany({
      where: { user_role: 'manager' },
    });

    return Promise.all(users.map(async (user) => {
      const profile = await strapi.db.query('api::manager.manager').findOne({ where: { manager: user.id } });
      if (!profile) {
        return {
          id: user.id, username: user.username, email: user.email,
          phone: null, venues: [], totalVenues: 0, totalCourts: 0,
          totalBookings: 0, totalRevenue: 0,
          isActive: !user.blocked, createdAt: user.createdAt,
        };
      }

      const venues = await strapi.db.query('api::venue.venue').findMany({ where: { manager: profile.id } });

      let totalCourts = 0, totalBookings = 0, totalRevenue = 0;
      for (const venue of venues) {
        const courts = await strapi.db.query('api::court.court').findMany({ where: { venue: venue.id } });
        totalCourts += courts.length;
        for (const court of courts) {
          const reservations = await strapi.db.query('api::reservation.reservation').findMany({
            where: { court: court.id, booking_status: { $in: ['confirmed', 'completed'] } },
          });
          totalBookings += reservations.length;
          totalRevenue  += reservations.reduce((s, r) => s + (r.total_price || 0), 0);
        }
      }

      return {
        id: user.id, username: user.username, email: user.email,
        phone: profile.phone || null,
        venues: venues.map(v => ({ id: v.id, name: v.name, location: v.location })),
        totalVenues: venues.length, totalCourts, totalBookings, totalRevenue,
        isActive: !user.blocked, createdAt: user.createdAt,
      };
    }));
  },

  // PLAYERS 

  async registerPlayer({ username, email, password, phone }) {
    const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
    if (existing) throw new Error('User already exists');

    const role = await strapi.db.query('plugin::users-permissions.role').findOne({ where: { type: 'authenticated' } });
    const user = await strapi.plugins['users-permissions'].services.user.add({
      username, email, password, role: role.id, user_role: 'player',
    });

    try {
      await strapi.db.query('api::player.player').create({
        data: { phone: phone || null, player: user.id },
      });
    } catch (e) {
      strapi.log.error('[admin] create player profile error:', e.message);
    }

    try {
      await sendEmail(
        email,
        'Sporta — Welcome!',
        `<p>Hi <strong>${username}</strong>,</p>
         <p>Your Sporta player account is ready.</p>
         <p>Email: <strong>${email}</strong><br/>Password: <strong>${password}</strong></p>
         <p>Please log in and change your password.</p>
         <p>— Sporta Team</p>`,
        `Hi ${username},\n\nYour player account:\nEmail: ${email}\nPassword: ${password}`,
      );
    } catch (e) {
      strapi.log.error('[admin] welcome email error:', e.message);
    }

    return user;
  },

  async updatePlayer(userId, { username, email, phone }) {
    const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
    if (!user)                        throw new Error('Player not found');
    if (user.user_role !== 'player')  throw new Error('User is not a player');

    if (email && email !== user.email) {
      const dup = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
      if (dup) throw new Error('Email already in use');
    }

    const updateData = {};
    if (username) updateData.username = username;
    if (email)    updateData.email    = email;

    const updatedUser = await strapi.db.query('plugin::users-permissions.user').update({
      where: { id: userId }, data: updateData,
    });

    if (phone !== undefined) {
      const profile = await strapi.db.query('api::player.player').findOne({ where: { player: userId } });
      if (profile) {
        await strapi.db.query('api::player.player').update({ where: { id: profile.id }, data: { phone } });
      }
    }

    return updatedUser;
  },

  async deletePlayer(userId) {
    const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
    if (!user)                       throw new Error('Player not found');
    if (user.user_role !== 'player') throw new Error('User is not a player');

    const profile = await strapi.db.query('api::player.player').findOne({ where: { player: userId } });
    if (profile) {
      await strapi.db.query('api::player.player').delete({ where: { id: profile.id } });
    }
    await strapi.db.query('plugin::users-permissions.user').delete({ where: { id: userId } });
    return { message: 'Player deleted' };
  },

  async getPlayers() {
    const users = await strapi.db.query('plugin::users-permissions.user').findMany({
      where: { user_role: 'player' },
    });

    return Promise.all(users.map(async (user) => {
      const profile = await strapi.db.query('api::player.player').findOne({ where: { player: user.id } });
      let bookingsCount = 0, totalSpent = 0;
      if (profile?.id) {
        const reservations = await strapi.db.query('api::reservation.reservation').findMany({
          where: { player: profile.id, booking_status: { $in: ['confirmed', 'completed'] } },
        });
        bookingsCount = reservations.length;
        totalSpent    = reservations.reduce((s, r) => s + (r.total_price || 0), 0);
      }
      return {
        id: user.id, username: user.username, email: user.email,
        phone: profile?.phone || null,
        bookings: bookingsCount, totalSpent,
        isActive: !user.blocked, createdAt: user.createdAt,
      };
    }));
  },

  // WORKERS 

  async registerWorker({ username, email, password, phone, nom, managerId }) {
    const existing = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
    if (existing) throw new Error('User already exists');

    const role = await strapi.db.query('plugin::users-permissions.role').findOne({ where: { type: 'authenticated' } });
    const user = await strapi.plugins['users-permissions'].services.user.add({
      username, email, password, role: role.id, user_role: 'worker',
    });

    const manager = await strapi.db.query('api::manager.manager').findOne({ where: { id: managerId } });
    if (!manager) throw new Error('Manager not found');

    const worker = await strapi.db.query('api::worker.worker').create({
      data: {
        phone: phone || null,
        nom:   nom || username,
        worker: user.id,
        manager: managerId,
        isActive: true,
        joinedAt: new Date(),
        publishedAt: new Date(),
      },
    });

    try {
      await sendEmail(
        email,
        'Sporta — Your Worker Account',
        `<p>Hi <strong>${username}</strong>,</p>
         <p>Your worker account has been created.</p>
         <p>Email: <strong>${email}</strong><br/>Password: <strong>${password}</strong></p>
         <p>Please log in and change your password immediately.</p>
         <p>— Sporta Team</p>`,
        `Hi ${username},\n\nYour worker account:\nEmail: ${email}\nPassword: ${password}`,
      );
    } catch (e) {
      strapi.log.error('[admin] welcome email error:', e.message);
    }

    return { user, worker };
  },

  async updateWorker(userId, { username, email, phone, nom }) {
    const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
    if (!user)                        throw new Error('Worker not found');
    if (user.user_role !== 'worker')  throw new Error('User is not a worker');

    if (email && email !== user.email) {
      const dup = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { email } });
      if (dup) throw new Error('Email already in use');
    }

    const updateData = {};
    if (username) updateData.username = username;
    if (email)    updateData.email    = email;

    const updatedUser = await strapi.db.query('plugin::users-permissions.user').update({
      where: { id: userId }, data: updateData,
    });

    const workerProfile = await strapi.db.query('api::worker.worker').findOne({ where: { worker: userId } });
    if (workerProfile) {
      const workerData = {};
      if (phone !== undefined) workerData.phone = phone;
      if (nom)                 workerData.nom   = nom;
      if (Object.keys(workerData).length > 0) {
        await strapi.db.query('api::worker.worker').update({ where: { id: workerProfile.id }, data: workerData });
      }
    }

    return updatedUser;
  },

  async getWorkers() {
    const users = await strapi.db.query('plugin::users-permissions.user').findMany({
      where: { user_role: 'worker' },
    });

    return Promise.all(users.map(async (user) => {
      const worker = await strapi.db.query('api::worker.worker').findOne({
        where:   { worker: user.id },
        populate: ['courts', 'manager'],
      });
      return {
        id: user.id, username: user.username, email: user.email,
        createdAt: user.createdAt,
        phone:       worker?.phone   || null,
        nom:         worker?.nom     || user.username,
        managerId:   worker?.manager?.id   || null,
        managerName: worker?.manager?.nom  || null,
        courts:      worker?.courts  || [],
        isActive:    worker?.isActive ?? !user.blocked,
        joinedAt:    worker?.joinedAt,
      };
    }));
  },

  async deleteWorker(userId) {
    const user = await strapi.db.query('plugin::users-permissions.user').findOne({
      where: { id: userId, user_role: 'worker' },
    });
    if (!user) throw new Error('Worker not found');

    const worker = await strapi.db.query('api::worker.worker').findOne({ where: { worker: userId } });
    if (worker) {
      await strapi.db.query('api::court.court').updateMany({
        where: { worker: worker.id }, data: { worker: null },
      });
      await strapi.db.query('api::worker.worker').delete({ where: { id: worker.id } });
    }
    await strapi.db.query('plugin::users-permissions.user').delete({ where: { id: userId } });
    return { message: 'Worker deleted' };
  },

  // TOGGLE STATUS 

  async toggleUserStatus(userId) {
    const user = await strapi.db.query('plugin::users-permissions.user').findOne({ where: { id: userId } });
    if (!user) throw new Error('User not found');

    const updated = await strapi.db.query('plugin::users-permissions.user').update({
      where: { id: userId },
      data:  { blocked: !user.blocked },
    });

    strapi.log.info(`[admin] User ${userId} ${updated.blocked ? 'blocked' : 'unblocked'}`);
    return updated;
  },
};


















/*// @ts-nocheck
const {sendEmail} = require("../../../utils/email");

module.exports = {
    async registerManager({username, email, password, phone}) {
        const existing = await strapi.db.query("plugin::users-permissions.user").findOne({ where: { email } });
        if(existing) throw new Error("User already exists");

        const role = await strapi.db.query("plugin::users-permissions.role").findOne({ where: { type: "authenticated" } });

        const user = await strapi.plugins['users-permissions'].services.user.add({
            username,
            email,
            password,
            role: role.id,
            user_role: "manager"
        });

        let profile;    
        try {
            profile = await strapi.db.query("api::manager.manager").create({
                data: { phone: phone || null, manager: user.id, publishedAt: new Date() }
            });
        } catch (error) {
            console.error("Error creating manager profile:", error.message);
        }

        try {
            await sendEmail(
                email,
                "Welcome to Our Platform",
                `Hello ${username},\n\nYour manager account has been successfully created.`+
                `email: ${email}\n password: ${password}\n phone: ${phone || 'Not provided'}\n\n
                Please log in to your account and change your password immediately for security reasons.
                \n\nBest regards,\nThe Sporta Team`
            );
        } catch (error) {
            console.error("Error sending welcome email:", error.message);
        }
        
        return user;
    },

    async updateManager(userId, {username, email, phone}) {
        const user = await strapi.db.query("plugin::users-permissions.user").findOne({ where: { id: userId } });
        if (!user) throw new Error("We can't find the Manager");
        if(user.user_role !== "manager") throw new Error("You can modify only the Manager");

        if(email && email !== user.email){
            const existing = await strapi.db.query("plugin::users-permissions.user").findOne({ where: { email } });
            if(existing) throw new Error("User already exists");
        }

        const updateUser = await strapi.db.query("plugin::users-permissions.user").update({
            where: { id: userId },
            data: { ...(username && { username }), ...(email && { email }) }
        });

        const managerProfile = await strapi.db.query("api::manager.manager").findOne({ where: { manager: userId } });
        if (managerProfile){
            await strapi.db.query("api::manager.manager").update({
                where: { id: managerProfile.id },
                data: { ...(phone && { phone }) }
            });
        }

        return updateUser;
    },

    async deleteManager(userId) {
        const user = await strapi.db.query("plugin::users-permissions.user").findOne({ where: { id: userId } });
        if (!user) throw new Error("We can't find the Manager");
        if(user.user_role !== "manager") throw new Error("You can delete only the Manager");

        const managerProfile = await strapi.db.query("api::manager.manager").findOne({ where: { manager: userId } });
        if(managerProfile){
            await strapi.db.query("api::manager.manager").delete({ where: { id: managerProfile.id } });
        }

        await strapi.db.query("plugin::users-permissions.user").delete({ where: { id: userId } });

        return { message: "Manager is deleted successfully!" };
    },

 // UPDATED: Get all managers with REAL stats - FIXED field names
async getManagers() {
    const users = await strapi.db.query("plugin::users-permissions.user").findMany({ 
        where: { user_role: "manager" } 
    });
    
    const result = await Promise.all(users.map(async (user) => {
        // Get manager profile
        const profile = await strapi.db.query("api::manager.manager").findOne({ 
            where: { manager: user.id }
        });
        
        // If no profile, return basic info
        if (!profile) {
            return {
                id: user.id,
                username: user.username,
                email: user.email,
                phone: null,
                venues: [],
                totalVenues: 0,
                totalCourts: 0,
                totalBookings: 0,
                totalRevenue: 0,
                isActive: true,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt
            };
        }
        
        // Get all venues for this manager
        const venues = await strapi.db.query("api::venue.venue").findMany({
            where: { manager: profile.id }
        });
        
        // Get all courts for these venues
        let allCourts = [];
        for (const venue of venues) {
            const courts = await strapi.db.query("api::court.court").findMany({
                where: { venue: venue.id }
            });
            allCourts = [...allCourts, ...courts];
        }
        
        // Get court IDs
        const courtIds = allCourts.map(c => c.id);
        
        // Get all reservations for these courts
        let totalRevenue = 0;
        let totalBookings = 0;
        
        if (courtIds.length > 0) {
            // Query reservations - using correct field name 'status' not 'booking_status'
            for (const courtId of courtIds) {
                const reservations = await strapi.db.query("api::reservation.reservation").findMany({
                    where: { 
                        court: courtId
                        // Don't filter by status in query, we'll filter in code
                    }
                });
                
                for (const res of reservations) {
                    // Only count confirmed or completed reservations
                    const status = res.status || res.booking_status;
                    if (status === 'confirmed' || status === 'completed') {
                        totalBookings++;
                        totalRevenue += res.total_price || 0;
                    }
                }
            }
        }
        
        return {
            id: user.id,
            username: user.username,
            email: user.email,
            phone: profile?.phone || null,
            venues: venues.map(v => ({ 
                id: v.id, 
                name: v.name, 
                location: v.location 
            })),
            totalVenues: venues.length,
            totalCourts: allCourts.length,
            totalBookings: totalBookings,
            totalRevenue: totalRevenue,
            isActive: user.blocked ? false : true,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt
        };
    }));
    
    return result;
},
    // ADDED: Get all players with REAL bookings count and total spent
    async getPlayers() {
        const users = await strapi.db.query("plugin::users-permissions.user").findMany({ 
            where: { user_role: "player" } 
        });
        
        const result = await Promise.all(users.map(async (user) => {
            const profile = await strapi.db.query("api::player.player").findOne({ 
                where: { player: user.id },
                populate: ['player']
            });
            
            // Calculate real bookings count and total spent from reservations
            let bookingsCount = 0;
            let totalSpent = 0;
            
            if (profile?.id) {
                // Get all confirmed and completed reservations for this player
                const reservations = await strapi.db.query("api::reservation.reservation").findMany({
                    where: { 
                        player: profile.id,
                        booking_status: { $in: ['confirmed', 'completed'] }
                    }
                });
                
                bookingsCount = reservations.length;
                totalSpent = reservations.reduce((sum, res) => sum + (res.total_price || 0), 0);
            }
            
            return {
                id: user.id,
                username: user.username,
                email: user.email,
                phone: profile?.phone || null,
                bookings: bookingsCount,
                totalSpent: totalSpent,
                isActive: user.blocked ? false : true,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt
            };
        }));
        
        return result;
    },

    // ─────────────────────────────────────────────────────────────────────────
    // WORKER MANAGEMENT (Admin only - create, list all, delete)
    // ─────────────────────────────────────────────────────────────────────────

    async registerWorker({ username, email, password, phone, nom, managerId }) {
        const existing = await strapi.db.query("plugin::users-permissions.user").findOne({ where: { email } });
        if (existing) throw new Error("User already exists");

        const role = await strapi.db.query("plugin::users-permissions.role").findOne({ where: { type: "authenticated" } });

        const user = await strapi.plugins['users-permissions'].services.user.add({
            username,
            email,
            password,
            role: role.id,
            user_role: "worker"
        });

        // Verify manager exists
        const manager = await strapi.db.query("api::manager.manager").findOne({
            where: { id: managerId },
        });

        if (!manager) throw new Error("Manager not found");

        // Create worker profile (initially with no courts assigned)
        const worker = await strapi.db.query("api::worker.worker").create({
            data: {
                phone: phone || null,
                nom: nom || username,
                worker: user.id,
                manager: managerId,
                isActive: true,
                joinedAt: new Date(),
                publishedAt: new Date()
            }
        });

        // Send welcome email
        try {
            await sendEmail(
                email,
                "Welcome to Our Platform - Worker Account",
                `Hello ${username},\n\nYour worker account has been successfully created.\n` +
                `Email: ${email}\nPassword: ${password}\nPhone: ${phone || 'Not provided'}\n\n` +
                `Your manager will assign you to courts shortly.\n\n` +
                `Please log in to your account and change your password immediately for security reasons.\n\n` +
                `Best regards,\nThe Sporta Team`
            );
        } catch (error) {
            console.error("Error sending welcome email:", error.message);
        }

        return { user, worker };
    },

    async getWorkers() {
        const users = await strapi.db.query("plugin::users-permissions.user").findMany({ 
            where: { user_role: "worker" },
            select: ['id', 'username', 'email', 'createdAt']
        });
        
        const result = await Promise.all(users.map(async (user) => {
            const worker = await strapi.db.query("api::worker.worker").findOne({
                where: { worker: user.id },
                populate: ['courts', 'manager']
            });
            
            return {
                id: user.id,
                username: user.username,
                email: user.email,
                createdAt: user.createdAt,
                phone: worker?.phone || null,
                nom: worker?.nom || user.username,
                managerId: worker?.manager?.id || null,
                managerName: worker?.manager?.nom || null,
                courts: worker?.courts || [],
                isActive: worker?.isActive ?? true,
                joinedAt: worker?.joinedAt,
                firebaseUid: worker?.firebaseUid || null
            };
        }));
        
        return result;
    },

    async deleteWorker(userId) {
        const user = await strapi.db.query("plugin::users-permissions.user").findOne({ 
            where: { id: userId, user_role: "worker" } 
        });
        
        if (!user) throw new Error("Worker not found");

        // Find and delete worker profile
        const worker = await strapi.db.query("api::worker.worker").findOne({
            where: { worker: userId }
        });

        if (worker) {
            // Remove worker from all courts
            await strapi.db.query("api::court.court").updateMany({
                where: { worker: worker.id },
                data: { worker: null }
            });

            // Delete worker profile
            await strapi.db.query("api::worker.worker").delete({
                where: { id: worker.id }
            });
        }

        // Delete user
        await strapi.db.query("plugin::users-permissions.user").delete({
            where: { id: userId }
        });

        return { message: "Worker deleted successfully" };
    },
};

*/