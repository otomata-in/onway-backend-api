import 'package:flutter/material.dart';

import '../../../core/models/flag_style.dart';
import '../../../core/theme/flag_style_catalog.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../../core/widgets/flag/teritory_flag.dart';
import 'flag_studio_screen.dart';

/// A review surface for the flag language itself, not the full studio.
///
/// It renders the real shared painter at every size and for every catalog
/// entry, so the visual system can be judged before it is wired into the map,
/// profile and ceremony. Nothing here saves: the editable Flag Studio is phase
/// 3. Open it with [FlagPreviewScreen.show] (it has no route in phase 1).
class FlagPreviewScreen extends StatefulWidget {
  final FlagStyle initialStyle;

  const FlagPreviewScreen({super.key, this.initialStyle = FlagStyle.fallback});

  static Future<void> show(BuildContext context, {FlagStyle? initialStyle}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlagPreviewScreen(
          initialStyle: initialStyle ?? FlagStyle.fallback,
        ),
      ),
    );
  }

  @override
  State<FlagPreviewScreen> createState() => _FlagPreviewScreenState();
}

class _FlagPreviewScreenState extends State<FlagPreviewScreen> {
  late FlagStyle _style = FlagStyleCatalog.normalize(widget.initialStyle);

  void _select(FlagStyle style) => setState(() => _style = style);

