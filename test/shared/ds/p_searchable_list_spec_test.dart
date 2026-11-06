// Searchable List 가 스펙 값(test/fixtures/design_spec/searchable-list.json)대로인지 — 놓인 자리 × 앞 붙이개 × 고름 × 상태 ×
// 라이트 · 다크를 모두 돈다. 웹은 같은 JSON 을 크로미움에서 잰다(desk-front `npm run ds:check`).
//
// 앱은 늘 large(검색칸 40)다 — medium(1280 이상 데스크톱 웹)은 재지 않는다. 강조는 실제로 ↓ 키로 짚고, 누름은 손가락을 대고
// 있는 채로 잰다. 동작 테스트(키보드 · 서버 검색 · 알림 · 가장 나쁜 값)는 아래 별도 group.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/bottom_sheet_parts.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';
import 'package:groo_damda_app/shared/ds/radio/p_radio.dart';
import 'package:groo_damda_app/shared/ds/searchable_list/p_searchable_list.dart';
import 'package:groo_damda_app/shared/ds/searchable_list/searchable_list_demo.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('searchable-list');

const _transparent = Color(0x00000000);
const _rows = ['신한은행', '국민은행', '카카오뱅크'];

Widget _host(
  Brightness mode,
  Widget child, {
  double width = 360,
  double? height,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    ),
  ),
);

/// 앞 붙이개 자리표시 — 스펙 크기(로고 40 · 카드 그림 56 폭 · 아바타 36).
Widget? _prefix(String prefix) => switch (prefix) {
  'logo' => const SizedBox(key: ValueKey('prefix'), width: 40, height: 40),
  'cardArt' => const SizedBox(
    key: ValueKey('prefix'),
    width: 56,
    height: 56 / 1.586,
  ),
  'avatar' => const SizedBox(key: ValueKey('prefix'), width: 36, height: 36),
  _ => null,
};

/// 줄 셋 — 둘째 줄만 설명이 있다(두 줄 줄).
Widget _sample({
  required PSearchableListPlacement placement,
  required String prefix,
  required bool current,
}) => PSearchableList(
  key: UniqueKey(),
  placement: placement,
  defaultValue: current ? _rows[0] : null,
  children: [
    const PSearchableListInput(
      autofocus: false,
      placeholder: '은행 이름 검색',
      semanticLabel: '검색',
    ),
    PSearchableListResults(
      semanticLabel: '은행',
      children: [
        PSearchableListGroup(
          label: '시중은행',
          children: [
            for (final (i, name) in _rows.indexed)
              PSearchableListItem(
                value: name,
                title: name,
                detail: i == 1 ? '계좌 · 카드' : null,
                prefix: _prefix(prefix),
              ),
          ],
        ),
      ],
    ),
  ],
);

class _Check {
  _Check(this.mode, this.want, this.where);
  final Brightness mode;
  final Map<String, Object?> want;
  final String where;
  final failures = <String>[];

  void fail(String message) => failures.add('$where — $message');

  void color(String key, Color actual) {
    final w = pickMode(want[key], mode);
    if (w == null) return fail('$key: 스펙에 없다');
    if (!sameColor(specColor(w), actual)) {
      fail('$key: 스펙 $w · 실제 ${colorHex(actual)}');
    }
  }

  void px(String key, num actual) {
    final w = want[key];
    if (w is! num) return fail('$key: 스펙에 수가 없다($w)');
    if ((w - actual).abs() > 0.5) fail('$key: 스펙 $w · 실제 $actual');
  }

  void typo(String key, TextStyle style) {
    final t = want[key] as Map?;
    if (t == null) return fail('$key: 스펙에 없다');
    final lineHeight = style.fontSize! * (style.height ?? 1);
    if (t['fontSize'] != style.fontSize ||
        ((t['lineHeight'] as num) - lineHeight).abs() > 0.01) {
      fail(
        '$key: 스펙 ${t['fontSize']}/${t['lineHeight']} · 실제 ${style.fontSize}/$lineHeight',
      );
    }
    final family = '${t['fontFamily']}'.split(',').first.trim();
    if (style.fontFamily != family) {
      fail('$key: 글꼴 스펙 $family · 실제 ${style.fontFamily}');
    }
  }

  void weight(String key, TextStyle style) {
    final w = want[key];
    if (w is! num) return fail('$key: 스펙에 수가 없다($w)');
    if (style.fontWeight?.value != w) {
      fail('$key: 스펙 $w · 실제 ${style.fontWeight}');
    }
  }
}

Finder get _input => find.byType(TextField);
Finder get _highlights =>
    find.byKey(const ValueKey('searchable-list-highlight'));
Finder get _contents => find.byKey(const ValueKey('searchable-list-content'));
Finder get _skeletonRows => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(
        'searchable-list-skeleton-row-',
      ),
);
Finder get _options => find.byType(PSearchableListItem);

Color _highlightColor(WidgetTester tester, int i) =>
    ((tester.widget<DecoratedBox>(_highlights.at(i)).decoration)
            as BoxDecoration)
        .color ??
    _transparent;

