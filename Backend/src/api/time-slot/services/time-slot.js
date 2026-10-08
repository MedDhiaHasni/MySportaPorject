// @ts-nocheck
'use strict';
const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::time-slot.time-slot', ({ strapi }) => ({

  async findMany(params) {
    return strapi.entityService.findMany('api::time-slot.time-slot', params);
  },

  async findOne(id, params = {}) {
    return strapi.entityService.findOne('api::time-slot.time-slot', id, params);
  },

  async create(params) {
    return strapi.entityService.create('api::time-slot.time-slot', params);
  },

  async update(id, params) {
    return strapi.entityService.update('api::time-slot.time-slot', id, params);
  },

  async delete(id) {
    return strapi.entityService.delete('api::time-slot.time-slot', id);
  },

  // Creates N time slots for a given day plan in one shot
  async bulkCreate(dayPlanId, slots) {
    const created = [];
    for (const slot of slots) {
      const entity = await strapi.entityService.create('api::time-slot.time-slot', {
        data: { ...slot, day_plan: dayPlanId, isActive: true },
      });
      created.push(entity);
    }
    return created;
  },
}));