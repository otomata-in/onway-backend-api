import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/teritory_theme.dart';

class SeaWaveNavItem {
  final IconData icon;
  final String label;

  const SeaWaveNavItem({required this.icon, required this.label});
}

class SeaWaveNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SeaWaveNavItem> items;
  final bool isDark;

  const SeaWaveNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.isDark = false,
  });

  @override
  State<SeaWaveNavBar> createState() => _SeaWaveNavBarState();
}

class _SeaWaveNavBarState extends State<SeaWaveNavBar>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animPosition;
  late double _previousIndex;

  // Continuous infinite wave animation loop
  late AnimationController _waveLoopController;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex.toDouble();

    // Tab transition controller
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _animPosition =
        Tween<double>(
          begin: _previousIndex,
          end: widget.currentIndex.toDouble(),
        ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    // Continuous sea wave ripple & swell loop
    _waveLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant SeaWaveNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = _animPosition.value;
      _animPosition =
          Tween<double>(
            begin: _previousIndex,
            end: widget.currentIndex.toDouble(),
          ).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
          );
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _waveLoopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barHeight = 68.0;
    const double waveOverflow = 18.0;
    final totalHeight = barHeight + waveOverflow + bottomPadding;

    return AnimatedBuilder(
      animation: Listenable.merge([_animController, _waveLoopController]),
      builder: (context, _) {
        final animVal = _animPosition.value;
        final waveLoopProgress = _waveLoopController.value;
        final wavePhase = waveLoopProgress * 2 * math.pi;

        // Gentle nautical bobbing for active component (like a sailboat on ocean swell)
        final waterBobbing = math.sin(wavePhase) * 2.5;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Layered Living Sea Wave Canvas
              Positioned.fill(
                child: CustomPaint(
                  painter: _SeaWavePainter(
                    itemCount: widget.items.length,
                    activePosition: animVal,
                    wavePhase: wavePhase,
                    isDark: widget.isDark,
                    waveOverflow: waveOverflow,
                    bottomPadding: bottomPadding,
                  ),
                ),
              ),

              // 2. Navigation Items Row
              Positioned(
                left: 0,
                right: 0,
                top: waveOverflow,
                height: barHeight,
                child: Row(
                  children: List.generate(widget.items.length, (index) {
                    final isSelected = widget.currentIndex == index;
                    final item = widget.items[index];

                    // Distance from animated position for smooth dynamic elevation
                    final dist = (animVal - index).abs();
                    final scaleFactor = (1.0 - (dist * 0.25)).clamp(0.85, 1.0);
                    final baseLift =
                        (1.0 - (dist * 0.8)).clamp(0.0, 1.0) * -14.0;
                    final totalLift = isSelected
                        ? (baseLift + waterBobbing)
                        : baseLift;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onTap(index),
                        behavior: HitTestBehavior.opaque,
                        child: Transform.translate(
                          offset: Offset(0, totalLift),
                          child: Transform.scale(
                            scale: scaleFactor,
                            child: _buildItemContent(
                              item,
                              isSelected,
                              waveLoopProgress,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemContent(
    SeaWaveNavItem item,
    bool isSelected,
    double waveProgress,
  ) {
    final activeColor = widget.isDark
        ? const Color(0xFF38BDF8) // Bright Ocean Cyan
        : TeritoryColors.primary; // Vibrant Nautical Coral
    final inactiveColor = widget.isDark
        ? const Color(0xFF94A3B8)
        : TeritoryColors.textMuted;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isSelected)
          SizedBox(
            width: 58,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Continuous Expanding Sea Ripple Waves
                _buildExpandingSeaRipple(waveProgress, 0.0),
                _buildExpandingSeaRipple(waveProgress, 0.5),

                // Active Elevated Disc on Wave Crest
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isDark
                          ? [const Color(0xFF1E3A8A), const Color(0xFF0C4A6E)]
                          : [const Color(0xFFFF5330), const Color(0xFFFF7A50)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (widget.isDark
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFFFF5330))
                                .withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.90),
                      width: 2.0,
                    ),
                  ),
                  child: Icon(item.icon, size: 22, color: Colors.white),
                ),
              ],
            ),
          )
        else
          Icon(item.icon, size: 22, color: inactiveColor),
        const SizedBox(height: 3),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isSelected ? 11 : 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? activeColor : inactiveColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  /// Builds a gentle circular sea-water ripple radiating outwards from the active component
  Widget _buildExpandingSeaRipple(double progress, double offset) {
    final effectiveProgress = (progress + offset) % 1.0;
    final size = 44.0 + (effectiveProgress * 16.0);
    final opacity = (1.0 - effectiveProgress).clamp(0.0, 0.65) * 0.45;

    final rippleColor = widget.isDark
        ? const Color(0xFF38BDF8)
        : const Color(0xFF38BDF8);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: rippleColor.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }
}

/// Custom painter that draws sculpted sea waves with continuous living water ripples
class _SeaWavePainter extends CustomPainter {
  final int itemCount;
  final double activePosition;
  final double wavePhase;
  final bool isDark;
  final double waveOverflow;
  final double bottomPadding;

  // Cached paint and shader instances to eliminate 120 FPS GC pressure
  static Size? _cachedSize;
  static bool? _cachedIsDark;
  static Paint? _cachedBgTidePaint;
  static Paint? _cachedMainWavePaint;
  static Paint? _cachedShadowPaint;
  static final Paint _foamPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;

  static void _ensurePaints(Size size, bool isDark) {
    if (_cachedSize == size && _cachedIsDark == isDark && _cachedBgTidePaint != null) {
      return;
    }
    _cachedSize = size;
    _cachedIsDark = isDark;
    final w = size.width;
    final h = size.height;

    _cachedBgTidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF0369A1).withValues(alpha: 0.28),
                const Color(0xFF0284C7).withValues(alpha: 0.05),
              ]
            : [
                const Color(0xFF38BDF8).withValues(alpha: 0.38),
                const Color(0xFFBAE6FD).withValues(alpha: 0.12),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    _cachedMainWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF0F172A),
                const Color(0xFF020617),
              ]
            : [
                Colors.white,
                const Color(0xFFF1F5F9),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    _cachedShadowPaint = Paint()
      ..color = (isDark ? const Color(0xFF0284C7) : Colors.black).withValues(
        alpha: isDark ? 0.22 : 0.08,
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
  }

  _SeaWavePainter({
    required this.itemCount,
    required this.activePosition,
    required this.wavePhase,
    required this.isDark,
    required this.waveOverflow,
    required this.bottomPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final itemWidth = w / itemCount;
    final crestX = (activePosition + 0.5) * itemWidth;

    // Baseline where flat nav bar begins
    final baseLineY = waveOverflow + 4.0;

    _ensurePaints(size, isDark);

    // ── 1. Soft Flowing Background Tide Swell (Continuous Live Motion) ──
    final bgPath = Path();
    bgPath.moveTo(0, baseLineY + 6);
    for (double x = 0; x <= w; x += 10) {
      // Continuous sinusoidal ocean swell flowing horizontally
      final waveSine =
          math.sin((x / w) * 4 * math.pi + (activePosition * 0.8) + wavePhase) *
          5.0;
      bgPath.lineTo(x, baseLineY + 2 + waveSine);
    }
    bgPath.lineTo(w, h);
    bgPath.lineTo(0, h);
    bgPath.close();
    canvas.drawPath(bgPath, _cachedBgTidePaint!);

    // Dynamic crest swell height influenced by continuous wave breathing
    final liveCrestOffset = math.sin(wavePhase) * 1.5;

    final wavePath = Path();
    wavePath.moveTo(0, baseLineY);

    // Wave parameters around active crest
    const crestRadius = 54.0;
    final leftTroughX = crestX - crestRadius;
    final rightTroughX = crestX + crestRadius;

    if (leftTroughX > 0) {
      wavePath.lineTo(leftTroughX - 16, baseLineY);
      // Lead into trough
      wavePath.cubicTo(
        leftTroughX - 8,
        baseLineY,
        leftTroughX - 4,
        baseLineY + 2.5,
        leftTroughX,
        baseLineY + 3.0,
      );
    } else {
      wavePath.lineTo(0, baseLineY + 3.0);
    }

    // Rise up smoothly into the active wave crest
    wavePath.cubicTo(
      crestX - (crestRadius * 0.55),
      baseLineY + 3.0,
      crestX - (crestRadius * 0.40),
      0.0 + liveCrestOffset,
      crestX,
      0.0 + liveCrestOffset,
    );

    // Descend gracefully through the right slope
    wavePath.cubicTo(
      crestX + (crestRadius * 0.40),
      0.0 + liveCrestOffset,
      crestX + (crestRadius * 0.55),
      baseLineY + 3.0,
      rightTroughX,
      baseLineY + 3.0,
    );

    if (rightTroughX + 16 < w) {
      wavePath.cubicTo(
        rightTroughX + 4,
        baseLineY + 2.5,
        rightTroughX + 8,
        baseLineY,
        rightTroughX + 16,
        baseLineY,
      );
      wavePath.lineTo(w, baseLineY);
    } else {
      wavePath.lineTo(w, baseLineY);
    }

    wavePath.lineTo(w, h);
    wavePath.lineTo(0, h);
    wavePath.close();

    // Draw shadow first
    canvas.drawPath(wavePath, _cachedShadowPaint!);
    // Draw solid wave body
    canvas.drawPath(wavePath, _cachedMainWavePaint!);

    // ── 3. Continuous Sea Foam Crest Stroke (Shimmering Water Foam) ──
    final shimmerOffset = math.sin(wavePhase * 1.2) * 20.0;

    _foamPaint.shader = LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF38BDF8).withValues(alpha: 0.10),
              const Color(0xFF38BDF8).withValues(alpha: 0.85),
              const Color(0xFF67E8F9).withValues(alpha: 1.0),
              const Color(0xFF38BDF8).withValues(alpha: 0.85),
              const Color(0xFF38BDF8).withValues(alpha: 0.10),
            ]
          : [
              const Color(0xFF0284C7).withValues(alpha: 0.15),
              const Color(0xFF38BDF8).withValues(alpha: 0.85),
              const Color(0xFF60A5FA).withValues(alpha: 0.95),
              const Color(0xFF38BDF8).withValues(alpha: 0.85),
              const Color(0xFF0284C7).withValues(alpha: 0.15),
            ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    ).createShader(Rect.fromLTWH(crestX - 80 + shimmerOffset, 0, 160, 24));

    final foamPath = Path();
    final foamLeft = math.max(0.0, crestX - 72);
    final foamRight = math.min(w, crestX + 72);

    foamPath.moveTo(foamLeft, baseLineY);
    foamPath.cubicTo(
      crestX - (crestRadius * 0.55),
      baseLineY + 3.0,
      crestX - (crestRadius * 0.40),
      0.0 + liveCrestOffset,
      crestX,
      0.0 + liveCrestOffset,
    );
    foamPath.cubicTo(
      crestX + (crestRadius * 0.40),
      0.0 + liveCrestOffset,
      crestX + (crestRadius * 0.55),
      baseLineY + 3.0,
      foamRight,
      baseLineY,
    );

    canvas.drawPath(foamPath, _foamPaint);
  }

  @override
  bool shouldRepaint(covariant _SeaWavePainter oldDelegate) {
    return oldDelegate.activePosition != activePosition ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.isDark != isDark ||
        oldDelegate.itemCount != itemCount;
  }
}
