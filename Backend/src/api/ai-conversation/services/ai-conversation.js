'use strict';

/**
 * ai-conversation service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::ai-conversation.ai-conversation');
