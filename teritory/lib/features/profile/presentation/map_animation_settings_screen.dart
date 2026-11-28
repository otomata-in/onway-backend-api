import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/teritory_theme.dart';
import 'map_animation_catalog.dart';

/// Dedicated customization studio for the Profile World Map Odyssey animation.
class MapAnimationSettingsScreen extends StatefulWidget {
  const MapAnimationSettingsScreen({
    super.key,
    required this.initialSettings,
  });

  final MapAnimationSettings initialSettings;

  @override
  State<MapAnimationSettingsScreen> createState() =>
      _MapAnimationSettingsScreenState();
}

class _MapAnimationSettingsScreenState
    extends State<MapAnimationSettingsScreen> {
  late MapAnimationSettings _settings;
  final ValueNotifier<double> _previewPulse = ValueNotifier<double>(0.35);

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  void dispose() {
    _previewPulse.dispose();
    super.dispose();
  }

  void _update(MapAnimationSettings next) {
    setState(() => _settings = next);
    next.save();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_settings);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'Odyssey Map Studio',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(_settings),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_settings),
              child: Text(
                'Apply',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: TeritoryColors.primary,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Hero card featuring the Teritorian Odyssey Ship emblem
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF144F87),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF144F87).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  OdysseyShipButton(
                    isPlaying: true,
                    pulsePhase: _previewPulse,
                    accentColor: _settings.transition.accentColor,
                    onTap: () {},
                    onLongPress: () {},
                    size: 58,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _settings.transition.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _settings.transition.subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Speed & Auto-play controls
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: TeritoryColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded,
                          size: 18, color: TeritoryColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Transition Speed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: TeritoryColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_settings.speedMultiplier.toStringAsFixed(1)}×',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: TeritoryColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.speedMultiplier,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    activeColor: TeritoryColors.primary,
                    onChanged: (val) => _update(
                      _settings.copyWith(
                        speedMultiplier: double.parse(val.toStringAsFixed(1)),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _speedChip('0.7× Calm', 0.7),
                      _speedChip('1.0× Cruise', 1.0),
                      _speedChip('1.4× Brisk', 1.4),
                      _speedChip('1.8× Warp', 1.8),
                    ],
                  ),
                  const Divider(height: 22),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Auto-start Odyssey on Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Start sailing automatically when opening your footprint map',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: TeritoryColors.textSecondary,
                      ),
                    ),
                    value: _settings.autoStart,
                    activeTrackColor: TeritoryColors.primary,
                    onChanged: (val) =>
                        _update(_settings.copyWith(autoStart: val)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'CHOOSE TRANSITION ANIMATION (${MapTourTransition.values.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: TeritoryColors.textSecondary,
                ),
              ),
            ),

            for (final item in MapTourTransition.values)
              _TransitionCard(
                transition: item,
                selected: item == _settings.transition,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _update(_settings.copyWith(transition: item));
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _speedChip(String label, double value) {
    final isSelected = (_settings.speedMultiplier - value).abs() < 0.08;
    return GestureDetector(
      onTap: () => _update(_settings.copyWith(speedMultiplier: value)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F172A)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : TeritoryColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TransitionCard extends StatelessWidget {
  const _TransitionCard({
    required this.transition,
    required this.selected,
    required this.onTap,
  });

  final MapTourTransition transition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? transition.accentColor
                    : TeritoryColors.border,
                width: selected ? 2.0 : 1.0,
              ),
              color: selected
                  ? transition.accentColor.withValues(alpha: 0.05)
                  : Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: transition.accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    transition.icon,
                    color: transition.accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            transition.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: TeritoryColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: transition.accentColor
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              transition.badge,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: transition.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transition.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: TeritoryColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? transition.accentColor
                      : TeritoryColors.textSecondary.withValues(alpha: 0.4),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

