// @ts-nocheck
'use strict';
const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::week-agenda.week-agenda', ({ strapi }) => ({

  async findMany(params) {
    return strapi.entityService.findMany('api::week-agenda.week-agenda', params);
  },

  async findOne(id, params = {}) {
    return strapi.entityService.findOne('api::week-agenda.week-agenda', id, params);
  },

  async create(params) {
    return strapi.entityService.create('api::week-agenda.week-agenda', params);
  },

  async update(id, params) {
    return strapi.entityService.update('api::week-agenda.week-agenda', id, params);
  },

  async delete(id) {
    return strapi.entityService.delete('api::week-agenda.week-agenda', id);
  },
}));