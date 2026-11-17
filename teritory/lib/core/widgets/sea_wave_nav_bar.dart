import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/teritory_theme.dart';

class SeaWaveNavItem {
  final IconData icon;
  final String label;

  const SeaWaveNavItem({
    required this.icon,
    required this.label,
  });
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
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animPosition;
  late double _previousIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex.toDouble();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _animPosition = Tween<double>(
      begin: _previousIndex,
      end: widget.currentIndex.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SeaWaveNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = _animPosition.value;
      _animPosition = Tween<double>(
        begin: _previousIndex,
        end: widget.currentIndex.toDouble(),
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Curves.easeOutBack,
        ),
      );
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barHeight = 68.0;
    const double waveOverflow = 16.0;
    final totalHeight = barHeight + waveOverflow + bottomPadding;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final animVal = _animPosition.value;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Layered Sea Wave Canvas
              Positioned.fill(
                child: CustomPaint(
                  painter: _SeaWavePainter(
                    itemCount: widget.items.length,
                    activePosition: animVal,
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

                    // Distance from animated position for subtle dynamic scaling
                    final dist = (animVal - index).abs();
                    final scaleFactor = (1.0 - (dist * 0.25)).clamp(0.85, 1.0);
                    final liftOffset = (1.0 - (dist * 0.8)).clamp(0.0, 1.0) * -12.0;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onTap(index),
                        behavior: HitTestBehavior.opaque,
                        child: Transform.translate(
                          offset: Offset(0, liftOffset),
                          child: Transform.scale(
                            scale: scaleFactor,
                            child: _buildItemContent(item, isSelected),
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

  Widget _buildItemContent(SeaWaveNavItem item, bool isSelected) {
    final activeColor = widget.isDark
        ? const Color(0xFF38BDF8) // Bright Cyan on dark oceanic
        : TeritoryColors.primary; // Vibrant Nautical Coral/Orange
    final inactiveColor = widget.isDark
        ? const Color(0xFF94A3B8)
        : TeritoryColors.textMuted;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isSelected)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isDark
                    ? [
                        const Color(0xFF1E3A8A),
                        const Color(0xFF0C4A6E),
                      ]
                    : [
                        const Color(0xFFFF5330),
                        const Color(0xFFFF7A50),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isDark
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFFF5330))
                      .withValues(alpha: 0.40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 2.0,
              ),
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: Colors.white,
            ),
          )
        else
          Icon(
            item.icon,
            size: 22,
            color: inactiveColor,
          ),
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
}

/// Custom painter that draws sculpted sea waves with dynamic crest under active tab
class _SeaWavePainter extends CustomPainter {
  final int itemCount;
  final double activePosition;
  final bool isDark;
  final double waveOverflow;
  final double bottomPadding;

  _SeaWavePainter({
    required this.itemCount,
    required this.activePosition,
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

    // ── 1. Soft Background Tide Swell ──
    final bgTidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF0369A1).withValues(alpha: 0.25),
                const Color(0xFF0284C7).withValues(alpha: 0.05),
              ]
            : [
                const Color(0xFF38BDF8).withValues(alpha: 0.35),
                const Color(0xFFBAE6FD).withValues(alpha: 0.10),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final bgPath = Path();
    bgPath.moveTo(0, baseLineY + 6);
    for (double x = 0; x <= w; x += 12) {
      final waveSine = math.sin((x / w) * 4 * math.pi + (activePosition * 0.8)) * 5;
      bgPath.lineTo(x, baseLineY + 2 + waveSine);
    }
    bgPath.lineTo(w, h);
    bgPath.lineTo(0, h);
    bgPath.close();
    canvas.drawPath(bgPath, bgTidePaint);

    // ── 2. Main Sea Wave Body ──
    final mainWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF0F172A), // Deep Midnight Oceanic Abyss
                const Color(0xFF020617),
              ]
            : [
                Colors.white, // Crisp Nautical White Deck
                const Color(0xFFF1F5F9),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // Ambient drop shadow
    final shadowPaint = Paint()
      ..color = (isDark ? const Color(0xFF0284C7) : Colors.black)
          .withValues(alpha: isDark ? 0.20 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    final wavePath = Path();
    wavePath.moveTo(0, baseLineY);

    // Wave parameters around active crest
    const crestRadius = 52.0;
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

    // Rise up smoothly into the crest
    wavePath.cubicTo(
      crestX - (crestRadius * 0.55),
      baseLineY + 3.0,
      crestX - (crestRadius * 0.40),
      0.0, // Peak crest
      crestX,
      0.0,
    );

    // Descend gracefully through the right slope
    wavePath.cubicTo(
      crestX + (crestRadius * 0.40),
      0.0,
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
    canvas.drawPath(wavePath, shadowPaint);
    // Draw solid wave body
    canvas.drawPath(wavePath, mainWavePaint);

    // ── 3. Sea Foam Crest Stroke (Top Rim Highlight) ──
    final foamPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [
                const Color(0xFF38BDF8).withValues(alpha: 0.10),
                const Color(0xFF38BDF8).withValues(alpha: 0.85),
                const Color(0xFF67E8F9).withValues(alpha: 0.95),
                const Color(0xFF38BDF8).withValues(alpha: 0.85),
                const Color(0xFF38BDF8).withValues(alpha: 0.10),
              ]
            : [
                const Color(0xFF0284C7).withValues(alpha: 0.15),
                const Color(0xFF38BDF8).withValues(alpha: 0.80),
                const Color(0xFF60A5FA).withValues(alpha: 0.90),
                const Color(0xFF38BDF8).withValues(alpha: 0.80),
                const Color(0xFF0284C7).withValues(alpha: 0.15),
              ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(crestX - 80, 0, 160, 24))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final foamPath = Path();
    final foamLeft = math.max(0.0, crestX - 70);
    final foamRight = math.min(w, crestX + 70);

    foamPath.moveTo(foamLeft, baseLineY);
    foamPath.cubicTo(
      crestX - (crestRadius * 0.55),
      baseLineY + 3.0,
      crestX - (crestRadius * 0.40),
      0.0,
      crestX,
      0.0,
    );
    foamPath.cubicTo(
      crestX + (crestRadius * 0.40),
      0.0,
      crestX + (crestRadius * 0.55),
      baseLineY + 3.0,
      foamRight,
      baseLineY,
    );

    canvas.drawPath(foamPath, foamPaint);
  }

  @override
  bool shouldRepaint(covariant _SeaWavePainter oldDelegate) {
    return oldDelegate.activePosition != activePosition ||
        oldDelegate.isDark != isDark ||
        oldDelegate.itemCount != itemCount;
  }
}
