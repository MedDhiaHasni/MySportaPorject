// @ts-nocheck
'use strict';
const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::time-slot.time-slot', ({ strapi }) => ({

  async find(ctx) {
    const { dayPlanId, isActive } = ctx.query;
    const filters = {};
    if (dayPlanId) filters.day_plan = dayPlanId;
    if (isActive !== undefined) filters.isActive = isActive === 'true';

    const entities = await strapi.service('api::time-slot.time-slot').findMany({
      filters,
      populate: ['day_plan', 'reservation'],
    });
    return this.transformResponse(entities);
  },

  async findOne(ctx) {
    const { id } = ctx.params;
    const entity = await strapi.service('api::time-slot.time-slot').findOne(id, {
      populate: ['day_plan', 'reservation'],
    });
    if (!entity) return ctx.notFound('TimeSlot not found');
    return this.transformResponse(entity);
  },

  async create(ctx) {
    const { data } = ctx.request.body;
    // Prevent creating a slot on a day_off day
    if (data.day_plan) {
      const dayPlan = await strapi.entityService.findOne('api::day-plan.day-plan', data.day_plan, {});
      if (dayPlan && dayPlan.dayType === 'day_off') {
        return ctx.badRequest('Cannot add time slots to a day-off day plan.');
      }
    }
    const entity = await strapi.service('api::time-slot.time-slot').create({
      data,
      populate: ['day_plan'],
    });
    return this.transformResponse(entity);
  },

  async update(ctx) {
    const { id } = ctx.params;
    const entity = await strapi.service('api::time-slot.time-slot').update(id, {
      data: ctx.request.body.data,
      populate: ['day_plan', 'reservation'],
    });
    return this.transformResponse(entity);
  },

  async delete(ctx) {
    const { id } = ctx.params;
    // Prevent deleting a slot that has a reservation
    const existing = await strapi.entityService.findOne('api::time-slot.time-slot', id, { populate: ['reservation'] });
    if (existing?.reservation) {
      return ctx.badRequest('Cannot delete a time slot with an active reservation.');
    }
    const entity = await strapi.service('api::time-slot.time-slot').delete(id);
    return this.transformResponse(entity);
  },

  // POST /time-slots/bulk — create multiple slots at once for a day plan
  async bulkCreate(ctx) {
    const { day_plan, slots } = ctx.request.body;
    if (!day_plan || !Array.isArray(slots) || slots.length === 0) {
      return ctx.badRequest('day_plan and slots[] are required.');
    }
    const created = await strapi.service('api::time-slot.time-slot').bulkCreate(day_plan, slots);
    return ctx.send({ count: created.length, data: created });
  },
}));