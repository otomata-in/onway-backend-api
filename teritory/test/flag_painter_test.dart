import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teritory/core/models/flag_style.dart';
import 'package:teritory/core/widgets/flag/flag_cloth_painter.dart';
import 'package:teritory/core/widgets/flag/teritory_flag.dart';

Widget _host(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

FlagClothPainter _painter(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((paint) => paint.painter)
      .whereType<FlagClothPainter>()
      .single;
}

void main() {
  testWidgets('every catalog dimension paints without an exception', (
    tester,
  ) async {
    const base = FlagStyle();

    for (final shape in FlagStyle.shapeIds) {
      await tester.pumpWidget(
        _host(TeritoryFlag(style: base.copyWith(shape: shape), width: 140)),
      );
      expect(tester.takeException(), isNull, reason: 'shape $shape');
    }

    for (final pattern in FlagStyle.patternIds) {
      await tester.pumpWidget(
        _host(
          TeritoryFlag(
            style: base.copyWith(pattern: pattern),
            width: 140,
            phase: 0.3,
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'pattern $pattern');
    }

    for (final emblem in FlagStyle.emblemIds) {
      await tester.pumpWidget(
        _host(
          TeritoryFlag(
            style: base.copyWith(emblem: emblem),
            width: 140,
            phase: 0.6,
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'emblem $emblem');
    }

    for (final motion in FlagStyle.motionIds) {
      await tester.pumpWidget(
        _host(
          TeritoryFlag(
            style: base.copyWith(motion: motion),
            width: 140,
            phase: 0.42,
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'motion $motion');
    }
  });

  testWidgets('a tiny badge and a major hero both render', (tester) async {
    await tester.pumpWidget(
      _host(
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TeritoryFlag(style: FlagStyle(), width: 24, showPole: false),
            TeritoryFlag(style: FlagStyle(theme: 'aurora'), width: 220, isMajor: true),
            TeritoryFlag(style: FlagStyle(), width: 80, unfurl: 0),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(TeritoryFlag), findsNWidgets(3));
  });

  testWidgets('a static flag reports the phase it was given', (tester) async {
    await tester.pumpWidget(
      _host(
        const TeritoryFlag(
          style: FlagStyle(motion: 'gust'),
          width: 120,
          phase: 0.35,
        ),
      ),
    );

    expect(_painter(tester).phase, 0.35);
  });

  testWidgets('an animated flag advances on its own ticker', (tester) async {
    await tester.pumpWidget(
      _host(
        const AnimatedTeritoryFlag(
          style: FlagStyle(motion: 'breeze'),
          width: 120,
        ),
      ),
    );

    final first = _painter(tester).phase;
    await tester.pump(const Duration(milliseconds: 600));
    final second = _painter(tester).phase;

    expect(second, isNot(first));
    expect(second, greaterThan(0));
  });

  testWidgets('reduce motion and still styles stay at rest', (tester) async {
    await tester.pumpWidget(
      _host(
        const AnimatedTeritoryFlag(
          style: FlagStyle(motion: 'gust'),
          width: 120,
        ),
        reduceMotion: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(_painter(tester).phase, 0);

    await tester.pumpWidget(
      _host(
        const AnimatedTeritoryFlag(
          style: FlagStyle(motion: 'still'),
          width: 120,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(_painter(tester).phase, 0);
    expect(flagWavePeriod(const FlagStyle(motion: 'still')), isNull);
    expect(flagWavePeriod(const FlagStyle(motion: 'breeze')), isNotNull);
  });

  testWidgets('the ceremony reveal paints every unfurl stage', (tester) async {
    for (final theme in FlagStyle.themeIds) {
      for (final unfurl in const [0.15, 0.5, 0.95]) {
        await tester.pumpWidget(
          _host(
            TeritoryFlag(
              style: FlagStyle(theme: theme, motion: 'storm'),
              width: 320,
              showPole: false,
              unfurl: unfurl,
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: '$theme @ $unfurl');
      }
    }
  });

  testWidgets('shouldRepaint only reports real changes', (tester) async {
    const painter = FlagClothPainter(style: FlagStyle());
    expect(painter.shouldRepaint(const FlagClothPainter(style: FlagStyle())), isFalse);
    expect(
      painter.shouldRepaint(const FlagClothPainter(style: FlagStyle(), phase: 0.1)),
      isTrue,
    );
    expect(
      painter.shouldRepaint(
        const FlagClothPainter(style: FlagStyle(theme: 'aurora')),
      ),
      isTrue,
    );
  });
}
