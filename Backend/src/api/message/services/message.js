// @ts-nocheck
const firebaseService = require('../../../firebase/firebase.service');

async function sendMessage(data) {
    const db = firebaseService.getFirestore();

    const { conversationId, text, senderId, type } = data;

    const messagesRef = db
        .collection('conversations')
        .doc(String(conversationId))
        .collection('messages');

    const newMessage = {
        text,
        senderId,
        type,
        createdAt: new Date(),
    };

    await messagesRef.add(newMessage);

    await db.collection('conversations')
        .doc(String(conversationId))
        .set({
            lastMessage: text,
            lastMessageAt: new Date()
        }, { merge: true });
}

async function getMessages(conversationId) {
    try {
        const db = firebaseService.getFirestore();
        console.log("Fetch messages for:", conversationId);

        const snapshot = await db
            .collection('conversations')
            .doc(String(conversationId))
            .collection('messages')
            .get();

        if (snapshot.empty) {
            console.log("No messages found");
            return [];
        }

        return snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data(),
        }));

    } catch (error) {
        console.error("getMessages ERROR:", error);
        throw error;
    }
}

async function getMessageById(conversationId, messageId) {
    try {
        const db = firebaseService.getFirestore();

        const doc = await db
            .collection('conversations')
            .doc(String(conversationId))
            .collection('messages')
            .doc(messageId)
            .get();

        if (!doc.exists) return null;

        return { id: doc.id, ...doc.data() };

    } catch (error) {
        console.error("getMessageById error:", error);
        throw error;
    }
}

async function deleteMessage(conversationId, messageId) {
    try {
        const db = firebaseService.getFirestore();

        await db
            .collection('conversations')
            .doc(String(conversationId))
            .collection('messages')
            .doc(messageId)
            .delete();

        return { success: true };

    } catch (error) {
        console.error("deleteMessage error:", error);
        throw error;
    }
}

module.exports = {
    sendMessage,
    getMessages,
    getMessageById,
    deleteMessage
};