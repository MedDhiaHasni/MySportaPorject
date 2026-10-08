// src/api/court/services/court.js
// @ts-nocheck
'use strict';

module.exports = {

  async getManagerCourts(managerId) {
    const venues = await strapi.db.query('api::venue.venue').findMany({
      where:  { manager: { id: managerId } },
      select: ['id'],
    });
    const venueIds = venues.map(v => v.id);

    const courts = await strapi.db.query('api::court.court').findMany({
      where:    { venue: { id: { $in: venueIds } } },
      populate: ['venue', 'court_img', 'photos', 'worker'],
    });

    const baseUrl = strapi.config.get('server.url') || '';
    return courts.map(court => ({
        // spread operator ycopi les champs mta3 el courts
      ...court,
      court_img_url: court.court_img?.url ? `${baseUrl}${court.court_img.url}` : null,
      court_img_id:  court.court_img?.id  || null,
      photos_urls:   court.photos?.map(p => `${baseUrl}${p.url}`) || [],
      photos_ids:    court.photos?.map(p => p.id) || [],
      worker: court.worker
        ? { id: court.worker.id, nom: court.worker.nom, phone: court.worker.phone }
        : null,
    }));
  },

  async getCourtById(courtId, managerId) {
    const court = await strapi.db.query('api::court.court').findOne({
      where:    { id: courtId },
      populate: ['venue', 'venue.manager', 'court_img', 'photos', 'worker'],
    });
    if (!court) throw new Error('Court not found');
    if (!court.venue || court.venue.manager.id !== managerId) {
      throw new Error("You don't have permission to access this court");
    }
    const baseUrl = strapi.config.get('server.url') || '';
    return {
      ...court,
      court_img_url: court.court_img?.url ? `${baseUrl}${court.court_img.url}` : null,
      court_img_id:  court.court_img?.id  || null,
      photos_urls:   court.photos?.map(p => `${baseUrl}${p.url}`) || [],
      photos_ids:    court.photos?.map(p => p.id) || [],
      worker: court.worker
        ? { id: court.worker.id, nom: court.worker.nom, phone: court.worker.phone }
        : null,
    };
  },

  async createCourt(data, managerId) {
    const { name, description, sport, pricePerHour, capacity, court_img, photos, amenities, isActive, venue } = data;

    const venueCheck = await strapi.db.query('api::venue.venue').findOne({
      where:    { id: venue },
      populate: ['manager'],
    });
    if (!venueCheck) throw new Error('Venue not found');
    if (venueCheck.manager.id !== managerId) throw new Error("You don't have permission to add courts to this venue");

    const court = await strapi.db.query('api::court.court').create({
      data: {
        name, description: description || null, sport, pricePerHour, capacity,
        court_img: court_img || null, photos: photos || null,
        amenities: amenities || null,
        isActive: isActive !== undefined ? isActive : true,
        venue, manager: venueCheck.manager.id,
        publishedAt: new Date(),
      },
    });

    const created = await strapi.db.query('api::court.court').findOne({
      where:    { id: court.id },
      populate: ['court_img', 'photos', 'worker'],
    });
    const baseUrl = strapi.config.get('server.url') || '';
    return {
      ...created,
      court_img_url: created.court_img?.url ? `${baseUrl}${created.court_img.url}` : null,
      photos_urls:   created.photos?.map(p => `${baseUrl}${p.url}`) || [],
      worker: created.worker
        ? { id: created.worker.id, nom: created.worker.nom, phone: created.worker.phone }
        : null,
    };
  },

  async updateCourt(courtId, managerId, data) {
    const existing = await strapi.db.query('api::court.court').findOne({
      where:    { id: courtId },
      populate: ['venue', 'venue.manager', 'worker'],
    });
    if (!existing) throw new Error('Court not found');
    if (!existing.venue || existing.venue.manager.id !== managerId) {
      throw new Error("You don't have permission to update this court");
    }

    const { name, description, sport, pricePerHour, capacity, court_img, photos, amenities, isActive, workerId } = data;
    const updateData = {};
    if (name        !== undefined) updateData.name        = name;
    if (description !== undefined) updateData.description = description;
    if (sport       !== undefined) updateData.sport       = sport;
    if (pricePerHour !== undefined) updateData.pricePerHour = pricePerHour;
    if (capacity    !== undefined) updateData.capacity    = capacity;
    if (court_img   !== undefined) updateData.court_img   = court_img;
    if (photos      !== undefined) updateData.photos      = photos;
    if (amenities   !== undefined) updateData.amenities   = amenities;
    if (isActive    !== undefined) updateData.isActive    = isActive;

    if (workerId !== undefined) {
      if (workerId === null) {
        updateData.worker = null;
      } else {
        const worker = await strapi.db.query('api::worker.worker').findOne({
          where: { id: workerId, manager: managerId },
        });
        if (!worker) throw new Error('Worker not found or not under your management');
        updateData.worker = workerId;
      }
    }

    await strapi.db.query('api::court.court').update({ where: { id: courtId }, data: updateData });

    const updated = await strapi.db.query('api::court.court').findOne({
      where:    { id: courtId },
      populate: ['court_img', 'photos', 'worker'],
    });
    const baseUrl = strapi.config.get('server.url') || '';
    return {
      ...updated,
      court_img_url: updated.court_img?.url ? `${baseUrl}${updated.court_img.url}` : null,
      photos_urls:   updated.photos?.map(p => `${baseUrl}${p.url}`) || [],
      worker: updated.worker
        ? { id: updated.worker.id, nom: updated.worker.nom, phone: updated.worker.phone }
        : null,
    };
  },

  async deleteCourt(courtId, managerId) {
    const existing = await strapi.db.query('api::court.court').findOne({
      where:    { id: courtId },
      populate: ['venue', 'venue.manager'],
    });
    if (!existing) throw new Error('Court not found');
    if (!existing.venue || existing.venue.manager.id !== managerId) {
      throw new Error("You don't have permission to delete this court");
    }
    await strapi.db.query('api::court.court').delete({ where: { id: courtId } });
    return { message: 'Court deleted successfully' };
  },

// hedhi l'assign
  async assignWorkerToCourt(courtId, workerId, managerId) {
    const court = await strapi.db.query('api::court.court').findOne({
      where:    { id: courtId },
      populate: ['venue', 'venue.manager'],
    });
    if (!court) throw new Error('Court not found');
    if (!court.venue || court.venue.manager.id !== managerId) {
      throw new Error("You don't have permission to update this court");
    }

    // npopulati el worker bech ne5ou l'id mte3ou
    const worker = await strapi.db.query('api::worker.worker').findOne({
      where:    { id: workerId, manager: managerId },
      populate: { worker: true }, // worker.worker = linked Strapi user
    });
    if (!worker) throw new Error('Worker not found or not under your management');

    await strapi.db.query('api::court.court').update({
      where: { id: courtId },
      data:  { worker: workerId },
    });

    // hnee creatit el conversation bin el worker wel manager fel firebase awel ma ysirlou assign
    try {
      const firebaseService = require('../../../firebase/firebase.service');

      // Fetch manager record to get nom + firebaseUid w yemzeùni nbadelha lel username el nom may5ademch
      const managerRecord = await strapi.db.query('api::manager.manager').findOne({
        where: { id: managerId },
      });

      // ✅ FIX: use worker.worker.id (Strapi user id) — same as Flutter getMe returns.
      // This ensures the UID in Firestore matches what the Flutter worker app reads.
      const workerUserId = worker.worker?.id ?? worker.id;
      const workerUid = worker.firebaseUid?.trim()
        ? worker.firebaseUid
        : `sporta_worker_${workerUserId}`;

      const managerUid = managerRecord?.firebaseUid?.trim()
        ? managerRecord.firebaseUid
        : `sporta_manager_${managerId}`;

      await firebaseService.createWorkerManagerConversation({
        // hnee l7ajet li nalgehom fel conversation fel firestore
        workerId:    workerUserId,
        managerId,
        workerUid,
        managerUid,
        workerName:  worker.nom         || 'Worker',
        managerName: managerRecord?.nom || 'Manager',
      });
    } catch (e) {
      // Non-fatal — assignment still succeeds even if Firebase fails
      console.error('[court] worker↔manager conversation error:', e.message);
    }

    return { message: 'Worker assigned successfully' };
  },

  // remove worker from the court mghir l'ndeleti el 
  async removeWorkerFromCourt(courtId, managerId) {
    const court = await strapi.db.query('api::court.court').findOne({
      where:    { id: courtId },
      populate: ['venue', 'venue.manager'],
    });
    if (!court) throw new Error('Court not found');
    if (!court.venue || court.venue.manager.id !== managerId) {
      throw new Error("You don't have permission to update this court");
    }

    await strapi.db.query('api::court.court').update({
      where: { id: courtId },
      data:  { worker: null },
    });

    return { message: 'Worker removed from court successfully' };
  },
};


















