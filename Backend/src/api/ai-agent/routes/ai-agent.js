// src/api/ai-agent/routes/ai-agent.js
'use strict';

module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/ai-agent/chat',
      handler: 'ai-agent.chat',
      config: {
        auth: false, // Allow without auth, but will respect if user is logged in
        policies: ['global::authMiddleware'], // Optional: Add custom policies if needed
        middlewares: [],
      },
    },
    {
      method: 'GET',
      path: '/ai-agent/history/:sessionId',
      handler: 'ai-agent.history',
      config: {
        auth: false,
        policies: [],
        middlewares: [],
      },
    },
    {
      method: 'DELETE',
      path: '/ai-agent/history/:sessionId',
      handler: 'ai-agent.clearHistory',
      config: {
        auth: false,
        policies: [],
        middlewares: [],
      },
    },
  ],
};