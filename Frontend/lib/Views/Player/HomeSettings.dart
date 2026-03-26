// home_settings.dart — Views/Player/home_settings.dart
// Profile page: avatar hero, 3 tabs (Profile / Bookings / Announcements)
// Phone number toast auto-dismisses on open if no phone set

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SAMPLE DATA — swap for real models/API later
// ─────────────────────────────────────────────────────────────────────────────
class _BookingHistory {
  final String court, date, time, image, status;
  final int price;
  const _BookingHistory({
    required this.court,
    required this.date,
    required this.time,
    required this.image,
    required this.status,
    required this.price,
  });
}

class _MyAnnouncement {
  final String court, date, time, description;
  final SportType sport;
  final int playersNeeded, joined;
  const _MyAnnouncement({
    required this.court,
    required this.date,
    required this.time,
    required this.description,
    required this.sport,
    required this.playersNeeded,
    required this.joined,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SETTINGS PAGE
// ─────────────────────────────────────────────────────────────────────────────
class HomeSettings extends StatefulWidget {
  final String username;
  final String email;
  final String? phone; // null → trigger phone toast
  final String? avatarPath; // local asset or http url
  const HomeSettings({
    super.key,
    required this.username,
    required this.email,
    this.phone,
    this.avatarPath,
  });
  @override
  State<HomeSettings> createState() => _HomeSettingsState();
}

class _HomeSettingsState extends State<HomeSettings>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── phone spotlight ──────────────────────────────────────────────────────────
  bool _showPhoneSpotlight = false;

  // ── page entry animation ────────────────────────────────────────────────────
  late AnimationController _entryAnim;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  // ── phone focus ─────────────────────────────────────────────────────────────
  final FocusNode _phoneFocus = FocusNode();

  // ── editable controllers ────────────────────────────────────────────────────
  late TextEditingController _usernameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;

  // sample data
  final _bookings = const [
    _BookingHistory(
      court: 'Arena Sport Center',
      date: 'Tomorrow',
      time: '20:00 – 21:00',
      image: 'assets/sportcenter.jpg',
      status: 'Confirmed',
      price: 100,
    ),
  ];

  final _announcements = const <_MyAnnouncement>[];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);

    _usernameCtrl = TextEditingController(text: widget.username);
    _phoneCtrl = TextEditingController(text: widget.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.email);

    // Entry animation
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryFade = CurvedAnimation(
      parent: _entryAnim,
      curve: Curves.easeOut,
    ).drive(Tween(begin: 0.0, end: 1.0));
    _entrySlide = CurvedAnimation(
      parent: _entryAnim,
      curve: Curves.easeOutCubic,
    ).drive(Tween(begin: const Offset(0, 0.06), end: Offset.zero));
    _entryAnim.forward();

    // Show phone spotlight if no phone set
    if (widget.phone == null || widget.phone!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showPhoneSpotlight = true);
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _phoneFocus.dispose();
    _entryAnim.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: Stack(
            children: [
              Column(
                children: [
                  // ── Hero header ────────────────────────────────────────────────
                  _buildHeader(),
                  // ── Tab body ───────────────────────────────────────────────────
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _ProfileTab(
                          usernameCtrl: _usernameCtrl,
                          phoneCtrl: _phoneCtrl,
                          emailCtrl: _emailCtrl,
                          avatarPath: widget.avatarPath,
                          phoneFocus: _phoneFocus,
                          showSpotlight: _showPhoneSpotlight,
                          onDismissSpotlight: () =>
                              setState(() => _showPhoneSpotlight = false),
                        ),
                        _BookingsTab(bookings: _bookings),
                        _AnnouncementsTab(announcements: _announcements),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF002526), Color(0xFF005D5E), Color(0xFF00837F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // top row: back + language
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Language selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🇬🇧', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Avatar + username + gear
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with Hero
                  Hero(
                    tag: 'profile_avatar',
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: widget.avatarPath != null
                          ? _buildAvatarImage(widget.avatarPath!)
                          : Center(
                              child: Text(
                                widget.username.isNotEmpty
                                    ? widget.username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Settings gear
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tab bar
            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.5),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              indicator: const BoxDecoration(),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  icon: Icon(Icons.person_outline_rounded, size: 18),
                  text: 'Profile',
                ),
                Tab(
                  icon: Icon(Icons.calendar_month_outlined, size: 18),
                  text: 'Bookings',
                ),
                Tab(
                  icon: Icon(Icons.campaign_outlined, size: 18),
                  text: 'Announcements',
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: Text(
          widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatefulWidget {
  final TextEditingController usernameCtrl, phoneCtrl, emailCtrl;
  final String? avatarPath;
  final FocusNode phoneFocus;
  final bool showSpotlight;
  final VoidCallback onDismissSpotlight;
  const _ProfileTab({
    required this.usernameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    this.avatarPath,
    required this.phoneFocus,
    this.showSpotlight = false,
    required this.onDismissSpotlight,
  });
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Profile saved ✓',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    final listView = ListView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, navH + 24),
      children: [
        // ── Avatar change ────────────────────────────────────────────────────
        Center(
          child: Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimary.withOpacity(0.08),
                  border: Border.all(
                    color: kPrimary.withOpacity(0.25),
                    width: 2.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.avatarPath != null
                    ? Image.asset(
                        widget.avatarPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initials(widget.usernameCtrl.text),
                      )
                    : _initials(widget.usernameCtrl.text),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Username ──────────────────────────────────────────────────────────
        _FieldLabel('Username'),
        const SizedBox(height: 6),
        _ProfileField(
          ctrl: widget.usernameCtrl,
          icon: Icons.person_outline_rounded,
          hint: 'Your username',
        ),
        const SizedBox(height: 16),

        // ── Phone ─────────────────────────────────────────────────────────────
        _FieldLabel('Phone Number'),
        const SizedBox(height: 6),
        _PhoneField(ctrl: widget.phoneCtrl, focusNode: widget.phoneFocus),
        const SizedBox(height: 16),

        // ── Email ─────────────────────────────────────────────────────────────
        _FieldLabel('Email'),
        const SizedBox(height: 6),
        _ProfileField(
          ctrl: widget.emailCtrl,
          icon: Icons.email_outlined,
          hint: 'Your email',
          type: TextInputType.emailAddress,
          readOnly: true,
        ),
        const SizedBox(height: 32),

        // ── Save ──────────────────────────────────────────────────────────────
        GestureDetector(
          onTap: _saving ? null : _save,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _saving
                    ? [kPrimary.withOpacity(0.4), kPrimary.withOpacity(0.4)]
                    : [
                        const Color(0xFF004748),
                        kPrimary,
                        const Color(0xFF007677),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _saving
                  ? []
                  : [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );

    // ── Spotlight overlay ────────────────────────────────────────────────────
    if (!widget.showSpotlight) return listView;

    return GestureDetector(
      onTap: widget.onDismissSpotlight,
      child: Stack(
        children: [
          // Scrollable content underneath (non-interactive while spotlight active)
          AbsorbPointer(child: listView),

          // Full-screen dark scrim
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.72)),
          ),

          // The phone field card — lifted and glowing in the centre
          Positioned(
            left: 20,
            right: 20,
            top: MediaQuery.of(context).size.height * 0.22,
            child: GestureDetector(
              onTap: () {}, // don't dismiss when tapping the card
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  // Glow ring behind the card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.18),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.08),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: _PhoneField(
                      ctrl: widget.phoneCtrl,
                      focusNode: widget.phoneFocus,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Big bold message
                  const Text(
                    'Please add your phone number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please add your phone number in your profile to make a booking',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initials(String name) => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        color: kPrimary,
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: kTextMid,
      letterSpacing: 0.2,
    ),
  );
}

class _ProfileField extends StatelessWidget {
  final TextEditingController ctrl;
  final IconData icon;
  final String hint;
  final TextInputType type;
  final bool readOnly;
  const _ProfileField({
    required this.ctrl,
    required this.icon,
    required this.hint,
    this.type = TextInputType.text,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: readOnly ? kBg : const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.black.withOpacity(0.06)),
    ),
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Icon(icon, size: 18, color: kTextMid),
        ),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            readOnly: readOnly,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: readOnly ? kTextMid : kTextDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: kTextLight),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (!readOnly)
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.edit_outlined, size: 15, color: kTextLight),
          ),
      ],
    ),
  );
}

// ── Phone field — flag + code + input, focus-aware ───────────────────────────
class _PhoneField extends StatefulWidget {
  final TextEditingController ctrl;
  final FocusNode? focusNode;
  const _PhoneField({required this.ctrl, this.focusNode});
  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = widget.focusNode?.hasFocus ?? false);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    decoration: BoxDecoration(
      color: _focused ? Colors.white : const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: _focused
            ? kAmber.withOpacity(0.6)
            : Colors.black.withOpacity(0.06),
        width: _focused ? 1.8 : 1.0,
      ),
      boxShadow: _focused
          ? [
              BoxShadow(
                color: kAmber.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ]
          : null,
    ),
    child: Row(
      children: [
        // Flag + code
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.black.withOpacity(0.07)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇹🇳', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 5),
              Text(
                '+216',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: kTextMid,
              ),
            ],
          ),
        ),
        // Number input
        Expanded(
          child: TextField(
            controller: widget.ctrl,
            focusNode: widget.focusNode,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kTextDark,
            ),
            decoration: const InputDecoration(
              hintText: 'Phone Number',
              hintStyle: TextStyle(color: kTextLight),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 14),
          child: Icon(Icons.edit_outlined, size: 15, color: kTextLight),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKINGS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _BookingsTab extends StatelessWidget {
  final List<_BookingHistory> bookings;
  const _BookingsTab({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    if (bookings.isEmpty)
      return _EmptyState(
        Icons.calendar_month_outlined,
        'No bookings yet',
        'Your booking history will appear here',
      );

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 20),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final b = bookings[i];
        final statusColor = b.status == 'Confirmed'
            ? kGreen
            : b.status == 'Completed'
            ? kPrimary
            : kRed;
        return Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: kElevation,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 72,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _AssetImage(b.image),
                      Container(color: Colors.black.withOpacity(0.18)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.court,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${b.date}  ·  ${b.time}',
                        style: const TextStyle(fontSize: 11, color: kTextMid),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${b.price} DT',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    b.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANNOUNCEMENTS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _AnnouncementsTab extends StatelessWidget {
  final List<_MyAnnouncement> announcements;
  const _AnnouncementsTab({required this.announcements});

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    if (announcements.isEmpty)
      return _EmptyState(
        Icons.campaign_outlined,
        'No announcements yet',
        'Announcements you post will appear here',
      );

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 20),
      itemCount: announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final a = announcements[i];
        final sc = a.sport.color;
        final spotsLeft = a.playersNeeded - a.joined;
        return Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: kElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: sc.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a.sport.icon, color: sc, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.court,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kTextDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${a.date}  ·  ${a.time}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kTextMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: spotsLeft > 0
                            ? kGreen.withOpacity(0.09)
                            : kRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (spotsLeft > 0 ? kGreen : kRed).withOpacity(
                            0.25,
                          ),
                        ),
                      ),
                      child: Text(
                        spotsLeft > 0 ? '$spotsLeft spots left' : 'Full',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: spotsLeft > 0 ? kGreen : kRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextMid,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _AnnounceStat(
                          Icons.people_rounded,
                          '${a.playersNeeded}',
                          'Needed',
                          sc,
                        ),
                        const SizedBox(width: 10),
                        _AnnounceStat(
                          Icons.check_circle_outline_rounded,
                          '${a.joined}',
                          'Joined',
                          kGreen,
                        ),
                        const SizedBox(width: 10),
                        _AnnounceStat(
                          Icons.hourglass_top_rounded,
                          '$spotsLeft',
                          'Left',
                          kAmber,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: kRed.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kRed.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 13,
                                  color: kRed,
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Remove',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: kRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnnounceStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _AnnounceStat(this.icon, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 9, color: kTextMid)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  const _EmptyState(this.icon, this.title, this.sub);
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: kTextLight.withOpacity(0.5)),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sub,
          style: const TextStyle(fontSize: 13, color: kTextMid),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _AssetImage extends StatelessWidget {
  final String path;
  const _AssetImage(this.path);
  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: kPrimary.withOpacity(0.08)),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Container(color: kPrimary.withOpacity(0.08)),
    );
  }
}
