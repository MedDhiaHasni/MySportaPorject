import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Widgets/Lists/grid_painter.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/sample_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// courts_page.dart
// Includes: Courts + CreateCourtPage
// ─────────────────────────────────────────────────────────────────────────────


List<BoxShadow> get _shadow => [
  BoxShadow(
    color: Colors.black.withOpacity(0.055),
    blurRadius: 18,
    offset: const Offset(0, 4),
  ),
  BoxShadow(
    color: Colors.black.withOpacity(0.022),
    blurRadius: 4,
    offset: const Offset(0, 1),
  ),
];
BoxDecoration kCard$(double r) => BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(r),
  boxShadow: _shadow,
);

// ─────────────────────────────────────────────────────────────────────────────
// COURTS PAGE
// ─────────────────────────────────────────────────────────────────────────────
class Courts extends StatefulWidget {
  const Courts({super.key});
  @override
  State<Courts> createState() => _CourtsState();
}

class _CourtsState extends State<Courts> {
  List<_CourtData> _courts = [
    _CourtData(
      '1',
      'Court Alpha',
      'Football',
      'Premium 5-a-side turf with LED floodlights and pro-grade grass.',
      'available',
      true,
      '80 TND/h',
    ),
    _CourtData(
      '2',
      'Court Beta',
      'Padel',
      'Panoramic glass padel court — tournament-certified and AC.',
      'in_use',
      false,
      '60 TND/h',
    ),
    _CourtData(
      '3',
      'Court Gamma',
      'Basketball',
      'Full-size indoor court with suspended hardwood floor and AC.',
      'maintenance',
      false,
      '70 TND/h',
    ),
    _CourtData(
      '4',
      'Court Delta',
      'Tennis',
      'Red clay surface with floodlights — ideal for serious players.',
      'available',
      true,
      '50 TND/h',
    ),
  ];

