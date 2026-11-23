import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/flag_style.dart';
import '../../../core/providers/flag_style_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/flag_style_catalog.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../../core/widgets/flag/teritory_flag.dart';

const _studioBg = Color(0xFF080F1C);
const _studioCard = Color(0xFF101A2E);

/// The editable home of a traveller's flag identity.
///
/// Every choice writes into one [FlagStyle] draft and previews it with the
/// same shared painter the map, profile and ceremony use. Nothing is committed
/// until "Save signature" succeeds against `PATCH /users/me/flag-style`, so a
/// refused save leaves the previous signature — and every already-staked flag —
/// untouched.
class FlagStudioScreen extends ConsumerStatefulWidget {
  /// Dev harness / deep-link starting point. In the app the saved signature is
  /// used.
  final FlagStyle? initialStyle;

  const FlagStudioScreen({super.key, this.initialStyle});

  /// Opens the studio and resolves with the saved style, or null when the
  /// traveller backs out without saving.
  static Future<FlagStyle?> show(
    BuildContext context, {
    FlagStyle? initialStyle,
  }) {
    return Navigator.of(context).push<FlagStyle>(
      MaterialPageRoute<FlagStyle>(
        builder: (_) => FlagStudioScreen(initialStyle: initialStyle),
      ),
    );
  }

  @override
  ConsumerState<FlagStudioScreen> createState() => _FlagStudioScreenState();
}

class _FlagStudioScreenState extends ConsumerState<FlagStudioScreen> {
  /// A few cloth overrides that look right with every theme's accent.
  static const List<String> _customColors = [
    '#0EA5E9',
    '#DC2626',
    '#F59E0B',
    '#22C55E',
    '#8B5CF6',
    '#EC4899',
    '#0F766E',
    '#F8FAFC',
  ];

  late FlagStyle _draft;
  late FlagStyle _saved;
  bool _saving = false;
  String? _error;

  bool get _dirty => _draft != _saved;

  @override
  void initState() {
    super.initState();
    _saved = FlagStyleCatalog.normalize(
      widget.initialStyle ?? ref.read(flagStyleProvider),
    );
    _draft = _saved;
  }

