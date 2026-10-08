// src/api/ai-agent/services/ai-agent.js
// @ts-nocheck
'use strict';

const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';
const DEFAULT_MODEL = 'openrouter/auto'; //llama 3.1 auto model

const formatTime = (t) => {
  if (!t) return null;
  return t.replace(/[hH]/, ':').replace(/^(\d):/, '0$1:').substring(0, 5);
};

const toLocalDateStr = (d = new Date()) => {
  const y = d.getFullYear();
  const mo = String(d.getMonth() + 1).padStart(2, '0');
  const da = String(d.getDate()).padStart(2, '0');
  return `${y}-${mo}-${da}`;
};

module.exports = ({ strapi }) => ({

  // aham 7aja  "el user role dima player "
  async processChat({ question, conversationHistory, sessionId, userId, userRole }) {
    try {
      const intentData = await this.analyzeIntent(question);
      strapi.log.info(`[AI Agent] Intent: ${intentData.intent}, userId: ${userId || 'none'}`);

      let actionResult = null;
      if (intentData.intent !== 'general' && intentData.intent !== 'help') {
        actionResult = await this.executeAction(intentData, userId);
        strapi.log.info(`[AI Agent] Action result type: ${actionResult?.type}`);
      }

      const reply = await this.generateResponse(question, intentData, actionResult);

      await this.saveConversation({
        sessionId,
        question,
        answer: reply,
        contextType: actionResult?.type,
        userId,
      });

      // ── FIX: expose actionResult.data at top level so Flutter can read it ──
      // Flutter reads response['data'] for booking details.
      // Previously this was only embedded inside the reply string.
      return {
        reply,
        intent: intentData.intent,
        contextType: actionResult?.type,
        usedDatabaseContext: !!actionResult,
        sessionId,
        // Top-level data field for booking_created / booking_cancelled
        data: actionResult?.data ?? null,
      };
    } catch (error) {
      strapi.log.error('[AI Agent] Error:', error);
      return {
        reply: "I'm having trouble processing your request right now. Please try again.",
        intent: 'error',
        usedDatabaseContext: false,
        sessionId,
        data: null,
      };
    }
  },

  
  async analyzeIntent(question) {
    const lower = question.toLowerCase();

    // ── BOOKING INTENT ────────────────────────────────────────────────────────
    if (lower.includes('book') || lower.includes('reserve') ||
        lower.includes('make a booking') || lower.includes('i want to book') ||
        lower.includes('schedule a') || lower.includes('create a booking')) {
      const entities = {};

      if (lower.includes('football') || lower.includes('⚽')) entities.sport = 'football';
      else if (lower.includes('padel') || lower.includes('🎾')) entities.sport = 'padel';
      else if (lower.includes('tennis')) entities.sport = 'tennis';
      else if (lower.includes('basketball') || lower.includes('🏀')) entities.sport = 'basketball';

      if (lower.includes('today')) entities.date = toLocalDateStr();
      else if (lower.includes('tomorrow')) {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        entities.date = toLocalDateStr(tomorrow);
      } else {
        const dateMatch = lower.match(/\d{4}-\d{2}-\d{2}/);
        if (dateMatch) entities.date = dateMatch[0];
      }

      const timeMatch = lower.match(/(\d{1,2}(?::\d{2})?\s*(?:am|pm|h)?)/i);
      if (timeMatch) entities.time = timeMatch[0];

      const venueMatch = lower.match(/(?:at|in)\s+([a-z0-9\s]+?)(?:court|venue|field|\?|$)/i);
      if (venueMatch) entities.venue_name = venueMatch[1].trim();

      return { intent: 'create_booking', entities };
    }

    // ── CANCEL BOOKING ────────────────────────────────────────────────────────
    if (lower.includes('cancel') || lower.includes('delete booking') || lower.includes('remove booking')) {
      const entities = {};
      const idMatch = lower.match(/(?:booking|reservation)\s*#?\s*([A-Z0-9-]+)/i);
      if (idMatch) entities.booking_reference = idMatch[1];
      return { intent: 'cancel_booking', entities };
    }

    // ── FIND VENUES ───────────────────────────────────────────────────────────
    if (lower.includes('find') || lower.includes('search') || lower.includes('where') ||
        lower.includes('venues') || lower.includes('courts') || lower.includes('fields')) {
      const entities = {};
      if (lower.includes('football')) entities.sport = 'football';
      else if (lower.includes('padel')) entities.sport = 'padel';
      else if (lower.includes('tennis')) entities.sport = 'tennis';
      else if (lower.includes('basketball')) entities.sport = 'basketball';
      const locationMatch = lower.match(/(?:in|near|at|around)\s+([a-z\s]+)$/i);
      if (locationMatch) entities.location = locationMatch[1].trim();
      return { intent: 'find_venues', entities };
    }

    // ── GET MANAGER ───────────────────────────────────────────────────────────
    if (lower.includes('who is the manager') || lower.includes('who\'s the manager') ||
        lower.includes('manager of') || lower.includes('venue manager')) {
      const entities = {};
      const nameMatch = lower.match(/(?:manager of|of)\s+([a-z0-9\s]+?)(?:\?|$)/i);
      if (nameMatch) entities.venue_name = nameMatch[1].trim();
      return { intent: 'get_manager', entities };
    }

    // ── GET WORKER ────────────────────────────────────────────────────────────
    if (lower.includes('who is the worker') || lower.includes('worker assigned') ||
        lower.includes('worker for') || lower.includes('assigned worker')) {
      const entities = {};
      const nameMatch = lower.match(/(?:worker for|to)\s+([a-z0-9\s]+?)(?:court|\?|$)/i);
      if (nameMatch) entities.court_name = nameMatch[1].trim();
      return { intent: 'get_worker', entities };
    }

    // ── GET SPORTS ────────────────────────────────────────────────────────────
    if (lower.includes('what sports') || lower.includes('sports available') ||
        lower.includes('which sports')) {
      const entities = {};
      const nameMatch = lower.match(/(?:at|in)\s+([a-z0-9\s]+?)(?:\?|$)/i);
      if (nameMatch) entities.venue_name = nameMatch[1].trim();
      return { intent: 'get_sports', entities };
    }

    // ── CHECK AVAILABILITY ────────────────────────────────────────────────────
    if (lower.includes('available') || lower.includes('availability') || lower.includes('free slot')) {
      const entities = {};
      if (lower.includes('today')) entities.date = toLocalDateStr();
      else if (lower.includes('tomorrow')) {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        entities.date = toLocalDateStr(tomorrow);
      }
      if (lower.includes('football')) entities.sport = 'football';
      else if (lower.includes('padel')) entities.sport = 'padel';
      else if (lower.includes('tennis')) entities.sport = 'tennis';
      else if (lower.includes('basketball')) entities.sport = 'basketball';
      return { intent: 'check_availability', entities };
    }

    // ── MY BOOKINGS ───────────────────────────────────────────────────────────
    if (lower.includes('my booking') || lower.includes('my reservation') || lower.includes('my matches')) {
      return { intent: 'my_bookings', entities: {} };
    }

    // ── PRICE INFO ────────────────────────────────────────────────────────────
    if (lower.includes('price') || lower.includes('cost') || lower.includes('how much')) {
      const entities = {};
      if (lower.includes('football')) entities.sport = 'football';
      else if (lower.includes('padel')) entities.sport = 'padel';
      else if (lower.includes('tennis')) entities.sport = 'tennis';
      else if (lower.includes('basketball')) entities.sport = 'basketball';
      return { intent: 'price_info', entities };
    }

    // ── RECOMMENDATIONS ───────────────────────────────────────────────────────
    if (lower.includes('recommend') || lower.includes('best') || lower.includes('top')) {
      const entities = {};
      if (lower.includes('football')) entities.sport = 'football';
      else if (lower.includes('padel')) entities.sport = 'padel';
      else if (lower.includes('tennis')) entities.sport = 'tennis';
      else if (lower.includes('basketball')) entities.sport = 'basketball';
      return { intent: 'recommend_venues', entities };
    }

    // ── HELP ──────────────────────────────────────────────────────────────────
    if (lower.includes('help') || lower.includes('what can you do') || lower.includes('commands')) {
      return { intent: 'help', entities: {} };
    }

    return { intent: 'general', entities: {} };
  },

  async executeAction(intentData, userId) {
    const { intent, entities } = intentData;
    switch (intent) {
      case 'find_venues':        return await this.findVenues(entities);
      case 'get_manager':        return await this.getManagerInfo(entities);
      case 'get_worker':         return await this.getWorkerInfo(entities);
      case 'get_sports':         return await this.getSportsInfo(entities);
      case 'check_availability': return await this.checkAvailability(entities);
      case 'my_bookings':        return await this.getMyBookings(userId);
      case 'price_info':         return await this.getPriceInfo(entities);
      case 'recommend_venues':   return await this.recommendVenues(entities);
      case 'create_booking':     return await this.createBooking(entities, userId);
      case 'cancel_booking':     return await this.cancelBooking(entities, userId);
      case 'help':               return { type: 'help', data: null };
      default:                   return null;
    }
  },

// ─────────────────────────────────────────────────────────────────────────
// CREATE BOOKING - FIXED FOR STRAPI v4
// ─────────────────────────────────────────────────────────────────────────
async createBooking(entities, userId) {
  try {
    console.log('=== CREATE BOOKING DEBUG ===');
    console.log('userId:', userId);
    console.log('entities:', JSON.stringify(entities, null, 2));
    
    if (!userId) {
      return {
        type: 'auth_required',
        data: null,
        message: '🔐 Please log in to make a booking.',
      };
    }

    const player = await strapi.db.query('api::player.player').findOne({
      where: { player: userId },
    });

    console.log('Player found:', player ? `id=${player.id}` : 'NO');

    if (!player) {
      return { type: 'error', data: null, message: 'Player profile not found.' };
    }

    // ken famech date yreservi lghodwa
    let dateStr = entities.date;
    if (!dateStr) {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      dateStr = toLocalDateStr(tomorrow);
    }
    
    console.log('Searching for slots on date:', dateStr);

    // n5arej day plans lel day hadheka
    const dayPlans = await strapi.db.query('api::day-plan.day-plan').findMany({
      where: {
        date: dateStr,
        dayType: { $ne: 'day_off' },
      },
      populate: {
        time_slots: {
          where: { isActive: true },
          populate: ['reservation'],
        },
        week_agend: {
          populate: {
            court: {
              populate: ['venue'],
            },
          },
        },
      },
    });

    console.log('Found dayPlans count:', dayPlans.length);

    // ay slot available n7otha
    let allAvailableSlots = [];
    for (const dp of dayPlans) {
      for (const slot of dp.time_slots || []) {
        if (slot.isActive && !slot.reservation) {
          allAvailableSlots.push({
            slot: slot,
            court: dp.week_agend?.court,
            venue: dp.week_agend?.court?.venue,
            dayPlan: dp,
          });
        }
      }
    }

    console.log('Total available slots found:', allAvailableSlots.length);

    if (allAvailableSlots.length === 0) {
      return { 
        type: 'no_slot', 
        data: null, 
        message: `😕 No available slots found for ${dateStr}. Try a different date!` 
      };
    }

    // yhez awel slot 
    const selectedSlot = allAvailableSlots[0];
    const { court, slot } = selectedSlot;

    console.log('Selected court:', court?.id, court?.name);
    console.log('Selected slot:', slot?.id, slot?.startTime, '-', slot?.endTime);

    if (!court || !court.id) {
      return { type: 'error', data: null, message: 'Court not found.' };
    }

    if (!slot || !slot.id) {
      return { type: 'error', data: null, message: 'Time slot not found.' };
    }

    // Format time for database (HH:mm:ss)
    const formatTimeForDB = (timeStr) => {
      if (!timeStr) return '00:00:00';
      const parts = timeStr.split(':');
      if (parts.length === 2) return `${parts[0].padStart(2, '0')}:${parts[1].padStart(2, '0')}:00`;
      if (parts.length === 3) return `${parts[0].padStart(2, '0')}:${parts[1].padStart(2, '0')}:${parts[2].padStart(2, '0')}`;
      return `${timeStr}:00`;
    };

    const bookingReference = `SPT-${Date.now()}-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
    const totalPrice = court.pricePerHour;

    console.log('Creating reservation with data:', {
      booking_reference: bookingReference,
      booking_date: new Date().toISOString(),
      booking_date_play: dateStr,
      start_time: formatTimeForDB(slot.startTime),
      end_time: formatTimeForDB(slot.endTime),
      duration_hours: 1,
      total_price: totalPrice,
      payment_method: 'pay_at_venue',
      booking_status: 'pending',
      court: court.id,
      player: player.id,
      time_slot: slot.id,
    });

    // Create reservation using db.query instead of entityService 
    const reservation = await strapi.db.query('api::reservation.reservation').create({
      data: {
        booking_reference: bookingReference,
        booking_date: new Date().toISOString(),
        booking_date_play: dateStr,
        start_time: formatTimeForDB(slot.startTime),
        end_time: formatTimeForDB(slot.endTime),
        duration_hours: 1,
        total_price: totalPrice,
        payment_method: 'pay_at_venue',
        booking_status: 'pending',
        court: court.id,
        player: player.id,
        time_slot: slot.id,
        publishedAt: new Date().toISOString(),
      },
    });

    console.log('Reservation created successfully:', reservation.id, reservation.booking_reference);

    // Mark time slot as inactive
    await strapi.db.query('api::time-slot.time-slot').update({
      where: { id: slot.id },
      data: { isActive: false },
    });

    console.log('Time slot marked as inactive');

    return {
      type: 'booking_created',
      data: {
        id: reservation.id,
        reference: bookingReference,
        status: reservation.booking_status,
        court: court.name,
        venue: selectedSlot.venue?.name || court.venue?.name || 'Venue',
        date: dateStr,
        startTime: slot.startTime,
        endTime: slot.endTime,
        price: totalPrice,
      },
    };
  } catch (error) {
    console.error('[AI Agent] createBooking error:', error);
    console.error('[AI Agent] Error stack:', error.stack);
    return { type: 'error', data: null, message: `Failed to create booking: ${error.message}` };
  }
},

  // ─────────────────────────────────────────────────────────────────────────
  // CANCEL BOOKING
  // ─────────────────────────────────────────────────────────────────────────
  async cancelBooking(entities, userId) {
    try {
      if (!userId) {
        return { type: 'auth_required', data: null, message: 'Please log in to cancel bookings.' };
      }

      const player = await strapi.db.query('api::player.player').findOne({
        where: { player: userId },
      });

      if (!player) {
        return { type: 'error', data: null, message: 'Player profile not found.' };
      }

      let reservation = null;

      if (entities.booking_reference) {
        reservation = await strapi.db.query('api::reservation.reservation').findOne({
          where: {
            booking_reference: { $containsi: entities.booking_reference },
            player: player.id,
          },
          populate: ['time_slot'],
        });
      }

      if (!reservation) {
        return { type: 'error', data: null, message: 'Booking not found. Please check your booking reference.' };
      }

      if (reservation.booking_status === 'cancelled') {
        return { type: 'error', data: null, message: 'This booking is already cancelled.' };
      }
      if (reservation.booking_status === 'completed') {
        return { type: 'error', data: null, message: 'Cannot cancel a completed booking.' };
      }

      await strapi.db.query('api::reservation.reservation').update({
        where: { id: reservation.id },
        data: { booking_status: 'cancelled' },
      });

      if (reservation.time_slot?.id) {
        await strapi.db.query('api::time-slot.time-slot').update({
          where: { id: reservation.time_slot.id },
          data: { isActive: true },
        });
      }

      return {
        type: 'booking_cancelled',
        data: {
          id: reservation.id,
          reference: reservation.booking_reference,
        },
      };
    } catch (error) {
      strapi.log.error('[AI Agent] cancelBooking error:', error);
      return { type: 'error', data: null, message: error.message };
    }
  },

  async findVenues(entities) {
    try {
      const filters = { isActive: true };
      if (entities.sport) filters.sports = { $containsi: entities.sport };

      let venues = await strapi.db.query('api::venue.venue').findMany({
        where: filters,
        populate: { courts: { fields: ['id', 'name', 'sport', 'pricePerHour'] }, photo: true },
        limit: 20,
      });

      if (entities.location) {
        venues = venues.filter(v => v.location?.toLowerCase().includes(entities.location.toLowerCase()));
      }

      return {
        type: 'venues_list',
        data: venues.map(v => ({
          id: v.id, name: v.name, location: v.location,
          courts_count: v.courts?.length || 0,
          price_range: this.getPriceRange(v.courts),
          rating: v.avg_rating || 0,
          amenities: v.amenities || [],
        })),
      };
    } catch (error) {
      strapi.log.error('[AI Agent] findVenues error:', error);
      return { type: 'error', data: null, message: error.message };
    }
  },

  async getManagerInfo(entities) {
    try {
      let venue = null;
      if (entities.venue_name) {
        const venues = await strapi.db.query('api::venue.venue').findMany({
          where: { name: { $containsi: entities.venue_name }, isActive: true },
          populate: { manager: { populate: ['manager'] } },
          limit: 1,
        });
        venue = venues[0];
      }

      if (!venue || !venue.manager) {
        return { type: 'manager_not_found', data: { name: entities.venue_name } };
      }

      return {
        type: 'manager_info',
        data: {
          venue_name: venue.name,
          manager_name: venue.manager.manager?.username || 'Not specified',
          manager_phone: venue.manager.phone || 'Not provided',
          manager_email: venue.manager.manager?.email || 'Not provided',
        },
      };
    } catch (error) {
      strapi.log.error('[AI Agent] getManagerInfo error:', error);
      return { type: 'error', data: null, message: error.message };
    }
  },

  async getWorkerInfo(entities) {
    try {
      let court = null;
      if (entities.court_name) {
        const courts = await strapi.db.query('api::court.court').findMany({
          where: { name: { $containsi: entities.court_name }, isActive: true },
          populate: { worker: { populate: ['worker'] }, venue: true },
          limit: 1,
        });
        court = courts[0];
      }

      if (!court || !court.worker) {
        return { type: 'worker_not_found', data: { name: entities.court_name } };
      }

      return {
        type: 'worker_info',
        data: {
          court_name: court.name,
          venue_name: court.venue?.name || 'Unknown',
          worker_name: court.worker.nom || court.worker.worker?.username || 'Not assigned',
          worker_phone: court.worker.phone || 'Not provided',
        },
      };
    } catch (error) {
      strapi.log.error('[AI Agent] getWorkerInfo error:', error);
      return { type: 'error', data: null, message: error.message };
    }
  },

  async getSportsInfo(entities) {
    try {
      let venue = null;
      if (entities.venue_name) {
        const venues = await strapi.db.query('api::venue.venue').findMany({
          where: { name: { $containsi: entities.venue_name }, isActive: true },
          populate: { courts: true },
          limit: 1,
        });
        venue = venues[0];
      }

      if (!venue) {
        return { type: 'venue_not_found', data: { name: entities.venue_name } };
      }
      // set tna7i duplicates w spread operator y7awelhom l array 
      const sports = [...new Set(venue.courts?.map(c => c.sport) || [])];

      return {
        type: 'sports_info',
        data: { venue_name: venue.name, sports, sports_count: sports.length },
      };
    } catch (error) {
      strapi.log.error('[AI Agent] getSportsInfo error:', error);
      return { type: 'error', data: null, message: error.message };
    }
  },

  async checkAvailability(entities) {
    try {
      const dateStr = entities.date || toLocalDateStr(); 

      const dayPlans = await strapi.db.query('api::day-plan.day-plan').findMany({
        where: { date: dateStr, dayType: { $ne: 'day_off' } },
        populate: {
          time_slots: { where: { isActive: true }, populate: ['reservation'] },
          week_agend: { populate: { court: { populate: ['venue'] } } },
        },
      });

      let filteredDayPlans = dayPlans;
      if (entities.sport) {
        filteredDayPlans = dayPlans.filter(dp =>
          dp.week_agend?.court?.sport?.toLowerCase() === entities.sport.toLowerCase()
        );
      }

      const availableSlots = [];
      for (const dp of filteredDayPlans) {
        for (const slot of dp.time_slots || []) {
          if (slot.isActive && !slot.reservation) {
            availableSlots.push({
              id: slot.id,
              startTime: slot.startTime,
              endTime: slot.endTime,
              court_name: dp.week_agend?.court?.name,
              venue_name: dp.week_agend?.court?.venue?.name,
              price: dp.week_agend?.court?.pricePerHour,
            });
          }
        }
      }

      return {
        type: 'availability',
        data: { date: dateStr, slots: availableSlots, total: availableSlots.length },
      };
    } catch (error) {
      strapi.log.error('[AI Agent] checkAvailability error:', error);
      return { type: 'error', data: null, message: error.message };
    }
  },

  async getMyBookings(userId) {
    try {
      if (!userId) {
        return { type: 'auth_required', data: null, message: 'Please log in to view your bookings.' };
      }

      const player = await strapi.db.query('api::player.player').findOne({ where: { player: userId } });
      if (!player) return { type: 'error', data: null, message: 'Player profile not found.' };

      const reservations = await strapi.db.query('api::reservation.reservation').findMany({
        where: { player: player.id },
        populate: { court: { populate: ['venue'] }, time_slot: true },
        orderBy: { booking_date_play: 'desc' },
        limit: 20,
      });

      const today = new Date();
      const upcoming = reservations.filter(r => new Date(r.booking_date_play) >= today);
      const past = reservations.filter(r => new Date(r.booking_date_play) < today);

      return {
        type: 'my_bookings',
        data: {
          total: reservations.length,
          upcoming: upcoming.map(r => ({
            id: r.id, reference: r.booking_reference, status: r.booking_status,
            date: r.booking_date_play, time: r.start_time ? `${r.start_time} - ${r.end_time}` : null,
            court: r.court?.name, venue: r.court?.venue?.name, price: r.total_price,
          })),
          past: past.map(r => ({
            id: r.id, reference: r.booking_reference, status: r.booking_status,
            date: r.booking_date_play, court: r.court?.name,
            venue: r.court?.venue?.name, price: r.total_price,
          })),
        },
      };
    } catch (error) {
      strapi.log.error('[AI Agent] getMyBookings error:', error);
      return { type: 'error', data: null, message: error.message };
    }
  },

  async getPriceInfo(entities) {
    try {
      const filters = { isActive: true };
      if (entities.sport) filters.sport = entities.sport;

      const courts = await strapi.db.query('api::court.court').findMany({
        where: filters,
        populate: { venue: true },
        limit: 30,
      });

      const venuePrices = {};
      let minOverall = Infinity, maxOverall = -Infinity;

      for (const court of courts) {
        const venueName = court.venue?.name || 'Unknown';
        if (!venuePrices[venueName]) {
          venuePrices[venueName] = { min: court.pricePerHour, max: court.pricePerHour, courts: [] };
        }
        venuePrices[venueName].min = Math.min(venuePrices[venueName].min, court.pricePerHour);
        venuePrices[venueName].max = Math.max(venuePrices[venueName].max, court.pricePerHour);
        venuePrices[venueName].courts.push({ name: court.name, price: court.pricePerHour });
        minOverall = Math.min(minOverall, court.pricePerHour);
        maxOverall = Math.max(maxOverall, court.pricePerHour);
      }

      return {
        type: 'price_info',
        data: {
          venues: venuePrices,
          range: {
            min: minOverall === Infinity ? 0 : minOverall,
            max: maxOverall === -Infinity ? 0 : maxOverall,
          },
        },
      };
    } catch (error) {
      strapi.log.error('[AI Agent] getPriceInfo error:', error);
      return { type: 'error', data: null, message: error.message };
    }
  },

  async recommendVenues(entities) {
    try {
      const filters = { isActive: true };
      if (entities.sport) filters.sports = { $containsi: entities.sport };

      const venues = await strapi.db.query('api::venue.venue').findMany({
        where: filters,
        populate: { courts: true, ratings: true },
        limit: 20,
      });

      const scored = venues.map(v => ({
        ...v,
        score: (v.avg_rating || 0) * 20 + (v.courts?.length || 0) * 5 + (v.amenities?.length || 0) * 3,
      }));
      scored.sort((a, b) => b.score - a.score);

      return {
        type: 'recommendations',
        data: scored.slice(0, 5).map(v => ({
          id: v.id, name: v.name, location: v.location,
          rating: v.avg_rating || 0,
          courts_count: v.courts?.length || 0,
          price_range: this.getPriceRange(v.courts),
          amenities: v.amenities || [],
          score: v.score,
        })),
      };
    } catch (error) {
      strapi.log.error('[AI Agent] recommendVenues error:', error);
      return { type: 'error', data: null, message: error.message };
    }
  },

  async generateResponse(question, intentData, actionResult) {
    if (!actionResult || actionResult.type === 'error') {
      if (actionResult?.type === 'auth_required') {
        return "🔐 Please log in to access this feature. You can still search for venues!";
      }
      if (actionResult?.type === 'manager_not_found') {
        return `😕 I couldn't find manager information for "${actionResult.data?.name}". Please check the venue name.`;
      }
      if (actionResult?.type === 'worker_not_found') {
        return `😕 I couldn't find worker information for "${actionResult.data?.name}". Please check the court name.`;
      }
      if (actionResult?.type === 'venue_not_found') {
        return `😕 I couldn't find "${actionResult.data?.name}". Please check the name and try again.`;
      }
      if (actionResult?.type === 'no_slot') {
        return actionResult.message || "😕 No available slots found. Try a different date or time!";
      }
      return "I couldn't find what you're looking for. Try asking differently!";
    }

    if (intentData.intent === 'help') {
      return this.getHelpMessage();
    }

    switch (actionResult.type) {
      case 'booking_created': {
        const b = actionResult.data;
        return `✅ **Booking Created Successfully!**\n\n` +
               `📋 **Details:**\n` +
               `• Reference: **${b.reference}**\n` +
               `• Court: ${b.court}\n` +
               `• Venue: ${b.venue}\n` +
               `• Date: ${b.date}\n` +
               `• Time: ${b.startTime} - ${b.endTime}\n` +
               `• Price: ${b.price} DT\n` +
               `• Status: ${b.status === 'pending' ? 'Pending confirmation' : 'Confirmed'}\n\n` +
               `💡 You can view your booking in the "My Bookings" section. Need anything else?`;
      }

      case 'booking_cancelled': {
        const b = actionResult.data;
        return `❌ **Booking Cancelled**\n\n` +
               `Your booking **${b.reference}** has been successfully cancelled.\n\n` +
               `The time slot is now available for rebooking. Need help with something else?`;
      }

      case 'venues_list': {
        const venues = actionResult.data;
        if (venues.length === 0) {
          let msg = `😕 No venues found`;
          if (intentData.entities.sport) msg += ` for ${intentData.entities.sport}`;
          if (intentData.entities.location) msg += ` in ${intentData.entities.location}`;
          return msg + `. Try a different sport or location!`;
        }
        let response = `🏟️ **Found ${venues.length} venue${venues.length > 1 ? 's' : ''}**\n\n`;
        for (let i = 0; i < Math.min(venues.length, 5); i++) {
          const v = venues[i];
          const stars = v.rating > 0 ? '⭐'.repeat(Math.min(Math.floor(v.rating), 5)) : '📌';
          response += `${i + 1}. **${v.name}** ${stars}\n   📍 ${v.location}\n   🏸 ${v.courts_count} courts | 💰 ${v.price_range || 'Contact'}\n\n`;
        }
        response += `💡 Want more details or availability? Just ask!`;
        return response;
      }

      case 'manager_info': {
        const m = actionResult.data;
        return `👨‍💼 **Manager at ${m.venue_name}**\n\n• Name: **${m.manager_name}**\n• Phone: 📞 ${m.manager_phone}\n• Email: ✉️ ${m.manager_email}\n\n💡 Need to contact them? You can message them directly in the app!`;
      }

      case 'worker_info': {
        const w = actionResult.data;
        return `👷 **Worker assigned to ${w.court_name}**\n\n• Worker: **${w.worker_name}**\n• Phone: 📞 ${w.worker_phone}\n• Venue: ${w.venue_name}\n\n💡 This worker is responsible for court maintenance and assistance.`;
      }

      case 'sports_info': {
        const s = actionResult.data;
        if (s.sports_count === 0) return `😕 No sports found at ${s.venue_name}.`;
        let response = `⚽ **Sports at ${s.venue_name}**\n\n`;
        s.sports.forEach(sport => response += `• ${sport.charAt(0).toUpperCase() + sport.slice(1)}\n`);
        response += `\n💡 ${s.sports_count} sport${s.sports_count > 1 ? 's are' : ' is'} available. Want to check pricing?`;
        return response;
      }

      case 'availability': {
        const slots = actionResult.data.slots;
        if (slots.length === 0) return `😕 No available slots for ${actionResult.data.date}. Try another date!`;
        let response = `📅 **Availability for ${actionResult.data.date}**\n\n`;
        for (const slot of slots.slice(0, 8)) {
          response += `• ${slot.startTime} - ${slot.endTime} | ${slot.court_name} (${slot.venue_name}) | ${slot.price} DT\n`;
        }
        if (slots.length > 8) response += `\n✨ And ${slots.length - 8} more slots!`;
        response += `\n\n🎯 Ready to book? Tell me which slot!`;
        return response;
      }

      case 'my_bookings': {
        const data = actionResult.data;
        if (data.total === 0) return "📋 You don't have any bookings yet. Want me to help you book a court?";
        let response = `📋 **Your Bookings (${data.total} total)**\n\n`;
        if (data.upcoming?.length > 0) {
          response += `**🆙 Upcoming (${data.upcoming.length})**\n`;
          for (const b of data.upcoming.slice(0, 5)) {
            response += `${b.status === 'confirmed' ? '✅' : '⏳'} ${b.date} - ${b.court} (${b.venue}) | ${b.price} DT\n`;
          }
        }
        if (data.past?.length > 0) {
          response += `\n**📁 Past (${data.past.length})**\n`;
          for (const b of data.past.slice(0, 3)) {
            response += `🕐 ${b.date} - ${b.court} | ${b.status}\n`;
          }
        }
        return response;
      }

      case 'price_info': {
        const data = actionResult.data;
        const venues = Object.keys(data.venues);
        if (venues.length === 0) return "💰 Price information not available right now.";
        let response = `💰 **Price Guide**\n\n📊 Range: **${data.range.min} - ${data.range.max} DT/hour**\n\n**By Venue:**\n`;
        for (const venue of venues.slice(0, 5)) {
          const p = data.venues[venue];
          response += `• ${venue}: ${p.min} - ${p.max} DT/hour\n`;
        }
        response += `\n💡 Early morning and late night slots are usually cheaper!`;
        return response;
      }

      case 'recommendations': {
        const venues = actionResult.data;
        if (venues.length === 0) return "😕 No recommendations available right now.";
        let response = `🌟 **Top Picks For You**\n\n`;
        for (let i = 0; i < venues.length; i++) {
          const v = venues[i];
          const stars = v.rating > 0 ? '⭐'.repeat(Math.min(Math.floor(v.rating), 5)) : '';
          response += `${i + 1}. **${v.name}** ${stars}\n   📍 ${v.location} | 🏸 ${v.courts_count} courts\n   💰 ${v.price_range || 'Contact'}\n\n`;
        }
        response += `✨ Want to check availability? Just ask!`;
        return response;
      }

      default:
        return "I'm here to help you find sports venues, check availability, book courts, and more! What would you like to do?";
    }
  },

  getPriceRange(courts) {
    if (!courts || courts.length === 0) return null;
    const prices = courts.map(c => c.pricePerHour).filter(p => p);
    if (prices.length === 0) return null;
    const min = Math.min(...prices);
    const max = Math.max(...prices);
    return min === max ? `${min} DT` : `${min}-${max} DT`;
  },

  getHelpMessage() {
    return `🤖 **Sporta AI Assistant - Help Guide**

I can help you with:

⚽ **Find Venues**
• "Find football venues near me"
• "Show me padel courts in Tunis"

👨‍💼 **Manager Info**
• "Who is the manager of Arena Sport?"

👷 **Worker Info**
• "Who is the worker assigned to Court A?"

📅 **Check Availability**
• "Is there availability tomorrow at 6 PM?"
• "Show me free slots for Saturday"

💰 **Pricing**
• "How much does a football court cost?"

🎯 **Book a Court**
• "Book a football court for tomorrow at 7 PM"
• "Book a padel court today at 6 PM"
• "Cancel my booking SPT-12345"
• "Show my upcoming bookings"

💡 Just ask naturally — I'll understand what you need!`;
  },

  async saveConversation({ sessionId, question, answer, contextType, userId }) {
    try {
      await strapi.entityService.create('api::ai-conversation.ai-conversation', {
        data: {
          sessionId,
          question,
          answer,
          contextType: contextType || 'general',
          usedDatabaseContext: !!contextType,
          user: userId ? { connect: [userId] } : undefined,
          publishedAt: new Date().toISOString(),
        },
      });
    } catch (err) {
      strapi.log.error('[AI Agent] Save conversation error:', err.message);
    }
  },
});
