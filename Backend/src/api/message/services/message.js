// @ts-nocheck
const firebaseService = require('../../../firebase/firebase.service');

function accessError(status, message) {
    const error = new Error(message);
    error.status = status;
    return error;
}

async function authorizeConversation(conversationId, user) {
    if (!user) throw accessError(401, 'Authentication required');

    const db = firebaseService.getFirestore();
    const conversationRef = db.collection('conversations').doc(String(conversationId));
    const conversation = await conversationRef.get();
    if (!conversation.exists) throw accessError(404, 'Conversation not found');

    const data = conversation.data() || {};
    const role = user.user_role;
    const profileId = user[`${role}Id`];
    if (!['player', 'manager', 'worker'].includes(role) || !profileId) {
        throw accessError(403, 'You are not a participant in this conversation');
    }

    const profileUid = {
        player: 'api::player.player',
        manager: 'api::manager.manager',
        worker: 'api::worker.worker',
    }[role];
    const profile = await strapi.db.query(profileUid).findOne({
        where: { id: profileId },
        select: ['firebaseUid'],
    });
    const identities = [
        String(profileId),
        `sporta_${role}_${profileId}`,
        profile?.firebaseUid,
    ].filter(Boolean);

    const participantIds = data.participantIds || {};
    const isParticipant =
        String(participantIds[role] ?? '') === String(profileId) ||
        identities.some((identity) =>
            Array.isArray(data.participants) && data.participants.includes(identity),
        );
    if (!isParticipant) {
        throw accessError(403, 'You are not a participant in this conversation');
    }

    return {
        conversationRef,
        identities,
        senderId: profile?.firebaseUid || `sporta_${role}_${profileId}`,
    };
}

async function sendMessage(data, user) {
    if (!data?.conversationId) throw accessError(400, 'conversationId is required');
    const { conversationId, text, type } = data;
    const { conversationRef, senderId } = await authorizeConversation(conversationId, user);
    if (typeof text !== 'string' || !text.trim()) {
        throw accessError(400, 'Message text is required');
    }

    const messagesRef = conversationRef.collection('messages');

    const newMessage = {
        text: text.trim(),
        senderId,
        type: type || 'text',
        createdAt: new Date(),
    };

    await messagesRef.add(newMessage);

    await conversationRef.set({
        lastMessage: text.trim(),
        lastMessageAt: new Date(),
    }, { merge: true });
}

async function getMessages(conversationId, user) {
    const { conversationRef } = await authorizeConversation(conversationId, user);
    const snapshot = await conversationRef
        .collection('messages')
        .orderBy('createdAt', 'asc')
        .get();

    return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
    }));
}

async function getMessageById(conversationId, messageId, user) {
    const { conversationRef } = await authorizeConversation(conversationId, user);
    const doc = await conversationRef
        .collection('messages')
        .doc(messageId)
        .get();

    if (!doc.exists) return null;

    return { id: doc.id, ...doc.data() };
}

async function deleteMessage(conversationId, messageId, user) {
    const { conversationRef, identities } = await authorizeConversation(conversationId, user);
    const messageRef = conversationRef
        .collection('messages')
        .doc(messageId);
    const message = await messageRef.get();
    if (!message.exists) throw accessError(404, 'Message not found');
    if (!identities.includes(String(message.data()?.senderId ?? ''))) {
        throw accessError(403, 'You can only delete your own messages');
    }
    await messageRef.delete();

    return { success: true };
}

module.exports = {
    authorizeConversation,
    sendMessage,
    getMessages,
    getMessageById,
    deleteMessage
};