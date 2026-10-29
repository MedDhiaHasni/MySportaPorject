'use strict';

/**
 * ai-conversation router
 */

const { createCoreRouter } = require('@strapi/strapi').factories;

const authConfig = {
  auth: false,
  policies: ['global::authMiddleware'],
};

module.exports = createCoreRouter('api::ai-conversation.ai-conversation', {
  config: {
    find: authConfig,
    findOne: authConfig,
    create: authConfig,
    update: authConfig,
    delete: authConfig,
  },
});
