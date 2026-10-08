// @ts-nocheck
const messageService = require('../services/message');

module.exports = {
    async create(ctx) {
        await messageService.sendMessage(ctx.request.body);
        ctx.send({ message: "Message sent" });
    },

    async findByConversation(ctx) {
        const { conversationId } = ctx.params;
        const messages = await messageService.getMessages(conversationId);
        ctx.send(messages);
    },

    async findOne(ctx) {
        try {
            const { conversationId, id } = ctx.params;

            console.log("conversationId:", conversationId);
            console.log("messageId:", id);

            const message = await messageService.getMessageById(conversationId, id);
            ctx.send(message);

        } catch (err) {
            console.error("ERROR:", err);
            ctx.throw(500, err.message);
        }
    },

    async delete(ctx) {
        const { conversationId, id } = ctx.params;
        await messageService.deleteMessage(conversationId, id);
        ctx.send({ message: "Deleted successfully" });
    }
};