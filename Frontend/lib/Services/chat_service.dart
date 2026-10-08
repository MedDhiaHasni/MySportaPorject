// lib/Services/chat_service.dart
// Three conversation types, each with a predictable Firestore doc id:
//
//   1. player ↔ manager  →  "reservation_{reservationId}"
//   2. player ↔ worker   →  "player_worker_{reservationId}"
//   3. worker ↔ manager  →  "worker_manager_{workerId}"
//
// All live in the top-level "conversations" collection.

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum ConversationType { playerManager, playerWorker, workerManager, unknown }

class ConversationModel {
  final String id;
  final String reservationId;
  final ConversationType type;
  final List<String> participants;
  final Map<String, String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  // Participant names — which ones are present depends on type
  final String? playerName;
  final String? managerName;
  final String? workerName;

  const ConversationModel({
    required this.id,
    required this.reservationId,
    required this.type,
    required this.participants,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
    this.playerName,
    this.managerName,
    this.workerName,
  });

  factory ConversationModel.fromDoc(DocumentSnapshot doc) {
    final d    = doc.data() as Map<String, dynamic>? ?? {};
    final docId = doc.id;

    // ── Infer type from the 'type' field first, then fall back to doc ID prefix.
    // This handles both new docs (with 'type' field) and legacy docs that
    // were created before the type field was added.
    ConversationType type;
    final typeField = d['type']?.toString();
    if (typeField == 'player_manager') {
      type = ConversationType.playerManager;
    } else if (typeField == 'player_worker') {
      type = ConversationType.playerWorker;
    } else if (typeField == 'worker_manager') {
      type = ConversationType.workerManager;
    } else if (docId.startsWith('player_worker_')) {
      type = ConversationType.playerWorker;
    } else if (docId.startsWith('worker_manager_')) {
      type = ConversationType.workerManager;
    } else if (docId.startsWith('reservation_')) {
      type = ConversationType.playerManager;
    } else {
      type = ConversationType.unknown;
    }

    // Extract reservationId from doc ID for legacy docs that don't have the field
    String reservationId = d['reservationId']?.toString() ?? '';
    if (reservationId.isEmpty) {
      if (docId.startsWith('reservation_')) {
        reservationId = docId.replaceFirst('reservation_', '');
      } else if (docId.startsWith('player_worker_')) {
        reservationId = docId.replaceFirst('player_worker_', '');
      } else {
        reservationId = docId;
      }
    }

    return ConversationModel(
      id:             docId,
      reservationId:  reservationId,
      type:           type,
      participants:   List<String>.from(d['participants'] ?? []),
      participantIds: Map<String, String>.from(
        (d['participantIds'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
      ),
      lastMessage:   d['lastMessage']?.toString(),
      lastMessageAt: _ts(d['lastMessageAt']),
      createdAt:     _ts(d['createdAt']),
      playerName:    d['playerName']?.toString(),
      managerName:   d['managerName']?.toString(),
      workerName:    d['workerName']?.toString(),
    );
  }

  /// Display name of the OTHER participant from the current user's perspective.
  String otherName(String myUid) {
    switch (type) {
      case ConversationType.playerManager:
        return participants.first == myUid
            ? (managerName ?? 'Manager')
            : (playerName  ?? 'Player');
      case ConversationType.playerWorker:
        return participants.first == myUid
            ? (workerName ?? 'Worker')
            : (playerName ?? 'Player');
      case ConversationType.workerManager:
        return participants.first == myUid
            ? (managerName ?? 'Manager')
            : (workerName  ?? 'Worker');
      default:
        return 'Unknown';
    }
  }

  String otherUid(String myUid) =>
      participants.firstWhere((uid) => uid != myUid, orElse: () => '');

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final String type;
  final DateTime? createdAt;

  const MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.type,
    this.createdAt,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel(
      id:        doc.id,
      text:      d['text']?.toString()     ?? '',
      senderId:  d['senderId']?.toString() ?? '',
      type:      d['type']?.toString()     ?? 'text',
      createdAt: ConversationModel._ts(d['createdAt']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Stream ALL conversations for a UID (all types) ───────────────────────
  // Sorted client-side by lastMessageAt desc (avoids composite index).
  Stream<List<ConversationModel>> streamConversations(String uid) {
    if (uid.isEmpty) return const Stream.empty();

    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => ConversationModel.fromDoc(doc))
          .toList();
      list.sort((a, b) {
        final ta = a.lastMessageAt ?? a.createdAt ?? DateTime(0);
        final tb = b.lastMessageAt ?? b.createdAt ?? DateTime(0);
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  // ── Stream only player↔manager conversations for a UID ──────────────────
  Stream<List<ConversationModel>> streamPlayerManagerConversations(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return streamConversations(uid).map(
      (list) => list.where((c) => c.type == ConversationType.playerManager).toList(),
    );
  }

  // ── Stream only player↔worker conversations for a UID ───────────────────
  Stream<List<ConversationModel>> streamPlayerWorkerConversations(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return streamConversations(uid).map(
      (list) => list.where((c) => c.type == ConversationType.playerWorker).toList(),
    );
  }

  // ── Stream only worker↔manager conversation for a worker ────────────────
  // Returns a single conversation (the permanent channel).
  Stream<ConversationModel?> streamWorkerManagerConversation(String workerId) {
    if (workerId.isEmpty) return const Stream.empty();
    return _db
        .collection('conversations')
        .doc('worker_manager_$workerId')
        .snapshots()
        .map((snap) => snap.exists ? ConversationModel.fromDoc(snap) : null);
  }

  // ── Stream ALL worker↔manager conversations for a manager ───────────────
  // Used in manager messages page — shows one channel per worker.
  Stream<List<ConversationModel>> streamWorkerManagerConversationsForManager(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return streamConversations(uid).map(
      (list) => list.where((c) => c.type == ConversationType.workerManager).toList(),
    );
  }

  // ── Stream ALL conversations for a worker ────────────────────────────────
  // Worker sees: player↔worker (per booking) + worker↔manager (permanent).
  Stream<List<ConversationModel>> streamWorkerConversations(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return streamConversations(uid).map(
      (list) => list.where((c) =>
        c.type == ConversationType.playerWorker ||
        c.type == ConversationType.workerManager
      ).toList(),
    );
  }

  // ── Get a conversation by reservation id (player↔manager) ───────────────
  Future<ConversationModel?> getPlayerManagerConversation(String reservationId) =>
      getConversation('reservation_$reservationId');

  // ── Get a conversation by reservation id (player↔worker) ────────────────
  Future<ConversationModel?> getPlayerWorkerConversation(String reservationId) =>
      getConversation('player_worker_$reservationId');

  // ── Get the permanent worker↔manager conversation ────────────────────────
  Future<ConversationModel?> getWorkerManagerConversation(String workerId) =>
      getConversation('worker_manager_$workerId');

  // ── Get any conversation by its doc id ──────────────────────────────────
  Future<ConversationModel?> getConversation(String conversationId) async {
    if (conversationId.isEmpty) return null;
    try {
      final doc = await _db.collection('conversations').doc(conversationId).get();
      if (!doc.exists) return null;
      return ConversationModel.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  // ── Stream messages in a conversation ───────────────────────────────────
  Stream<List<MessageModel>> streamMessages(String conversationId) {
    if (conversationId.isEmpty) return const Stream.empty();
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => MessageModel.fromDoc(doc)).toList());
  }

  // ── Send a message ───────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String type = 'text',
  }) async {
    if (conversationId.isEmpty || senderId.isEmpty || text.trim().isEmpty) return;

    final now = FieldValue.serverTimestamp();

    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'text':      text.trim(),
      'senderId':  senderId,
      'type':      type,
      'createdAt': now,
    });

    await _db
        .collection('conversations')
        .doc(conversationId)
        .update({
      'lastMessage':   text.trim(),
      'lastMessageAt': now,
    });
  }

  // ── Delete a single message ──────────────────────────────────────────────
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    if (conversationId.isEmpty || messageId.isEmpty) return;
    try {
      await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Update lastMessage after deletion
      final remaining = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (remaining.docs.isNotEmpty) {
        final d = remaining.docs.first.data();
        await _db.collection('conversations').doc(conversationId).update({
          'lastMessage':   d['text']?.toString() ?? '',
          'lastMessageAt': d['createdAt'] ?? FieldValue.serverTimestamp(),
        });
      } else {
        await _db.collection('conversations').doc(conversationId).update({
          'lastMessage':   null,
          'lastMessageAt': null,
        });
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // ── Delete a conversation and all its messages ───────────────────────────
  // NOTE: Never call this on worker↔manager conversations — they are permanent.
  Future<void> deleteConversation(String conversationId) async {
    if (conversationId.isEmpty) return;
    try {
      final msgs = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();
      for (final doc in msgs.docs) {
        await doc.reference.delete();
      }
      await _db.collection('conversations').doc(conversationId).delete();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // ── Delete both player conversations for a reservation ───────────────────
  // Use when a reservation is deleted. Does NOT touch worker↔manager.
  Future<void> deleteReservationConversations(String reservationId) async {
    await Future.wait([
      deleteConversation('reservation_$reservationId'),
      deleteConversation('player_worker_$reservationId'),
    ]);
  }

  // ── Clear all conversations for a UID (except worker↔manager) ───────────
  Future<void> clearAllConversations(String userUid) async {
    if (userUid.isEmpty) return;
    try {
      final snap = await _db
          .collection('conversations')
          .where('participants', arrayContains: userUid)
          .get();
      for (final convDoc in snap.docs) {
        // Skip the permanent worker↔manager channel
        if (convDoc.id.startsWith('worker_manager_')) continue;
        final msgs = await convDoc.reference.collection('messages').get();
        for (final msg in msgs.docs) await msg.reference.delete();
        await convDoc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to clear conversations: $e');
    }
  }
}
















/*// lib/Services/chat_service.dart
// Requires Firebase to be initialized AND the user to be signed in
// (anonymously is fine) before calling any method here.
// Firebase.initializeApp() + FirebaseAuth.instance.signInAnonymously()
// are both called in main.dart before runApp().
//
// pubspec.yaml dependencies needed:
//   firebase_core: ^2.32.0
//   firebase_auth: ^4.20.0      ← ADD THIS if not present
//   cloud_firestore: ^4.17.0

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class ConversationModel {
  final String id;
  final String reservationId;
  final List<String> participants;
  final Map<String, String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  const ConversationModel({
    required this.id,
    required this.reservationId,
    required this.participants,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
  });

  factory ConversationModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return ConversationModel(
      id:             doc.id,
      reservationId:  d['reservationId']?.toString() ?? doc.id,
      participants:   List<String>.from(d['participants'] ?? []),
      participantIds: Map<String, String>.from(
        (d['participantIds'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      ),
      lastMessage:   d['lastMessage']?.toString(),
      lastMessageAt: _ts(d['lastMessageAt']),
      createdAt:     _ts(d['createdAt']),
    );
  }

  String otherUid(String myUid) =>
      participants.firstWhere((uid) => uid != myUid, orElse: () => '');

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final String type;
  final DateTime? createdAt;

  const MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.type,
    this.createdAt,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel(
      id:        doc.id,
      text:      d['text']?.toString() ?? '',
      senderId:  d['senderId']?.toString() ?? '',
      type:      d['type']?.toString() ?? 'text',
      createdAt: ConversationModel._ts(d['createdAt']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Stream all conversations for a uid ───────────────────────────────────
  // No orderBy to avoid needing a composite Firestore index.
  // Sorted in Dart after the snapshot arrives.
  Stream<List<ConversationModel>> streamConversations(String uid) {
    if (uid.isEmpty) return const Stream.empty();

    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => ConversationModel.fromDoc(doc))
          .toList();

      list.sort((a, b) {
        final ta = a.lastMessageAt ?? a.createdAt ?? DateTime(0);
        final tb = b.lastMessageAt ?? b.createdAt ?? DateTime(0);
        return tb.compareTo(ta);
      });

      return list;
    });
  }

  // ── Stream messages in a conversation ────────────────────────────────────
  Stream<List<MessageModel>> streamMessages(String conversationId) {
    if (conversationId.isEmpty) return const Stream.empty();

    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => MessageModel.fromDoc(doc)).toList());
  }

  // ── Send a message ────────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String type = 'text',
  }) async {
    if (conversationId.isEmpty || senderId.isEmpty || text.trim().isEmpty) return;

    final now = FieldValue.serverTimestamp();

    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'text':      text.trim(),
      'senderId':  senderId,
      'type':      type,
      'createdAt': now,
    });

    await _db
        .collection('conversations')
        .doc(conversationId)
        .update({
      'lastMessage':   text.trim(),
      'lastMessageAt': now,
    });
  }

  // ── Get a single conversation once ──────────────────────────────────────
  Future<ConversationModel?> getConversation(String conversationId) async {
    if (conversationId.isEmpty) return null;
    try {
      final doc = await _db
          .collection('conversations')
          .doc(conversationId)
          .get();
      if (!doc.exists) return null;
      return ConversationModel.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  // ── NEW: Delete a single conversation and all its messages ───────────────
  Future<void> deleteConversation(String conversationId) async {
    if (conversationId.isEmpty) return;
    
    try {
      // First, delete all messages in the conversation subcollection
      final messagesSnapshot = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();
      
      // Delete all messages in batches
      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Then delete the conversation document itself
      await _db
          .collection('conversations')
          .doc(conversationId)
          .delete();
          
      print('Conversation $conversationId deleted successfully');
    } catch (e) {
      print('Error deleting conversation: $e');
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // ── NEW: Clear all conversations for a specific user ─────────────────────
  Future<void> clearAllConversations(String userUid) async {
    if (userUid.isEmpty) return;
    
    try {
      // Get all conversations where the user is a participant
      final conversationsSnapshot = await _db
          .collection('conversations')
          .where('participants', arrayContains: userUid)
          .get();
      
      // Delete each conversation and its messages
      for (final convDoc in conversationsSnapshot.docs) {
        final convId = convDoc.id;
        
        // Delete all messages in this conversation
        final messagesSnapshot = await _db
            .collection('conversations')
            .doc(convId)
            .collection('messages')
            .get();
        
        for (final msgDoc in messagesSnapshot.docs) {
          await msgDoc.reference.delete();
        }
        
        // Delete the conversation document
        await convDoc.reference.delete();
      }
      
      print('All conversations for user $userUid cleared successfully');
    } catch (e) {
      print('Error clearing conversations: $e');
      throw Exception('Failed to clear conversations: $e');
    }
  }

  // ── NEW: Delete a single message from a conversation ─────────────────────
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    if (conversationId.isEmpty || messageId.isEmpty) return;
    
    try {
      // Get the message to check if it's the last message
      final messageDoc = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .get();
      
      if (!messageDoc.exists) return;
      
      // Delete the message
      await messageDoc.reference.delete();
      
      // Get the new last message (most recent)
      final remainingMessages = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      // Update conversation with new last message info
      if (remainingMessages.docs.isNotEmpty) {
        final lastMsg = remainingMessages.docs.first;
        final lastMsgData = lastMsg.data();
        await _db
            .collection('conversations')
            .doc(conversationId)
            .update({
          'lastMessage': lastMsgData['text']?.toString() ?? '',
          'lastMessageAt': lastMsgData['createdAt'] ?? FieldValue.serverTimestamp(),
        });
      } else {
        // No messages left, clear last message fields
        await _db
            .collection('conversations')
            .doc(conversationId)
            .update({
          'lastMessage': null,
          'lastMessageAt': null,
        });
      }
      
      print('Message $messageId deleted from conversation $conversationId');
    } catch (e) {
      print('Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }
}






******************************











// lib/Services/chat_service.dart
// Requires Firebase to be initialized AND the user to be signed in
// (anonymously is fine) before calling any method here.
// Firebase.initializeApp() + FirebaseAuth.instance.signInAnonymously()
// are both called in main.dart before runApp().
//
// pubspec.yaml dependencies needed:
//   firebase_core: ^2.32.0
//   firebase_auth: ^4.20.0      ← ADD THIS if not present
//   cloud_firestore: ^4.17.0

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class ConversationModel {
  final String id;
  final String reservationId;
  final List<String> participants;
  final Map<String, String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  const ConversationModel({
    required this.id,
    required this.reservationId,
    required this.participants,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
  });

  factory ConversationModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return ConversationModel(
      id:             doc.id,
      reservationId:  d['reservationId']?.toString() ?? doc.id,
      participants:   List<String>.from(d['participants'] ?? []),
      participantIds: Map<String, String>.from(
        (d['participantIds'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      ),
      lastMessage:   d['lastMessage']?.toString(),
      lastMessageAt: _ts(d['lastMessageAt']),
      createdAt:     _ts(d['createdAt']),
    );
  }

  String otherUid(String myUid) =>
      participants.firstWhere((uid) => uid != myUid, orElse: () => '');

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final String type;
  final DateTime? createdAt;

  const MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.type,
    this.createdAt,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel(
      id:        doc.id,
      text:      d['text']?.toString() ?? '',
      senderId:  d['senderId']?.toString() ?? '',
      type:      d['type']?.toString() ?? 'text',
      createdAt: ConversationModel._ts(d['createdAt']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Stream all conversations for a uid ───────────────────────────────────
  // No orderBy to avoid needing a composite Firestore index.
  // Sorted in Dart after the snapshot arrives.
  Stream<List<ConversationModel>> streamConversations(String uid) {
    if (uid.isEmpty) return const Stream.empty();

    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => ConversationModel.fromDoc(doc))
          .toList();

      list.sort((a, b) {
        final ta = a.lastMessageAt ?? a.createdAt ?? DateTime(0);
        final tb = b.lastMessageAt ?? b.createdAt ?? DateTime(0);
        return tb.compareTo(ta);
      });

      return list;
    });
  }

  // ── Stream messages in a conversation ────────────────────────────────────
  Stream<List<MessageModel>> streamMessages(String conversationId) {
    if (conversationId.isEmpty) return const Stream.empty();

    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => MessageModel.fromDoc(doc)).toList());
  }

  // ── Send a message ────────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String type = 'text',
  }) async {
    if (conversationId.isEmpty || senderId.isEmpty || text.trim().isEmpty) return;

    final now = FieldValue.serverTimestamp();

    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'text':      text.trim(),
      'senderId':  senderId,
      'type':      type,
      'createdAt': now,
    });

    await _db
        .collection('conversations')
        .doc(conversationId)
        .update({
      'lastMessage':   text.trim(),
      'lastMessageAt': now,
    });
  }

  // ── Get a single conversation once ──────────────────────────────────────
  Future<ConversationModel?> getConversation(String conversationId) async {
    if (conversationId.isEmpty) return null;
    try {
      final doc = await _db
          .collection('conversations')
          .doc(conversationId)
          .get();
      if (!doc.exists) return null;
      return ConversationModel.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }
}


















// lib/Services/chat_service.dart
// Requires Firebase to be initialized AND the user to be signed in
// (anonymously is fine) before calling any method here.
// Firebase.initializeApp() + FirebaseAuth.instance.signInAnonymously()
// are both called in main.dart before runApp().
//
// pubspec.yaml dependencies needed:
//   firebase_core: ^2.32.0
//   firebase_auth: ^4.20.0      ← ADD THIS if not present
//   cloud_firestore: ^4.17.0

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class ConversationModel {
  final String id;
  final String reservationId;
  final List<String> participants;
  final Map<String, String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  const ConversationModel({
    required this.id,
    required this.reservationId,
    required this.participants,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
  });

  factory ConversationModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return ConversationModel(
      id:             doc.id,
      reservationId:  d['reservationId']?.toString() ?? doc.id,
      participants:   List<String>.from(d['participants'] ?? []),
      participantIds: Map<String, String>.from(
        (d['participantIds'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      ),
      lastMessage:   d['lastMessage']?.toString(),
      lastMessageAt: _ts(d['lastMessageAt']),
      createdAt:     _ts(d['createdAt']),
    );
  }

  String otherUid(String myUid) =>
      participants.firstWhere((uid) => uid != myUid, orElse: () => '');

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final String type;
  final DateTime? createdAt;

  const MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.type,
    this.createdAt,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel(
      id:        doc.id,
      text:      d['text']?.toString() ?? '',
      senderId:  d['senderId']?.toString() ?? '',
      type:      d['type']?.toString() ?? 'text',
      createdAt: ConversationModel._ts(d['createdAt']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Stream all conversations for a uid ───────────────────────────────────
  // No orderBy to avoid needing a composite Firestore index.
  // Sorted in Dart after the snapshot arrives.
  Stream<List<ConversationModel>> streamConversations(String uid) {
    // DEBUG: Check if user is authenticated
    print('🔍 [DEBUG] streamConversations called with uid: $uid');
    
    if (uid.isEmpty) {
      print('❌ [DEBUG] uid is empty! User is NOT authenticated!');
      return const Stream.empty();
    }
    
    // Check current auth state
    final currentUser = FirebaseAuth.instance.currentUser;
    print('✅ [DEBUG] FirebaseAuth.currentUser.uid: ${currentUser?.uid ?? "null"}');
    print('✅ [DEBUG] Passed uid: $uid');
    print('✅ [DEBUG] Users match: ${currentUser?.uid == uid}');
    
    print('📡 [DEBUG] Querying conversations with participants arrayContains: $uid');
    
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      print('📦 [DEBUG] Received ${snap.docs.length} conversations from Firestore');
      
      final list = snap.docs
          .map((doc) {
            print('📄 [DEBUG] Conversation doc: ${doc.id}, data: ${doc.data()}');
            return ConversationModel.fromDoc(doc);
          })
          .toList();

      list.sort((a, b) {
        final ta = a.lastMessageAt ?? a.createdAt ?? DateTime(0);
        final tb = b.lastMessageAt ?? b.createdAt ?? DateTime(0);
        return tb.compareTo(ta);
      });

      print('✅ [DEBUG] Returning ${list.length} conversations sorted');
      return list;
    });
  }

  // ── Stream messages in a conversation ────────────────────────────────────
  Stream<List<MessageModel>> streamMessages(String conversationId) {
    // DEBUG: Check conversation ID
    print('🔍 [DEBUG] streamMessages called with conversationId: $conversationId');
    
    if (conversationId.isEmpty) {
      print('❌ [DEBUG] conversationId is empty!');
      return const Stream.empty();
    }
    
    print('📡 [DEBUG] Querying messages for conversation: $conversationId');
    
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
          print('📦 [DEBUG] Received ${snap.docs.length} messages from Firestore');
          return snap.docs.map((doc) => MessageModel.fromDoc(doc)).toList();
        });
  }

  // ── Send a message ────────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String type = 'text',
  }) async {
    // DEBUG: Check send message parameters
    print('🔍 [DEBUG] sendMessage called');
    print('  - conversationId: $conversationId');
    print('  - senderId: $senderId');
    print('  - text: $text');
    
    if (conversationId.isEmpty || senderId.isEmpty || text.trim().isEmpty) {
      print('❌ [DEBUG] Invalid parameters for sendMessage');
      return;
    }

    final now = FieldValue.serverTimestamp();
    
    print('📡 [DEBUG] Adding message to Firestore...');

    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'text':      text.trim(),
      'senderId':  senderId,
      'type':      type,
      'createdAt': now,
    });
    
    print('✅ [DEBUG] Message added successfully');

    await _db
        .collection('conversations')
        .doc(conversationId)
        .update({
      'lastMessage':   text.trim(),
      'lastMessageAt': now,
    });
    
    print('✅ [DEBUG] Conversation updated with lastMessage');
  }

  // ── Get a single conversation once ──────────────────────────────────────
  Future<ConversationModel?> getConversation(String conversationId) async {
    // DEBUG: Check get conversation parameters
    print('🔍 [DEBUG] getConversation called with conversationId: $conversationId');
    
    if (conversationId.isEmpty) return null;
    try {
      print('📡 [DEBUG] Fetching conversation from Firestore...');
      final doc = await _db
          .collection('conversations')
          .doc(conversationId)
          .get();
      if (!doc.exists) {
        print('❌ [DEBUG] Conversation does not exist');
        return null;
      }
      print('✅ [DEBUG] Conversation found: ${doc.id}');
      print('📄 [DEBUG] Conversation data: ${doc.data()}');
      return ConversationModel.fromDoc(doc);
    } catch (e) {
      print('❌ [DEBUG] Error getting conversation: $e');
      return null;
    }
  }
}*/