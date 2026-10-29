// @ts-nocheck
const messageService = require('../services/message');

module.exports = {
    async create(ctx) {
        try {
            await messageService.sendMessage(ctx.request.body, ctx.state.user);
            ctx.send({ message: 'Message sent' });
        } catch (error) {
            if (!error.status) strapi.log.error('[message] Send failed', error.message);
            ctx.status = error.status || 500;
            ctx.body = { error: { message: error.status ? error.message : 'Failed to send message' } };
        }
    },

    async findByConversation(ctx) {
        try {
            const { conversationId } = ctx.params;
            const messages = await messageService.getMessages(conversationId, ctx.state.user);
            ctx.send(messages);
        } catch (error) {
            if (!error.status) strapi.log.error('[message] Read conversation failed', error.message);
            ctx.status = error.status || 500;
            ctx.body = { error: { message: error.status ? error.message : 'Failed to get messages' } };
        }
    },

    async findOne(ctx) {
        try {
            const { conversationId, id } = ctx.params;
            const message = await messageService.getMessageById(conversationId, id, ctx.state.user);
            if (!message) return ctx.notFound('Message not found');
            ctx.send(message);
        } catch (err) {
            if (!err.status) strapi.log.error('[message] Read message failed', err.message);
            ctx.status = err.status || 500;
            ctx.body = { error: { message: err.status ? err.message : 'Failed to get message' } };
        }
    },

    async delete(ctx) {
        try {
            const { conversationId, id } = ctx.params;
            await messageService.deleteMessage(conversationId, id, ctx.state.user);
            ctx.send({ message: 'Deleted successfully' });
        } catch (error) {
            if (!error.status) strapi.log.error('[message] Delete failed', error.message);
            ctx.status = error.status || 500;
            ctx.body = { error: { message: error.status ? error.message : 'Failed to delete message' } };
        }
    }
};