  void _openCreate({_CourtData? court}) async {
    final result = await Navigator.push<_CourtData>(
      context,
      MaterialPageRoute(builder: (_) => CreateCourtPage(court: court)),
    );
    if (result != null) {
      setState(() {
        final idx = _courts.indexWhere((c) => c.id == result.id);
        if (idx != -1)
          _courts[idx] = result;
        else
          _courts.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navBarH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final available = _courts.where((c) => c.status == 'available').length;
    final inUse = _courts.where((c) => c.status == 'in_use').length;
    final maintenance = _courts.where((c) => c.status == 'maintenance').length;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Header ──
          Container(
            color: kCard,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Courts',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: kTextDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                '${_courts.length} courts total',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kTextMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openCreate(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'New Court',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 20,
                            color: kTextMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status summary strip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        _StatusChip('$available Available', kGreen),
                        const SizedBox(width: 8),
                        _StatusChip('$inUse In Use', kOrange),
                        const SizedBox(width: 8),
                        _StatusChip('$maintenance Maintenance', kRed),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── List ──
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, navBarH + 16),
              itemCount: _courts.length,
              itemBuilder: (_, i) => _CourtCard(
                court: _courts[i],
                onToggle: (v) => setState(() {
                  _courts[i] = _courts[i].copyWith(
                    available: v,
                    status: v ? 'available' : 'maintenance',
                  );
                }),
                onEdit: () => _openCreate(court: _courts[i]),
                onDelete: () => setState(() => _courts.removeAt(i)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Court card
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final _CourtData court;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit, onDelete;
  const _CourtCard({
    required this.court,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = court;
    // Status
    late Color sc;
    late String sl;
    switch (c.status) {
      case 'available':
        sc = kGreen;
        sl = 'Available';
        break;
      case 'in_use':
        sc = kOrange;
        sl = 'In Use';
        break;
      default:
        sc = kRed;
        sl = 'Maintenance';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: kCard$(22),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Banner ──
          Container(
            height: 118,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: c.gradientColors,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: GridPainter())),
                Positioned(
                  right: 16,
                  top: 12,
                  child: Text(
                    c.sportEmoji,
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          c.price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(top: 12, right: 16, child: _StatusBadge(sl, sc)),
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SportTag(c.sport, c.sportColor),
                    const Spacer(),
                    Text(
                      c.available ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.available ? kGreen : kTextLight,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Transform.scale(
                      scale: 0.78,
                      child: Switch(
                        value: c.available,
                        onChanged: onToggle,
                        activeColor: kPrimary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextMid,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _OutlineBtn(
                        Icons.edit_outlined,
                        'Edit Court',
                        kPrimary,
                        onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _IconBtn(
                      Icons.delete_outline_rounded,
                      kRed.withOpacity(0.07),
                      kRed,
                      onDelete,
                    ),
                    const SizedBox(width: 6),
                    _IconBtn(
                      Icons.visibility_outlined,
                      kPrimary.withOpacity(0.07),
                      kPrimary,
                      () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE / EDIT COURT PAGE
// ─────────────────────────────────────────────────────────────────────────────
class CreateCourtPage extends StatefulWidget {
  final _CourtData? court;
  const CreateCourtPage({super.key, this.court});
  @override
  State<CreateCourtPage> createState() => _CreateCourtPageState();
}

class _CreateCourtPageState extends State<CreateCourtPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  String _sport = 'Football';
  bool _available = true;
  bool _photo = false;

  final _sports = ['Football', 'Padel', 'Tennis', 'Basketball', 'Multi-sport'];
  final _sportEmojis = {
    'Football': '⚽',
    'Padel': '🎾',
    'Tennis': '🎾',
    'Basketball': '🏀',
    'Multi-sport': '🏟',
  };

  bool get _isEdit => widget.court != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final c = widget.court!;
      _nameCtrl.text = c.name;
      _descCtrl.text = c.description;
      _priceCtrl.text = c.price.replaceAll(' TND/h', '');
      _sport = c.sport;
      _available = c.available;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Header ──
          Container(
            color: kCard,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 14, 14),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: kTextDark,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isEdit ? 'Edit Court' : 'New Court',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kAmber,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Text(
                        'Draft',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                // Photo upload
                GestureDetector(
                  onTap: () => setState(() => _photo = !_photo),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    height: 148,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: _photo
                          ? const LinearGradient(
                              colors: [Color(0xFF002E2F), kPrimary],
                            )
                          : null,
                      color: _photo ? null : kCard,
                      boxShadow: _shadow,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: _photo
                        ? Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(painter: GridPainter()),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '🏟',
                                      style: TextStyle(fontSize: 46),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Tap to change photo',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: kPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Upload Court Photo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: kTextDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Tap to browse gallery',
                                style: TextStyle(fontSize: 11, color: kTextMid),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Details form
                Container(
                  decoration: kCard$(20),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Court Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FormField(
                        'Court Name',
                        'e.g. Court Alpha',
                        _nameCtrl,
                        Icons.sports_tennis_outlined,
                      ),
                      const SizedBox(height: 14),
                      // Sport dropdown
                      _FieldLabel('Sport Type'),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sport,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: kTextMid,
                              size: 20,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: kTextDark,
                            ),
                            items: _sports
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Row(
                                      children: [
                                        Text(
                                          _sportEmojis[s] ?? '🏅',
                                          style: const TextStyle(fontSize: 17),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(s),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _sport = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FormField(
                        'Description',
                        'Describe this court…',
                        _descCtrl,
                        Icons.description_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              'Price / Hour',
                              '60',
                              _priceCtrl,
                              Icons.payments_outlined,
                              suffix: 'TND',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FormField(
                              'Capacity',
                              '10',
                              _capCtrl,
                              Icons.people_outline,
                              suffix: 'players',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Availability card
                Container(
                  decoration: kCard$(20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (_available ? kGreen : kRed).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          _available
                              ? Icons.check_circle_outlined
                              : Icons.cancel_outlined,
                          color: _available ? kGreen : kRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _available
                                  ? 'Court Available'
                                  : 'Court Unavailable',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                              ),
                            ),
                            Text(
                              _available
                                  ? 'Players can book this court'
                                  : 'No bookings accepted',
                              style: const TextStyle(
                                fontSize: 11,
                                color: kTextMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _available,
                        onChanged: (v) => setState(() => _available = v),
                        activeColor: kPrimary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Save button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF004748),
                          kPrimary,
                          Color(0xFF007677),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isEdit ? 'Save Changes' : 'Create Court',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _SportTag extends StatelessWidget {
  final String sport;
  final Color color;
  const _SportTag(this.sport, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      sport,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback fn;
  const _OutlineBtn(this.icon, this.label, this.color, this.fn);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: fn,
    child: Container(
      height: 38,
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(11),
        color: color.withOpacity(0.04),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color bg, fg;
  final VoidCallback fn;
  const _IconBtn(this.icon, this.bg, this.fg, this.fn);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: fn,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 17, color: fg),
    ),
  );
}

class _FormField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final IconData icon;
  final int maxLines;
  final String? suffix;
  const _FormField(
    this.label,
    this.hint,
    this.ctrl,
    this.icon, {
    this.maxLines = 1,
    this.suffix,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label),
      const SizedBox(height: 5),
      Container(
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(13),
        ),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: kTextDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kTextLight, fontSize: 13),
            prefixIcon: Icon(icon, size: 17, color: kTextMid),
            suffixText: suffix,
            suffixStyle: const TextStyle(fontSize: 12, color: kTextMid),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
        ),
      ),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: kTextMid,
    ),
  );
}

// ── Model ─────────────────────────────────────────────────────────────────────
class _CourtData {
  final String id, name, sport, description, status, price;
  final bool available;
  const _CourtData(
    this.id,
    this.name,
    this.sport,
    this.description,
    this.status,
    this.available,
    this.price,
  );

  _CourtData copyWith({String? status, bool? available}) => _CourtData(
    id,
    name,
    sport,
    description,
    status ?? this.status,
    available ?? this.available,
    price,
  );

  String get sportEmoji =>
      const {
        'Football': '⚽',
        'Padel': '🎾',
        'Basketball': '🏀',
        'Tennis': '🎾',
        'Multi-sport': '🏟',
      }[sport] ??
      '🏅';
  Color get sportColor =>
      const {
        'Football': kGreen,
        'Padel': kPurple,
        'Basketball': kOrange,
        'Tennis': kPrimary,
        'Multi-sport': kAmber,
      }[sport] ??
      kPrimary;
  List<Color> get gradientColors =>
      const {
        'Football': [Color(0xFF0F2E0F), Color(0xFF1A5C1A)],
        'Padel': [Color(0xFF1E0A38), Color(0xFF4C1D7A)],
        'Basketball': [Color(0xFF2E1200), Color(0xFF7A3410)],
        'Tennis': [Color(0xFF002630), Color(0xFF005D5E)],
        'Multi-sport': [Color(0xFF1A1200), Color(0xFF5C4000)],
      }[sport] ??
      [kPrimary, kPrimary];
}

