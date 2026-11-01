module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/messages',
      handler: 'message.create',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
    {
      method: 'GET',
      path: '/messages/:conversationId',
      handler: 'message.findByConversation',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
    {
      method: 'GET',
      path: '/messages/:conversationId/:id',
      handler: 'message.findOne',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
    {
      method: 'DELETE',
      path: '/messages/:conversationId/:id',
      handler: 'message.delete',
      config: {
        auth: false,
        policies: ['global::authMiddleware'],
      },
    },
  ],
};