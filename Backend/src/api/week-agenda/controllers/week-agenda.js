// @ts-nocheck
'use strict';
const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::week-agenda.week-agenda', ({ strapi }) => ({

  // GET /week-agendas — manager list (filtered by court optional)
  async find(ctx) {
    const { courtId } = ctx.query;
    const filters = courtId ? { court: courtId } : {};
    const entities = await strapi.service('api::week-agenda.week-agenda').findMany({
      filters,
      populate: ['court', 'day_plans'],
    });
    return this.transformResponse(entities);
  },

  // GET /week-agendas/:id — with full day plans + time slots
  async findOne(ctx) {
    const { id } = ctx.params;
    const entity = await strapi.service('api::week-agenda.week-agenda').findOne(id, {
      populate: { court: true, day_plans: { populate: ['time_slots'] } },
    });
    if (!entity) return ctx.notFound('WeekAgenda not found');
    return this.transformResponse(entity);
  },

  // ─────────────────────────────────────────────────────────────────────────
  // GET /week-agendas/court/:courtId
  // Player-accessible: returns the published week agenda + its day plans
  // for the given court so the player can discover available dates
  // ─────────────────────────────────────────────────────────────────────────
  async findByCourt(ctx) {
    const { courtId } = ctx.params;

    if (!courtId) return ctx.badRequest('courtId is required');

    const agendas = await strapi.entityService.findMany('api::week-agenda.week-agenda', {
      filters: {
        court: courtId,
        statu: 'Published',
      },
      populate: {
        day_plans: {
          fields: ['id', 'date', 'dayOfWeek', 'dayType'],
        },
      },
      sort: { weekStartDate: 'desc' },
      limit: 4, // return up to 4 weeks so player can pick a date range
    });

    if (!agendas || agendas.length === 0) {
      return ctx.send({ dayPlans: [] });
    }

    // Flatten all day plans from all published agendas
    const dayPlans = agendas.flatMap((agenda) =>
      (agenda.day_plans || []).map((dp) => ({
        id:         dp.id,
        date:       dp.date,
        dayOfWeek:  dp.dayOfWeek,
        dayType:    dp.dayType,
      }))
    );

    // Sort by date ascending
    dayPlans.sort((a, b) => new Date(a.date) - new Date(b.date));

    return ctx.send({ dayPlans });
  },

  // POST /week-agendas
  async create(ctx) {
    const entity = await strapi.service('api::week-agenda.week-agenda').create({
      data: ctx.request.body.data,
      populate: ['court', 'day_plans'],
    });
    return this.transformResponse(entity);
  },

  // PUT /week-agendas/:id
  async update(ctx) {
    const { id } = ctx.params;
    const entity = await strapi.service('api::week-agenda.week-agenda').update(id, {
      data: ctx.request.body.data,
      populate: ['court', 'day_plans'],
    });
    return this.transformResponse(entity);
  },

  // DELETE /week-agendas/:id
  async delete(ctx) {
    const { id } = ctx.params;
    const entity = await strapi.service('api::week-agenda.week-agenda').delete(id);
    return this.transformResponse(entity);
  },

  // POST /week-agendas/:id/publish
  async publish(ctx) {
    const { id } = ctx.params;
    const entity = await strapi.service('api::week-agenda.week-agenda').update(id, {
      data: { statu: 'Published' },
    });
    return this.transformResponse(entity);
  },
}));