Future<void> _focusInput(WidgetTester tester) async {
  await tester.tap(_input);
  await tester.pump();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

/// 강조한 줄들의 번호 — 한 번에 한 줄이어야 한다.
List<int> _highlighted(WidgetTester tester) => [
  for (var i = 0; i < _highlights.evaluate().length; i++)
    if (_highlightColor(tester, i).a != 0) i,
];

void main() {
  group('Searchable List — 스펙(large × 자리 × 앞 붙이개 × 고름 × 상태 × 라이트 · 다크)', () {
    Future<void> check(
      WidgetTester tester,
      Brightness mode,
      Map<String, String> combo,
      String state,
      List<String> failures,
    ) async {
      final placement = PSearchableListPlacement.values.byName(
        combo['placement']!,
      );
      final prefix = combo['prefix']!;
      final current = combo['selected'] == 'current';
      await tester.pumpWidget(
        _host(
          mode,
          _sample(placement: placement, prefix: prefix, current: current),
        ),
      );
      TestGesture? finger;
      if (state == 'highlighted') {
        await _focusInput(tester);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        await _key(tester, LogicalKeyboardKey.arrowDown); // 둘째 줄
      } else if (state == 'pressed') {
        finger = await tester.startGesture(tester.getCenter(_options.at(1)));
      }
      // 색 전환 · 눌림 모션이 끝나게
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      final want = _spec.resolve(combo, state);
      final k = _Check(mode, want, '${mode.name} $combo $state');

      // 묶음 — 검색칸 ↔ 결과 8, 검색칸 40 · 좌우 24
      final list = tester.getRect(find.byType(PSearchableList));
      final field = tester.getRect(find.byType(PInput));
      k.px('field.height', field.height);
      k.px('field.marginX', field.left - list.left);
      k.px('field.marginX', list.right - field.right);
      final results = tester.getRect(
        find.byKey(const ValueKey('searchable-list-results')),
      );
      k.px('root.gap', results.top - field.bottom);

      // 줄 — 위아래 12 · 좌우 24, 제목 · 설명 글자, 라디오 24
      final firstHeight = tester.getSize(_options.at(0)).height;
      // 위아래 12 + 안쪽 높이. 오른쪽 라디오(24)가 제목 줄(22)보다 커서 앞 붙이개 없는 한 줄은 48 이다(List 의 보기만 하는 줄은 46)
      final wantFirst = switch (prefix) {
        'logo' => 64.0, // 앞 40 이면 64
        'cardArt' => 56 / 1.586 + 24,
        'avatar' => 36.0 + 24,
        _ => 48.0,
      };
      if ((firstHeight - wantFirst).abs() > 0.5) {
        k.fail('option 높이: 기대 $wantFirst · 실제 $firstHeight');
      }
      final secondHeight = tester.getSize(_options.at(1)).height;
      final wantSecond = prefix == 'logo'
          ? 66.0
          : 66.0; // 두 줄 66(앞 40 · 36 은 글이 더 크다)
      if ((secondHeight - wantSecond).abs() > 0.5) {
        k.fail('option 높이(두 줄): 기대 $wantSecond · 실제 $secondHeight');
      }
      final firstRow = tester.getRect(_options.at(0));
      final titleLeft = tester
          .getTopLeft(
            find.descendant(
              of: _options.at(0),
              matching: find.byKey(const ValueKey('searchable-list-title')),
            ),
          )
          .dx;
      final prefixWidth = switch (prefix) {
        'logo' => 40.0 + 12,
        'cardArt' => 56.0 + 12,
        'avatar' => 36.0 + 12,
        _ => 0.0,
      };
      k.px('option.paddingX', titleLeft - firstRow.left - prefixWidth);
      final radio = find.descendant(
        of: _options.at(0),
        matching: find.byType(PRadiomark),
      );
      k.px('radio.size', tester.getSize(radio).width);
      if (tester.getRect(radio).right != firstRow.right - 24) {
        k.fail('option.paddingX: 라디오 오른쪽 여백');
      }
      final title = tester
          .widget<Text>(
            find.descendant(
              of: _options.at(0),
              matching: find.byKey(const ValueKey('searchable-list-title')),
            ),
          )
          .style!;
      k.typo('title.typography', title);
      k.weight('title.fontWeight', title);
      k.color('title.foreground', title.color!);
      final detail = tester
          .widget<Text>(
            find.descendant(
              of: _options.at(1),
              matching: find.byKey(const ValueKey('searchable-list-detail')),
            ),
          )
          .style!;
      k.typo('detail.typography', detail);
      k.color('detail.foreground', detail.color!);

      // 고름 — 오른쪽 라디오만 켠다. 줄 바탕은 칠하지 않는다
      final radios = tester
          .widgetList<PRadiomark>(find.byType(PRadiomark))
          .map((r) => r.checked)
          .toList();
      final wantRadios = current ? [true, false, false] : [false, false, false];
      if ('$radios' != '$wantRadios')
        k.fail('라디오: 기대 $wantRadios · 실제 $radios');
      if (want['radio.display'] != null && !current) {
        k.fail('radio.display 는 고른 줄에만');
      }

      // 강조 바탕 — 좌우 6 들어온 누름 바탕 · 모서리 10. 상태가 아닌 줄은 칠하지 않는다
      final box = tester.getRect(_highlights.at(1));
      final row = tester.getRect(_options.at(1));
      k.px('highlight.insetX', box.left - row.left);
      k.px('highlight.insetX', row.right - box.right);
      if (box.height != row.height) k.fail('강조 바탕은 줄 높이를 채운다');
      final deco =
          tester.widget<DecoratedBox>(_highlights.at(1)).decoration
              as BoxDecoration;
      k.px('highlight.radius', (deco.borderRadius! as BorderRadius).topLeft.x);
      final onSecond = state != 'enabled';
      k.color(
        'highlight.background',
        onSecond ? _highlightColor(tester, 1) : _transparent,
      );
      if (!onSecond && _highlighted(tester).isNotEmpty) {
        k.fail('상태가 없는데 줄이 강조돼 있다');
      }
      if (onSecond && '${_highlighted(tester)}' != '[1]') {
        k.fail('강조는 한 줄만: ${_highlighted(tester)}');
      }
      // 고른 줄(첫 줄)의 바탕은 칠하지 않는다
      if (_highlightColor(tester, 0).a != 0) k.fail('고른 줄의 바탕을 칠했다');

      // 누름 — 콘텐츠만 2px 거리로 준다(기준 max(높이, 폭 ÷ 4, 24))
      final scale = tester.widget<AnimatedScale>(_contents.at(1));
      if (state == 'pressed') {
        final size = tester.getSize(_options.at(1));
        final basis = [
          size.height,
          size.width / 4,
          24.0,
        ].reduce((a, b) => a > b ? a : b);
        if ((scale.scale - (basis - 2) / basis).abs() > 0.0005) {
          k.fail('option.scale: 실제 ${scale.scale}');
        }
        final motion =
            (_spec.json['motion'] as Map)['누름 — 콘텐츠'] as Map<String, dynamic>;
        if (scale.duration != specMs(motion['duration'])) {
          k.fail('scaleDuration: 실제 ${scale.duration}');
        }
        final cubic = specCubic(motion['easing']);
        final curve = scale.curve as Cubic;
        if ([curve.a, curve.b, curve.c, curve.d].toString() !=
            cubic.toString()) {
          k.fail('scaleEasing: 실제 $curve');
        }
        // 바탕은 줄지 않는다 — 콘텐츠 층만
        if (tester.getRect(_highlights.at(1)) != box) k.fail('바탕이 줄었다');
      } else if (scale.scale != 1) {
        k.fail('눌리지 않았는데 콘텐츠가 줄었다');
      }

      await finger?.up();
      await tester.pump(const Duration(milliseconds: 400));
      failures.addAll(k.failures);
    }

    testWidgets('조합 × 상태 × 라이트 · 다크가 스펙과 같다', (tester) async {
      expect(_spec.states, ['enabled', 'highlighted', 'pressed']);
      final failures = <String>[];
      final combos = _spec.combos(['placement', 'prefix', 'selected']);
      expect(combos, hasLength(16));
      for (final mode in [Brightness.light, Brightness.dark]) {
        for (final combo in combos) {
          for (final state in _spec.states) {
            await check(
              tester,
              mode,
              {...combo, 'size': 'large'},
              state,
              failures,
            );
          }
        }
      }
      expect(failures, isEmpty, reason: failures.take(20).join('\n'));
    });
  });

  group('Searchable List — 거르기 · 고르기', () {
    // 쓰는 쪽이 거른다 — 분류 · 줄을 다시 그린다. 공백 · 대소문자는 무시
    const groups = {
      '시중은행': ['국민은행', '신한은행', '하나은행'],
      '인터넷은행': ['카카오뱅크', '토스뱅크'],
    };

    Widget filtered({
      String? value,
      String? query,
      ValueChanged<String>? onValue,
      ValueChanged<String>? onQuery,
      ValueChanged<String>? onSearch,
      Duration delay = const Duration(milliseconds: 300),
      PSearchableListPlacement placement = PSearchableListPlacement.sheet,
      String defaultQuery = '',
    }) => _FilterHost(
      groups: groups,
      value: value,
      query: query,
      onValue: onValue,
      onQuery: onQuery,
      onSearch: onSearch,
      delay: delay,
      placement: placement,
      defaultQuery: defaultQuery,
    );

    testWidgets('치는 대로 onQueryChanged — 쓰는 쪽이 거르고 남은 줄이 없는 분류는 머리째 숨는다', (
      tester,
    ) async {
      final queries = <String>[];
      await tester.pumpWidget(
        _host(Brightness.light, filtered(onQuery: queries.add)),
      );
      expect(_options, findsNWidgets(5));
      expect(find.byKey(const ValueKey('plist-header')), findsNWidgets(2));
      await tester.enterText(_input, '카카오');
      await tester.pump();
      expect(queries, ['카카오']);
      expect(_options, findsOneWidget);
      // 시중은행 줄이 모두 걸러져 머리째 없다
      expect(find.byKey(const ValueKey('plist-header')), findsOneWidget);
      await tester.enterText(_input, '  신 한 ');
      await tester.pump();
      expect(_options, findsOneWidget);
    });

    testWidgets('조합 중에 친 글자도 그대로 검색어가 된다', (tester) async {
      final queries = <String>[];
      await tester.pumpWidget(
        _host(Brightness.light, filtered(onQuery: queries.add)),
      );
      await _focusInput(tester);
      for (final text in ['ㅅ', '시', '신']) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
            composing: TextRange(start: 0, end: text.length),
          ),
        );
        await tester.pump();
      }
      expect(queries, ['ㅅ', '시', '신']);
    });

    testWidgets('치면 강조를 지운다', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, filtered()));
      await _focusInput(tester);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_highlighted(tester), [0]);
      await tester.enterText(_input, '은행');
      await tester.pump();
      expect(_highlighted(tester), isEmpty);
    });

    testWidgets('지우기 버튼은 검색어를 비우고 검색칸에 초점을 둔다 — 전체 목록으로', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, filtered(defaultQuery: '카카오')),
      );
      expect(_options, findsOneWidget);
      await tester.tap(find.byIcon(LucideIcons.circleX));
      await tester.pump();
      expect(_options, findsNWidgets(5));
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
      expect(tester.widget<TextField>(_input).controller!.text, '');
    });

    testWidgets('검색어를 제어하면 밖에서 바꾼 값이 칸에 들어간다', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, filtered(query: '토스')));
      expect(tester.widget<TextField>(_input).controller!.text, '토스');
      await tester.pumpWidget(_host(Brightness.light, filtered(query: '')));
      expect(tester.widget<TextField>(_input).controller!.text, '');
    });

    testWidgets('누르면 그 줄을 고른다 — 비제어는 라디오가 바뀌고 제어는 값을 주는 쪽이 정한다', (
      tester,
    ) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _host(Brightness.light, filtered(onValue: picked.add)),
      );
      await tester.tap(_options.at(1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(picked, ['신한은행']);
      expect(
        tester
            .widgetList<PRadiomark>(find.byType(PRadiomark))
            .map((r) => r.checked),
        [false, true, false, false, false],
      );
      // 제어 — 값을 주는 쪽이 안 바꾸면 그대로
      await tester.pumpWidget(
        _host(Brightness.light, filtered(value: '국민은행', onValue: picked.add)),
      );
      await tester.tap(_options.at(3));
      await tester.pump(const Duration(milliseconds: 400));
      expect(picked, ['신한은행', '카카오뱅크']);
      expect(
        tester
            .widgetList<PRadiomark>(find.byType(PRadiomark))
            .map((r) => r.checked),
        [true, false, false, false, false],
      );
    });

    testWidgets('줄을 눌러도 초점은 검색칸에 남는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          filtered(placement: PSearchableListPlacement.inline),
        ),
      );
      await _focusInput(tester);
      final focused = FocusManager.instance.primaryFocus;
      await tester.tap(_options.at(0));
      await tester.pump(const Duration(milliseconds: 400));
      expect(FocusManager.instance.primaryFocus, focused);
      expect(focused?.hasPrimaryFocus, isTrue);
    });

    testWidgets('마우스를 올린 줄이 강조된다 — 터치는 아니다 · 마우스 강조는 150ms 로 바뀐다', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, filtered()));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(
        tester.getCenter(_options.at(2)) - const Offset(10, 0),
      );
      await mouse.moveTo(tester.getCenter(_options.at(2)));
      // 첫 프레임에서 시작하고 두 번째에서 끝난다
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_highlighted(tester), [2]);
      final box = tester.widget<TweenAnimationBuilder<double>>(
        find.descendant(
          of: _options.at(2),
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
      );
      final motion = (_spec.json['motion'] as Map)['강조 · 누름 — 바탕'] as Map;
      expect(box.duration, specMs(motion['duration']));
      // 다른 줄로 옮기면 한 줄만
      await mouse.moveTo(
        tester.getCenter(_options.at(0)) - const Offset(10, 0),
      );
      await mouse.moveTo(tester.getCenter(_options.at(0)));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_highlighted(tester), [0]);
      // 화살표로 옮길 때는 전환 없이 바로
      await _focusInput(tester);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      final keyed = tester.widget<TweenAnimationBuilder<double>>(
        find.descendant(
          of: _options.at(1),
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
      );
      expect(keyed.duration, Duration.zero);
      // 터치는 강조하지 않는다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          KeyedSubtree(key: UniqueKey(), child: filtered()),
        ),
      );
      final touch = await tester.createGesture();
      await touch.addPointer(location: tester.getCenter(_options.at(3)));
      await touch.moveTo(tester.getCenter(_options.at(4)));
      await tester.pump();
      expect(_highlighted(tester), isEmpty);
      await touch.removePointer();
    });

    testWidgets('마우스가 목록을 떠나면 마우스 강조를 지운다 — 화살표 강조는 남긴다(Q-007-2)', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, filtered()));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 599));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(
        tester.getCenter(_options.at(1)) - const Offset(10, 0),
      );
      await mouse.moveTo(tester.getCenter(_options.at(1)));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_highlighted(tester), [1]);
      // 목록 밖(아래 빈 자리)으로 — 강조가 사라진다
      await mouse.moveTo(const Offset(1, 599));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_highlighted(tester), isEmpty);
      // 화살표로 짚은 강조는 마우스가 떠나도 남는다
      await _focusInput(tester);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_highlighted(tester), [0]);
      await mouse.moveTo(tester.getCenter(_options.at(0)));
      await mouse.moveTo(const Offset(1, 599));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_highlighted(tester), [0]);
    });

    testWidgets(
      '강조 바탕은 좌우 0 → 6 들어오며 모서리 0 → 10 으로 둥글어진다 — 마우스는 150ms, 화살표는 바로',
      (tester) async {
        await tester.pumpWidget(_host(Brightness.light, filtered()));
        Rect rowOf(int i) => tester.getRect(_options.at(i));
        double insetOf(int i) =>
            tester.getRect(_highlights.at(i)).left - rowOf(i).left;
        double radiusOf(int i) =>
            ((tester.widget<DecoratedBox>(_highlights.at(i)).decoration)
                    as BoxDecoration)
                .borderRadius!
                .resolve(TextDirection.ltr)
                .topLeft
                .x;
        // 평소 — 들임 0 · 모서리 0
        expect(insetOf(0), 0);
        expect(radiusOf(0), 0);
        // 화살표 — 전환 없이 바로 6 · 10
        await _focusInput(tester);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(insetOf(0), 6);
        expect(radiusOf(0), 10);
        // 마우스 — 150ms 동안 사이 값을 지난다
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(1, 1));
        addTearDown(mouse.removePointer);
        await mouse.moveTo(
          tester.getCenter(_options.at(2)) - const Offset(10, 0),
        );
        await mouse.moveTo(tester.getCenter(_options.at(2)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        expect(insetOf(2), inExclusiveRange(0, 6));
        expect(radiusOf(2), inExclusiveRange(0, 10));
        await tester.pump(const Duration(milliseconds: 200));
        expect(insetOf(2), 6);
        expect(radiusOf(2), 10);
      },
    );

    testWidgets('강조한 줄이 걸러져 사라지면 강조도 지운다', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, filtered()));
      await _focusInput(tester);
      await _key(tester, LogicalKeyboardKey.arrowUp); // 마지막 줄
      expect(_highlighted(tester), [4]);
      // 검색어를 밖에서 바꿔 그 줄이 없어진다 — 검색어 변경은 강조를 지우지만, 줄만 사라지는 경우도 본다
      await tester.pumpWidget(
        _host(Brightness.light, _RemovableHost(removeLast: true)),
      );
      await tester.pump();
      await tester.pump();
      expect(_highlighted(tester), isEmpty);
    });

    testWidgets('누르는 순간 기준 길이 max(높이, 폭 ÷ 4, 24) 를 잰다 — 폭이 좁으면 높이', (
      tester,
    ) async {
      for (final width in [360.0, 120.0]) {
        await tester.pumpWidget(
          _host(Brightness.light, filtered(), width: width),
        );
        final finger = await tester.startGesture(
          tester.getCenter(_options.at(0)),
        );
        await tester.pump(const Duration(milliseconds: 400));
        final size = tester.getSize(_options.at(0));
        final basis = [
          size.height,
          size.width / 4,
          24.0,
        ].reduce((a, b) => a > b ? a : b);
        expect(
          tester.widget<AnimatedScale>(_contents.first).scale,
          closeTo((basis - 2) / basis, 0.0005),
          reason: '폭 $width',
        );
        await finger.up();
        await tester.pump(const Duration(milliseconds: 400));
      }
    });

    testWidgets('모션 줄이기 — 눌러도 콘텐츠가 줄지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, filtered(), reduceMotion: true),
      );
      final finger = await tester.startGesture(
        tester.getCenter(_options.at(0)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<AnimatedScale>(_contents.first).scale, 1);
      await finger.up();
    });
  });

  group('Searchable List — 키보드 · 초점은 검색칸에', () {
    Widget plain({
      ValueChanged<String>? onValue,
      ValueChanged<String>? onQuery,
      String defaultQuery = '',
    }) => PSearchableList(
      onValueChanged: onValue,
      onQueryChanged: onQuery,
      defaultQuery: defaultQuery,
      children: [
        const PSearchableListInput(semanticLabel: '검색'),
        PSearchableListResults(
          semanticLabel: '은행',
          children: [
            PSearchableListGroup(
              label: '시중은행',
              children: [
                for (final n in ['국민은행', '신한은행'])
                  PSearchableListItem(value: n, title: n),
              ],
            ),
            PSearchableListGroup(
              label: '인터넷은행',
              children: [
                for (final n in ['카카오뱅크', '토스뱅크'])
                  PSearchableListItem(value: n, title: n),
              ],
            ),
          ],
        ),
      ],
    );

    testWidgets('↓ 는 첫 줄 · ↑ 는 마지막 줄에서 시작하고 끝에서 멈춘다 — 분류 머리는 건너뛴다', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, plain()));
      await _focusInput(tester);
      expect(_highlighted(tester), isEmpty);
      final seen = <int>[];
      for (var i = 0; i < 5; i++) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
        seen.add(_highlighted(tester).single);
      }
      expect(seen, [0, 1, 2, 3, 3]);
      for (var i = 0; i < 5; i++) {
        await _key(tester, LogicalKeyboardKey.arrowUp);
      }
      expect(_highlighted(tester), [0]);
      // 강조가 없을 때 ↑ 는 마지막 줄
      await tester.enterText(_input, 'x');
      await tester.enterText(_input, '');
      await tester.pump();
      expect(_highlighted(tester), isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_highlighted(tester), [3]);
      // 초점은 검색칸에 그대로
      expect(
        tester.widget<TextField>(_input).focusNode!.hasPrimaryFocus,
        isTrue,
      );
    });

    testWidgets('Enter 는 강조한 줄을 고른다 · 강조가 없으면 아무것도 하지 않는다', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _host(Brightness.light, plain(onValue: picked.add)),
      );
      await _focusInput(tester);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, ['신한은행']);
      // 소프트 키보드의 확인도 같다
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(picked, ['신한은행', '카카오뱅크']);
    });

    testWidgets('Esc — 검색어가 있으면 지운다 · 비었으면 쓰지 않는다(시트의 뒤로 가기는 따로)', (
      tester,
    ) async {
      final queries = <String>[];
      await tester.pumpWidget(
        _host(Brightness.light, plain(onQuery: queries.add)),
      );
      await _focusInput(tester);
      await tester.enterText(_input, '토스');
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.escape);
      expect(queries, ['토스', '']);
      expect(tester.widget<TextField>(_input).controller!.text, '');
      // 비었으면 아무 일도 없다 — 키를 받지 않고 지나간다
      var bubbled = false;
      FocusManager.instance.primaryFocus!.parent!.onKeyEvent = (n, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          bubbled = true;
        }
        return KeyEventResult.ignored;
      };
      await _key(tester, LogicalKeyboardKey.escape);
      expect(queries, ['토스', '']);
      expect(bubbled, isTrue);
    });

    testWidgets('글자를 조합하는 동안의 ↓ Enter Esc 는 조합의 것이다', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _host(Brightness.light, plain(onValue: picked.add)),
      );
      await _focusInput(tester);
      await _key(tester, LogicalKeyboardKey.arrowDown); // 강조 첫 줄
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '시',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
      );
      await tester.pump();
      // 입력으로 강조는 지워졌다 — 조합 중 ↓ 는 강조를 만들지 않고 Enter 는 고르지 않는다
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_highlighted(tester), isEmpty);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, isEmpty);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(tester.widget<TextField>(_input).controller!.text, '시');
      // 조합이 끝나면 다시 쓰인다
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '시',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_highlighted(tester), [0]);
    });
  });

  group('Searchable List — 서버 검색 · 열릴 때', () {
    Widget server({
      ValueChanged<String>? onSearch,
      Duration delay = const Duration(milliseconds: 300),
      PSearchableListPlacement placement = PSearchableListPlacement.inline,
    }) => PSearchableList(
      placement: placement,
      onSearch: onSearch,
      searchDelay: delay,
      children: const [
        PSearchableListInput(semanticLabel: '검색'),
        PSearchableListEmpty(title: '없어요'),
      ],
    );

    testWidgets('6글자를 쳐도 요청은 한 번 — 마지막 검색어로, 300ms 뒤', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(
        _host(Brightness.light, server(onSearch: sent.add)),
      );
      await _focusInput(tester);
      for (final text in ['t', 'ta', 'tap', 'tapt', 'tapta', 'taptap']) {
        await tester.enterText(_input, text);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(sent, isEmpty);
      await tester.pump(const Duration(milliseconds: 199));
      expect(sent, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(sent, ['taptap']);
    });

    testWidgets('searchDelay 로 바꾼다 · 지우기도 한 번 보낸다 · 사라지면 보내지 않는다', (
      tester,
    ) async {
      final sent = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          server(onSearch: sent.add, delay: const Duration(milliseconds: 50)),
        ),
      );
      await _focusInput(tester);
      await tester.enterText(_input, 'a');
      await tester.pump(const Duration(milliseconds: 49));
      expect(sent, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(sent, ['a']);
      await tester.tap(find.byIcon(LucideIcons.circleX));
      await tester.pump(const Duration(milliseconds: 60));
      expect(sent, ['a', '']);
      // 보내기 전에 사라지면 보내지 않는다
      await tester.enterText(_input, 'b');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      expect(sent, ['a', '']);
    });

    testWidgets('sheet 는 검색칸에 초점, inline 은 두지 않는다 — autofocus 로 바꾼다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          server(placement: PSearchableListPlacement.sheet),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<TextField>(_input).focusNode!.hasPrimaryFocus,
        isTrue,
      );
      await tester.pumpWidget(
        _host(Brightness.light, SizedBox(key: UniqueKey())),
      );
      await tester.pumpWidget(_host(Brightness.light, server()));
      await tester.pump();
      expect(
        tester.widget<TextField>(_input).focusNode!.hasPrimaryFocus,
        isFalse,
      );
    });

    testWidgets('열면 지금 값이 보이게 — 가운데 오도록 스크롤한다', (tester) async {
      final names = [
        for (var i = 0; i < 400; i++) '종목 ${i.toString().padLeft(3, '0')}',
      ];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSearchableList(
            defaultValue: names[250],
            children: [
              const PSearchableListInput(semanticLabel: '검색'),
              PSearchableListResults(
                semanticLabel: '종목',
                children: [
                  for (final n in names)
                    PSearchableListItem(value: n, title: n),
                ],
              ),
            ],
          ),
          height: 400,
        ),
      );
      await tester.pump();
      await tester.pump();
      final scroller = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scroller.position.pixels, greaterThan(250 * 48 - 400));
      // 지금 값이 결과 영역(검색칸 아래)의 가운데쯤에 있다
      final selected = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is PSearchableListItem && w.value == names[250],
        ),
      );
      final results = tester.getRect(find.byType(SingleChildScrollView).first);
      expect((selected.center.dy - results.center.dy).abs(), lessThan(1));
    });
  });

  group('Searchable List — 0건 · 실패 · 불러오는 줄 · 가장 나쁜 값', () {
    testWidgets('0건 — 검색어로 제목을 만들고 알린다(live region) · 개수는 알리지 않는다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSearchableList(
            defaultQuery: '나루로리롱',
            children: [
              const PSearchableListInput(semanticLabel: '검색'),
              PSearchableListEmpty(
                titleBuilder: (q) => "'$q'에 대한 검색 결과가 없어요",
                description: '카드사 이름으로도 찾아보세요.',
              ),
            ],
          ),
        ),
      );
      expect(findText(keepAll("'나루로리롱'에 대한 검색 결과가 없어요")), findsOneWidget);
      expect(findText(keepAll('카드사 이름으로도 찾아보세요.')), findsOneWidget);
      final live = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      expect(live, findsOneWidget);
      expect(find.byIcon(LucideIcons.searchX), findsOneWidget);
      // 공백만이면 검색어를 넣지 않는다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSearchableList(
            key: UniqueKey(),
            defaultQuery: '   ',
            children: [
              const PSearchableListInput(semanticLabel: '검색'),
              PSearchableListEmpty(
                titleBuilder: (q) => q.isEmpty ? '검색 결과가 없어요' : "'$q'",
              ),
            ],
          ),
        ),
      );
      expect(findText(keepAll('검색 결과가 없어요')), findsOneWidget);
      // 결과가 있을 때는 알림 자리가 없다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSearchableList(
            key: UniqueKey(),
            children: [
              const PSearchableListInput(semanticLabel: '검색'),
              PSearchableListResults(
                semanticLabel: '은행',
                children: const [PSearchableListItem(value: 'a', title: 'a')],
              ),
            ],
          ),
        ),
      );
      expect(live, findsNothing);
      handle.dispose();
    });

    testWidgets('실패 — 0건과 따로 쓰고 다시 시도가 onRetry 를 부른다 · 다시 시도 중이면 로딩', (
      tester,
    ) async {
      var retries = 0;
      Widget error({bool retrying = false}) => _host(
        Brightness.light,
        PSearchableList(
          children: [
            const PSearchableListInput(semanticLabel: '검색'),
            PSearchableListError(
              title: '검색 결과를 불러오지 못했어요',
              retryLabel: '다시 시도',
              retrying: retrying,
              onRetry: () => retries++,
            ),
          ],
        ),
      );
      await tester.pumpWidget(error());
      await tester.pump(const Duration(milliseconds: 300));
      expect(findText(keepAll('검색 결과를 불러오지 못했어요')), findsOneWidget);
      expect(findText(keepAll('검색 결과가 없어요')), findsNothing);
      await tester.tap(findText('다시 시도'));
      await tester.pump();
      expect(retries, 1);
      await tester.pumpWidget(error(retrying: true));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byType(PSearchableListError), warnIfMissed: false);
      expect(retries, 1);
    });

    testWidgets('스켈레톤 — 기본 5줄 · 보조 기술에 숨김 · 앞 자리별 모양', (tester) async {
      final sizes = <PSearchableListSkeletonPrefix, Size>{
        PSearchableListSkeletonPrefix.logo: const Size(40, 40),
        PSearchableListSkeletonPrefix.cardArt: const Size(56, 56 / 1.586),
        PSearchableListSkeletonPrefix.avatar: const Size(42, 42),
      };
      final handle = tester.ensureSemantics();
      for (final prefix in PSearchableListSkeletonPrefix.values) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PSearchableList(
              key: UniqueKey(),
              children: [
                const PSearchableListInput(semanticLabel: '검색'),
                PSearchableListSkeleton(prefix: prefix),
              ],
            ),
          ),
        );
        final rows = _skeletonRows;
        expect(rows, findsNWidgets(5), reason: '$prefix');
        // 줄 높이 그대로 — 위아래 12 + 안쪽
        final inner = sizes[prefix];
        final want = inner == null
            ? 22 + 2 + 18 + 24.0
            : [inner.height, 22 + 2 + 18.0].reduce((a, b) => a > b ? a : b) +
                  24;
        expect(
          tester.getSize(rows.first).height,
          closeTo(want, 0.01),
          reason: '$prefix',
        );
        if (inner != null) {
          final prefixBox = tester.getSize(
            find
                .descendant(of: rows.first, matching: find.byType(SizedBox))
                .at(0),
          );
          expect(prefixBox, isNotNull);
        }
        expect(
          find.ancestor(
            of: find.byKey(const ValueKey('searchable-list-skeleton')),
            matching: find.byType(ExcludeSemantics),
          ),
          findsWidgets,
          reason: '$prefix — 스켈레톤은 읽지 않는다',
        );
      }
      // 줄 수를 바꾼다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PSearchableList(
            children: [
              PSearchableListInput(semanticLabel: '검색'),
              PSearchableListSkeleton(rows: 3),
            ],
          ),
        ),
      );
      expect(_skeletonRows, findsNWidgets(3));
      await tester.pump(const Duration(seconds: 2));
      handle.dispose();
    });

    testWidgets('목록 400개 — ↓ 가 끝에서 멈추고 강조한 줄은 보인다', (tester) async {
      final names = [for (var i = 0; i < 400; i++) '종목 $i'];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSearchableList(
            children: [
              const PSearchableListInput(semanticLabel: '검색'),
              PSearchableListResults(
                semanticLabel: '종목',
                children: [
                  for (final n in names)
                    PSearchableListItem(value: n, title: n),
                ],
              ),
            ],
          ),
          height: 500,
        ),
      );
      await _focusInput(tester);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_highlighted(tester), [399]);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_highlighted(tester), [399]);
      // 끝 줄이 결과 영역 안에 있다
      final scroll = tester.getRect(find.byType(SingleChildScrollView).first);
      final last = tester.getRect(_options.at(399));
      expect(last.bottom, lessThanOrEqualTo(scroll.bottom + 0.5));
      expect(_options, findsNWidgets(400));
      // 위로 한 줄씩 — 강조가 따라 올라온다
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_highlighted(tester), [398]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('300자 이름은 단어 단위로 줄바꿈하고 넘치지 않는다 · 빈 목록 · 긴 검색어', (tester) async {
      final long = '가나다라마바사아자차카타파하 ' * 20;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSearchableList(
            defaultQuery: long,
            children: [
              const PSearchableListInput(semanticLabel: '검색'),
              PSearchableListResults(
                semanticLabel: '종목',
                children: [
                  PSearchableListItem(
                    value: 'a',
                    title: long,
                    detail: '설명',
                    prefix: const SizedBox(width: 40, height: 40),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_options.first).height, greaterThan(66));
      final title = tester.getRect(
        find.byKey(const ValueKey('searchable-list-title')),
      );
      final radio = tester.getRect(find.byType(PRadiomark));
      expect(title.right, lessThanOrEqualTo(radio.left));
      // 빈 목록
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSearchableList(
            key: UniqueKey(),
            defaultQuery: long,
            children: [
              const PSearchableListInput(semanticLabel: '검색'),
              PSearchableListEmpty(titleBuilder: (q) => "'$q'에 대한 검색 결과가 없어요"),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // 줄 없는 결과 · 분류도 깨지지 않는다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSearchableList(
            key: UniqueKey(),
            children: const [
              PSearchableListInput(semanticLabel: '검색'),
              PSearchableListResults(
                semanticLabel: '종목',
                children: [PSearchableListGroup(label: '없음', children: [])],
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('접근성 — 검색칸 이름 · 목록 이름 · 고른 줄은 selected · 앞 붙이개 · 라디오는 읽지 않는다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSearchableList(
            defaultValue: 'b',
            children: [
              const PSearchableListInput(
                placeholder: '은행 이름 검색',
                semanticLabel: '검색',
              ),
              PSearchableListResults(
                semanticLabel: '은행',
                children: const [
                  PSearchableListItem(
                    value: 'a',
                    title: '국민은행',
                    detail: '계좌 · 카드',
                    prefix: Text('PREFIX'),
                  ),
                  PSearchableListItem(value: 'b', title: '신한은행'),
                ],
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('검색'), findsWidgets);
      expect(find.bySemanticsLabel('은행'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('PREFIX')), findsNothing);
      final selected = tester.getSemantics(
        find.bySemanticsLabel(RegExp('신한은행')).first,
      );
      expect(selected.flagsCollection.isSelected.toBoolOrNull(), isTrue);
      final other = tester.getSemantics(
        find.bySemanticsLabel(RegExp('국민은행')).first,
      );
      expect(other.flagsCollection.isSelected.toBoolOrNull(), isNot(isTrue));
      expect(other.label, contains('계좌 · 카드'));
      handle.dispose();
    });

    testWidgets(
      'selectionMark off — 라디오가 없고 줄은 최소 48 · 좌우 24 · 누르면 바로 알린다(스펙 radio.display 없음 · option.minHeight 48)',
      (tester) async {
        final picked = <String>[];
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PSearchableList(
              selectionMark: PSearchableListSelectionMark.off,
              onValueChanged: picked.add,
              children: const [
                PSearchableListInput(placeholder: '검색', semanticLabel: '검색'),
                PSearchableListResults(
                  semanticLabel: '결과',
                  children: [
                    PSearchableListItem(value: 'a', title: '한 줄'),
                    PSearchableListItem(value: 'b', title: '두 줄', detail: '설명'),
                  ],
                ),
              ],
            ),
          ),
        );
        expect(find.byType(PRadiomark), findsNothing);
        final h = [
          for (var i = 0; i < 2; i++) tester.getSize(_options.at(i)).height,
        ];
        expect(h[0], 48); // 제목 22 + 위아래 24 = 46 을 48 로 올린다
        expect(h[1], 66);
        // 글 왼쪽 24 · 오른쪽 끝 24 안에 든다
        final title = tester.getRect(
          find.byKey(const ValueKey('searchable-list-title')).first,
        );
        expect(title.left - tester.getRect(_options.at(0)).left, 24);
        await tester.tap(_options.at(1));
        await tester.pump(const Duration(milliseconds: 400));
        expect(picked, ['b']);
      },
    );

    testWidgets('묶음 밖에서 쓰면 알려 준다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PSearchableListItem(value: 'a', title: 'a'),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });

  testWidgets('은행 시트 — 입력칸을 누르면 시트가 열려 검색칸에 초점, 줄을 누르면 고르고 닫힌다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        Brightness.light,
        const SingleChildScrollView(child: SearchableListDemo()),
        width: 390,
        height: 844,
      ),
    );
    final trigger = find.byWidgetPredicate(
      (w) => w is PInputButton && w.placeholder == '은행 선택',
    );
    await tester.ensureVisible(trigger);
    await tester.pump();
    await tester.tap(trigger);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    // 시트가 첫 초점을 검색칸으로 넘겨준다 — 열린 첫 프레임 뒤 한 번(다시 잡지 않는다)
    await tester.pump();
    // 시트 안 검색칸에 초점
    final sheetInput = find.descendant(
      of: find.byType(PBottomSheetContent),
      matching: find.byType(TextField),
    );
    expect(sheetInput, findsOneWidget);
    expect(
      tester.widget<TextField>(sheetInput).focusNode!.hasPrimaryFocus,
      isTrue,
    );
    // 거르면 줄이 줄고, 줄을 누르면 닫히며 칸에 들어간다
    await tester.enterText(sheetInput, '토스');
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(PBottomSheetContent),
        matching: find.byType(PSearchableListItem),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(PBottomSheetContent),
        matching: find.byType(PSearchableListItem),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(PBottomSheetContent), findsNothing);
    expect(tester.widget<PInputButton>(trigger).value, '토스뱅크');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('견본 은행 시트 — 별칭으로 찾고, 낱자로 쪼개진 한글(NFD)도 같은 글자로 본다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        Brightness.light,
        const SingleChildScrollView(child: SearchableListDemo()),
        width: 390,
        height: 844,
      ),
    );
    final trigger = find.byWidgetPredicate(
      (w) => w is PInputButton && w.placeholder == '은행 선택',
    );
    await tester.ensureVisible(trigger);
    await tester.pump();
    await tester.tap(trigger);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    final sheetInput = find.descendant(
      of: find.byType(PBottomSheetContent),
      matching: find.byType(TextField),
    );
    final sheetRows = find.descendant(
      of: find.byType(PBottomSheetContent),
      matching: find.byType(PSearchableListItem),
    );
    // 별칭 — 이름에 없는 "카뱅"
    await tester.enterText(sheetInput, '카뱅');
    await tester.pump();
    expect(sheetRows, findsOneWidget);
    expect(tester.widget<PSearchableListItem>(sheetRows).value, '카카오뱅크');
    // 공백 · 대소문자 무시 — "K B 국민" = 별칭 "KB국민은행"
    await tester.enterText(sheetInput, 'k b 국민');
    await tester.pump();
    expect(tester.widget<PSearchableListItem>(sheetRows).value, '국민은행');
    // NFD — 토(ㅌ ㅗ) 스(ㅅ ㅡ) 를 자모로 쪼갠 글도 "토스뱅크" 를 찾는다
    await tester.enterText(sheetInput, '\u1110\u1169\u1109\u1173');
    await tester.pump();
    expect(tester.widget<PSearchableListItem>(sheetRows).value, '토스뱅크');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('견본이 폰 폭에서 라이트 · 다크로 그려진다 — 400개 · 300자 이름 포함', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final mode in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(PSpacing.x4 + PSpacing.x5),
              child: SearchableListDemo(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      // 서버 검색 견본의 스켈레톤이 끝나게
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpWidget(const SizedBox());
  });
}

/// 쓰는 쪽이 검색어로 거른다 — 분류 · 줄을 다시 그린다.
class _FilterHost extends StatefulWidget {
  const _FilterHost({
    required this.groups,
    required this.value,
    required this.query,
    required this.onValue,
    required this.onQuery,
    required this.onSearch,
    required this.delay,
    required this.placement,
    required this.defaultQuery,
  });

  final Map<String, List<String>> groups;
  final String? value;
  final String? query;
  final ValueChanged<String>? onValue;
  final ValueChanged<String>? onQuery;
  final ValueChanged<String>? onSearch;
  final Duration delay;
  final PSearchableListPlacement placement;
  final String defaultQuery;

  @override
  State<_FilterHost> createState() => _FilterHostState();
}

class _FilterHostState extends State<_FilterHost> {
  late String _query = widget.query ?? widget.defaultQuery;

  @override
  void didUpdateWidget(_FilterHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != null) _query = widget.query!;
  }

  bool _match(String name) => name
      .replaceAll(RegExp(r'\s+'), '')
      .toLowerCase()
      .contains(_query.replaceAll(RegExp(r'\s+'), '').toLowerCase());

  @override
  Widget build(BuildContext context) {
    return PSearchableList(
      value: widget.value,
      query: widget.query,
      defaultQuery: widget.defaultQuery,
      placement: widget.placement,
      searchDelay: widget.delay,
      onValueChanged: widget.onValue,
      onSearch: widget.onSearch,
      onQueryChanged: (q) {
        setState(() => _query = q);
        widget.onQuery?.call(q);
      },
      children: [
        const PSearchableListInput(
          semanticLabel: '검색',
          placeholder: '은행 이름 검색',
        ),
        PSearchableListResults(
          semanticLabel: '은행',
          children: [
            for (final e in widget.groups.entries)
              PSearchableListGroup(
                label: e.key,
                children: [
                  for (final n in e.value)
                    if (_match(n)) PSearchableListItem(value: n, title: n),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// 줄이 마지막에 하나 빠지는 목록.
class _RemovableHost extends StatelessWidget {
  const _RemovableHost({required this.removeLast});

  final bool removeLast;

  @override
  Widget build(BuildContext context) {
    final names = ['a', 'b', 'c', 'd', if (!removeLast) 'e'];
    return PSearchableList(
      children: [
        const PSearchableListInput(semanticLabel: '검색'),
        PSearchableListResults(
          semanticLabel: '목록',
          children: [
            for (final n in names) PSearchableListItem(value: n, title: n),
          ],
        ),
      ],
    );
  }
}