  @override
  Widget build(BuildContext context) {
    final theme = FlagStyleCatalog.themeFor(_style.theme);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        title: const Text('Flag Preview'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _hero(theme),
          const SizedBox(height: 28),
          _sectionTitle('One flag, every size'),
          const SizedBox(height: 12),
          _sizeRow(),
          const SizedBox(height: 28),
          _sectionTitle('Presets'),
          const SizedBox(height: 12),
          _presets(),
          const SizedBox(height: 28),
          _sectionTitle('Themes'),
          const SizedBox(height: 12),
          _themeGrid(),
          const SizedBox(height: 28),
          _sectionTitle('Patterns'),
          const SizedBox(height: 12),
          _patternGrid(),
          const SizedBox(height: 28),
          _sectionTitle('Shapes'),
          const SizedBox(height: 12),
          _shapeGrid(),
          const SizedBox(height: 28),
          _sectionTitle('Emblems'),
          const SizedBox(height: 12),
          _emblemGrid(),
          const SizedBox(height: 28),
          _sectionTitle('Motion'),
          const SizedBox(height: 12),
          _motionGrid(),
          const SizedBox(height: 28),
          _sectionTitle('Speed'),
          const SizedBox(height: 12),
          _speedRow(),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () async {
                final saved = await FlagStudioScreen.show(
                  context,
                  initialStyle: _style,
                );
                if (saved != null) _select(saved);
              },
              icon: const Icon(Icons.brush_rounded, size: 18),
              label: const Text('Open the Flag Studio'),
              style: FilledButton.styleFrom(
                backgroundColor: _styleAccent(),
                foregroundColor: FlagStyleCatalog.foregroundOn(_styleAccent()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'This review screen is dev-only. The Flag Studio saves the real '
            'signature, and staked flags keep the style they were born with.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(FlagThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: RadialGradient(
          center: const Alignment(0.2, -0.4),
          radius: 1.4,
          colors: [
            theme.primary.withValues(alpha: 0.28),
            const Color(0xFF111C31),
          ],
        ),
        border: Border.all(color: theme.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          AnimatedTeritoryFlag(style: _style, width: 260),
          const SizedBox(height: 18),
          Text(
            theme.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${FlagStyleCatalog.patternFor(_style.pattern).label} · '
            '${FlagStyleCatalog.shapeFor(_style.shape).label} · '
            '${FlagStyleCatalog.emblemFor(_style.emblem).label} · '
            '${FlagStyleCatalog.motionFor(_style.motion).label}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12.5,
            ),
          ),
          if (_style.hasCustomColor) ...[
            const SizedBox(height: 10),
            _swatch(_style.color!, label: 'Custom ${_style.color}'),
          ],
        ],
      ),
    );
  }

  Widget _sizeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _sizeSample(96, 'Detail'),
        const SizedBox(width: 18),
        _sizeSample(56, 'Pin'),
        const SizedBox(width: 18),
        _sizeSample(34, 'Tiny'),
      ],
    );
  }

  Widget _sizeSample(double width, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeritoryFlag(style: _style, width: width, phase: 0.18),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _presets() {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FlagStyleCatalog.presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final preset = FlagStyleCatalog.presets[index];
          final selected = preset.style == _style;
          return GestureDetector(
            onTap: () => _select(preset.style),
            child: Container(
              width: 104,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? _styleAccent().withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? _styleAccent()
                      : Colors.white.withValues(alpha: 0.10),
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: TeritoryFlag(
                        style: preset.style,
                        width: 82,
                        showPole: false,
                        phase: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preset.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _themeGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: FlagStyleCatalog.themes.map((theme) {
        final selected = theme.id == _style.theme;
        final style = _style.copyWith(theme: theme.id, color: null);
        return _tile(
          selected: selected,
          label: theme.label,
          onTap: () => _select(style),
          width: 150,
          child: TeritoryFlag(style: style, width: 116, showPole: false, phase: 0.1),
        );
      }).toList(),
    );
  }

  Widget _patternGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: FlagStyleCatalog.patterns.map((pattern) {
        final selected = pattern.id == _style.pattern;
        return _tile(
          selected: selected,
          label: pattern.label,
          onTap: () => _select(_style.copyWith(pattern: pattern.id)),
          width: 104,
          child: TeritoryFlag(
            style: _style.copyWith(pattern: pattern.id),
            width: 84,
            showPole: false,
            phase: 0.12,
          ),
        );
      }).toList(),
    );
  }

  Widget _shapeGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: FlagStyleCatalog.shapes.map((shape) {
        final selected = shape.id == _style.shape;
        return _tile(
          selected: selected,
          label: shape.label,
          onTap: () => _select(_style.copyWith(shape: shape.id)),
          width: 150,
          child: TeritoryFlag(
            style: _style.copyWith(shape: shape.id),
            width: 96,
            phase: 0.1,
          ),
        );
      }).toList(),
    );
  }

  Widget _emblemGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: FlagStyleCatalog.emblems.map((emblem) {
        final selected = emblem.id == _style.emblem;
        final style = _style.copyWith(emblem: emblem.id);
        return _tile(
          selected: selected,
          label: emblem.label,
          onTap: () => _select(style),
          width: 104,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emblem.icon, size: 15, color: Colors.white70),
              const SizedBox(width: 6),
              TeritoryFlag(style: style, width: 62, showPole: false, phase: 0.1),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _motionGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: FlagStyleCatalog.motions.map((motion) {
        final selected = motion.id == _style.motion;
        final style = _style.copyWith(motion: motion.id);
        return _tile(
          selected: selected,
          label: motion.label,
          subtitle: motion.description,
          onTap: () => _select(style),
          width: 168,
          child: AnimatedTeritoryFlag(
            style: style,
            width: 82,
            showPole: false,
          ),
        );
      }).toList(),
    );
  }

  Widget _speedRow() {
    return Wrap(
      spacing: 8,
      children: const [0.5, 1.0, 2.0].map((speed) {
        final selected = _style.speed == speed;
        final label = speed < 1 ? 'Calm' : (speed > 1 ? 'Wild' : 'Steady');
        return ChoiceChip(
          label: Text('$label  ${speed.toStringAsFixed(1)}×'),
          selected: selected,
          onSelected: (_) => _select(_style.copyWith(speed: speed)),
          selectedColor: _styleAccent(),
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: selected ? _styleAccent() : Colors.white24,
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _tile({
    required bool selected,
    required String label,
    required VoidCallback onTap,
    required double width,
    required Widget child,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? _styleAccent().withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _styleAccent() : Colors.white.withValues(alpha: 0.10),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            child,
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 9.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _swatch(String hex, {required String label}) {
    final color = FlagStyleCatalog.colorFromHex(hex) ?? Colors.white;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white38),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  Color _styleAccent() =>
      FlagStyleCatalog.themeFor(_style.theme).accent;

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: TeritoryColors.majorGold,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}
