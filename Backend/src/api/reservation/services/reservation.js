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