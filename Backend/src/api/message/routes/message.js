module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/messages',
      handler: 'message.create',
      config: {
        auth: false,
      },
    },
    {
      method: 'GET',
      path: '/messages/:conversationId',
      handler: 'message.findByConversation',
      config: {
        auth: false,
      },
    },
    {
      method: 'GET',
      path: '/messages/:conversationId/:id',
      handler: 'message.findOne',
      config: {
        auth: false,
      },
    },
    {
      method: 'DELETE',
      path: '/messages/:conversationId/:id',
      handler: 'message.delete',
      config: {
        auth: false,
      },
    },
  ],
};