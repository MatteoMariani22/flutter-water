import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ink = Color(0xFF183B3A);
const _muted = Color(0xFF78908D);
const _mint = Color(0xFFB8F1DB);
const _teal = Color(0xFF54CFB0);
const _paper = Color(0xFFF5F8F5);
const _glassSizeMl = 250;
const _goals = [1500, 2000, 2500, 3000];

void main() {
  runApp(const AquaApp());
}

class AquaApp extends StatelessWidget {
  const AquaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'aqua',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _teal,
          surface: _paper,
          onSurface: _ink,
        ),
        fontFamily: 'Inter',
      ),
      home: const HydrationHome(),
    );
  }
}

class HydrationHome extends StatefulWidget {
  const HydrationHome({super.key});

  @override
  State<HydrationHome> createState() => _HydrationHomeState();
}

class _HydrationHomeState extends State<HydrationHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  int _consumedMl = 0;
  int _goalMl = 2000;
  bool _ready = false;

  double get _progress => (_consumedMl / _goalMl).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadToday();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadToday() async {
    final preferences = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final savedDate = preferences.getString('hydration_date');
    if (!mounted) return;
    setState(() {
      _consumedMl = savedDate == today
          ? preferences.getInt('hydration_ml') ?? 0
          : 0;
      _goalMl = preferences.getInt('hydration_goal') ?? 2000;
      _ready = true;
    });
    if (savedDate != today) {
      await preferences.setString('hydration_date', today);
      await preferences.setInt('hydration_ml', 0);
    }
  }

  Future<void> _save() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final succeeded = await preferences.setString(
            'hydration_date',
            _dateKey(DateTime.now()),
          ) &&
          await preferences.setInt('hydration_ml', _consumedMl) &&
          await preferences.setInt('hydration_goal', _goalMl);
      if (!succeeded && mounted) _showSaveError();
    } on Exception {
      if (mounted) _showSaveError();
    }
  }

  void _showSaveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't save your progress on this device.")),
    );
  }

  void _addGlass() {
    setState(() => _consumedMl += _glassSizeMl);
    _save();
  }

  void _undoGlass() {
    if (_consumedMl == 0) return;
    setState(() {
      _consumedMl = math.max(0, _consumedMl - _glassSizeMl);
    });
    _save();
  }

  void _changeGoal() {
    final currentIndex = _goals.indexOf(_goalMl);
    setState(() => _goalMl = _goals[(currentIndex + 1) % _goals.length]);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(now),
                  const SizedBox(height: 34),
                  Text(
                    '$greeting,',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'stay in your flow.',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 34,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildIntakeCard(),
                  const SizedBox(height: 18),
                  _buildMilestones(),
                  const SizedBox(height: 20),
                  _buildAddButton(),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton.icon(
                      onPressed: _consumedMl == 0 ? null : _undoGlass,
                      icon: const Icon(Icons.undo_rounded, size: 17),
                      label: const Text('Undo last glass'),
                      style: TextButton.styleFrom(
                        foregroundColor: _muted,
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime now) {
    final date = _formattedDate(now);
    final dateLabel = MediaQuery.sizeOf(context).width < 360
        ? date.split(', ').last
        : date;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: _ink,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.water_drop_rounded,
            color: _mint,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'aqua',
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
        const Spacer(),
        Text(
          dateLabel.toUpperCase(),
          style: const TextStyle(
            color: _muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildIntakeCard() {
    return Container(
      height: 234,
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF214B47), Color(0xFF153431)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.13),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -56,
            right: 72,
            child: Container(
              width: 154,
              height: 154,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _teal.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 21, 18, 19),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TODAY'S INTAKE",
                        style: TextStyle(
                          color: Color(0xFFB8D1CA),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: FittedBox(
                          key: ValueKey(_consumedMl),
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            (_consumedMl / 1000).toStringAsFixed(2),
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 46,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -2.2,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'liters',
                        style: TextStyle(
                          color: Color(0xFFB8D1CA),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildProgressTrack(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _encouragement,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _mint,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          InkWell(
                            key: const Key('dailyGoalButton'),
                            onTap: _changeGoal,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(_goalMl / 1000).toStringAsFixed(1)} L',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(
                                    Icons.expand_more_rounded,
                                    color: Color(0xFFB8D1CA),
                                    size: 15,
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
                const SizedBox(width: 8),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width < 360 ? 84 : 112,
                  height: 168,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) => CustomPaint(
                      painter: _GlassPainter(
                        progress: _progress,
                        phase: _waveController.value * math.pi * 2,
                      ),
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

  String get _encouragement {
    if (_progress >= 1) return 'Goal complete!';
    if (_consumedMl == 0) return 'Fresh start.';
    if (_progress >= 0.5) return 'Halfway there.';
    return 'Nice start!';
  }

  Widget _buildProgressTrack() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 5,
        child: Stack(
          children: [
            const ColoredBox(
              color: Color(0xFF496761),
              child: SizedBox.expand(),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeOutCubic,
              widthFactor: _progress,
              alignment: Alignment.centerLeft,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_mint, _teal]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestones() {
    final milestones = [_goalMl ~/ 4, _goalMl ~/ 2, _goalMl * 3 ~/ 4, _goalMl];
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EFEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR DAILY FLOW',
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(milestones.length, (index) {
              final reached = _consumedMl >= milestones[index];
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: reached ? const Color(0xFFDFF6EB) : _paper,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        reached
                            ? Icons.check_rounded
                            : Icons.water_drop_outlined,
                        color: reached ? _ink : const Color(0xFFB3C4BF),
                        size: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _compactAmount(milestones[index]),
                      style: TextStyle(
                        color: reached ? _ink : _muted,
                        fontSize: 11,
                        fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: FilledButton(
        key: const Key('addGlassButton'),
        onPressed: _ready ? _addGlass : null,
        style: FilledButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: _ink,
          disabledBackgroundColor: const Color(0xFFD5E4DD),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Add a glass',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _ink.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '250 ml',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  const _GlassPainter({required this.progress, required this.phase});

  final double progress;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final glass = Path()
      ..moveTo(size.width * 0.2, size.height * 0.07)
      ..lineTo(size.width * 0.8, size.height * 0.07)
      ..lineTo(size.width * 0.72, size.height * 0.91)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height,
        size.width * 0.28,
        size.height * 0.91,
      )
      ..close();
    final inside = Path()
      ..moveTo(size.width * 0.23, size.height * 0.105)
      ..lineTo(size.width * 0.77, size.height * 0.105)
      ..lineTo(size.width * 0.695, size.height * 0.885)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.968,
        size.width * 0.305,
        size.height * 0.885,
      )
      ..close();

    canvas.drawPath(
      glass,
      Paint()
        ..color = const Color(0xFFB6EBDD).withValues(alpha: 0.14)
        ..style = PaintingStyle.fill,
    );
    canvas.save();
    canvas.clipPath(inside);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * (1 - progress),
        size.width,
        size.height * progress,
      ),
      Paint()..color = const Color(0xFF62DCC0).withValues(alpha: 0.18),
    );
    if (progress > 0) {
      final waterLine = size.height * (1 - progress);
      final wave = Path()..moveTo(0, waterLine);
      for (var x = 0.0; x <= size.width; x += 2) {
        final y =
            waterLine +
            math.sin((x / size.width * math.pi * 2) + phase) * 3.2;
        wave.lineTo(x, y);
      }
      wave
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        wave,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF8CE7CE), Color(0xFF4CC9B0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Offset.zero & size),
      );
    }
    canvas.restore();

    canvas.drawPath(
      glass,
      Paint()
        ..color = const Color(0xFFC3E8DE).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.52)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.29, size.height * 0.2),
      Offset(size.width * 0.255, size.height * 0.57),
      shine,
    );
    canvas.drawLine(
      Offset(size.width * 0.71, size.height * 0.14),
      Offset(size.width * 0.705, size.height * 0.22),
      shine,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.phase != phase;
}

String _formattedDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _compactAmount(int ml) =>
    ml >= 1000 ? '${(ml / 1000).toStringAsFixed(ml % 1000 == 0 ? 0 : 1)} L' : '$ml ml';
