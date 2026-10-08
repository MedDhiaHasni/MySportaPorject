// @ts-nocheck
'use strict';
const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::day-plan.day-plan', ({ strapi }) => ({

  async find(ctx) {
    const { weekAgendaId, dayType } = ctx.query;
    const filters = {};
    if (weekAgendaId) filters.week_agend = weekAgendaId; // bech l'app matecrushish
    if (dayType)      filters.dayType    = dayType;

    const entities = await strapi.service('api::day-plan.day-plan').findMany({
      filters,
      populate: ['week_agend', 'time_slots'],
    });
    return this.transformResponse(entities); // yetransformi reponse automatiquement
  },

  async findOne(ctx) {
    const { id } = ctx.params;
    const entity = await strapi.service('api::day-plan.day-plan').findOne(id, {
      populate: { week_agend: true, time_slots: { populate: ['reservation'] } },
    });
    if (!entity) return ctx.notFound('DayPlan not found');
    return this.transformResponse(entity);
  },

  async create(ctx) {
    const entity = await strapi.service('api::day-plan.day-plan').create({
      data: ctx.request.body.data,
      populate: ['week_agend', 'time_slots'],
    });
    return this.transformResponse(entity);
  },

  async update(ctx) {
    const { id } = ctx.params;
    const entity = await strapi.service('api::day-plan.day-plan').update(id, {
      data: ctx.request.body.data,
      populate: ['week_agend', 'time_slots'],
    });
    return this.transformResponse(entity);
  },

  async delete(ctx) {
    const { id } = ctx.params;
    const entity = await strapi.service('api::day-plan.day-plan').delete(id);
    return this.transformResponse(entity);
  },

  // GET /day-plans/:id/availability — hedhi traja3li time slots m3a l'etat mte3hom
  async availability(ctx) {
    const { id } = ctx.params;
    const entity = await strapi.service('api::day-plan.day-plan').findOne(id, {
      populate: { time_slots: { populate: ['reservation'] } },
    });
    if (!entity) return ctx.notFound('DayPlan not found');

    const slots = (entity.time_slots || []).map((slot) => ({
      id:        slot.id,
      startTime: slot.startTime,
      endTime:   slot.endTime,
      isActive:  slot.isActive,
      isBooked:  !!slot.reservation,
    }));

    return ctx.send({ date: entity.date, dayType: entity.dayType, slots });
  },
}));