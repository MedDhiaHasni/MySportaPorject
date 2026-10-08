'use strict';

/**
 * join-request service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::join-request.join-request');
