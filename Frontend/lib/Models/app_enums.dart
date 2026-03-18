import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

enum SportType { tennis, padel, football, basketball }
extension SportTypeX on SportType {
  String get label { switch(this) {
    case SportType.tennis:     return 'Tennis';
    case SportType.padel:      return 'Padel';
    case SportType.football:   return 'Football';
    case SportType.basketball: return 'Basketball';
  }}
  IconData get icon { switch(this) {
    case SportType.tennis:     return Icons.sports_tennis_rounded;
    case SportType.padel:      return Icons.sports_tennis_rounded;
    case SportType.football:   return Icons.sports_soccer_rounded;
    case SportType.basketball: return Icons.sports_basketball_rounded;
  }}
  Color get color { switch(this) {
    case SportType.tennis:     return kGreen;
    case SportType.padel:      return kPurple;
    case SportType.football:   return kPrimary;
    case SportType.basketball: return kAmber;
  }}
}

enum MatchType { singles, doubles, team }
extension MatchTypeX on MatchType {
  String get label { switch(this) {
    case MatchType.singles: return 'Singles';
    case MatchType.doubles: return 'Doubles';
    case MatchType.team:    return 'Team';
  }}
  int get defaultPlayers { switch(this) {
    case MatchType.singles: return 2;
    case MatchType.doubles: return 4;
    case MatchType.team:    return 10;
  }}
}

enum MatchVisibility { private, public }

enum MatchStatus { open, halfFull, full, confirmed, inProgress, finished, cancelled }
extension MatchStatusX on MatchStatus {
  String get label { switch(this) {
    case MatchStatus.open:       return 'Open';
    case MatchStatus.halfFull:   return 'Half Full';
    case MatchStatus.full:       return 'Full';
    case MatchStatus.confirmed:  return 'Confirmed';
    case MatchStatus.inProgress: return 'In Progress';
    case MatchStatus.finished:   return 'Finished';
    case MatchStatus.cancelled:  return 'Cancelled';
  }}
  Color get color { switch(this) {
    case MatchStatus.open:       return kBlue;
    case MatchStatus.halfFull:   return kAmber;
    case MatchStatus.full:       return kOrange;
    case MatchStatus.confirmed:  return kGreen;
    case MatchStatus.inProgress: return kPrimary;
    case MatchStatus.finished:   return kTextMid;
    case MatchStatus.cancelled:  return kRed;
  }}
}

enum PaymentOption { payNow, payAtVenue }

enum JoinRequestStatus { pending, accepted, declined }