/*// @ts-nocheck
'use strict';

module.exports = {
    async getManagerCourts(managerId) {
        const venues = await strapi.db.query("api::venue.venue").findMany({
            where: { manager: { id: managerId } },
            select: ['id']
        });
        
        const venueIds = venues.map(v => v.id);
        
        const courts = await strapi.db.query("api::court.court").findMany({
            where: { venue: { id: { $in: venueIds } } },
            populate: ['venue', 'court_img', 'photos', 'worker']
        });
        
        const baseUrl = strapi.config.get('server.url') || '';
        const transformedCourts = courts.map(court => ({
            ...court,
            court_img_url: court.court_img?.url ? `${baseUrl}${court.court_img.url}` : null,
            court_img_id: court.court_img?.id || null,
            photos_urls: court.photos?.map(p => `${baseUrl}${p.url}`) || [],
            photos_ids: court.photos?.map(p => p.id) || [],
            worker: court.worker ? {
                id: court.worker.id,
                nom: court.worker.nom,
                phone: court.worker.phone
            } : null
        }));
        
        return transformedCourts;
    },

    async getCourtById(courtId, managerId) {
        const court = await strapi.db.query("api::court.court").findOne({
            where: { id: courtId },
            populate: ['venue', 'venue.manager', 'court_img', 'photos', 'worker']
        });
        
        if (!court) throw new Error("Court not found");
        if (!court.venue || court.venue.manager.id !== managerId) {
            throw new Error("You don't have permission to access this court");
        }
        
        const baseUrl = strapi.config.get('server.url') || '';
        const transformedCourt = {
            ...court,
            court_img_url: court.court_img?.url ? `${baseUrl}${court.court_img.url}` : null,
            court_img_id: court.court_img?.id || null,
            photos_urls: court.photos?.map(p => `${baseUrl}${p.url}`) || [],
            photos_ids: court.photos?.map(p => p.id) || [],
            worker: court.worker ? {
                id: court.worker.id,
                nom: court.worker.nom,
                phone: court.worker.phone
            } : null
        };
        
        return transformedCourt;
    },

    async createCourt(data, managerId) {
        const { 
            name, description, sport, pricePerHour, capacity, 
            court_img, photos, amenities, isActive, venue 
        } = data;
        
        const venueCheck = await strapi.db.query("api::venue.venue").findOne({
            where: { id: venue },
            populate: ['manager']
        });
        
        if (!venueCheck) throw new Error("Venue not found");
        if (venueCheck.manager.id !== managerId) throw new Error("You don't have permission to add courts to this venue");
        
        const court = await strapi.db.query("api::court.court").create({
            data: {
                name,
                description: description || null,
                sport,
                pricePerHour,
                capacity,
                court_img: court_img || null,
                photos: photos || null,
                amenities: amenities || null,
                isActive: isActive !== undefined ? isActive : true,
                venue: venue,
                manager: venueCheck.manager.id,
                publishedAt: new Date()
            }
        });
        
        const createdCourt = await strapi.db.query("api::court.court").findOne({
            where: { id: court.id },
            populate: ['court_img', 'photos', 'worker']
        });
        
        const baseUrl = strapi.config.get('server.url') || '';
        return {
            ...createdCourt,
            court_img_url: createdCourt.court_img?.url ? `${baseUrl}${createdCourt.court_img.url}` : null,
            photos_urls: createdCourt.photos?.map(p => `${baseUrl}${p.url}`) || [],
            worker: createdCourt.worker ? {
                id: createdCourt.worker.id,
                nom: createdCourt.worker.nom,
                phone: createdCourt.worker.phone
            } : null
        };
    },

    async updateCourt(courtId, managerId, data) {
        const existing = await strapi.db.query("api::court.court").findOne({
            where: { id: courtId },
            populate: ['venue', 'venue.manager', 'worker']
        });
        
        if (!existing) throw new Error("Court not found");
        if (!existing.venue || existing.venue.manager.id !== managerId) {
            throw new Error("You don't have permission to update this court");
        }
        
        const { 
            name, description, sport, pricePerHour, capacity, 
            court_img, photos, amenities, isActive, workerId
        } = data;
        
        const updateData = {};
        if (name !== undefined) updateData.name = name;
        if (description !== undefined) updateData.description = description;
        if (sport !== undefined) updateData.sport = sport;
        if (pricePerHour !== undefined) updateData.pricePerHour = pricePerHour;
        if (capacity !== undefined) updateData.capacity = capacity;
        if (court_img !== undefined) updateData.court_img = court_img;
        if (photos !== undefined) updateData.photos = photos;
        if (amenities !== undefined) updateData.amenities = amenities;
        if (isActive !== undefined) updateData.isActive = isActive;
        
        // Handle worker assignment
        if (workerId !== undefined) {
            if (workerId === null) {
                updateData.worker = null;
            } else {
                const worker = await strapi.db.query("api::worker.worker").findOne({
                    where: { id: workerId, manager: managerId }
                });
                if (worker) {
                    updateData.worker = workerId;
                } else {
                    throw new Error("Worker not found or not under your management");
                }
            }
        }
        
        await strapi.db.query("api::court.court").update({
            where: { id: courtId },
            data: updateData
        });
        
        const updated = await strapi.db.query("api::court.court").findOne({
            where: { id: courtId },
            populate: ['court_img', 'photos', 'worker']
        });
        
        const baseUrl = strapi.config.get('server.url') || '';
        return {
            ...updated,
            court_img_url: updated.court_img?.url ? `${baseUrl}${updated.court_img.url}` : null,
            photos_urls: updated.photos?.map(p => `${baseUrl}${p.url}`) || [],
            worker: updated.worker ? {
                id: updated.worker.id,
                nom: updated.worker.nom,
                phone: updated.worker.phone
            } : null
        };
    },

    async deleteCourt(courtId, managerId) {
        const existing = await strapi.db.query("api::court.court").findOne({
            where: { id: courtId },
            populate: ['venue', 'venue.manager']
        });
        
        if (!existing) throw new Error("Court not found");
        if (!existing.venue || existing.venue.manager.id !== managerId) {
            throw new Error("You don't have permission to delete this court");
        }
        
        await strapi.db.query("api::court.court").delete({
            where: { id: courtId }
        });
        
        return { message: "Court deleted successfully" };
    },
    
    // NEW: Assign worker to a court
    async assignWorkerToCourt(courtId, workerId, managerId) {
        const court = await strapi.db.query("api::court.court").findOne({
            where: { id: courtId },
            populate: ['venue', 'venue.manager']
        });
        
        if (!court) throw new Error("Court not found");
        if (!court.venue || court.venue.manager.id !== managerId) {
            throw new Error("You don't have permission to update this court");
        }
        
        const worker = await strapi.db.query("api::worker.worker").findOne({
            where: { id: workerId, manager: managerId }
        });
        
        if (!worker) throw new Error("Worker not found or not under your management");
        
        await strapi.db.query("api::court.court").update({
            where: { id: courtId },
            data: { worker: workerId }
        });
        
        return { message: "Worker assigned successfully" };
    },
    
    // NEW: Remove worker from a court
    async removeWorkerFromCourt(courtId, managerId) {
        const court = await strapi.db.query("api::court.court").findOne({
            where: { id: courtId },
            populate: ['venue', 'venue.manager']
        });
        
        if (!court) throw new Error("Court not found");
        if (!court.venue || court.venue.manager.id !== managerId) {
            throw new Error("You don't have permission to update this court");
        }
        
        await strapi.db.query("api::court.court").update({
            where: { id: courtId },
            data: { worker: null }
        });
        
        return { message: "Worker removed from court successfully" };
    }
};








**********************************






// @ts-nocheck
// src/api/court/services/court.js

'use strict';

module.exports = {
    // Get all courts for a manager's venues
    /**
     * @param {any} managerId
     */
   /* async getManagerCourts(managerId) {
        // First get all venues belonging to this manager
        const venues = await strapi.db.query("api::venue.venue").findMany({
            where: { manager: { id: managerId } },
            select: ['id']
        });
        
        const venueIds = venues.map(v => v.id);
        
        // Get all courts in those venues with media populated
        const courts = await strapi.db.query("api::court.court").findMany({
            where: { venue: { id: { $in: venueIds } } },
            populate: ['venue', 'court_img', 'photos']
        });
        
        // Transform to include image URLs
        const baseUrl = strapi.config.get('server.url') || '';
        const transformedCourts = courts.map(court => ({
            ...court,
            court_img_url: court.court_img?.url ? `${baseUrl}${court.court_img.url}` : null,
            court_img_id: court.court_img?.id || null,
            photos_urls: court.photos?.map(p => `${baseUrl}${p.url}`) || [],
            photos_ids: court.photos?.map(p => p.id) || [],
        }));
        
        return transformedCourts;
    },

    // Get single court by ID with ownership check
    /**
     * @param {any} courtId
     * @param {any} managerId
     */
  /*  async getCourtById(courtId, managerId) {
        const court = await strapi.db.query("api::court.court").findOne({
            where: { id: courtId },
            populate: ['venue', 'venue.manager', 'court_img', 'photos']
        });
        
        if (!court) throw new Error("Court not found");
        if (!court.venue || court.venue.manager.id !== managerId) {
            throw new Error("You don't have permission to access this court");
        }
        
        // Transform to include image URLs
        const baseUrl = strapi.config.get('server.url') || '';
        const transformedCourt = {
            ...court,
            court_img_url: court.court_img?.url ? `${baseUrl}${court.court_img.url}` : null,
            court_img_id: court.court_img?.id || null,
            photos_urls: court.photos?.map(p => `${baseUrl}${p.url}`) || [],
            photos_ids: court.photos?.map(p => p.id) || [],
        };
        
        return transformedCourt;
    },

    // Create a new court
    /**
     * @param {{ name: any; description: any; sport: any; pricePerHour: any; capacity: any; court_img: any; photos: any; amenities: any; isActive: any; venue: any; }} data
     * @param {any} managerId
     */
 /*   async createCourt(data, managerId) {
        const { 
            name, 
            description, 
            sport, 
            pricePerHour, 
            capacity, 
            court_img, 
            photos, 
            amenities, 
            isActive, 
            venue 
        } = data;
        
        // Verify the venue belongs to this manager
        const venueCheck = await strapi.db.query("api::venue.venue").findOne({
            where: { id: venue },
            populate: ['manager']
        });
        
        if (!venueCheck) throw new Error("Venue not found");
        if (venueCheck.manager.id !== managerId) throw new Error("You don't have permission to add courts to this venue");
        
        const court = await strapi.db.query("api::court.court").create({
            data: {
                name,
                description: description || null,
                sport,
                pricePerHour,
                capacity,
                court_img: court_img || null,
                photos: photos || null,
                amenities: amenities || null,
                isActive: isActive !== undefined ? isActive : true,
                venue: venue,
                manager: venueCheck.manager.id,
                publishedAt: new Date()
            }
        });
        
        // Fetch the created court with populated media
        const createdCourt = await strapi.db.query("api::court.court").findOne({
            where: { id: court.id },
            populate: ['court_img', 'photos']
        });
        
        const baseUrl = strapi.config.get('server.url') || '';
        return {
            ...createdCourt,
            court_img_url: createdCourt.court_img?.url ? `${baseUrl}${createdCourt.court_img.url}` : null,
            photos_urls: createdCourt.photos?.map(p => `${baseUrl}${p.url}`) || [],
        };
    },

    // Update a court
    /**
     * @param {any} courtId
     * @param {any} managerId
     * @param {{ name: any; description: any; sport: any; pricePerHour: any; capacity: any; court_img: any; photos: any; amenities: any; isActive: any; }} data
     */
  /*  async updateCourt(courtId, managerId, data) {
        // First check if court exists and belongs to manager's venue
        const existing = await strapi.db.query("api::court.court").findOne({
            where: { id: courtId },
            populate: ['venue', 'venue.manager']
        });
        
        if (!existing) throw new Error("Court not found");
        if (!existing.venue || existing.venue.manager.id !== managerId) {
            throw new Error("You don't have permission to update this court");
        }
        
        const { 
            name, 
            description, 
            sport, 
            pricePerHour, 
            capacity, 
            court_img, 
            photos, 
            amenities, 
            isActive 
        } = data;
        
        const updatedCourt = await strapi.db.query("api::court.court").update({
            where: { id: courtId },
            data: {
                ...(name !== undefined && { name }),
                ...(description !== undefined && { description }),
                ...(sport !== undefined && { sport }),
                ...(pricePerHour !== undefined && { pricePerHour }),
                ...(capacity !== undefined && { capacity }),
                ...(court_img !== undefined && { court_img }),
                ...(photos !== undefined && { photos }),
                ...(amenities !== undefined && { amenities }),
                ...(isActive !== undefined && { isActive })
            }
        });
        
        // Fetch the updated court with populated media
        const updated = await strapi.db.query("api::court.court").findOne({
            where: { id: courtId },
            populate: ['court_img', 'photos']
        });
        
        const baseUrl = strapi.config.get('server.url') || '';
        return {
            ...updated,
            court_img_url: updated.court_img?.url ? `${baseUrl}${updated.court_img.url}` : null,
            photos_urls: updated.photos?.map(p => `${baseUrl}${p.url}`) || [],
        };
    },

    // Delete a court
    /**
     * @param {any} courtId
     * @param {any} managerId
     */
  /*  async deleteCourt(courtId, managerId) {
        // First check if court exists and belongs to manager's venue
        const existing = await strapi.db.query("api::court.court").findOne({
            where: { id: courtId },
            populate: ['venue', 'venue.manager']
        });
        
        if (!existing) throw new Error("Court not found");
        if (!existing.venue || existing.venue.manager.id !== managerId) {
            throw new Error("You don't have permission to delete this court");
        }
        
        await strapi.db.query("api::court.court").delete({
            where: { id: courtId }
        });
        
        return { message: "Court deleted successfully" };
    }
};*/