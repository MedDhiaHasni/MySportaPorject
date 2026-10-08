import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

final samplePlayers = [
  const AppPlayer(
    id: 'p1',
    name: 'Karim Jaziri',
    avatarInitials: 'KJ',
    phone: '+216 55 100 002',
  ),
  const AppPlayer(
    id: 'p2',
    name: 'Nadia Ben Salah',
    avatarInitials: 'NB',
    phone: '+216 55 100 003',
  ),
  const AppPlayer(
    id: 'p3',
    name: 'Mehdi Trabelsi',
    avatarInitials: 'MT',
    phone: '+216 55 100 004',
  ),
  const AppPlayer(
    id: 'p4',
    name: 'Leila Mallouli',
    avatarInitials: 'LM',
    phone: '+216 55 100 005',
  ),
  const AppPlayer(
    id: 'p5',
    name: 'Omar Haddad',
    avatarInitials: 'OH',
    phone: '+216 55 100 006',
  ),
  const AppPlayer(
    id: 'p6',
    name: 'Sana Khelifi',
    avatarInitials: 'SK',
    phone: '+216 55 100 001',
  ),
];

final sampleCourts = [
  const CourtModel(
    id: 'c1',
    name: 'Court Alpha',
    sport: SportType.football,
    pricePerHour: 90,
    color: kPrimary,
    imageUrl:
        'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=600&q=80',
    availableTimeSlots: ['08:00', '10:00', '14:00', '16:00', '18:00', '20:00'],
  ),
  const CourtModel(
    id: 'c2',
    name: 'Court Beta',
    sport: SportType.padel,
    pricePerHour: 120,
    color: kPurple,
    imageUrl:
        'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=600&q=80',
    availableTimeSlots: ['09:00', '11:00', '15:00', '17:00', '19:00', '21:00'],
  ),
  const CourtModel(
    id: 'c3',
    name: 'Court Gamma',
    sport: SportType.tennis,
    pricePerHour: 105,
    color: kGreen,
    imageUrl:
        'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=600&q=80',
  ),
  const CourtModel(
    id: 'c4',
    name: 'Court Delta',
    sport: SportType.basketball,
    pricePerHour: 75,
    color: kAmber,
    imageUrl:
        'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=600&q=80',
    availableTimeSlots: [
      '08:00',
      '09:00',
      '11:00',
      '13:00',
      '15:00',
      '17:00',
      '19:00',
    ],
  ),
];

