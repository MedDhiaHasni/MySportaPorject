// @ts-nocheck
'use strict';
const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::day-plan.day-plan', ({ strapi }) => ({

  async findMany(params) {
    return strapi.entityService.findMany('api::day-plan.day-plan', params);
  },

  async findOne(id, params = {}) {
    return strapi.entityService.findOne('api::day-plan.day-plan', id, params);
  },

  async create(params) {
    return strapi.entityService.create('api::day-plan.day-plan', params);
  },

  async update(id, params) {
    return strapi.entityService.update('api::day-plan.day-plan', id, params);
  },

  async delete(id) {
    return strapi.entityService.delete('api::day-plan.day-plan', id);
  },
}));