// @ts-nocheck
'use strict';
const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::reservation.reservation', ({ strapi }) => ({

  async findMany(params) {
    return strapi.entityService.findMany('api::reservation.reservation', params);
  },

  async findOne(id, params = {}) {
    return strapi.entityService.findOne('api::reservation.reservation', id, params);
  },

  async create(params) {
    return strapi.entityService.create('api::reservation.reservation', params);
  },

  async createForAvailableSlot(slotId, data) {
    return strapi.db.transaction(async ({ trx }) => {
      const lockedSlot = await trx('time_slots')
        .where({ id: slotId })
        .forUpdate()
        .first();
      if (!lockedSlot) {
        const error = new Error('Time slot not found');
        error.status = 404;
        throw error;
      }

      const slot = await strapi.entityService.findOne(
        'api::time-slot.time-slot',
        slotId,
        { populate: ['reservation', 'day_plan'] },
      );
      if (!slot) {
        const error = new Error('Time slot not found');
        error.status = 404;
        throw error;
      }
      if (!slot.isActive || slot.reservation) {
        throw new Error('This time slot is not available');
      }
      if (slot.day_plan?.dayType === 'day_off') {
        throw new Error('Cannot book on a day-off');
      }

      const reservation = await strapi.entityService.create(
        'api::reservation.reservation',
        {
          data: { ...data, time_slot: slotId },
          populate: ['court', 'player', 'time_slot'],
        },
      );

      await strapi.entityService.update('api::time-slot.time-slot', slotId, {
        data: { isActive: false },
      });

      return reservation;
    });
  },

  async releaseReservationSlot(reservationId, reservationData) {
    return strapi.db.transaction(async ({ trx }) => {
      const reservation = await strapi.entityService.findOne(
        'api::reservation.reservation',
        reservationId,
        { populate: ['time_slot'] },
      );
      if (!reservation) {
        const error = new Error('Reservation not found');
        error.status = 404;
        throw error;
      }

      const slotId = reservation.time_slot?.id;
      if (slotId) {
        await trx('time_slots').where({ id: slotId }).forUpdate().first();
      }

      const updated = await strapi.entityService.update(
        'api::reservation.reservation',
        reservationId,
        {
          data: { ...reservationData, time_slot: null },
          populate: ['court', 'player', 'time_slot'],
        },
      );

      if (slotId) {
        await strapi.entityService.update('api::time-slot.time-slot', slotId, {
          data: { isActive: true },
        });
      }

      return updated;
    });
  },

  async update(id, params) {
    return strapi.entityService.update('api::reservation.reservation', id, params);
  },

  async delete(id) {
    return strapi.entityService.delete('api::reservation.reservation', id);
  },

  // Resolves a manager record from an auth user id
  async resolveManagerId(userId) {
    // Look for manager where the 'manager' relation equals userId
    const managers = await strapi.entityService.findMany('api::manager.manager', {
      filters: { manager: userId },  // 'manager' is the relation field name
      limit: 1,
    });
    return managers?.[0]?.id ?? null;
  },
}));