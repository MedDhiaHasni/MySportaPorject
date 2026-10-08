import 'package:flutter/material.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Utils/date_utils.dart';

class AppPlayer {
  final String id, name, avatarInitials, phone; // Add phone field

  const AppPlayer({
    required this.id,
    required this.name,
    required this.avatarInitials,
    required this.phone, // Add this
  });
}

class CourtModel {
  final String id, name; // location removed
  final SportType sport;
  final double pricePerHour;
  final Color color;
  final String? imageUrl;
  final List<String> availableTimeSlots;
  final bool isActive; // NEW: Court availability status
  
  const CourtModel({
    required this.id,
    required this.name,
    required this.sport,
    required this.pricePerHour,
    required this.color,
    this.imageUrl,
    this.availableTimeSlots = const [
      '08:00',
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
      '19:00',
      '20:00',
      '21:00',
    ],
    this.isActive = true, // NEW: Default to true
  });
}

class CourtReservation {
  final String id, courtId, courtName, hostId;
  final SportType sport;
  final DateTime date;
  final String startTime, endTime;
  final double durationHours, totalPrice;
  final PaymentOption paymentOption;
  final String? courtImageUrl;

  const CourtReservation({
    required this.id,
    required this.courtId,
    required this.courtName,
    required this.hostId,
    required this.sport,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.totalPrice,
    this.paymentOption = PaymentOption.payNow,
    this.courtImageUrl,
  });

  String get dateLabel => AppDateUtils.formatDate(date);
}

class MatchPlayer {
  final AppPlayer player;
  final bool hasPaid, isHost;
  final String paymentMethod;
  const MatchPlayer({
    required this.player,
    this.hasPaid = false,
    this.isHost = false,
    this.paymentMethod = 'pending',
  });
  MatchPlayer copyWith({bool? hasPaid, String? paymentMethod}) => MatchPlayer(
    player: player,
    isHost: isHost,
    hasPaid: hasPaid ?? this.hasPaid,
    paymentMethod: paymentMethod ?? this.paymentMethod,
  );
}

class MatchModel {
  final String id;
  final CourtReservation? reservation;
  final MatchVisibility visibility;
  final MatchType matchType;
  final int maxPlayers;
  final SportType sport;
  final String description;
  final DateTime scheduledDate;
  final String scheduledTime;
  final List<MatchPlayer> players;
  final MatchStatus status;

  const MatchModel({
    required this.id,
    this.reservation,
    required this.visibility,
    required this.matchType,
    required this.maxPlayers,
    required this.sport,
    required this.description,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.players,
    required this.status,
  });

  int get joinedCount => players.length;
  double get fillRatio => (joinedCount / maxPlayers).clamp(0.0, 1.0);
  bool get isFull => joinedCount >= maxPlayers;
  bool get isPublic => visibility == MatchVisibility.public;
  bool get hasCourt => reservation != null;
  double get totalCourtCost => reservation?.totalPrice ?? 0;
  double get pricePerPlayer => hasCourt ? totalCourtCost / maxPlayers : 0;

  MatchStatus computeStatus() {
    if (isFull) return MatchStatus.confirmed;
    if (fillRatio >= 0.5) return MatchStatus.halfFull;
    return MatchStatus.open;
  }

  MatchModel copyWith({
    List<MatchPlayer>? players,
    MatchStatus? status,
    CourtReservation? reservation,
    String? description,
  }) => MatchModel(
    id: id,
    reservation: reservation ?? this.reservation,
    visibility: visibility,
    matchType: matchType,
    maxPlayers: maxPlayers,
    sport: sport,
    description: description ?? this.description,
    scheduledDate: scheduledDate,
    scheduledTime: scheduledTime,
    players: players ?? this.players,
    status: status ?? this.status,
  );
}

class JoinRequest {
  final String id;
  final AppPlayer player;
  JoinRequestStatus status;
  final String message;
  JoinRequest({
    required this.id,
    required this.player,
    this.status = JoinRequestStatus.pending,
    this.message = '',
  });
}

class AnnouncementModel {
  final String id;
  final CourtReservation reservation;
  final AppPlayer host;
  final int playersNeeded;
  final String description;
  final DateTime createdAt;
  final List<JoinRequest> requests;

  AnnouncementModel({
    required this.id,
    required this.reservation,
    required this.host,
    required this.playersNeeded,
    required this.description,
    required this.createdAt,
    List<JoinRequest>? requests,
  }) : requests = requests ?? [];

  int get acceptedCount =>
      requests.where((r) => r.status == JoinRequestStatus.accepted).length;
  int get pendingCount =>
      requests.where((r) => r.status == JoinRequestStatus.pending).length;
  int get spotsLeft => (playersNeeded - acceptedCount).clamp(0, playersNeeded);
  bool get isFull => spotsLeft == 0;
}