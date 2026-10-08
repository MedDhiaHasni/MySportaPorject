// lib/Models/worker_chat_models.dart

class ChatConversation {
  final String id;
  final String reservationId;
  final List<String> participants;
  final Map<String, String> participantIds;
  final String? playerId;
  final String? managerId;
  final String? workerId;
  final String? playerName;
  final String? managerName;
  final String? workerName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final String type;
  final String status;

  ChatConversation({
    required this.id,
    required this.reservationId,
    required this.participants,
    required this.participantIds,
    this.playerId,
    this.managerId,
    this.workerId,
    this.playerName,
    this.managerName,
    this.workerName,
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
    required this.type,
    required this.status,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id']?.toString() ?? '',
      reservationId: json['reservationId']?.toString() ?? '',
      participants: json['participants'] is List 
          ? (json['participants'] as List).map((e) => e.toString()).toList()
          : [],
      participantIds: json['participantIds'] is Map
          ? Map<String, String>.from(json['participantIds'])
          : {},
      playerId: json['playerId']?.toString(),
      managerId: json['managerId']?.toString(),
      workerId: json['workerId']?.toString(),
      playerName: json['playerName']?.toString(),
      managerName: json['managerName']?.toString(),
      workerName: json['workerName']?.toString(),
      lastMessage: json['lastMessage']?.toString(),
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      type: json['type']?.toString() ?? 'player_manager',
      status: json['status']?.toString() ?? 'active',
    );
  }

  String getOtherParticipantName(String currentUserId, String currentUserRole) {
    final currentUid = 'sporta_${currentUserRole}_$currentUserId';
    if (type == 'player_worker') {
      return playerName ?? 'Player';
    } else if (type == 'player_manager') {
      return managerName ?? 'Manager';
    } else {
      // player_worker_manager - determine the other participant
      if (currentUid.startsWith('sporta_worker')) {
        return playerName ?? 'Player';
      } else if (currentUid.startsWith('sporta_player')) {
        return workerName ?? 'Worker';
      }
      return managerName ?? 'Manager';
    }
  }

  String getOtherParticipantRole(String currentUserId, String currentUserRole) {
    final currentUid = 'sporta_${currentUserRole}_$currentUserId';
    if (type == 'player_worker') {
      return currentUid.startsWith('sporta_worker') ? 'Player' : 'Worker';
    } else if (type == 'player_manager') {
      return currentUid.startsWith('sporta_manager') ? 'Player' : 'Manager';
    } else {
      if (currentUid.startsWith('sporta_worker')) {
        return 'Player';
      } else if (currentUid.startsWith('sporta_player')) {
        return 'Worker';
      }
      return 'Manager';
    }
  }
}

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final String senderRole;
  final DateTime createdAt;
  final bool read;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.createdAt,
    required this.read,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      read: json['read'] ?? false,
    );
  }

  bool get isFromWorker => senderRole == 'worker';
  bool get isFromPlayer => senderRole == 'player';
  bool get isFromManager => senderRole == 'manager';
}