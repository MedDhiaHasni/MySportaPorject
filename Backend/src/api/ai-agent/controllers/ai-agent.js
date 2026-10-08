// @ts-nocheck
// src/api/ai-agent/controllers/ai-agent.js
'use strict';

const { v4: uuidv4 } = require('uuid');

module.exports = {
    
  async chat(ctx) {
    const { question, conversationHistory = [], sessionId } = ctx.request.body;

    if (!question?.trim()) {
      return ctx.badRequest('Question is required.');
    }
    if (question.length > 2000) {
      return ctx.badRequest('Question cannot exceed 2000 characters.');
    }

    // debug mel louwel lel le5er 
    console.log('=== AI CHAT DEBUG ===');
    console.log('ctx.state.user:', ctx.state.user);
    console.log('ctx.state.user?.id:', ctx.state.user?.id);
    console.log('ctx.state.user?.user_role:', ctx.state.user?.user_role);
    console.log('ctx.request.headers.authorization:', ctx.request.headers.authorization ? 'Present' : 'Missing');
    
    // Check if user is authenticated
    const userId = ctx.state.user?.id ?? null;
    const userRole = ctx.state.user?.user_role ?? null;

    try {
      const result = await strapi
        .service('api::ai-agent.ai-agent')
        .processChat({
          question: question.trim(),
          conversationHistory,
          sessionId: sessionId || uuidv4(),
          userId,
          userRole,
        });

      ctx.body = result;
    } catch (error) {
      strapi.log.error('[ai-agent] Controller error:', error.message);
      strapi.log.error('[ai-agent] Stack:', error.stack);

      if (error.response?.status === 429) {
        return ctx.tooManyRequests('API quota exceeded. Please try again in a few moments.');
      }
      return ctx.internalServerError('Error processing AI request.');
    }
  },

  async history(ctx) {
    const { sessionId } = ctx.params;

    if (!sessionId) return ctx.badRequest('sessionId required.');

    const conversations = await strapi.entityService.findMany(
      'api::ai-conversation.ai-conversation',
      {
        filters: { sessionId },
        fields: ['question', 'answer', 'contextType', 'createdAt'],
        sort: { createdAt: 'asc' },
        limit: 50,
      }
    );

    ctx.body = { data: conversations };
  },

  async clearHistory(ctx) {
    const { sessionId } = ctx.params;

    if (!sessionId) return ctx.badRequest('sessionId required.');

    await strapi.db.query('api::ai-conversation.ai-conversation').deleteMany({
      where: { sessionId },
    });

    ctx.body = { message: 'Conversation history cleared successfully.' };
  },
};