List<AnnouncementModel> sampleAnnouncements = [
  AnnouncementModel(
    id: 'a1',
    reservation: CourtReservation(
      id: 'r_a1',
      courtId: 'c1',
      courtName: 'Arena Sport Center',
      hostId: 'p2',
      sport: SportType.football,
      date: DateTime.now().add(const Duration(days: 1)),
      startTime: '20:00',
      endTime: '21:00',
      durationHours: 1.0,
      totalPrice: 90,
      paymentOption: PaymentOption.payNow,
      courtImageUrl:
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
    ),
    host: const AppPlayer(
      id: 'p2',
      name: 'Nadia Ben Salah',
      avatarInitials: 'NB',
      phone: '+216 55 100 003',
    ),
    playersNeeded: 4,
    description:
        'Need 4 more for a friendly 5v5. All levels welcome, just come with good energy!',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    requests: [
      JoinRequest(
        id: 'jr1',
        player: const AppPlayer(
          id: 'p5',
          name: 'Omar Haddad',
          avatarInitials: 'OH',
          phone: '+216 55 100 006',
        ),
        message: "I'm in, intermediate level",
      ),
    ],
  ),
  AnnouncementModel(
    id: 'a2',
    reservation: CourtReservation(
      id: 'r_a2',
      courtId: 'c2',
      courtName: 'Padel Club Marsa',
      hostId: 'p3',
      sport: SportType.padel,
      date: DateTime.now().add(const Duration(days: 2)),
      startTime: '18:00',
      endTime: '19:30',
      durationHours: 1.5,
      totalPrice: 180,
      paymentOption: PaymentOption.payAtVenue,
      courtImageUrl:
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=700&q=80',
    ),
    host: const AppPlayer(
      id: 'p3',
      name: 'Mehdi Trabelsi',
      avatarInitials: 'MT',
      phone: '+216 55 100 004',
    ),
    playersNeeded: 2,
    description:
        'Padel doubles session — looking for 2 players, intermediate level preferred.',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  AnnouncementModel(
    id: 'a3',
    reservation: CourtReservation(
      id: 'r_a3',
      courtId: 'c3',
      courtName: 'Court Gamma',
      hostId: 'p4',
      sport: SportType.tennis,
      date: DateTime.now().add(const Duration(days: 2)),
      startTime: '10:00',
      endTime: '11:30',
      durationHours: 1.5,
      totalPrice: 157.5,
      paymentOption: PaymentOption.payNow,
      courtImageUrl:
          'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=700&q=80',
    ),
    host: const AppPlayer(
      id: 'p4',
      name: 'Leila Mallouli',
      avatarInitials: 'LM',
      phone: '+216 55 100 005',
    ),
    playersNeeded: 1,
    description:
        'Looking for 1 tennis partner for a fun doubles match. All levels welcome!',
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  AnnouncementModel(
    id: 'a4',
    reservation: CourtReservation(
      id: 'r_a4',
      courtId: 'c4',
      courtName: 'City Basketball Arena',
      hostId: 'p5',
      sport: SportType.basketball,
      date: DateTime.now().add(const Duration(days: 3)),
      startTime: '19:00',
      endTime: '20:00',
      durationHours: 1.0,
      totalPrice: 75,
      paymentOption: PaymentOption.payAtVenue,
      courtImageUrl:
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=700&q=80',
    ),
    host: const AppPlayer(
      id: 'p5',
      name: 'Omar Haddad',
      avatarInitials: 'OH',
      phone: '+216 55 100 006',
    ),
    playersNeeded: 6,
    description:
        '3v3 basketball — need 6 players total. Casual game, all welcome. Pay at venue.',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    requests: [
      JoinRequest(
        id: 'jr2',
        player: const AppPlayer(
          id: 'p6',
          name: 'Sana Khelifi',
          avatarInitials: 'SK',
          phone: '+216 55 100 001',
        ),
        message: 'Count me in!',
      ),
      JoinRequest(
        id: 'jr3',
        player: const AppPlayer(
          id: 'p1',
          name: 'Karim Jaziri',
          avatarInitials: 'KJ',
          phone: '+216 55 100 002',
        ),
        message: 'Ready to play',
      ),
    ],
  ),
  AnnouncementModel(
    id: 'a5',
    reservation: CourtReservation(
      id: 'r_a5',
      courtId: 'c1',
      courtName: 'Arena Sport Center',
      hostId: 'p1',
      sport: SportType.football,
      date: DateTime.now().add(const Duration(days: 2)),
      startTime: '21:00',
      endTime: '22:00',
      durationHours: 1.0,
      totalPrice: 90,
      paymentOption: PaymentOption.payNow,
      courtImageUrl:
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
    ),
    host: const AppPlayer(
      id: 'p1',
      name: 'Karim Jaziri',
      avatarInitials: 'KJ',
      phone: '+216 55 100 002',
    ),
    playersNeeded: 3,
    description:
        'Evening football — need 3 more. Intermediate level, competitive but friendly.',
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    requests: [
      JoinRequest(
        id: 'jr4',
        player: const AppPlayer(
          id: 'p2',
          name: 'Nadia Ben Salah',
          avatarInitials: 'NB',
          phone: '+216 55 100 003',
        ),
        message: 'Would love to join!',
      ),
      JoinRequest(
        id: 'jr5',
        player: const AppPlayer(
          id: 'p3',
          name: 'Mehdi Trabelsi',
          avatarInitials: 'MT',
          phone: '+216 55 100 004',
        ),
        message: 'I play centre-mid',
      ),
      JoinRequest(
        id: 'jr6',
        player: const AppPlayer(
          id: 'p6',
          name: 'Sana Khelifi',
          avatarInitials: 'SK',
          phone: '+216 55 100 001',
        ),
        message: 'Available and ready',
      ),
    ],
  ),
];
