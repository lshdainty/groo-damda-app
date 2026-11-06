// Card 가 스펙 값(test/fixtures/design_spec/card.json)대로인지 — 면 · 본문 · 머리 · 머리 동작 · 지표 · 증감 · 순자산을
// 라이트 · 다크로 잰다. 웹은 같은 JSON 을 크로미움에서 잰다. 앱에 없는 상태(hovered · focused)와 웹 전용 값(cursor ·
// transition 이름)은 건너뛰고, 누름(pressed)은 손가락으로 눌러 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('card');

Widget _host(Brightness mode, Widget child, {bool reduceMotion = false}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Builder(
            builder: (context) => ColoredBox(
              color: context.colors.bgLayerBasement,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: 330, child: child),
              ),
            ),
          ),
        ),
      ),
    );

const _variants = {'default': PCardVariant.standard, 'hero': PCardVariant.hero};
const _bodies = {
  'content': PCardBody.content,
  'list': PCardBody.list,
  'accordion': PCardBody.accordion,
};

Text _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key)));

BoxDecoration _face(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byKey(const ValueKey('card-surface')),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

Map<String, dynamic> _typo(Object? v) => (v as Map).cast<String, dynamic>();

/// 글의 크기 · 줄 높이 · 굵기 · 색을 스펙과 맞춘다 — 어긋난 곳을 모아 돌려준다.
void _expectText(
  List<String> failures,
  String where,
  TextStyle style,
  Map<String, Object?> want,
  String slot,
  Brightness mode, {
  Object? weight,
}) {
  final typo = _typo(want['$slot.typography']);
  if (style.fontSize != typo['fontSize']) {
    failures.add(
      '$where — $slot 크기: 스펙 ${typo['fontSize']} · 실제 ${style.fontSize}',
    );
  }
  final line = style.fontSize! * style.height!;
  if ((line - (typo['lineHeight'] as num)).abs() > 0.6) {
    failures.add('$where — $slot 줄 높이: 스펙 ${typo['lineHeight']} · 실제 $line');
  }
  final w = weight ?? want['$slot.fontWeight'] ?? typo['fontWeight'];
  if (style.fontWeight?.value != w) {
    failures.add('$where — $slot 굵기: 스펙 $w · 실제 ${style.fontWeight?.value}');
  }
  final fg = want['$slot.foreground'];
  if (fg != null && !sameColor(specColor(pickMode(fg, mode)), style.color!)) {
    failures.add(
      '$where — $slot 색: 스펙 ${pickMode(fg, mode)} · 실제 ${colorHex(style.color!)}',
    );
  }
}

Widget _statCard(PCardStatSize size, PDeltaDirection d, PCardVariant v) =>
    PCard(
      variant: v,
      children: [
        PCardStat(
          size: size,
          label: '이번 달 지출',
          value: '1,240,000원',
          delta: PDelta(direction: d, value: '+12%', text: '지난달보다'),
        ),
      ],
    );

void main() {
  for (final mode in Brightness.values) {
    testWidgets('${mode.name} — 면 · 여백 · 테두리가 변형 × 본문마다 스펙 값이다', (
      tester,
    ) async {
      final failures = <String>[];
      for (final combo in _spec.combos(['variant', 'body'])) {
        final variant = _variants[combo['variant']]!;
        final body = _bodies[combo['body']]!;
        final want = _spec.resolve(combo, 'enabled');
        final where = '${mode.name} $combo';
        await tester.pumpWidget(
          _host(
            mode,
            PCard(
              key: UniqueKey(),
              variant: variant,
              body: body,
              children: const [
                PCardHeader(title: '제목'),
                SizedBox(height: 40, child: Text('본문')),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final face = _face(tester);
        if (variant == PCardVariant.hero) {
          final g = face.gradient! as LinearGradient;
          final start = specColor(pickMode(want['root.background'], mode));
          final end = specColor(pickMode(want['root.gradientEnd'], mode));
          if (!sameColor(start, g.colors.first) ||
              !sameColor(end, g.colors.last)) {
            failures.add('$where — 그라디언트 색이 스펙과 다르다');
          }
          if (face.border != null) failures.add('$where — 순자산에 테두리가 있다');
        } else {
          final bg = specColor(pickMode(want['root.background'], mode));
          if (!sameColor(bg, face.color!)) {
            failures.add(
              '$where — root.background: 스펙 $bg · 실제 ${colorHex(face.color!)}',
            );
          }
          final border = (face.border! as Border).top;
          if (border.width != want['root.borderWidth'] ||
              !sameColor(
                specColor(pickMode(want['root.borderColor'], mode)),
                border.color,
              )) {
            failures.add('$where — 테두리가 스펙과 다르다');
          }
        }
        if (face.boxShadow != null) failures.add('$where — 그림자가 있다');
        final r = (face.borderRadius! as BorderRadius).topLeft.x;
        if (r != want['root.radius']) {
          failures.add(
            '$where — root.radius: 스펙 ${want['root.radius']} · 실제 $r',
          );
        }
        // 여백 — 카드 안 첫 · 마지막 자식이 면 가장자리에서 떨어진 만큼
        final card = tester.getRect(find.byKey(const ValueKey('card-surface')));
        final header = tester.getRect(
          find.byKey(const ValueKey('card-header')),
        );
        final tail = tester.getRect(findText('본문'));
        final isHero = variant == PCardVariant.hero;
        final inset = isHero ? 0.0 : 1.0; // 테두리 1
        // 순자산은 본문 종류와 상관없이 글 카드 여백 24 다(card.json 은 list 규칙의 아래 12 를 그대로 둔다)
        final isHero0 = variant == PCardVariant.hero;
        final pad = (want['root.padding'] ?? 0) as num;
        final padB = isHero0 ? 24 : (want['root.paddingBottom'] ?? pad) as num;
        final padT = (want['root.paddingTop'] ?? (pad == 0 ? 0 : pad)) as num;
        final wantLeft = body == PCardBody.content || isHero ? pad : 0;
        if ((header.left - card.left - inset - wantLeft).abs() > 0.5 &&
            body == PCardBody.content) {
          failures.add('$where — 왼쪽 여백이 $pad 가 아니다');
        }
        if ((header.top - card.top - inset - padT).abs() > 0.5) {
          failures.add(
            '$where — 위 여백: 스펙 $padT · 실제 ${header.top - card.top - inset}',
          );
        }
        // 본문 글줄은 40 높이 칸 안 위쪽 — 칸 아래가 면 아래 여백이다
        final boxBottom = tester.getRect(find.byType(SizedBox).last).bottom;
        if ((card.bottom - inset - boxBottom - padB).abs() > 0.5) {
          failures.add(
            '$where — 아래 여백: 스펙 $padB · 실제 ${card.bottom - inset - boxBottom}',
          );
        }
        expect(tail.isEmpty, isFalse);
      }
      if (failures.isNotEmpty) fail(failures.join('\n'));
    });

    testWidgets('${mode.name} — 머리 · 제목 · 머리 동작이 스펙 값이다', (tester) async {
      final failures = <String>[];
      for (final combo in _spec.combos(['body'])) {
        final body = _bodies[combo['body']]!;
        final want = _spec.resolve(combo, 'enabled');
        final where = '${mode.name} $combo';
        await tester.pumpWidget(
          _host(
            mode,
            PCard(
              key: UniqueKey(),
              body: body,
              children: const [
                PCardHeader(
                  title: '이번 달 예산',
                  actionLabel: '전체 보기',
                  onAction: _noop,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        _expectText(
          failures,
          where,
          _text(tester, 'card-title').style!,
          want,
          'title',
          mode,
        );
        final box = tester.getSize(
          find.byKey(const ValueKey('text-button-box')),
        );
        if (box.height != want['headerAction.height']) {
          failures.add('$where — 동작 높이 ${box.height}');
        }
        final deco =
            tester
                    .widget<Container>(
                      find.byKey(const ValueKey('text-button-box')),
                    )
                    .decoration!
                as BoxDecoration;
        final rr = (deco.borderRadius! as BorderRadius).topLeft.x;
        if (rr != want['headerAction.radius']) {
          failures.add('$where — 동작 모서리 $rr');
        }
        final label = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('text-button-box')),
            matching: findText('전체 보기'),
          ),
        );
        _expectText(failures, where, label.style!, want, 'headerAction', mode);
        // 아이콘 · 꺾쇠는 없다(SEED Text Button)
        if (find
            .descendant(
              of: find.byKey(const ValueKey('text-button-box')),
              matching: find.byType(Icon),
            )
            .evaluate()
            .isNotEmpty) {
          failures.add('$where — 글 버튼에 아이콘이 있다');
        }
        final text = tester.getRect(findText('전체 보기'));
        final boxRect = tester.getRect(
          find.byKey(const ValueKey('text-button-box')),
        );
        if ((text.left -
                        boxRect.left -
                        (want['headerAction.paddingLeft'] as num))
                    .abs() >
                0.5 ||
            (boxRect.right -
                        text.right -
                        (want['headerAction.paddingRight'] as num))
                    .abs() >
                0.5) {
          failures.add('$where — 동작 좌우 여백이 14 · 14 가 아니다');
        }
        // 머리 여백
        final h = tester.getRect(find.byKey(const ValueKey('card-header')));
        final t = tester.getRect(find.byKey(const ValueKey('card-title')));
        final wantPadX = body == PCardBody.content ? 0 : 24;
        if ((t.left - h.left - wantPadX).abs() > 0.5) {
          failures.add('$where — 머리 좌우 여백 $wantPadX 아님');
        }
        final wantH = 36 + (body == PCardBody.content ? 8 : 24 + 4);
        if ((h.height - wantH).abs() > 0.5) {
          failures.add('$where — 머리 높이 ${h.height} · 기대 $wantH');
        }
      }
      if (failures.isNotEmpty) fail(failures.join('\n'));
    });

    testWidgets('${mode.name} — 지표 · 증감이 크기 × 방향마다 스펙 값이다', (tester) async {
      final failures = <String>[];
      const sizes = {
        'large': PCardStatSize.large,
        'small': PCardStatSize.small,
      };
      const dirs = {
        'up': PDeltaDirection.up,
        'down': PDeltaDirection.down,
        'flat': PDeltaDirection.flat,
      };
      for (final combo in _spec.combos(['stat', 'delta'])) {
        if (combo['stat'] == 'none' || combo['delta'] == 'none') continue;
        final want = _spec.resolve(combo, 'enabled');
        final where = '${mode.name} $combo';
        await tester.pumpWidget(
          _host(
            mode,
            _statCard(
              sizes[combo['stat']]!,
              dirs[combo['delta']]!,
              PCardVariant.standard,
            ),
          ),
        );
        await tester.pumpAndSettle();
        _expectText(
          failures,
          where,
          _text(tester, 'card-stat-label').style!,
          want,
          'statLabel',
          mode,
        );
        final value = _text(tester, 'card-stat-value').style!;
        _expectText(failures, where, value, want, 'statValue', mode);
        if (!(value.fontFeatures ?? []).contains(
          const FontFeature.tabularFigures(),
        )) {
          failures.add('$where — 숫자가 고정폭이 아니다');
        }
        final label = tester.getRect(
          find.byKey(const ValueKey('card-stat-label')),
        );
        final valueRect = tester.getRect(
          find.byKey(const ValueKey('card-stat-value')),
        );
        final delta = tester.getRect(find.byKey(const ValueKey('delta-value')));
        if ((valueRect.top -
                    label.bottom -
                    (want['statValue.marginTop'] as num))
                .abs() >
            0.5) {
          failures.add('$where — 라벨 ↔ 숫자 ${valueRect.top - label.bottom}');
        }
        if ((delta.top - valueRect.bottom - (want['delta.marginTop'] as num))
                .abs() >
            0.5) {
          failures.add('$where — 숫자 ↔ 증감 ${delta.top - valueRect.bottom}');
        }
        _expectText(
          failures,
          where,
          _text(tester, 'delta-value').style!,
          want,
          'delta',
          mode,
        );
        if (combo['delta'] != 'flat') {
          _expectText(
            failures,
            where,
            _text(tester, 'delta-text').style!,
            want,
            'deltaText',
            mode,
          );
          final dt = tester.getRect(find.byKey(const ValueKey('delta-text')));
          if ((dt.left - delta.right - (want['deltaText.gap'] as num)).abs() >
              0.5) {
            failures.add('$where — 증감 값 ↔ 글 ${dt.left - delta.right}');
          }
        } else if (find
            .byKey(const ValueKey('delta-text'))
            .evaluate()
            .isNotEmpty) {
          failures.add('$where — flat 인데 기준 글이 보인다');
        }
      }
      if (failures.isNotEmpty) fail(failures.join('\n'));
    });

    testWidgets('${mode.name} — 순자산 카드: 흰 글자 셋 · 장식 빛 · 증감도 흰 글자', (
      tester,
    ) async {
      final want = _spec.resolve({'variant': 'hero'}, 'enabled');
      final failures = <String>[];
      await tester.pumpWidget(
        _host(
          mode,
          const PCard(
            variant: PCardVariant.hero,
            children: [
              PCardHeroLabel('순자산'),
              PCardHeroAmount('42,898,100원'),
              PCardHeroDetail(
                child: PDelta(
                  direction: PDeltaDirection.up,
                  value: '1.8%',
                  text: '지난달보다',
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      _expectText(
        failures,
        mode.name,
        _text(tester, 'card-hero-label').style!,
        want,
        'heroLabel',
        mode,
      );
      final amount = _text(tester, 'card-hero-amount').style!;
      _expectText(failures, mode.name, amount, want, 'heroAmount', mode);
      expect(amount.color!.a, 1, reason: '흰 글자에 불투명도를 주지 않는다');
      expect(amount.fontFeatures, contains(const FontFeature.tabularFigures()));
      final label = tester.getRect(
        find.byKey(const ValueKey('card-hero-label')),
      );
      final amountRect = tester.getRect(
        find.byKey(const ValueKey('card-hero-amount')),
      );
      expect(amountRect.top - label.bottom, want['heroAmount.marginTop']);
      final delta = tester.getRect(find.byKey(const ValueKey('delta-value')));
      expect(delta.top - amountRect.bottom, want['heroDetail.marginTop']);
      for (final k in ['delta-value', 'delta-text']) {
        expect(
          _text(tester, k).style!.color,
          (mode == Brightness.dark ? PColors.dark : PColors.light).staticWhite,
          reason: k,
        );
      }
      // 장식 빛 — 240 원 · 오른쪽 −40 · 위 −80, 흰 22%
      final glow = tester.getRect(find.byKey(const ValueKey('card-hero-glow')));
      final card = tester.getRect(find.byKey(const ValueKey('card-surface')));
      final glowSpec = (want['heroGlow.size'] as num).toDouble();
      expect(glow.size, Size(glowSpec, glowSpec));
      expect(card.right - glow.right, -40);
      expect(glow.top - card.top, -80);
      final glowDeco =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byKey(const ValueKey('card-hero-glow')),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      final rg = glowDeco.gradient! as RadialGradient;
      expect(
        sameColor(specColor(want['heroGlow.background']), rg.colors.first),
        isTrue,
      );
      expect(rg.colors.last.a, 0);
      // 보조 기술에는 없다
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('card-hero-glow')),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      if (failures.isNotEmpty) fail(failures.join('\n'));
    });

    testWidgets('${mode.name} — 누름: whole 은 면 색 + 축소, peers 는 색만, 순자산은 축소만', (
      tester,
    ) async {
      final pressedBg = specColor(
        pickMode(
          _spec.resolve({'press': 'whole'}, 'pressed')['root.background'],
          mode,
        ),
      );
      final plain = specColor(
        pickMode(_spec.resolve({}, 'enabled')['root.background'], mode),
      );
      Future<TestGesture> press(Finder at) async {
        final g = await tester.startGesture(tester.getCenter(at));
        // 누름이 서는 데 100ms(누름 시간), 바탕이 바뀌는 데 150ms — 한 번에 건너뛰면 애니메이션이 아직 시작 전이다
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 300));
        return g;
      }

      double scale() =>
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

      // whole
      await tester.pumpWidget(
        _host(
          mode,
          PCard(
            onTap: _noop,
            children: const [SizedBox(height: 56, child: Text('식비'))],
          ),
        ),
      );
      expect(sameColor(plain, _face(tester).color!), isTrue);
      var g = await press(findText('식비'));
      expect(
        sameColor(pressedBg, _face(tester).color!),
        isTrue,
        reason: 'whole 눌림 색',
      );
      final size = tester.getSize(find.byKey(const ValueKey('card-surface')));
      final basis = [
        size.height,
        size.width / 4,
        24.0,
      ].reduce((a, b) => a > b ? a : b);
      expect(scale(), closeTo((basis - 2) / basis, 1e-6), reason: '2px 거리 축소');
      await g.up();
      await tester.pumpAndSettle();
      expect(scale(), 1);
      expect(sameColor(plain, _face(tester).color!), isTrue);

      // 모션 줄이기 — 색만
      await tester.pumpWidget(
        _host(
          mode,
          PCard(
            onTap: _noop,
            children: const [SizedBox(height: 56, child: Text('식비'))],
          ),
          reduceMotion: true,
        ),
      );
      g = await press(findText('식비'));
      expect(scale(), 1);
      expect(sameColor(pressedBg, _face(tester).color!), isTrue);
      await g.up();
      await tester.pumpAndSettle();

      // peers — 색만 바뀌고 축소는 없다
      await tester.pumpWidget(
        _host(
          mode,
          PCard(
            press: PCardPress.peers,
            onTap: _noop,
            semanticLabel: '장보기 메모',
            children: const [SizedBox(height: 56, child: Text('메모'))],
          ),
        ),
      );
      expect(find.byType(AnimatedScale), findsNothing);
      g = await press(findText('메모'));
      expect(
        sameColor(
          specColor(
            pickMode(
              _spec.resolve({'press': 'peers'}, 'pressed')['root.background'],
              mode,
            ),
          ),
          _face(tester).color!,
        ),
        isTrue,
      );
      await g.up();
      await tester.pumpAndSettle();

      // 순자산 — 색은 그대로, 축소만
      await tester.pumpWidget(
        _host(
          mode,
          PCard(
            variant: PCardVariant.hero,
            onTap: _noop,
            children: const [PCardHeroLabel('순자산')],
          ),
        ),
      );
      final before = (_face(tester).gradient! as LinearGradient).colors;
      g = await press(find.byKey(const ValueKey('card-hero-label')));
      expect((_face(tester).gradient! as LinearGradient).colors, before);
      expect(scale(), lessThan(1));
      await g.up();
      await tester.pumpAndSettle();
    });
  }

  group('동작', () {
    testWidgets('보기만 하는 카드는 역할이 없고 눌리지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PCard(children: [SizedBox(height: 40, child: Text('보기'))]),
        ),
      );
      expect(find.byType(AnimatedScale), findsNothing);
      expect(
        tester.getSemantics(findText('보기')),
        isNot(matchesSemantics(isButton: true)),
      );
      handle.dispose();
    });

    testWidgets('whole 은 카드 전체가 버튼 하나이고 탭하면 불린다', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCard(
            onTap: () => taps++,
            children: const [PCardHeader(title: '식비 예산')],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('card-surface'))),
        containsSemantics(isButton: true, hasTapAction: true, label: '식비 예산'),
      );
      await tester.tap(find.byKey(const ValueKey('card-title')));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('머리 동작의 이름은 "{제목} {글}" 이고 제목은 머리글이다', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCard(
            children: [
              PCardHeader(
                title: '이번 달 예산',
                actionLabel: '전체 보기',
                onAction: () => taps++,
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('이번 달 예산 전체 보기'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('card-title'))),
        matchesSemantics(isHeader: true, label: '이번 달 예산'),
      );
      await tester.tap(findText('전체 보기'));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('머리 동작을 누르면 카드는 그대로이고 동작 상자만 바탕 + 축소다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCard(
            children: const [
              PCardHeader(title: '예산', actionLabel: '관리', onAction: _noop),
            ],
          ),
        ),
      );
      final g = await tester.startGesture(tester.getCenter(findText('관리')));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 300));
      final deco =
          tester
                  .widget<Container>(
                    find.byKey(const ValueKey('text-button-box')),
                  )
                  .decoration!
              as BoxDecoration;
      final want = specColor(
        pickMode(
          _spec.resolve({}, 'pressed')['headerAction.background'],
          Brightness.light,
        ),
      );
      expect(sameColor(want, deco.color!), isTrue);
      final box = tester.getSize(find.byKey(const ValueKey('text-button-box')));
      final basis = [
        box.height,
        box.width / 4,
        24.0,
      ].reduce((a, b) => a > b ? a : b);
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        closeTo((basis - 2) / basis, 1e-6),
      );
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets('peers — 안의 버튼은 따로 눌리고 카드 누름은 일어나지 않는다, 카드의 이름은 따로 읽힌다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var card = 0, star = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCard(
            press: PCardPress.peers,
            onTap: () => card++,
            semanticLabel: '장보기 메모',
            children: [
              Row(
                children: [
                  const Expanded(child: Text('장보기 메모')),
                  Semantics(
                    button: true,
                    label: '장보기 메모 고정',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => star++,
                      child: const SizedBox(
                        key: ValueKey('star'),
                        width: 40,
                        height: 40,
                        child: ColoredBox(color: Color(0x00000000)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('장보기 메모'), findsWidgets);
      expect(find.bySemanticsLabel('장보기 메모 고정'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('star')));
      expect((card, star), (0, 1));
      await tester.tap(findText('장보기 메모').first);
      expect((card, star), (1, 1));
      handle.dispose();
    });

    testWidgets('peers — 카드 이름과 보이는 제목을 한 번만 읽는다(03D-014)', (tester) async {
      final handle = tester.ensureSemantics();
      Widget card({String? label, PCardPress press = PCardPress.peers}) =>
          _host(
            Brightness.light,
            PCard(
              press: press,
              onTap: () {},
              semanticLabel: label,
              children: const [
                PCardHeader(title: '장보기 메모'),
                PCardContent(children: [Text('우유 · 달걀 · 빵')]),
              ],
            ),
          );
      int named(WidgetTester t) => t.semantics
          .simulatedAccessibilityTraversal()
          .where((n) => n.label == '장보기 메모')
          .length;
      // 이름 있는 peers 카드 — 카드 링크 하나만 그 이름을 읽는다, 제목은 머리말로도 따로 읽지 않는다
      await tester.pumpWidget(card(label: '장보기 메모'));
      expect(named(tester), 1);
      final link = tester.getSemantics(
        find.byKey(const ValueKey('card-peers-link')),
      );
      expect(link.label, '장보기 메모');
      expect(link.getSemanticsData().flagsCollection.isButton, isTrue);
      // 본문은 그대로 읽힌다
      expect(find.bySemanticsLabel('우유 · 달걀 · 빵'), findsOneWidget);
      // 이름 없는 peers 카드 — 이름을 줄 곳이 제목뿐이라 제목을 머리말로 읽는다
      await tester.pumpWidget(card());
      expect(named(tester), 1);
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('card-title')))
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
      );
      // peers 가 아닌 카드(whole)는 지금처럼 제목이 머리말이다
      await tester.pumpWidget(card(label: '장보기 메모', press: PCardPress.whole));
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('card-title')))
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets(
      'peers — 안의 버튼을 누르는 동안 카드 면은 바뀌지 않고, 카드 링크 자리를 누르면 면 색만 바뀐다(Q-011-9)',
      (tester) async {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PCard(
              press: PCardPress.peers,
              onTap: () {},
              semanticLabel: '장보기 메모',
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('장보기 메모')),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: const SizedBox(
                        key: ValueKey('star'),
                        width: 40,
                        height: 40,
                        child: ColoredBox(color: Color(0x00000000)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        Color? face() =>
            ((tester
                        .widget<Container>(
                          find.descendant(
                            of: find.byKey(const ValueKey('card-surface')),
                            matching: find.byType(Container),
                          ),
                        )
                        .decoration)
                    as BoxDecoration)
                .color;
        final rest = face();
        // 안의 버튼 위에 오래 댄다 — 카드 면은 그대로
        final onButton = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('star'))),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 300));
        expect(face(), rest);
        await onButton.cancel();
        await tester.pump(const Duration(milliseconds: 300));
        // 카드 링크 자리(글 · 빈 곳) — 면 색이 바뀐다(축소는 없다)
        final onLink = await tester.startGesture(
          tester.getCenter(findText('장보기 메모')),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 300));
        expect(face(), isNot(rest));
        expect(
          tester
              .widget<Container>(
                find.descendant(
                  of: find.byKey(const ValueKey('card-surface')),
                  matching: find.byType(Container),
                ),
              )
              .decoration,
          isNotNull,
        );
        await onLink.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '머리 동작의 누르는 영역은 44 — 보이는 상자(36) 위아래 4 에서도 눌린다, 5 에서는 눌리지 않는다(Q-011-8)',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PCard(
              children: [
                PCardHeader(
                  title: '예산',
                  actionLabel: '관리',
                  onAction: () => taps++,
                ),
                const PCardContent(children: [SizedBox(height: 40)]),
              ],
            ),
          ),
        );
        final box = tester.getRect(
          find.byKey(const ValueKey('text-button-box')),
        );
        expect(box.height, 36, reason: '보이는 상자 36(SEED Text Button)');
        final x = box.center.dx;
        await tester.tapAt(Offset(x, box.top - 3.5));
        await tester.tapAt(Offset(x, box.bottom + 3.5));
        expect(taps, 2, reason: '위 · 아래 4 안');
        await tester.tapAt(Offset(x, box.top - 5));
        await tester.tapAt(Offset(x, box.bottom + 5));
        expect(taps, 2, reason: '44 밖');
      },
    );

    testWidgets('순자산은 body 를 list 로 줘도 글 카드 여백 24 이다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PCard(
            variant: PCardVariant.hero,
            body: PCardBody.list,
            children: [PCardHeroLabel('순자산')],
          ),
        ),
      );
      final card = tester.getRect(find.byKey(const ValueKey('card-surface')));
      expect(
        tester.getRect(find.byKey(const ValueKey('card-hero-label'))).left -
            card.left,
        24,
      );
    });

    testWidgets('PCardContent 는 요소 사이 12 로 쌓는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PCard(
            children: [
              PCardContent(
                children: [
                  SizedBox(height: 10, key: ValueKey('a')),
                  SizedBox(height: 10, key: ValueKey('b')),
                ],
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('b'))).dy -
            tester.getBottomLeft(find.byKey(const ValueKey('a'))).dy,
        _spec.resolve({}, 'enabled')['content.gap'],
      );
    });

    testWidgets('1억이 넘는 금액도 줄이지 않고 그대로, 칸보다 길면 줄이 바뀐다', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, _statCardWorst()));
      expect(findText('−123,456,789,012원'), findsNothing); // 낱말 이음 문자가 끼어 있다
      expect(tester.takeException(), isNull);
      final value = _text(tester, 'card-stat-value');
      expect(value.semanticsLabel, '−123,456,789,012원');
      expect(value.style!.fontSize, 24);
    });

    testWidgets('카드 안 목록의 누름 바탕 모서리는 List 기본 10(카드 16 − 6) — 카드가 덮지 않는다', (
      tester,
    ) async {
      expect(
        _spec.resolve({'body': 'list'}, 'enabled')['list.itemRadius'],
        PRounded.r4 - 6,
      );
    });
  });

  group('증감', () {
    test('값 앞의 부호는 뗀다 — "+-12.5%" 가 아니라 "12.5%"', () {
      expect(unsignedDelta('+12%'), '12%');
      expect(unsignedDelta('−12%'), '12%');
      expect(unsignedDelta('-12%'), '12%');
      expect(unsignedDelta('±0%'), '0%');
      expect(unsignedDelta('+-12.5%'), '12.5%');
      expect(unsignedDelta(' + 3원'), '3원');
    });

    test('읽는 문장 — 방향에서 만든다', () {
      expect(
        deltaSentence(PDeltaDirection.up, '+12%', '지난달보다'),
        '지난달보다 12% 늘었어요',
      );
      expect(
        deltaSentence(PDeltaDirection.down, '−3%', '지난달보다'),
        '지난달보다 3% 줄었어요',
      );
      expect(
        deltaSentence(PDeltaDirection.flat, null, '지난달보다'),
        '지난달보다 변화가 없어요',
      );
    });

    testWidgets('보조 기술은 화살표 · 값 조각 대신 문장 하나를 읽고, srText 가 이긴다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Column(
            children: const [
              PDelta(
                direction: PDeltaDirection.up,
                value: '+12%',
                text: '지난달보다',
              ),
              PDelta(
                direction: PDeltaDirection.up,
                value: '12%',
                text: '지난달보다',
                srText: '지난달보다 12% 더 썼어요',
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('지난달보다 12% 늘었어요'), findsOneWidget);
      expect(find.bySemanticsLabel('지난달보다 12% 더 썼어요'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('▲')), findsNothing);
      handle.dispose();
    });

    testWidgets('flat 은 "변화 없음" 만 보인다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PDelta(direction: PDeltaDirection.flat, text: '지난달보다'),
        ),
      );
      // 낱말 이음 문자(U+2060)를 뺀 글이 "변화 없음" 이다
      expect(
        _text(tester, 'delta-value').data!.replaceAll('\u2060', ''),
        '변화 없음',
      );
      expect(find.byKey(const ValueKey('delta-text')), findsNothing);
    });
  });

  group('기다림 · 실패', () {
    test('카드 안 Result Section 은 글 카드 0 · 목록 카드 24 로 좌우 여백이 갈린다', () {
      // 글 카드는 카드 여백 24 가 가장자리를 맡고, 목록 카드는 카드 여백이 없어 묶음이 24 를 가진다 — 어느 쪽이든 보이는 24
      expect(resultSectionPaddingX(PResultPlacement.card), 0);
      expect(resultSectionPaddingX(PResultPlacement.listCard), 24);
    });
  });

  test('모션 — 누름 면 · 축소는 스펙의 시간 · easing 이다', () {
    final motion = _spec.json['motion'] as Map;
    final color = motion['누름 — 면'] as Map;
    final shrink = motion['누름 — 축소'] as Map;
    expect(PDuration.colorTransition, specMs(color['duration']));
    expect(PDuration.pressedScale, specMs(shrink['duration']));
    final e = PEasing.easing as Cubic;
    expect([e.a, e.b, e.c, e.d], specCubic(color['easing']));
    final p = PEasing.pressedScale as Cubic;
    expect([p.a, p.b, p.c, p.d], specCubic(shrink['easing']));
  });

  test('순자산 그라디언트는 135° — 모서리에서 모서리까지 선을 긋는다', () {
    final g = PCardHeroGradient(
      start: const Color(0xFF000000),
      end: const Color(0xFFFFFFFF),
    );
    // 정사각형이면 대각선과 같고, 가로로 길어도 선은 (폭 + 높이) ÷ 4 만큼 중심에서 떨어진다
    expect(g.createShader(const Rect.fromLTWH(0, 0, 330, 100)), isNotNull);
    expect(g.colors, hasLength(2));
  });
}

void _noop() {}

Widget _statCardWorst() => const PCard(
  children: [
    PCardStat(
      label: '이번 달 지출 — 이름이 아주 긴 지표 라벨',
      value: '−123,456,789,012원',
      delta: PDelta(
        direction: PDeltaDirection.up,
        value: '+-12.5%',
        text: '지난달보다 훨씬 많이',
      ),
    ),
  ],
);
