'use strict';

/**
 * ai-conversation controller
 */

const { createCoreController } = require('@strapi/strapi').factories;

const UID = 'api::ai-conversation.ai-conversation';

function isOwnedBy(entry, userId) {
  const ownerId = entry.user?.id ?? entry.user;
  return String(ownerId ?? '') === String(userId);
}

module.exports = createCoreController(UID, ({ strapi }) => ({
  async find(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized('Authentication required');

    const query = await this.sanitizeQuery(ctx);
    query.filters = {
      $and: [
        query.filters || {},
        { user: { id: { $eq: user.id } } },
      ],
    };
    const entries = await strapi.entityService.findMany(UID, query);
    return this.transformResponse(await this.sanitizeOutput(entries, ctx));
  },

  async findOne(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized('Authentication required');

    const entry = await strapi.entityService.findOne(UID, ctx.params.id, {
      populate: ['user'],
    });
    if (!entry || !isOwnedBy(entry, user.id)) return ctx.notFound('Conversation not found');
    return this.transformResponse(await this.sanitizeOutput(entry, ctx));
  },

  async create(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized('Authentication required');

    const input = ctx.request.body?.data ?? ctx.request.body ?? {};
    const data = await this.sanitizeInput(input, ctx);
    delete data.user;
    delete data.userId;
    const entry = await strapi.entityService.create(UID, {
      data: { ...data, user: user.id },
    });
    return this.transformResponse(await this.sanitizeOutput(entry, ctx));
  },

  async update(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized('Authentication required');

    const existing = await strapi.entityService.findOne(UID, ctx.params.id, {
      populate: ['user'],
    });
    if (!existing || !isOwnedBy(existing, user.id)) return ctx.notFound('Conversation not found');

    const input = ctx.request.body?.data ?? ctx.request.body ?? {};
    const data = await this.sanitizeInput(input, ctx);
    delete data.user;
    delete data.userId;
    const entry = await strapi.entityService.update(UID, ctx.params.id, { data });
    return this.transformResponse(await this.sanitizeOutput(entry, ctx));
  },

  async delete(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized('Authentication required');

    const existing = await strapi.entityService.findOne(UID, ctx.params.id, {
      populate: ['user'],
    });
    if (!existing || !isOwnedBy(existing, user.id)) return ctx.notFound('Conversation not found');

    const entry = await strapi.entityService.delete(UID, ctx.params.id);
    return this.transformResponse(await this.sanitizeOutput(entry, ctx));
  },
}));
