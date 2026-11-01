import 'package:flutter/material.dart';

import '../Core/Theme/app_theme.dart';
import '../Core/Theme/app_tokens.dart';
import 'booking_components.dart';
import 'Buttons/app_buttons.dart';
import 'Cards/app_card.dart';
import 'feedback_components.dart';
import 'Inputs/app_text_field.dart';
import 'navigation_components.dart';

class DesignSystemPreviewScreen extends StatelessWidget {
  const DesignSystemPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Night Match component preview')),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final panels = [
          _ThemePreviewPanel(title: 'Light mode', theme: AppTheme.light),
          _ThemePreviewPanel(title: 'Dark mode', theme: AppTheme.dark),
        ];
        if (constraints.maxWidth >= 900) {
          return SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final panel in panels)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: panel,
                    ),
                  ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          itemCount: panels.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, index) => panels[index],
        );
      },
    ),
  );
}

class _ThemePreviewPanel extends StatefulWidget {
  const _ThemePreviewPanel({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  State<_ThemePreviewPanel> createState() => _ThemePreviewPanelState();
}

class _ThemePreviewPanelState extends State<_ThemePreviewPanel> {
  final _textController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeSlotState _selectedSlot = TimeSlotState.selected;
  int _selectedNav = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: widget.theme,
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sporta Night Match · Sora headlines · Inter body',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionLabel(context, 'Typography and color'),
                Text(
                  'Find your next game',
                  style: theme.textTheme.displaySmall,
                ),
                Text(
                  'Reserve a court, meet your team, and play.',
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  'كرة القدم تجمعنا — احجز ملعبك اليوم',
                  style: theme.textTheme.bodyMedium,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: AppSpacing.md),
                _sectionLabel(context, 'Sport categories'),
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      SportCategoryCircle(
                        label: 'Football',
                        icon: Icons.sports_soccer_rounded,
                        selected: true,
                        onTap: () {},
                      ),
                      SportCategoryCircle(
                        label: 'Padel',
                        icon: Icons.sports_tennis_rounded,
                        selected: false,
                        onTap: () {},
                      ),
                      SportCategoryCircle(
                        label: 'Basketball',
                        icon: Icons.sports_basketball_rounded,
                        selected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _sectionLabel(context, 'Venue hero card'),
                Center(
                  child: VenueCard(
                    name: 'Stadium Central',
                    sport: 'Football',
                    rating: '4.8',
                    distance: '1.2 km away',
                    price: '45 TND',
                    earliestSlot: '18:30',
                    photoProvider: const AssetImage(
                      'assets/admin_illustration.jpg',
                    ),
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionLabel(context, 'Date rail and time slots'),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      return DateRailItem(
                        date: date,
                        isToday: index == 0,
                        selected:
                            date.year == _selectedDate.year &&
                            date.month == _selectedDate.month &&
                            date.day == _selectedDate.day,
                        onTap: () => setState(() => _selectedDate = date),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    TimeSlotButton(
                      label: '17:00',
                      state: TimeSlotState.available,
                      onPressed: () => setState(
                        () => _selectedSlot = TimeSlotState.available,
                      ),
                    ),
                    TimeSlotButton(
                      label: '18:30',
                      state: _selectedSlot,
                      onPressed: () => setState(
                        () => _selectedSlot = TimeSlotState.selected,
                      ),
                    ),
                    const TimeSlotButton(
                      label: '20:00',
                      state: TimeSlotState.unavailable,
                      onPressed: null,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionLabel(context, 'Reservation states'),
                const Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ReservationStatusBadge(status: ReservationStatus.pending),
                    ReservationStatusBadge(status: ReservationStatus.confirmed),
                    ReservationStatusBadge(status: ReservationStatus.cancelled),
                    ReservationStatusBadge(status: ReservationStatus.refunded),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionLabel(context, 'Buttons and fields'),
                AppPrimaryButton(
                  label: 'Book this court',
                  icon: Icons.sports_soccer_rounded,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.xs),
                AppSecondaryButton(
                  label: 'View details',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {},
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppTextButton(
                    label: 'See all venues',
                    onPressed: () {},
                  ),
                ),
                AppTextField(
                  controller: _textController,
                  label: 'Search venues',
                  hint: 'Enter a venue or area',
                  prefixIcon: Icons.search_rounded,
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionLabel(context, 'Booking bar and navigation'),
                const StickyBookingBar(
                  priceLabel: '45 TND',
                  onBook: _previewNoop,
                  enabled: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                FloatingBottomNav(
                  destinations: const [
                    PlayerNavDestination(
                      label: 'Home',
                      icon: Icons.home_rounded,
                    ),
                    PlayerNavDestination(
                      label: 'Explore',
                      icon: Icons.explore_rounded,
                    ),
                    PlayerNavDestination(
                      label: 'Bookings',
                      icon: Icons.sports_soccer_rounded,
                    ),
                  ],
                  selectedIndex: _selectedNav,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedNav = index),
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionLabel(context, 'Cards and dashboard stats'),
                const DashboardStatCard(
                  label: 'Bookings today',
                  value: '12',
                  icon: Icons.calendar_month_rounded,
                  supportingText: '+3 this week',
                ),
                const SizedBox(height: AppSpacing.sm),
                SectionHeader(
                  title: 'Today’s schedule',
                  subtitle: '12 bookings across 4 courts',
                  actionLabel: 'See all',
                  onAction: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Text(
                    'Reusable surface card',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionLabel(context, 'Loading, empty, and error states'),
                const LoadingSkeleton(height: 18),
                const SizedBox(height: AppSpacing.xs),
                const LoadingSkeleton(width: 180, height: 18),
                const SizedBox(height: AppSpacing.sm),
                const EmptyState(
                  title: 'No bookings yet',
                  message: 'Your next game starts with a free time slot.',
                ),
                const SizedBox(height: AppSpacing.sm),
                ErrorState(
                  title: 'Could not load venues',
                  message: 'Check your connection and try again.',
                  onRetry: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSecondaryButton(
                  label: 'Preview bottom sheet',
                  onPressed: () => AppBottomSheet.show<void>(
                    context: context,
                    title: 'Choose a sport',
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SportChip(
                          label: 'Football',
                          icon: Icons.sports_soccer_rounded,
                          selected: true,
                        ),
                        SizedBox(height: AppSpacing.xs),
                        SportChip(
                          label: 'Padel',
                          icon: Icons.sports_tennis_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _sectionLabel(BuildContext context, String label) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.secondary,
      ),
    ),
  );
}

void _previewNoop() {}
