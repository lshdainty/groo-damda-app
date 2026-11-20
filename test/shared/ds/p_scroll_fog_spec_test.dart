// Scroll Fog 가 스펙 값(test/fixtures/design_spec/scroll-fog.json)대로인지 — 자리마다 흐림 깊이 · 방향 · 안쪽 여백과
// 마스크(gradient-fade-mask). 웹은 같은 JSON 을 크로미움에서 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';

import '../../support/design_spec.dart';

final _spec = DesignSpec.load('scroll-fog');

/// "위 20px · 아래 80px" · 20 → (시작, 끝)
(double, double) _pair(Object? v) {
  if (v is num) return (v.toDouble(), v.toDouble());
  final m = RegExp(r'위 (\d+)px · 아래 (\d+)px').firstMatch('$v');
  if (m == null) throw ArgumentError('$v');
  return (double.parse(m.group(1)!), double.parse(m.group(2)!));
}

void main() {
  for (final combo in _spec.combos(['use'])) {
    testWidgets('${combo['use']} — 흐림 깊이 · 안쪽 여백이 스펙 값이다', (tester) async {
      final use = PScrollFogUse.values.byName(combo['use']!);
      final want = _spec.resolve(combo, 'enabled');
      final m = scrollFogMetrics(use);

      final (fogStart, fogEnd) = _pair(want['fog.size']);
      expect((m.fogStart, m.fogEnd), (fogStart, fogEnd));

      final padStart =
          want['content.paddingTop'] ??
          want['content.paddingX'] ??
          want['content.padding'];
      final padEnd =
          want['content.paddingBottom'] ??
          want['content.paddingX'] ??
          want['content.padding'];
      expect((m.padStart, m.padEnd), (padStart, padEnd));

      await tester.pumpWidget(
        MaterialApp(
          theme: GrooTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: PScrollFog(
                use: use,
                child: const SizedBox(width: 600, height: 600),
              ),
            ),
          ),
        ),
      );
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      // 가로 줄만 가로, 나머지는 세로
      expect(
        scroll.scrollDirection,
        use == PScrollFogUse.row ? Axis.horizontal : Axis.vertical,
      );
      final padding = scroll.padding! as EdgeInsets;
      if (use == PScrollFogUse.row) {
        expect((padding.left, padding.right), (padStart, padEnd));
      } else {
        expect((padding.top, padding.bottom), (padStart, padEnd));
      }
    });
  }

  // sliver 로 짠 화면(업데이트 안내 — 바닥 짝 위 영역)도 같은 깊이 · 여백이다
  for (final use in [PScrollFogUse.page, PScrollFogUse.overlayBody]) {
    testWidgets('slivers · ${use.name} — 흐림 깊이 · 앞뒤 여백이 같은 표다', (tester) async {
      final m = scrollFogMetrics(use);
      await tester.pumpWidget(
        MaterialApp(
          theme: GrooTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: PScrollFog.slivers(
                use: use,
                slivers: const [
                  SliverToBoxAdapter(
                    child: SizedBox(key: ValueKey('body'), height: 600),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final mask = tester.widget<PScrollFogMask>(find.byType(PScrollFogMask));
      expect((mask.start, mask.end), (m.fogStart, m.fogEnd));
      expect(mask.axis, Axis.vertical);
      // 앞 여백 — 내용이 그만큼 아래에서 시작한다
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('body'))).dy,
        m.padStart,
      );
      // 끝 여백 — 끝까지 내리면 내용 끝이 그만큼 위에서 멈춘다
      await tester.drag(find.byType(Scrollable), const Offset(0, -10000));
      await tester.pumpAndSettle();
      expect(
        300 - tester.getBottomLeft(find.byKey(const ValueKey('body'))).dy,
        m.padEnd,
      );
      expect(
        tester.widget<PScrollFogInset>(find.byType(PScrollFogInset)).top,
        m.fogStart,
      );
    });
  }

  test('마스크는 흐린 쪽마다 상자 전체 크기의 층 하나 — 단계는 그 쪽 깊이의 몫이다', () {
    final want = specGradient(_spec.resolve({}, 'enabled')['fog.mask']);
    final fade = PGradients.light.fadeMask;
    // 토큰(16단계)이 스펙과 같다
    expect(fade.colors.length, want.colors.length);
    for (var i = 0; i < want.colors.length; i++) {
      expect(sameColor(want.colors[i], fade.colors[i]), isTrue);
      expect(fade.stops![i], closeTo(want.stops[i], 1e-9));
    }
    // 높이 200 · 위 20 · 아래 80 — 위 층은 0 ~ 0.1 에서 불투명에 닿고, 아래 층은 반대 방향으로 0 ~ 0.4 에서 닿는다
    final top = fogLayer(
      fade,
      Axis.vertical,
      const Size(100, 200),
      20,
      atEnd: false,
    );
    expect(top.begin, Alignment.topCenter);
    expect(top.end, Alignment.bottomCenter);
    expect(top.colors.first.a, 0); // 가장자리는 투명
    expect(top.stops![15], closeTo(0.1, 1e-9)); // 깊이 20 ÷ 200 — 불투명
    expect(top.colors[15].a, 1);
    expect(top.stops!.last, 1); // 그 뒤는 끝까지 불투명
    expect(top.colors.last.a, 1);

    final bottom = fogLayer(
      fade,
      Axis.vertical,
      const Size(100, 200),
      80,
      atEnd: true,
    );
    // 아래 층은 아래에서 위로 — 시작점이 아래다
    expect(bottom.begin, Alignment.bottomCenter);
    expect(bottom.end, Alignment.topCenter);
    expect(bottom.stops![15], closeTo(0.4, 1e-9)); // 깊이 80 ÷ 200
    expect(bottom.colors[15].a, 1);

    // 가로 — 시작 쪽은 왼쪽에서 오른쪽, 끝 쪽은 오른쪽에서 왼쪽
    final left = fogLayer(
      fade,
      Axis.horizontal,
      const Size(400, 40),
      20,
      atEnd: false,
    );
    expect(left.begin, Alignment.centerLeft);
    expect(left.end, Alignment.centerRight);
    expect(left.stops![15], closeTo(20 / 400, 1e-9));
    final right = fogLayer(
      fade,
      Axis.horizontal,
      const Size(400, 40),
      20,
      atEnd: true,
    );
    expect(right.begin, Alignment.centerRight);
    expect(right.end, Alignment.centerLeft);
  });

  test('상자가 두 깊이의 합보다 낮아도 두 층이 겹쳐 곱해진다 — 양 끝이 함께 흐리다(이어 붙여 더하지 않는다)', () {
    final fade = PGradients.light.fadeMask;
    // 높이 50 · 위 20 · 아래 80(합 100) — 아래 층의 깊이는 상자보다 길어 상자 안에서 끝낸다
    const box = Size(10, 50);
    final top = fogLayer(fade, Axis.vertical, box, 20, atEnd: false);
    final bottom = fogLayer(fade, Axis.vertical, box, 80, atEnd: true);
    expect(top.stops![15], closeTo(20 / 50, 1e-9));
    expect(bottom.stops![15], closeTo(1, 1e-9)); // 상자 끝까지 — 1 을 넘지 않는다
    for (final layer in [top, bottom]) {
      for (var i = 1; i < layer.stops!.length; i++) {
        expect(layer.stops![i], greaterThanOrEqualTo(layer.stops![i - 1]));
      }
    }
    // 두 층의 곱 — 상자 한가운데(위에서 25)에서 위 층은 불투명, 아래 층은 아직 흐리다 → 곱하면 흐리다
    double alphaAt(LinearGradient g, double t) {
      for (var i = 1; i < g.stops!.length; i++) {
        if (t <= g.stops![i]) {
          final span = g.stops![i] - g.stops![i - 1];
          final f = span == 0 ? 1.0 : (t - g.stops![i - 1]) / span;
          return g.colors[i - 1].a + (g.colors[i].a - g.colors[i - 1].a) * f;
        }
      }
      return g.colors.last.a;
    }

    // 위 층은 위에서부터, 아래 층은 아래에서부터 잰 위치다 — 아래 층은 위치를 뒤집는다
    final fromTop = alphaAt(top, 25 / 50);
    final fromBottom = alphaAt(bottom, (50 - 25) / 50);
    expect(fromTop, 1);
    expect(fromBottom, lessThan(1));
    expect(fromTop * fromBottom, lessThan(1));
  });

  testWidgets('흐림은 색을 덮지 않는 마스크다(dstIn) — 흐린 자리도 눌린다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 200,
            child: PScrollFog(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(width: 300, height: 400),
              ),
            ),
          ),
        ),
      ),
    );
    // 흐린 쪽마다 한 겹 — 위 · 아래 둘이고 모두 dstIn 이다(겹쳐 쓰면 알파가 곱해진다)
    final masks = tester
        .widgetList<ShaderMask>(find.byType(ShaderMask))
        .toList();
    expect(masks, hasLength(2));
    expect(masks.every((m) => m.blendMode == BlendMode.dstIn), isTrue);
    // 위 흐림 자리(위에서 5px)를 눌러도 받는다 — 여백 20 위라 내용 첫 줄 위는 여백이다
    await tester.tapAt(
      tester.getTopLeft(find.byType(PScrollFog)) + const Offset(150, 25),
    );
    expect(taps, 1);
  });
}