  void _set(FlagStyle style) {
    setState(() {
      _draft = FlagStyleCatalog.normalize(style);
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving || !_dirty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(flagStyleProvider.notifier)
          .saveSignature(_draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signature saved. Flags you stake from now fly it.'),
        ),
      );
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is ApiException
            ? error.message
            : 'Could not save your flag. Check the connection and try again.';
      });
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Your flag has unsaved changes. Leaving now keeps the signature you '
          'already have.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlagStyleCatalog.themeFor(_draft.theme);

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: _studioBg,
        appBar: AppBar(
          backgroundColor: _studioBg,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Flag Studio',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: _saving
                  ? null
                  : () => _set(FlagStyleCatalog.normalize(FlagStyle.fallback)),
              icon: const Icon(Icons.restart_alt_rounded, size: 17),
              label: const Text('Reset'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            _hero(theme),
            const SizedBox(height: 24),
            _sectionHeader('Quick starts', 'One tap for a complete look'),
            const SizedBox(height: 10),
            _presetRail(),
            const SizedBox(height: 24),
            _sectionHeader('Cloth', 'The palette your flag flies'),
            const SizedBox(height: 10),
            _themeRail(),
            const SizedBox(height: 12),
            _customColorRow(),
            const SizedBox(height: 24),
            _sectionHeader('Pattern', 'How the fabric is marked'),
            const SizedBox(height: 10),
            _patternRail(),
            const SizedBox(height: 24),
            _sectionHeader('Silhouette', 'The cut of the fly edge'),
            const SizedBox(height: 10),
            _shapeRail(),
            const SizedBox(height: 24),
            _sectionHeader('Emblem', 'Your mark on the cloth'),
            const SizedBox(height: 10),
            _emblemWrap(),
            const SizedBox(height: 24),
            _sectionHeader('Motion', 'How it moves in the wind'),
            const SizedBox(height: 10),
            _motionWrap(),
            const SizedBox(height: 24),
            _speedCard(theme),
          ],
        ),
        bottomNavigationBar: _bottomBar(theme),
      ),
    );
  }

  Widget _hero(FlagThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: RadialGradient(
          center: const Alignment(0.25, -0.45),
          radius: 1.35,
          colors: [
            theme.primary.withValues(alpha: 0.32),
            const Color(0xFF111C31),
          ],
        ),
        border: Border.all(color: theme.accent.withValues(alpha: 0.38)),
      ),
      child: Column(
        children: [
          AnimatedTeritoryFlag(style: _draft, width: 250),
          const SizedBox(height: 16),
          Text(
            theme.label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${FlagStyleCatalog.patternFor(_draft.pattern).label} · '
            '${FlagStyleCatalog.shapeFor(_draft.shape).label} · '
            '${FlagStyleCatalog.emblemFor(_draft.emblem).label}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pill(
                _dirty ? 'Unsaved changes' : 'All changes saved',
                color: _dirty ? theme.accent : const Color(0xFF4ADE80),
              ),
              const SizedBox(width: 8),
              _pill(
                '${FlagStyleCatalog.motionFor(_draft.motion).label} · '
                '${_draft.speed.toStringAsFixed(1)}×',
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _presetRail() {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FlagStyleCatalog.presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final preset = FlagStyleCatalog.presets[index];
          final selected = preset.style == _draft;
          return _choiceTile(
            selected: selected,
            width: 96,
            label: preset.label,
            onTap: () => _set(preset.style),
            child: TeritoryFlag(
              style: preset.style,
              width: 78,
              showPole: false,
              phase: 0.2,
            ),
          );
        },
      ),
    );
  }

  Widget _themeRail() {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FlagStyleCatalog.themes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final theme = FlagStyleCatalog.themes[index];
          final selected = theme.id == _draft.theme;
          final preview = FlagStyle(
            theme: theme.id,
            pattern: _draft.pattern,
            shape: _draft.shape,
            emblem: 'none',
            motion: 'still',
          );
          return _choiceTile(
            selected: selected,
            width: 88,
            label: theme.label,
            onTap: () => _set(_draft.copyWith(theme: theme.id, color: null)),
            child: TeritoryFlag(
              style: preview,
              width: 70,
              showPole: false,
            ),
          );
        },
      ),
    );
  }

  Widget _customColorRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom cloth'.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _colorChip(
              label: 'Theme',
              color: null,
              selected: _draft.color == null,
            ),
            for (final hex in _customColors)
              _colorChip(
                label: hex,
                color: hex,
                selected: _draft.color == hex,
              ),
          ],
        ),
      ],
    );
  }

  Widget _colorChip({
    required String label,
    required String? color,
    required bool selected,
  }) {
    final swatch = color == null
        ? null
        : FlagStyleCatalog.colorFromHex(color);
    return GestureDetector(
      onTap: () => _set(_draft.copyWith(color: color)),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: swatch ?? Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.18),
            width: selected ? 2 : 1,
          ),
        ),
        child: swatch == null
            ? const Icon(Icons.palette_outlined, size: 17, color: Colors.white70)
            : selected
                ? Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: FlagStyleCatalog.foregroundOn(swatch),
                  )
                : null,
      ),
    );
  }

  Widget _patternRail() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FlagStyleCatalog.patterns.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final pattern = FlagStyleCatalog.patterns[index];
          final selected = pattern.id == _draft.pattern;
          return _choiceTile(
            selected: selected,
            width: 84,
            label: pattern.label,
            onTap: () => _set(_draft.copyWith(pattern: pattern.id)),
            child: TeritoryFlag(
              style: _draft.copyWith(pattern: pattern.id, emblem: 'none'),
              width: 66,
              showPole: false,
            ),
          );
        },
      ),
    );
  }

  Widget _shapeRail() {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FlagStyleCatalog.shapes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final shape = FlagStyleCatalog.shapes[index];
          final selected = shape.id == _draft.shape;
          return _choiceTile(
            selected: selected,
            width: 112,
            label: shape.label,
            onTap: () => _set(_draft.copyWith(shape: shape.id)),
            child: TeritoryFlag(
              style: _draft.copyWith(shape: shape.id, emblem: 'none'),
              width: 90,
              showPole: false,
            ),
          );
        },
      ),
    );
  }

  Widget _emblemWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FlagStyleCatalog.emblems.map((emblem) {
        final selected = emblem.id == _draft.emblem;
        return GestureDetector(
          onTap: () => _set(_draft.copyWith(emblem: emblem.id)),
          child: Container(
            width: 104,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? _accent().withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? _accent()
                    : Colors.white.withValues(alpha: 0.10),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  emblem.icon,
                  size: 16,
                  color: selected ? Colors.white : Colors.white60,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    emblem.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _motionWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FlagStyleCatalog.motions.map((motion) {
        final selected = motion.id == _draft.motion;
        return GestureDetector(
          onTap: () => _set(_draft.copyWith(motion: motion.id)),
          child: Container(
            width: 168,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? _accent().withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? _accent()
                    : Colors.white.withValues(alpha: 0.10),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  motion.label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  motion.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 9.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _speedCard(FlagThemeData theme) {
    final label = _draft.speed < 0.85
        ? 'Calm'
        : (_draft.speed > 1.3 ? 'Wild' : 'Steady');
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: _studioCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.air_rounded, size: 16, color: theme.accent),
              const SizedBox(width: 8),
              Text(
                'Wind speed',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$label · ${_draft.speed.toStringAsFixed(1)}×',
                style: TextStyle(
                  color: theme.accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.accent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              thumbColor: Colors.white,
              overlayColor: theme.accent.withValues(alpha: 0.18),
            ),
            child: Slider(
              value: _draft.speed,
              min: FlagStyle.minSpeed,
              max: FlagStyle.maxSpeed,
              divisions: 15,
              onChanged: (value) =>
                  _set(_draft.copyWith(speed: value)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(FlagThemeData theme) {
    final onAccent = FlagStyleCatalog.foregroundOn(theme.accent);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: _studioBg,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving || !_dirty ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded, size: 19),
                label: Text(
                  _saving
                      ? 'Saving…'
                      : (_dirty ? 'Save signature' : 'Signature saved'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: onAccent,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                  disabledForegroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceTile({
    required bool selected,
    required VoidCallback onTap,
    required double width,
    required String label,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? _accent().withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? _accent()
                : Colors.white.withValues(alpha: 0.10),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(child: child),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String hint) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: TeritoryColors.majorGold,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10.5,
            ),
          ),
        ),
      ],
    );
  }

  Color _accent() => FlagStyleCatalog.themeFor(_draft.theme).accent;
}
