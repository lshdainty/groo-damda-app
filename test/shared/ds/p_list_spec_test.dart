// List 가 스펙 값(test/fixtures/design_spec/list.json · list-header.json)대로인지 — 줄(맞춤 × 강조 × 상태 · 부모 줄 ×
// 펼침 · 하위 줄) × 기본 · 누름 · 비활성 × 라이트 · 다크의 여백 · 글자 · 색 · 바탕 층(좌우 6 · 모서리 10) · 콘텐츠 층
// 축소 · 앞 아이콘 22 · 타일 40 · 뒤 글 · 화살표 · 줄 사이 선 · 꺾쇠 단추 44, 목록 제목 두 모양, 그리고 줄의 종류별 동작
// · 읽는 말 · 읽는 순서 · 가장 나쁜 값. 웹은 같은 JSON 을 크로미움에서 잰다.
//
// 앱에 없는 상태(웹의 hovered · focused — 올림 · 포커스 링)는 재지 않는다. 문장으로 된 값은 그린 결과나 동작으로 본다 —
// 누름 축소("2px 거리")는 그려진 배율로, 누르는 영역("줄 전체")은 누른 자리로, 하위 줄 보임 · 숨김은 트리에 있는지로 잰다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/shared/ds/header_row/p_header_row.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/list/list_demo.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_parent_item.dart';
import 'package:groo_damda_app/shared/ds/radio/p_radio.dart';
import 'package:groo_damda_app/shared/ds/switch/p_switch.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('list');
final _headerSpec = DesignSpec.load('list-header');

/// 앱의 상태 — 웹의 hovered(올림) · focused(키보드 포커스 링)는 앱에 없다.
final _appStates = _spec.states
    .where((s) => s != 'hovered' && s != 'focused')
    .toList();

PColors _colors(Brightness mode) =>
    mode == Brightness.dark ? PColors.dark : PColors.light;

/// 본문 최소 폭 — 제목의 가장 긴 낱말 폭(t5, 배율 1, 상한 없음) + 뒤 여백 10.
double _minBody(String title) =>
    listTitleMinWidth(
      title: title,
      style: PTypography.t5,
      scaler: TextScaler.noScaling,
      direction: TextDirection.ltr,
      cap: 10000,
    ) +
    kPListBodyTrailGap;

Widget _host(
  Brightness mode,
  Widget child, {
  bool reduceMotion = false,
  double width = 360,
}) {
  final app = MaterialApp(
    theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
  return reduceMotion
      ? MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: app,
        )
      : app;
}

void _noop() {}

// ── 찾기 · 재기 ──────────────────────────────────────────────

Finder _key(String name) => find.byKey(ValueKey(name));
Finder get _items => _key('plist-item');
Finder get _rows => _key('plist-row');
Finder get _backgrounds => _key('plist-background');
Finder get _contents => _key('plist-content');
Finder get _titles => _key('plist-title');
Finder get _details => _key('plist-detail');
Finder get _prefixes => _key('plist-prefix');
Finder get _bodies => _key('plist-body');
Finder get _suffixes => _key('plist-suffix');
Finder get _expandButtons => _key('plist-expand-button');
Finder get _expandIcons => _key('plist-expand-icon');
Finder get _subLists => _key('plist-sub-list');

BoxDecoration _decoration(WidgetTester tester, Finder finder) =>
    tester.widget<DecoratedBox>(finder).decoration as BoxDecoration;

/// 글의 실제 모습 — 줄이 입힌 글자 모양까지 합쳐진 값.
TextStyle _textStyle(WidgetTester tester, Finder text) => tester
    .widget<RichText>(
      find
              .descendant(of: text, matching: find.byType(RichText))
              .evaluate()
              .isEmpty
          ? find.ancestor(of: text, matching: find.byType(RichText)).first
          : find.descendant(of: text, matching: find.byType(RichText)).first,
    )
    .text
    .style!;

/// 아이콘의 색 — Icon 이 그리는 글자(아이콘 글꼴)의 색.
Color _iconColor(WidgetTester tester, Finder icon) => tester
    .widget<RichText>(
      find.descendant(of: icon, matching: find.byType(RichText)).first,
    )
    .text
    .style!
    .color!;

/// 그려지는 배율 — 그 상자에서 화면까지 겹친 변환의 확대(레이아웃 크기에는 안 잡히는 누름 축소를 잰다).
double _paintedScale(WidgetTester tester, Finder finder) =>
    tester.renderObject(finder).getTransformTo(null).entry(0, 0);

/// 누른 채로 두고(누름), 전환(바탕 150ms · 축소 150ms)이 끝나게 기다린다.
Future<TestGesture> _press(WidgetTester tester, Finder target) async {
  final gesture = await tester.startGesture(tester.getCenter(target));
  // 누른 프레임 — 여기서 누름 바탕 · 축소가 시작된다. 바깥 줄과 겨루는 안쪽 버튼(꺾쇠 단추)은 누름 지연(100ms)이
  // 지나야 누른 모습이 된다
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
  await tester.pump(const Duration(milliseconds: 400));
  return gesture;
}

/// 상태가 바뀐 프레임에서 전환이 시작되므로 한 프레임을 먼저 돌린 뒤 끝나게 기다린다.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// 실패를 모으는 도우미 — 색 · 수 · 글자를 스펙과 맞춘다.
class _Check {
  _Check(this.mode, this.want, this.where);

  final Brightness mode;
  final Map<String, Object?> want;
  final String where;
  final failures = <String>[];
  final measured = <String>{};

  void fail(String message) => failures.add('$where — $message');

  void color(String key, Color actual) {
    measured.add(key);
    final w = pickMode(want[key], mode);
    if (w == null) return;
    if (!sameColor(specColor(w), actual)) {
      fail('$key: 스펙 $w · 실제 ${colorHex(actual)}');
    }
  }

  void px(String key, num actual) {
    measured.add(key);
    final w = want[key];
    if (w is num && (w - actual).abs() > 0.5) {
      fail('$key: 스펙 $w · 실제 $actual');
    }
  }

  void typo(String key, TextStyle style) {
    measured.add(key);
    final t = want[key] as Map?;
    if (t == null) return;
    final lineHeight = style.fontSize! * (style.height ?? 1);
    if (t['fontSize'] != style.fontSize ||
        ((t['lineHeight'] as num) - lineHeight).abs() > 0.01) {
      fail(
        '$key: 스펙 ${t['fontSize']}/${t['lineHeight']} · 실제 ${style.fontSize}/$lineHeight',
      );
    }
    final family = '${t['fontFamily']}'.split(',').first.trim();
    if (style.fontFamily != family) {
      fail('$key 글꼴: 스펙 $family · 실제 ${style.fontFamily}');
    }
  }

  void weight(String key, TextStyle style) {
    measured.add(key);
    final w = want[key];
    if (w is num && style.fontWeight?.value != w) {
      fail('$key: 스펙 $w · 실제 ${style.fontWeight}');
    }
  }

  /// 웹 cursor — pointer 는 손가락(click), not-allowed 는 금지(forbidden).
  void cursor(String key, MouseCursor actual) {
    measured.add(key);
    final expected = switch (want[key]) {
      'pointer' => SystemMouseCursors.click,
      'not-allowed' => SystemMouseCursors.forbidden,
      _ => null,
    };
    if (expected != null && actual != expected) {
      fail('$key: 스펙 ${want[key]} · 실제 $actual');
    }
  }

  void radius(String key, BoxDecoration deco) =>
      px(key, (deco.borderRadius! as BorderRadius).topLeft.x);

  /// 누름 축소 — 스펙에 그 값이 있으면(누름) 기준 길이 max(높이, 폭 ÷ 4, 24) 에서 세로 2px, 없으면 1.
  void pressScale(String key, double actual, Size size) {
    measured.add(key);
    var expected = 1.0;
    if (want[key] != null) {
      final basis = math.max(size.height, math.max(size.width / 4, 24.0));
      expected = (basis - 2) / basis;
    }
    if ((expected - actual).abs() > 1e-3) {
      fail('$key: 배율 스펙 $expected · 실제 $actual');
    }
  }

  void motion(String durationKey, String easingKey, Duration d, Curve curve) {
    measured
      ..add(durationKey)
      ..add(easingKey);
    if (want[durationKey] != null && specMs(want[durationKey]) != d) {
      fail('$durationKey: 스펙 ${want[durationKey]} · 실제 $d');
    }
    if (want[easingKey] != null) {
      final cubic = specCubic(want[easingKey]);
      if (curve is! Cubic ||
          [curve.a, curve.b, curve.c, curve.d].join(',') != cubic.join(',')) {
        fail('$easingKey: 스펙 ${want[easingKey]} · 실제 $curve');
      }
    }
  }

  /// 스펙이 푼 값은 모두 어딘가에서 잰다 — 여기서 재거나, 동작 테스트가 보거나([elsewhere]), 앱에 없는 값이다.
  /// 스펙에 새 값이 생기면 여기서 걸린다(재지 않고 지나가지 않게).
  void coverage(Set<String> elsewhere, {Set<String> skipSlots = const {}}) {
    for (final key in want.keys) {
      if (skipSlots.contains(key.split('.').first)) continue;
      if (!measured.contains(key) && !elsewhere.contains(key)) {
        fail('$key: 스펙에 있는데 이 테스트가 재지 않는다 — 재는 곳을 더한다');
      }
    }
  }
}

/// 동작 테스트가 보는 값 — 누르는 영역(줄 전체) · 전환이 무엇을 바꾸는지의 글 · 하위 줄 보임 · 숨김 · 이름 · 카테고리마다 다른
/// 색(타일 바탕 · 아이콘 색은 부르는 쪽이 준다 — 막히면 비활성 색이고 그 값은 여기서 잰다).
const _behavior = {
  'item.touchTarget',
  'background.transitionProperty',
  'content.transitionProperty',
  'expandButton.touchTarget',
  'expandButton.transitionProperty',
  'expandButton.name',
  'subList.display',
  // 좁은 줄(03-D 결정 1 B) — 아래 '좁은 줄' 묶음이 문턱과 모양을 잰다
  'content.stackBelow',
  // 값이 길 때(Q-001) — 가장 나쁜 값 묶음의 '값이 길 때' 테스트가 잰다
  'body.flexGrow',
  'body.minWidth',
  'title.overflowWrap',
  'title.wordBreak',
  'detail.overflowWrap',
  'suffix.shrink',
  'suffixText.shrink',
  'suffixText.overflowWrap',
  // 줄 끝 오른쪽 맞춤(end) — p_list_value_end_test.dart 가 줄마다 오른쪽 끝으로 잰다
  'suffixText.textAlign',
};

/// 앱에 없는 값 — 포커스 링은 웹 상태(키보드 포커스 링)다.
const _webOnly = {
  'focusRing.width',
  'focusRing.offset',
  'focusRing.color',
  'expandButton.outlineWidth',
  'expandButton.outlineOffset',
  'expandButton.outlineColor',
};

// ── 견본 ─────────────────────────────────────────────────────

/// 단계 없는 목록의 견본 — 앞 아이콘 · 제목 · 설명 · 값 글자 + 화살표 줄, 앞 타일 · 금액 줄, 줄 사이 선. 맞춤 · 강조 ·
/// 상태가 스펙의 조합이다.
Widget _flatList(
  Brightness mode,
  Map<String, String> combo, {
  required bool enabled,
}) {
  final c = _colors(mode);
  return PList(
    semanticLabel: '설정',
    children: [
      PListButtonItem(
        align: combo['align'] == 'top' ? PListAlign.top : PListAlign.center,
        highlighted: combo['highlight'] == 'highlighted',
        prefix: const Icon(LucideIcons.bell, key: ValueKey('sample-icon')),
        title: '결제 알림',
        detail: '결제 예정일 D-1',
        suffix: const PListSuffix(
          children: [
            Text('대한민국 원', key: ValueKey('sample-value')),
            Icon(LucideIcons.chevronRight, key: ValueKey('sample-arrow')),
          ],
        ),
        onTap: enabled ? _noop : null,
      ),
      PListButtonItem(
        prefix: PListTile(
          background: c.chartOrangeWeak,
          color: c.chartOrange,
          child: const Icon(LucideIcons.utensils, key: ValueKey('tile-icon')),
        ),
        title: '점심 · 김치찌개',
        detail: '식비',
        suffix: const Text('-9,000원', key: ValueKey('sample-amount')),
        onTap: enabled ? _noop : null,
      ),
      const PListDivider(),
    ],
  );
}

/// 아이콘 · 타일의 색 — 스펙에 모드 값이 있으면(비활성) 그 값이고, 토큰 이름이면(`chart-{색}`) 부르는 쪽이 준 색이 그대로다.
void _colorOrCaller(_Check k, String key, Color actual, Color passed) {
  if (k.want[key] is Map) {
    k.color(key, actual);
  } else {
    k.measured.add(key);
    if (!sameColor(passed, actual)) {
      k.fail(
        '$key: 부르는 쪽이 준 ${colorHex(passed)} 가 그대로가 아니다 · 실제 ${colorHex(actual)}',
      );
    }
  }
}

/// 단계 없는 줄 — 맞춤 × 강조 × 기본 · 누름 · 비활성.
Future<void> _checkFlat(
  WidgetTester tester,
  Brightness mode,
  Map<String, String> combo,
  String state,
  String title,
) async {
  final c = _colors(mode);
  await tester.pumpWidget(
    _host(mode, _flatList(mode, combo, enabled: state != 'disabled')),
  );
  await tester.pump(const Duration(milliseconds: 400));
  final k = _Check(mode, _spec.resolve(combo, state), title);

  final item = tester.getRect(_items.at(0));
  final row = tester.getRect(_rows.at(0));
  final item2 = tester.getRect(_items.at(1));

  // 목록 — 줄 사이 간격 0
  k.px('root.gap', item2.top - item.bottom);
  final divider = tester.getRect(_key('plist-divider'));
  k.px('root.gap', divider.top - item2.bottom);
  k.px('divider.height', divider.height);
  k.color(
    'divider.background',
    tester
        .widget<ColoredBox>(
          find.descendant(
            of: _key('plist-divider'),
            matching: find.byType(ColoredBox),
          ),
        )
        .color,
  );

  // 줄 — 위아래 12 · 좌우 24 · 맞춤
  k.px('item.paddingY', row.top - item.top);
  k.px('item.paddingY', item.bottom - row.bottom);
  k.px('item.paddingX', row.left - item.left);
  k.px('item.paddingX', item.right - row.right);
  final prefixBox = tester.getRect(_prefixes.at(0));
  final icon = tester.getRect(_key('sample-icon'));
  k.measured.add('item.alignItems');
  if (k.want['item.alignItems'] == 'flex-start') {
    if ((prefixBox.top - row.top).abs() > 0.5) {
      k.fail('item.alignItems: 앞 붙이개가 위가 아니다 $prefixBox · $row');
    }
  } else if ((prefixBox.center.dy - row.center.dy).abs() > 0.5) {
    k.fail('item.alignItems: 앞 붙이개가 가운데가 아니다 $prefixBox · $row');
  }
  k.cursor(
    'item.cursor',
    tester
        .widget<MouseRegion>(
          find
              .ancestor(of: _items.at(0), matching: find.byType(MouseRegion))
              .first,
        )
        .cursor,
  );

  // 앞 붙이개 — 아이콘 22 · 뒤 12
  k.px('prefix.paddingRight', prefixBox.right - icon.right);
  k.px('icon.size', icon.width);
  k.px('icon.size', icon.height);

  // 본문 — 제목 아래 2 · 제목 16 / 22 · 400 · 설명 13 / 18 · 본문 오른쪽 10
  final titleRect = tester.getRect(_titles.at(0));
  final detailRect = tester.getRect(_details.at(0));
  k.px('body.gap', detailRect.top - titleRect.bottom);
  k.px(
    'body.paddingRight',
    ((tester.widget<Padding>(_bodies.at(0)).padding) as EdgeInsetsDirectional)
        .end,
  );

  // 뒤 붙이개 — 값 글자 · 화살표 18 · 사이 4
  final value = tester.getRect(_key('sample-value'));
  final arrow = tester.getRect(_key('sample-arrow'));
  k.px('suffix.gap', arrow.left - value.right);
  k.px('suffixIcon.size', arrow.width);
  k.px('suffixIcon.size', arrow.height);

  // 앞 타일 — 40 · 모서리 12 · 아이콘 20
  final tile = tester.getRect(_key('plist-tile'));
  k.px('tile.size', tile.width);
  k.px('tile.size', tile.height);
  k.radius('tile.radius', _decoration(tester, _key('plist-tile')));
  final tileIcon = tester.getRect(_key('tile-icon'));
  k.px('tile.iconSize', tileIcon.width);
  k.px('tile.iconSize', tileIcon.height);
  k.measured.addAll(['tile.background', 'tile.color']);

  // 누름 — 바탕 층이 들어오고, 콘텐츠 층만 줄어든다
  TestGesture? gesture;
  if (state == 'pressed') gesture = await _press(tester, _items.at(0));

  // 바탕 층 — 색 · 들임 · 모서리 · 전환
  final background = tester.getRect(_backgrounds.at(0));
  final backgroundDeco = _decoration(tester, _backgrounds.at(0));
  k.color('background.background', backgroundDeco.color!);
  k.px('background.insetX', background.left - item.left);
  k.px('background.insetX', item.right - background.right);
  k.radius('background.radius', backgroundDeco);
  final fade = tester.widget<TweenAnimationBuilder<double>>(
    find
        .ancestor(
          of: _backgrounds.at(0),
          matching: find.byType(TweenAnimationBuilder<double>),
        )
        .first,
  );
  k.motion(
    'background.transitionDuration',
    'background.transitionEasing',
    fade.duration,
    fade.curve,
  );
  // 콘텐츠 층 — 줄어드는 배율 · 전환
  final scale = tester.widget<AnimatedScale>(_contents.at(0));
  k.pressScale('content.scale', _paintedScale(tester, _rows.at(0)), item.size);
  k.motion(
    'content.transitionDuration',
    'content.transitionEasing',
    scale.duration,
    scale.curve,
  );

  // 글 — 제목 · 설명 · 값 글자(누른 강조 줄은 설명 · 값 글자만 짙다) · 화살표
  final titleStyle = _textStyle(tester, _titles.at(0));
  k.typo('title.typography', titleStyle);
  k.weight('title.fontWeight', titleStyle);
  k.color('title.foreground', titleStyle.color!);
  final detailStyle = _textStyle(tester, _details.at(0));
  k.typo('detail.typography', detailStyle);
  k.color('detail.foreground', detailStyle.color!);
  final valueStyle = _textStyle(tester, _key('sample-value'));
  k.typo('suffixText.typography', valueStyle);
  k.color('suffixText.foreground', valueStyle.color!);
  k.color('suffixIcon.color', _iconColor(tester, _key('sample-arrow')));
  k.color('icon.color', _iconColor(tester, _key('sample-icon')));
  _colorOrCaller(
    k,
    'tile.color',
    _iconColor(tester, _key('tile-icon')),
    c.chartOrange,
  );
  final tileDeco = _decoration(tester, _key('plist-tile'));
  _colorOrCaller(k, 'tile.background', tileDeco.color!, c.chartOrangeWeak);

  k.coverage({..._behavior, ..._webOnly});
  await gesture?.up();
  await tester.pump(const Duration(milliseconds: 400));
  if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
}

// ── 부모 줄 · 하위 줄 ─────────────────────────────────────────

/// 하위 줄을 접는 부모 줄의 견본 — 식비(하위 둘) · 기타(하위 없음).
Widget _parentList(
  Brightness mode, {
  required bool open,
  required bool enabled,
  bool childrenEnabled = true,
}) {
  final c = _colors(mode);
  Widget tile(Color bg, Color fg, IconData icon) =>
      PListTile(background: bg, color: fg, child: Icon(icon));
  return PList(
    semanticLabel: '지출 카테고리',
    children: [
      PListParentItem(
        prefix: tile(c.chartOrangeWeak, c.chartOrange, LucideIcons.utensils),
        title: '식비',
        detail: '지출 · 하위 2개',
        expandLabel: '식비 하위 카테고리',
        defaultOpen: open,
        onTap: enabled ? _noop : null,
        children: [
          PListButtonItem(
            prefix: tile(c.chartOrangeWeak, c.chartOrange, LucideIcons.tag),
            title: '외식',
            detail: '지출',
            onTap: childrenEnabled ? _noop : null,
          ),
          PListButtonItem(
            prefix: tile(c.chartOrangeWeak, c.chartOrange, LucideIcons.tag),
            title: '배달음식',
            detail: '지출',
            onTap: childrenEnabled ? _noop : null,
          ),
        ],
      ),
      PListParentItem(
        prefix: tile(c.chartGrayWeak, c.chartGray, LucideIcons.tag),
        title: '기타',
        detail: '지출 · 하위 없음',
        expandLabel: '기타 하위 카테고리',
        onTap: enabled ? _noop : null,
      ),
    ],
  );
}

/// 부모 줄 — 펼침 × 기본 · 누름(줄 · 꺾쇠 단추) · 비활성. 줄과 꺾쇠 단추는 따로 눌리므로 누름은 둘을 따로 본다.
Future<void> _checkParent(
  WidgetTester tester,
  Brightness mode,
  String expanded,
  String state,
  String part,
  String title,
) async {
  final open = expanded == 'expanded';
  await tester.pumpWidget(
    _host(mode, _parentList(mode, open: open, enabled: state != 'disabled')),
  );
  await tester.pump(const Duration(milliseconds: 400));
  final want = {
    ..._spec.resolve({'nest': 'parent', 'expanded': expanded}, state),
  };
  if (state == 'pressed' && part == 'row') {
    // 줄을 눌러도 꺾쇠 단추는 눌리지 않는다
    want['expandButton.background'] = 'transparent';
    want.remove('expandButton.scale');
  }
  if (state == 'pressed' && part == 'button') {
    // 꺾쇠 단추를 눌러도 줄은 눌리지 않는다
    want['background.background'] = 'transparent';
    want['background.insetX'] = 0;
    want['background.radius'] = 0;
    want.remove('content.scale');
  }
  final k = _Check(mode, want, title);

  final item = tester.getRect(_items.at(0));
  final row = tester.getRect(_rows.at(0));
  final button = tester.getRect(_expandButtons);
  final prefixBox = tester.getRect(_prefixes.at(0));

  // 줄 — 앞 4 · 꺾쇠 단추 44 · 단추 뒤 4 · 앞 붙이개는 52 에서 시작
  k.px('item.paddingLeft', row.left - item.left);
  k.px('item.paddingX', item.right - row.right);
  k.px('expandButton.size', button.width);
  k.px('expandButton.size', button.height);
  k.px('expandButton.marginRight', prefixBox.left - button.right);
  if ((button.left - item.left - 4).abs() > 0.5) {
    k.fail('꺾쇠 단추가 줄 앞 4 에 서지 않는다 $button · $item');
  }
  if ((prefixBox.left - item.left - 52).abs() > 0.5) {
    k.fail('앞 붙이개가 52 에서 시작하지 않는다 $prefixBox · $item');
  }
  k.radius('expandButton.radius', _decoration(tester, _expandButtons));
  final arrow = tester.getRect(
    find.descendant(of: _expandIcons, matching: find.byType(Icon)),
  );
  k.px('expandButton.iconSize', arrow.width);
  k.px('expandButton.iconSize', arrow.height);
  k.cursor(
    'expandButton.cursor',
    tester
        .widget<MouseRegion>(
          find
              .ancestor(of: _expandButtons, matching: find.byType(MouseRegion))
              .first,
        )
        .cursor,
  );
  // 하위 줄 — 접히면 트리에 없다
  k.measured.add('subList.display');
  if (open != _subLists.evaluate().isNotEmpty) {
    k.fail('subList.display: 펼침 $expanded 인데 하위 줄이 ${open ? '없다' : '있다'}');
  }

  TestGesture? gesture;
  if (state == 'pressed') {
    gesture = await _press(
      tester,
      part == 'button' ? _expandButtons : _items.at(0),
    );
  }

  // 꺾쇠 — 색 · 접히면 오른쪽(0°) · 펼치면 아래(90°)
  k.color(
    'expandButton.color',
    _iconColor(
      tester,
      find.descendant(of: _expandIcons, matching: find.byType(Icon)),
    ),
  );
  final m = tester
      .renderObject(
        find.descendant(of: _expandIcons, matching: find.byType(Icon)),
      )
      .getTransformTo(null);
  final degrees = math.atan2(m.entry(1, 0), m.entry(0, 0)) * 180 / math.pi;
  k.measured.add('expandButton.rotate');
  final wantDegrees = double.parse(
    '${want['expandButton.rotate']}'.replaceAll('deg', ''),
  );
  if ((degrees - wantDegrees).abs() > 0.5) {
    k.fail('expandButton.rotate: 스펙 $wantDegrees° · 실제 $degrees°');
  }
  // 단추 바탕 · 누름 축소(기준 44)
  k.color(
    'expandButton.background',
    _decoration(tester, _expandButtons).color!,
  );
  // 꺾쇠 단추가 따로 줄어드는 배율 — 줄이 눌려 함께 줄어든 것은 뺀다
  k.pressScale(
    'expandButton.scale',
    _paintedScale(tester, _expandButtons) / _paintedScale(tester, _rows.at(0)),
    const Size.square(PTouch.min),
  );
  // 줄 — 바탕 층 · 콘텐츠 층
  final backgroundRect = tester.getRect(_backgrounds.at(0));
  final backgroundDeco = _decoration(tester, _backgrounds.at(0));
  k.color('background.background', backgroundDeco.color!);
  k.px('background.insetX', backgroundRect.left - item.left);
  k.radius('background.radius', backgroundDeco);
  k.pressScale('content.scale', _paintedScale(tester, _rows.at(0)), item.size);
  // 막힌 줄 — 줄만 막힌다
  final titleStyle = _textStyle(tester, _titles.at(0));
  k.color('title.foreground', titleStyle.color!);
  k.color('detail.foreground', _textStyle(tester, _details.at(0)).color!);

  k.coverage(
    {..._behavior, ..._webOnly},
    skipSlots: const {
      'root',
      'item',
      'background',
      'content',
      'prefix',
      'icon',
      'tile',
      'body',
      'title',
      'detail',
      'suffix',
      'suffixText',
      'suffixIcon',
      'divider',
    },
  );
  await gesture?.up();
  await tester.pump(const Duration(milliseconds: 400));
  if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
}

/// 하위 줄 — 부모의 제목 자리 104 에서 시작한다(누름 바탕은 줄 폭 그대로).
Future<void> _checkChild(
  WidgetTester tester,
  Brightness mode,
  String state,
  String title,
) async {
  await tester.pumpWidget(
    _host(
      mode,
      _parentList(
        mode,
        open: true,
        enabled: true,
        childrenEnabled: state != 'disabled',
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  final combo = {'nest': 'child', 'expanded': 'expanded'};
  final k = _Check(mode, _spec.resolve(combo, state), title);
  // 하위 줄은 둘째 · 셋째 줄이다
  final item = tester.getRect(_items.at(1));
  final row = tester.getRect(_rows.at(1));
  final parentTitle = tester.getRect(_titles.at(0));
  final childPrefix = tester.getRect(_prefixes.at(1));
  k.px('item.paddingLeft', row.left - item.left);
  k.px('item.paddingX', item.right - row.right);
  // 하위 타일은 부모 제목 아래에서 시작한다
  if ((childPrefix.left - parentTitle.left).abs() > 0.5) {
    k.fail('하위 타일이 부모 제목 자리에서 시작하지 않는다 $childPrefix · $parentTitle');
  }
  TestGesture? gesture;
  if (state == 'pressed') gesture = await _press(tester, _items.at(1));
  final background = tester.getRect(_backgrounds.at(1));
  final backgroundDeco = _decoration(tester, _backgrounds.at(1));
  k.color('background.background', backgroundDeco.color!);
  // 누름 바탕은 줄 폭 그대로(좌우 6 들임뿐) — 하위 줄의 들임 104 가 바탕에는 없다
  k.px('background.insetX', background.left - item.left);
  k.px('background.insetX', item.right - background.right);
  k.radius('background.radius', backgroundDeco);
  k.pressScale('content.scale', _paintedScale(tester, _rows.at(1)), item.size);
  k.color('title.foreground', _textStyle(tester, _titles.at(1)).color!);
  k.coverage(
    {..._behavior, ..._webOnly},
    skipSlots: const {
      'root',
      'item',
      'background',
      'content',
      'prefix',
      'icon',
      'tile',
      'body',
      'title',
      'detail',
      'suffix',
      'suffixText',
      'suffixIcon',
      'divider',
      'expandButton',
      'subList',
    },
  );
  await gesture?.up();
  await tester.pump(const Duration(milliseconds: 400));
  if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
}

void main() {
  for (final mode in Brightness.values) {
    group('${mode.name} · 단계 없는 줄 스펙 값', () {
      for (final combo in _spec.combos(['align', 'highlight'])) {
        for (final state in _appStates) {
          final title =
              '${mode.name} ${combo['align']} ${combo['highlight']} $state';
          testWidgets('$title — 스펙 값이다', (tester) async {
            await _checkFlat(tester, mode, combo, state, title);
          });
        }
      }
    });

    group('${mode.name} · 하위 줄 스펙 값', () {
      for (final expanded in _spec.axes['expanded']!) {
        for (final (state, part) in const [
          ('enabled', 'row'),
          ('pressed', 'row'),
          ('pressed', 'button'),
          ('disabled', 'row'),
        ]) {
          final title = '${mode.name} 부모 $expanded $state($part)';
          testWidgets('$title — 스펙 값이다', (tester) async {
            await _checkParent(tester, mode, expanded, state, part, title);
          });
        }
      }
      for (final state in _appStates) {
        final title = '${mode.name} 하위 줄 $state';
        testWidgets('$title — 스펙 값이다', (tester) async {
          await _checkChild(tester, mode, state, title);
        });
      }
    });
  }

  _headerTests();
  _kindTests();
  _pressTests();
  _controlTests();
  _parentTests();
  _worstTests();
}

// ── 목록 제목 ────────────────────────────────────────────────

void _headerTests() {
  for (final mode in Brightness.values) {
    for (final variant in _headerSpec.axes['variant']!) {
      final title = '${mode.name} 목록 제목 $variant';
      testWidgets('$title — 스펙 값이다', (tester) async {
        final strong = variant == 'boldSolid';
        var taps = 0;
        await tester.pumpWidget(
          _host(
            mode,
            PListHeader(
              title: '카테고리별 예산',
              variant: strong
                  ? PListHeaderVariant.boldSolid
                  : PListHeaderVariant.mediumWeak,
            ),
          ),
        );
        final k = _Check(
          mode,
          _headerSpec.resolve({'variant': variant}, 'enabled'),
          title,
        );
        final header = tester.getRect(_key('plist-header'));
        final text = tester.getRect(_key('plist-header-title'));
        // 좌우 24(줄과 같다) · 위아래 8
        k.px('root.paddingX', text.left - header.left);
        k.px('root.paddingY', text.top - header.top);
        k.px('root.paddingY', header.bottom - text.bottom);
        final style = _textStyle(tester, _key('plist-header-title'));
        k.typo('root.typography', style);
        k.weight('root.fontWeight', style);
        k.color('root.foreground', style.color!);
        // 제목과 오른쪽 버튼 사이 10
        k.measured.add('root.gap');
        final row = tester.widget<PHeaderRow>(
          find.descendant(
            of: _key('plist-header'),
            matching: find.byType(PHeaderRow),
          ),
        );
        if (row.gap != 10) {
          k.fail('root.gap: 스펙 10 · 실제 ${row.gap}');
        }
        await tester.pumpWidget(
          _host(
            mode,
            // 위 · 아래에 이웃이 있어야 줄 밖 4 가 받아진다
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: PListHeader(
                title: '카테고리별 예산',
                variant: strong
                    ? PListHeaderVariant.boldSolid
                    : PListHeaderVariant.mediumWeak,
                action: PTextButton(label: '전체 보기', onPressed: () => taps++),
              ),
            ),
          ),
        );
        final header2 = tester.getRect(_key('plist-header'));
        // 오른쪽 글 버튼(SEED Text Button, D2) — 보이는 36 · 좌우 14 · 700 · muted, 누르는 44, 머리 높이는 그대로
        final box = tester.getRect(_key('text-button-box'));
        k.px('action.height', box.height);
        final label = tester.getRect(_key('text-button-label'));
        k.px('action.paddingX', label.left - box.left);
        k.px('action.paddingX', box.right - label.right);
        k.px(
          'action.radius',
          ((tester.widget<Container>(_key('text-button-box')).decoration!
                          as BoxDecoration)
                      .borderRadius!
                  as BorderRadius)
              .topLeft
              .x,
        );
        final astyle = tester.widget<Text>(_key('text-button-label')).style!;
        k.typo('action.typography', astyle);
        k.weight('action.fontWeight', astyle);
        k.color('action.foreground', astyle.color!);
        // 머리 줄 높이 — 글 버튼이 늘리지 않는다(marginY −8): 위아래 8 + 제목 한 줄과 20 중 큰 것
        k.measured.add('action.marginY');
        final titleLine = tester.getSize(_key('plist-header-title')).height;
        if ((header2.height - (16 + (titleLine > 20 ? titleLine : 20))).abs() >
            0.5) {
          k.fail('action.marginY: 머리 높이 ${header2.height}');
        }
        // 누르는 영역 44 — 보이는 36 위 · 아래 4 까지 눌리고 5 에서는 눌리지 않는다(PTouchTargetScope slack 4)
        k.measured.add('action.touchTarget');
        await tester.tapAt(box.topCenter - const Offset(0, 3.5));
        await tester.tapAt(box.bottomCenter + const Offset(0, 3.5));
        await tester.pump();
        if (taps != 2) k.fail('action.touchTarget: 위 · 아래 4 안이 안 눌린다 ($taps)');
        await tester.tapAt(box.topCenter - const Offset(0, 6));
        await tester.pump();
        if (taps != 2) k.fail('action.touchTarget: 44 밖이 눌린다 ($taps)');
        k.coverage({});
        if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
      });
    }
  }

  testWidgets('제목은 왼쪽, 오른쪽 버튼은 끝에 서고 좌우 24 는 줄과 맞는다', (tester) async {
    await tester.pumpWidget(
      _host(
        Brightness.light,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PListHeader(
              title: '카테고리별 예산',
              action: PTextButton(label: '전체 보기', onPressed: _noop),
            ),
            const PList(
              semanticLabel: '카테고리별 예산',
              children: [PListItem(title: '식비')],
            ),
          ],
        ),
      ),
    );
    final header = tester.getRect(_key('plist-header'));
    final title = tester.getRect(_key('plist-header-title'));
    final action = tester.getRect(_key('text-button-box'));
    final row = tester.getRect(_rows);
    expect(title.left, row.left, reason: '제목의 왼쪽이 줄의 왼쪽과 맞는다');
    // 글 버튼은 오른쪽 14 만큼 바깥으로 내어 글자 끝이 24 에 선다
    expect(
      tester.getRect(_key('text-button-label')).right,
      header.right - PSpacing.globalGutter,
    );
    expect(title.right, lessThanOrEqualTo(action.left - 10));
  });

  testWidgets('제목은 머리말로 읽고 오른쪽 버튼은 따로 읽는다 — 목록 이름은 제목 글만', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Brightness.light,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PListHeader(
              title: '카테고리별 예산',
              action: PTextButton(label: '전체 보기', onPressed: _noop),
            ),
            const PList(
              semanticLabel: '카테고리별 예산',
              children: [PListItem(title: '식비', suffix: Text('240,000원'))],
            ),
          ],
        ),
      ),
    );
    final head = tester.getSemantics(find.bySemanticsLabel('카테고리별 예산').first);
    expect(head.label, '카테고리별 예산');
    expect(
      tester.getSemantics(find.bySemanticsLabel('전체 보기')).label,
      '전체 보기',
      reason: '버튼 글은 제목 · 목록 이름에 섞이지 않는다',
    );
    semantics.dispose();
  });
}

// ── 줄의 종류 ────────────────────────────────────────────────

void _kindTests() {
  group('보기만 하는 줄', () {
    testWidgets('누르지 않는다 — 눌림 · 포커스 · 커서가 없다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PList(
            semanticLabel: '계정 정보',
            children: [PListItem(title: '가입일', suffix: Text('2026년 3월 2일'))],
          ),
        ),
      );
      final gesture = await _press(tester, _items);
      expect(_paintedScale(tester, _rows), 1.0);
      expect(
        _decoration(tester, _backgrounds).color!.a,
        0,
        reason: '눌림 바탕이 생기지 않는다',
      );
      await gesture.up();
      expect(
        find.descendant(
          of: find.byType(PListItem),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(PListItem),
          matching: find.byType(MouseRegion),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(PListItem),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
    });

    testWidgets('제목 + 설명 + 값이 한 노드로 읽힌다(줄 하나 = 한 노드)', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PList(
            semanticLabel: '알림',
            children: [
              PListItem(
                title: '결제 알림',
                detail: '결제 예정일 D-1',
                suffix: Text('켜짐'),
              ),
            ],
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('결제 알림')));
      expect(node.label, '결제 알림\n결제 예정일 D-1\n켜짐');
      expect(
        node.getSemanticsData().flagsCollection.isButton,
        isFalse,
        reason: '보기만 하는 줄은 버튼이 아니다',
      );
      expect(
        find.bySemanticsLabel('켜짐'),
        findsNothing,
        reason: '값은 따로 읽히지 않는다',
      );
      semantics.dispose();
    });

    testWidgets('설명은 글(detail)이나 위젯(detailChild) 하나만 준다', (tester) async {
      expect(
        () => PListItem(title: 'a', detail: 'b', detailChild: const Text('c')),
        throwsAssertionError,
      );
    });
  });

  group('누르는 줄', () {
    testWidgets('줄 어디를 눌러도 눌린다 — 가장자리 · 위아래 끝도, 줄 높이는 44 이상', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PList(
            semanticLabel: '설정',
            children: [
              PListButtonItem(
                prefix: const Icon(LucideIcons.user),
                title: '계정',
                suffix: const Icon(LucideIcons.chevronRight),
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      );
      final item = tester.getRect(_items);
      expect(item.height, greaterThanOrEqualTo(PTouch.min));
      for (final p in [
        item.topLeft + const Offset(1, 1),
        item.topRight + const Offset(-1, 1),
        item.bottomLeft + const Offset(1, -1),
        item.bottomRight + const Offset(-1, -1),
        item.center,
      ]) {
        await tester.tapAt(p);
      }
      expect(taps, 5);
    });

    testWidgets('onTap 이 없으면 막힌 줄 — 눌러도 아무 일 없고 눌림 · 포커스가 없다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PList(
            semanticLabel: '설정',
            children: [PListButtonItem(title: '주간 리포트', onTap: null)],
          ),
        ),
      );
      final gesture = await _press(tester, _items);
      expect(_paintedScale(tester, _rows), 1.0);
      expect(_decoration(tester, _backgrounds).color!.a, 0);
      await gesture.up();
      final focus = tester.widget<Focus>(
        find
            .descendant(
              of: find.byType(PListButtonItem),
              matching: find.byType(Focus),
            )
            .first,
      );
      expect(focus.canRequestFocus, isFalse, reason: '막힌 줄은 포커스에서 빠진다');
    });

    testWidgets('키보드 — 포커스에서 Enter · Space 로 누른다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PList(
            semanticLabel: '설정',
            children: [PListButtonItem(title: '계정', onTap: () => taps++)],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, 2);
    });

    testWidgets('제목 + 설명 + 값이 버튼의 이름 하나다(03-D 결정 4 A)', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PList(
            semanticLabel: '설정',
            children: [
              PListButtonItem(
                title: '기본 통화',
                detail: '표시할 통화',
                suffix: const Text('대한민국 원'),
                onTap: _noop,
              ),
              const PListButtonItem(title: '막힌 줄', onTap: null),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('기본 통화'))),
        isSemantics(
          label: '기본 통화\n표시할 통화\n대한민국 원',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
      // 값은 따로 읽히지 않는다 — 줄 하나 = 한 번
      expect(find.bySemanticsLabel('대한민국 원'), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('막힌 줄')),
        isSemantics(
          label: '막힌 줄',
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
          hasTapAction: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('줄 · 작은 버튼 · 메뉴 — 누르는 것 셋은 따로 눌린다(작은 버튼 이벤트는 줄로 가지 않는다)', (
      tester,
    ) async {
      var row = 0;
      var small = 0;
      var menu = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PList(
            semanticLabel: '거래',
            children: [
              PListButtonItem(
                title: '카페 · 아메리카노',
                suffix: PListSuffix(
                  children: [
                    PListAction(
                      child: PButton(
                        label: '분류',
                        variant: PButtonVariant.neutralWeak,
                        size: PButtonSize.xsmall,
                        onPressed: () => small++,
                      ),
                    ),
                    PListAction(
                      child: PButton.icon(
                        icon: LucideIcons.ellipsisVertical,
                        semanticLabel: '더 보기',
                        variant: PButtonVariant.ghost,
                        size: PButtonSize.xsmall,
                        onPressed: () => menu++,
                      ),
                    ),
                  ],
                ),
                onTap: () => row++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(findText('분류'));
      expect((row, small, menu), (0, 1, 0));
      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      expect((row, small, menu), (0, 1, 1));
      await tester.tapAt(tester.getTopLeft(_items) + const Offset(30, 20));
      expect((row, small, menu), (1, 1, 1));
    });

    testWidgets('작은 버튼을 길게 눌러도 줄은 눌린 모습이 되지 않는다 — 줄 다른 자리를 누르면 눌린다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PList(
            semanticLabel: '거래',
            children: [
              PListButtonItem(
                title: '카페 · 아메리카노',
                suffix: PListAction(
                  child: PButton(
                    label: '분류',
                    variant: PButtonVariant.neutralWeak,
                    size: PButtonSize.xsmall,
                    onPressed: _noop,
                  ),
                ),
                onTap: _noop,
              ),
            ],
          ),
        ),
      );
      var gesture = await _press(tester, findText('분류'));
      expect(_decoration(tester, _backgrounds).color!.a, 0);
      expect(_paintedScale(tester, _rows), 1.0);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 400));
      gesture = await _press(tester, _titles);
      expect(_decoration(tester, _backgrounds).color!.a, 1);
      expect(_paintedScale(tester, _rows), lessThan(1));
      await gesture.up();
    });

    testWidgets('PListAction 은 줄 밖에서는 그대로 아이를 돌려준다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PListAction(child: Text('밖', key: ValueKey('outside'))),
        ),
      );
      expect(find.byKey(const ValueKey('outside')), findsOneWidget);
      expect(find.byType(Listener), findsWidgets);
    });
  });

  group('링크 줄', () {
    testWidgets('줄 전체가 링크 — 이름은 제목 + 설명이고 막지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PList(
            semanticLabel: '도움말',
            children: [
              PListLinkItem(
                title: '도움말',
                detail: '설명서에서 자세히 알아보세요',
                suffix: const Icon(LucideIcons.chevronRight),
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^도움말\n')));
      expect(node.label, '도움말\n설명서에서 자세히 알아보세요');
      expect(node.getSemanticsData().flagsCollection.isLink, isTrue);
      expect(node.getSemanticsData().flagsCollection.isButton, isFalse);
      await tester.tapAt(tester.getTopLeft(_items) + const Offset(10, 10));
      expect(taps, 1);
      semantics.dispose();
    });
  });

  group('그 밖', () {
    testWidgets('줄 사이 선 — 보조 기술에 숨기고, 들이면 좌우 24', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PList(
            semanticLabel: '구분선',
            children: [
              PListItem(title: '가입일'),
              PListDivider(),
              PListDivider(inset: true),
              PListItem(title: '이메일'),
            ],
          ),
        ),
      );
      Rect line(int i) => tester.getRect(
        find
            .descendant(
              of: _key('plist-divider').at(i),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      final full = line(0);
      final inset = line(1);
      expect(full.width, 360);
      expect(inset.left - full.left, PSpacing.globalGutter);
      expect(full.right - inset.right, PSpacing.globalGutter);
      expect(find.bySemanticsLabel(RegExp('가입일')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PListDivider),
          matching: find.byType(ExcludeSemantics),
        ),
        findsNWidgets(2),
      );
      semantics.dispose();
    });

    testWidgets('목록 이름을 읽는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PList(
            semanticLabel: '일반',
            children: [PListItem(title: '계정')],
          ),
        ),
      );
      expect(find.bySemanticsLabel('일반'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('설명 자리에 위젯(detailChild)을 둘 수 있고 글자 모양은 설명을 따른다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PList(
            semanticLabel: '거래',
            children: [
              PListItem(title: '무신사', detailChild: Text('쇼핑 · 10월 2일')),
            ],
          ),
        ),
      );
      final style = _textStyle(tester, findText('쇼핑 · 10월 2일'));
      expect(style.fontSize, 13);
      expect(sameColor(PColors.light.fgNeutralSubtle, style.color!), isTrue);
    });
  });
}

// ── 누름 ─────────────────────────────────────────────────────

Widget _pressRow({
  bool highlighted = false,
  VoidCallback? onTap = _noop,
  double itemRadius = PRounded.r2_5,
  Color? titleColor,
}) => PList(
  semanticLabel: '설정',
  itemRadius: itemRadius,
  children: [
    PListButtonItem(
      prefix: const Icon(LucideIcons.bell),
      title: '결제 알림',
      detail: '결제 예정일 D-1',
      suffix: const Text('대한민국 원'),
      highlighted: highlighted,
      titleColor: titleColor,
      onTap: onTap,
    ),
  ],
);

void _pressTests() {
  group('누름', () {
    testWidgets('바탕 층은 줄지 않고 콘텐츠 층만 준다 — 기준 길이는 max(높이, 폭 ÷ 4, 24)', (
      tester,
    ) async {
      for (final width in [80.0, 360.0, 640.0]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            // 좁은 폭에서는 앞 · 뒤 붙이개 없이 제목만 — 줄 높이가 기준 길이가 된다
            width < 100
                ? const PList(
                    semanticLabel: '설정',
                    children: [PListButtonItem(title: '가', onTap: _noop)],
                  )
                : _pressRow(),
            width: width,
          ),
        );
        final item = tester.getRect(_items);
        final basis = math.max(item.height, math.max(item.width / 4, 24.0));
        final gesture = await _press(tester, _items);
        expect(
          _paintedScale(tester, _rows),
          closeTo((basis - 2) / basis, 1e-3),
          reason: '폭 $width — 기준 $basis',
        );
        expect(
          _paintedScale(tester, _backgrounds),
          1.0,
          reason: '바탕 층은 줄지 않는다',
        );
        await gesture.up();
        await _settle(tester);
        expect(_paintedScale(tester, _rows), closeTo(1, 1e-6));
      }
    });

    testWidgets('바탕은 좌우 6 들어오며 모서리 10 · 누름 색이 되고, 떼면 150ms 로 돌아간다', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, _pressRow()));
      final item = tester.getRect(_items);
      final gesture = await tester.startGesture(tester.getCenter(_items));
      await tester.pump();
      // 150ms 의 한가운데 — motion-ease-easing 의 0.5 지점
      await tester.pump(const Duration(milliseconds: 75));
      final t = PEasing.easing.transform(0.5);
      final mid = _decoration(tester, _backgrounds);
      expect(
        tester.getRect(_backgrounds).left - item.left,
        closeTo(PSpacing.x1_5 * t, 0.01),
      );
      expect(
        (mid.borderRadius! as BorderRadius).topLeft.x,
        closeTo(PRounded.r2_5 * t, 0.01),
      );
      expect(
        mid.color!.a,
        closeTo(t, 0.01),
        reason: '투명에서 누름 색으로 — 어두워졌다 밝아지지 않는다',
      );
      expect(
        mid.color!.r,
        closeTo(PColors.light.bgLayerDefaultPressed.r, 0.01),
      );
      await tester.pump(const Duration(milliseconds: 75));
      expect(tester.getRect(_backgrounds).left - item.left, PSpacing.x1_5);
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(_decoration(tester, _backgrounds).color!.a, 0);
      expect(tester.getRect(_backgrounds).left, item.left);
    });

    testWidgets('콘텐츠 축소는 150ms · 누름 곡선(0, 0, 0.15, 1)이다', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, _pressRow()));
      final item = tester.getRect(_items);
      final basis = math.max(item.height, math.max(item.width / 4, 24.0));
      final target = (basis - 2) / basis;
      final gesture = await tester.startGesture(tester.getCenter(_items));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(
        _paintedScale(tester, _rows),
        closeTo(1 + (target - 1) * PEasing.pressedScale.transform(0.5), 1e-3),
      );
      await tester.pump(const Duration(milliseconds: 75));
      expect(_paintedScale(tester, _rows), closeTo(target, 1e-3));
      await gesture.up();
    });

    testWidgets('모션 줄이기면 축소를 빼고 바탕 색 전환은 그대로다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _pressRow(), reduceMotion: true),
      );
      final gesture = await _press(tester, _items);
      expect(_paintedScale(tester, _rows), 1.0);
      expect(_decoration(tester, _backgrounds).color!.a, 1);
      expect(
        tester.getRect(_backgrounds).left - tester.getRect(_items).left,
        6,
      );
      await gesture.up();
    });

    testWidgets('카드 안에서는 목록의 itemRadius 로 바탕 모서리를 바꾼다(동심 모서리)', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _pressRow(itemRadius: PRounded.r1)),
      );
      final gesture = await _press(tester, _items);
      expect(
        (_decoration(tester, _backgrounds).borderRadius! as BorderRadius)
            .topLeft
            .x,
        PRounded.r1,
      );
      await gesture.up();
    });

    testWidgets('손가락이 줄 밖으로 끌려 나가면 눌림이 풀리고 누른 것으로 치지 않는다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(Brightness.light, _pressRow(onTap: () => taps++)),
      );
      final gesture = await tester.startGesture(tester.getCenter(_items));
      await _settle(tester);
      expect(_decoration(tester, _backgrounds).color!.a, 1);
      await gesture.moveBy(const Offset(0, 200));
      await _settle(tester);
      expect(_decoration(tester, _backgrounds).color!.a, 0);
      expect(_paintedScale(tester, _rows), closeTo(1, 1e-6));
      await gesture.up();
      expect(taps, 0);
    });

    testWidgets('누르는 사이 막히면 눌림이 남지 않는다', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, _pressRow()));
      final gesture = await tester.startGesture(tester.getCenter(_items));
      await _settle(tester);
      expect(_decoration(tester, _backgrounds).color!.a, 1);
      await tester.pumpWidget(_host(Brightness.light, _pressRow(onTap: null)));
      await _settle(tester);
      expect(_decoration(tester, _backgrounds).color!.a, 0);
      expect(_paintedScale(tester, _rows), closeTo(1, 1e-6));
      await gesture.up();
    });

    testWidgets('카탈로그는 눌림을 멈춰 그린다 — 손가락 없이도 바탕 · 축소가 같은 값이다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, PListPressedPreview(child: _pressRow())),
      );
      await _settle(tester);
      final item = tester.getRect(_items);
      final basis = math.max(item.height, math.max(item.width / 4, 24.0));
      expect(tester.getRect(_backgrounds).left - item.left, PSpacing.x1_5);
      expect(_paintedScale(tester, _rows), closeTo((basis - 2) / basis, 1e-3));
    });

    testWidgets('강조 줄 — 바탕이 짙어지고 설명 · 값 글자만 한 단계 짙다(제목은 그대로)', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _pressRow(highlighted: true)),
      );
      final c = PColors.light;
      expect(
        sameColor(c.bgBrandWeak, _decoration(tester, _backgrounds).color!),
        isTrue,
      );
      expect(
        sameColor(c.fgNeutralSubtle, _textStyle(tester, _details).color!),
        isTrue,
      );
      final gesture = await _press(tester, _items);
      expect(
        sameColor(
          c.bgBrandWeakPressed,
          _decoration(tester, _backgrounds).color!,
        ),
        isTrue,
      );
      expect(
        sameColor(c.fgNeutralMuted, _textStyle(tester, _details).color!),
        isTrue,
      );
      expect(
        sameColor(
          c.fgNeutralMuted,
          _textStyle(tester, findText('대한민국 원')).color!,
        ),
        isTrue,
      );
      expect(
        sameColor(c.fgNeutral, _textStyle(tester, _titles).color!),
        isTrue,
      );
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        sameColor(c.fgNeutralSubtle, _textStyle(tester, _details).color!),
        isTrue,
      );
    });

    testWidgets('합계에 안 드는 줄 — 제목 색을 덮는다. 막히면 비활성 색이 이긴다', (tester) async {
      final c = PColors.light;
      await tester.pumpWidget(
        _host(Brightness.light, _pressRow(titleColor: c.fgNeutralSubtle)),
      );
      expect(
        sameColor(c.fgNeutralSubtle, _textStyle(tester, _titles).color!),
        isTrue,
      );
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _pressRow(titleColor: c.fgNeutralSubtle, onTap: null),
        ),
      );
      expect(
        sameColor(c.fgDisabled, _textStyle(tester, _titles).color!),
        isTrue,
      );
    });

    testWidgets('막힌 줄은 불투명도로 흐리지 않는다 — 제목 · 설명 · 앞뒤 아이콘이 모두 비활성 색', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, _pressRow(onTap: null)));
      expect(
        find.descendant(of: find.byType(PList), matching: find.byType(Opacity)),
        findsNothing,
      );
      final c = PColors.light;
      expect(
        sameColor(c.fgDisabled, _textStyle(tester, _titles).color!),
        isTrue,
      );
      expect(
        sameColor(c.fgDisabled, _textStyle(tester, _details).color!),
        isTrue,
      );
      expect(
        sameColor(c.fgDisabled, _textStyle(tester, findText('대한민국 원')).color!),
        isTrue,
      );
      expect(
        sameColor(
          c.fgDisabled,
          _iconColor(tester, find.byIcon(LucideIcons.bell)),
        ),
        isTrue,
      );
    });
  });
}

// ── 컨트롤 줄 ────────────────────────────────────────────────

/// 값을 쥐는 쓰는 쪽 — 눌러서 바꾼다.
class _Live<T> extends StatefulWidget {
  const _Live({required this.initial, required this.builder, this.log});

  final T initial;
  final Widget Function(T value, ValueChanged<T> onChanged) builder;
  final List<T>? log;

  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<_Live<T>> {
  late T value = widget.initial;

  @override
  Widget build(BuildContext context) => widget.builder(value, (next) {
    widget.log?.add(next);
    setState(() => value = next);
  });
}

void _controlTests() {
  group('스위치 줄', () {
    Widget switchRow({
      required bool checked,
      required ValueChanged<bool>? onChanged,
    }) => PList(
      semanticLabel: '알림',
      children: [
        PListSwitchItem(
          prefix: const Icon(LucideIcons.bell),
          title: '결제 알림',
          detail: '결제 예정일 D-1',
          checked: checked,
          onChanged: onChanged,
        ),
      ],
    );

    testWidgets('줄 어디를 눌러도 바뀐다 — 앞 · 제목 · 빈 자리 · 스위치, 바로 알린다', (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Live<bool>(
            initial: false,
            log: log,
            builder: (value, onChanged) =>
                switchRow(checked: value, onChanged: onChanged),
          ),
        ),
      );
      final item = tester.getRect(_items);
      for (final p in [
        item.topLeft + const Offset(2, 2),
        tester.getCenter(_titles),
        item.center + const Offset(40, 0),
        tester.getCenter(find.byType(PSwitchmark)),
      ]) {
        await tester.tapAt(p);
        await tester.pump();
      }
      expect(log, [true, false, true, false]);
    });

    testWidgets('스위치는 뒤에 32(트랙 52 × 32)이고 따로 줄지 않는다 — 줄이 줄 때 함께 줄 뿐', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Brightness.light, switchRow(checked: true, onChanged: (_) {})),
      );
      final item = tester.getRect(_items);
      final track = tester.getRect(_key('switchmark-track'));
      expect((track.width, track.height), (52.0, 32.0));
      expect(track.right, item.right - PSpacing.globalGutter);
      final gesture = await _press(tester, _items);
      final row = _paintedScale(tester, _rows);
      expect(row, lessThan(1));
      expect(
        _paintedScale(tester, _key('switchmark-track')) / row,
        closeTo(1, 1e-6),
        reason: '스위치는 따로 줄지 않는다',
      );
      await gesture.up();
    });

    testWidgets('onChanged 가 없으면 막힌 줄 — 눌러도 바뀌지 않고 켜진 모양 그대로 회색', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Brightness.light, switchRow(checked: true, onChanged: null)),
      );
      final gesture = await _press(tester, _items);
      expect(_decoration(tester, _backgrounds).color!.a, 0);
      await gesture.up();
      expect(
        tester.widget<PSwitchmark>(find.byType(PSwitchmark)).enabled,
        isFalse,
      );
      expect(
        tester.widget<PSwitchmark>(find.byType(PSwitchmark)).checked,
        isTrue,
      );
    });

    testWidgets('켬 · 끔을 toggled 로 읽고 제목 + 설명이 이름이다 — 마크는 읽지 않는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, switchRow(checked: true, onChanged: (_) {})),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('결제 알림'))),
        isSemantics(
          label: '결제 알림\n결제 예정일 D-1',
          isToggled: true,
          hasToggledState: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
      await tester.pumpWidget(
        _host(Brightness.light, switchRow(checked: false, onChanged: null)),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('결제 알림'))),
        isSemantics(
          label: '결제 알림\n결제 예정일 D-1',
          isToggled: false,
          hasToggledState: true,
          isEnabled: false,
          hasEnabledState: true,
          hasTapAction: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('키보드 — Space · Enter 로 바꾼다', (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Live<bool>(
            initial: false,
            log: log,
            builder: (value, onChanged) =>
                switchRow(checked: value, onChanged: onChanged),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(log, [true, false]);
    });
  });

  group('체크 줄', () {
    Widget checkRows({
      required bool? checked,
      required ValueChanged<bool>? onChanged,
      PListMarkPosition position = PListMarkPosition.prefix,
    }) => PListCheckGroup(
      semanticLabel: '내보낼 항목',
      children: [
        PListCheckItem(
          markPosition: position,
          prefix: position == PListMarkPosition.suffix
              ? const Icon(LucideIcons.creditCard)
              : null,
          title: '거래 내역',
          detail: '내보낼 항목',
          checked: checked,
          onChanged: onChanged,
        ),
      ],
    );

    testWidgets('줄 어디를 눌러도 바뀐다 — 선택이면 해제, 선택 안 됨 · 일부 선택이면 선택', (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(
        _host(Brightness.light, checkRows(checked: false, onChanged: log.add)),
      );
      await tester.tap(find.byType(PCheckmark));
      await tester.tapAt(tester.getCenter(_titles));
      await tester.tapAt(tester.getTopRight(_items) + const Offset(-2, 20));
      expect(log, [true, true, true]);
      log.clear();
      await tester.pumpWidget(
        _host(Brightness.light, checkRows(checked: true, onChanged: log.add)),
      );
      await tester.tapAt(tester.getCenter(_titles));
      await tester.pumpWidget(
        _host(Brightness.light, checkRows(checked: null, onChanged: log.add)),
      );
      await tester.tapAt(tester.getCenter(_titles));
      expect(log, [false, true]);
    });

    testWidgets('체크 24 는 앞(기본)에, 뒤에도 둔다 — 뒤에 두면 앞 붙이개를 같이 쓴다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, checkRows(checked: true, onChanged: (_) {})),
      );
      var item = tester.getRect(_items);
      var mark = tester.getRect(find.byType(PCheckmark));
      expect((mark.width, mark.height), (24.0, 24.0));
      expect(mark.left, item.left + PSpacing.globalGutter, reason: '앞 체크');
      expect(
        tester.widget<PCheckmark>(find.byType(PCheckmark)).size,
        PCheckboxSize.large,
      );
      await tester.pumpWidget(
        _host(
          Brightness.light,
          checkRows(
            checked: true,
            onChanged: (_) {},
            position: PListMarkPosition.suffix,
          ),
        ),
      );
      item = tester.getRect(_items);
      mark = tester.getRect(find.byType(PCheckmark));
      expect(mark.right, item.right - PSpacing.globalGutter, reason: '뒤 체크');
      expect(find.byIcon(LucideIcons.creditCard), findsOneWidget);
    });

    testWidgets('체크를 앞에 두고도 앞 붙이개를 같이 쓴다 — 체크 → 앞 붙이개 → 제목(뒤 값은 체크를 뒤에 둘 때만)', (
      tester,
    ) async {
      expect(
        () => PListCheckItem(
          title: 'a',
          checked: false,
          onChanged: (_) {},
          prefix: const Icon(LucideIcons.bell),
        ),
        returnsNormally,
      );
      expect(
        () => PListCheckItem(
          title: 'a',
          checked: false,
          onChanged: (_) {},
          suffixValue: const Text('1'),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('눌리면 칸은 누름 색만 받고 따로 줄지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, checkRows(checked: false, onChanged: (_) {})),
      );
      final gesture = await _press(tester, _items);
      expect(
        sameColor(
          PColors.light.bgLayerDefaultPressed,
          _decoration(tester, _key('checkmark-box')).color!,
        ),
        isTrue,
      );
      final row = _paintedScale(tester, _rows);
      expect(row, lessThan(1));
      expect(
        _paintedScale(tester, _key('checkmark-box')) / row,
        closeTo(1, 1e-6),
      );
      await gesture.up();
    });

    testWidgets('Space 로 바꾸고 Enter 는 바꾸지 않는다(폼 제출에 둔다)', (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(
        _host(Brightness.light, checkRows(checked: false, onChanged: log.add)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(log, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(log, [true]);
    });

    testWidgets('선택 · 일부 선택 · 막힘을 읽고 묶음 이름을 읽는다', (tester) async {
      final semantics = tester.ensureSemantics();
      Future<SemanticsNode> node(bool? checked, {bool enabled = true}) async {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            checkRows(checked: checked, onChanged: enabled ? (_) {} : null),
          ),
        );
        // 포커스 노드는 막힘을 다음 프레임에 알린다(Focus 가 그렇다)
        await tester.pump();
        return tester.getSemantics(find.bySemanticsLabel(RegExp('거래 내역')));
      }

      expect(
        await node(true),
        isSemantics(
          label: '거래 내역\n내보낼 항목',
          hasCheckedState: true,
          isChecked: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
      expect(
        await node(false),
        isSemantics(
          label: '거래 내역\n내보낼 항목',
          hasCheckedState: true,
          isChecked: false,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
      expect(
        await node(null),
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          isCheckStateMixed: true,
        ),
      );
      expect(
        await node(true, enabled: false),
        isSemantics(
          label: '거래 내역\n내보낼 항목',
          hasCheckedState: true,
          isChecked: true,
          isEnabled: false,
          hasEnabledState: true,
          hasTapAction: false,
        ),
      );
      expect(find.bySemanticsLabel('내보낼 항목'), findsWidgets);
      semantics.dispose();
    });

    testWidgets('묶음의 이름은 필수다', (tester) async {
      expect(
        () => PListCheckGroup(semanticLabel: '', children: const []),
        throwsAssertionError,
      );
    });
  });

  group('라디오 줄', () {
    Widget radioRows({
      required String? value,
      required ValueChanged<String>? onChanged,
      Map<String, FocusNode> focus = const {},
      String? disabled,
      PListMarkPosition position = PListMarkPosition.suffix,
      VoidCallback? onReselect,
    }) => PListRadioGroup<String>(
      semanticLabel: '기본 통화',
      value: value,
      onChanged: onChanged,
      onReselect: onReselect,
      children: [
        for (final (v, title) in const [
          ('KRW', '대한민국 원'),
          ('USD', '미국 달러'),
          ('JPY', '일본 엔'),
        ])
          PListRadioItem<String>(
            value: v,
            title: title,
            detail: v,
            markPosition: position,
            enabled: v != disabled,
            focusNode: focus[v],
          ),
      ],
    );

    bool selected(WidgetTester tester, String title) => tester
        .widget<PRadiomark>(
          find.descendant(
            of: find.ancestor(
              of: findText(keepAll(title)),
              matching: find.byType(PListRadioItem<String>),
            ),
            matching: find.byType(PRadiomark),
          ),
        )
        .checked;

    testWidgets('줄 어디를 눌러도 고르고 앞에 고른 것은 풀린다 — 고른 줄을 다시 눌러도 그대로다', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Live<String>(
            initial: 'KRW',
            log: log,
            builder: (value, onChanged) =>
                radioRows(value: value, onChanged: onChanged),
          ),
        ),
      );
      expect(selected(tester, '대한민국 원'), isTrue);
      expect(selected(tester, '미국 달러'), isFalse);
      await tester.tap(findText(keepAll('미국 달러')));
      await tester.pump();
      expect(log, ['USD']);
      expect(selected(tester, '미국 달러'), isTrue);
      expect(selected(tester, '대한민국 원'), isFalse);
      await tester.tapAt(
        tester.getTopRight(_items.at(2)) + const Offset(-2, 20),
      );
      await tester.pump();
      expect(log, ['USD', 'JPY']);
      // 고른 줄을 다시 누르면 아무 일도 없다
      await tester.tap(findText(keepAll('일본 엔')));
      await tester.pump();
      expect(log, ['USD', 'JPY']);
    });

    testWidgets('onReselect — 고른 줄을 다시 눌렀을 때만 부르고 onChanged 는 부르지 않는다', (
      tester,
    ) async {
      final log = <String>[];
      var reselect = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Live<String>(
            initial: 'KRW',
            log: log,
            builder: (value, onChanged) => radioRows(
              value: value,
              onChanged: onChanged,
              onReselect: () => reselect++,
            ),
          ),
        ),
      );
      await tester.tap(findText(keepAll('대한민국 원')));
      await tester.pump();
      expect(reselect, 1);
      expect(log, isEmpty, reason: '값은 그대로 · 바꿈 호출 없음');
      expect(selected(tester, '대한민국 원'), isTrue);
      await tester.tap(findText(keepAll('미국 달러')));
      await tester.pump();
      expect(reselect, 1, reason: '다른 줄을 고르면 부르지 않는다');
      expect(log, ['USD']);
    });

    testWidgets('라디오 24 는 뒤(기본)에, 앞에도 둔다 — 고른 것 · 안 고른 것이 모두 보인다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Brightness.light, radioRows(value: 'KRW', onChanged: (_) {})),
      );
      var item = tester.getRect(_items.first);
      var mark = tester.getRect(find.byType(PRadiomark).first);
      expect((mark.width, mark.height), (24.0, 24.0));
      expect(mark.right, item.right - PSpacing.globalGutter, reason: '뒤 라디오');
      expect(find.byType(PRadiomark), findsNWidgets(3));
      await tester.pumpWidget(
        _host(
          Brightness.light,
          radioRows(
            value: 'KRW',
            onChanged: (_) {},
            position: PListMarkPosition.prefix,
          ),
        ),
      );
      item = tester.getRect(_items.first);
      mark = tester.getRect(find.byType(PRadiomark).first);
      expect(mark.left, item.left + PSpacing.globalGutter, reason: '앞 라디오');
    });

    testWidgets('라디오를 앞에 두면 앞 붙이개를 같이 쓸 수 없다', (tester) async {
      expect(
        () => PListRadioItem<String>(
          value: 'a',
          title: 'a',
          prefix: const Icon(LucideIcons.bell),
          markPosition: PListMarkPosition.prefix,
        ),
        throwsAssertionError,
      );
      expect(
        () => PListRadioItem<String>(
          value: 'a',
          title: 'a',
          prefix: const Icon(LucideIcons.bell),
        ),
        returnsNormally,
      );
    });

    testWidgets('막힌 줄은 누르지 않고 막힌 묶음은 모두 막힌다 — 고른 것은 채운 원 그대로 색만', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          radioRows(value: 'KRW', onChanged: log.add, disabled: 'USD'),
        ),
      );
      await tester.tap(findText(keepAll('미국 달러')));
      await tester.pump();
      expect(log, isEmpty);
      await tester.tap(findText(keepAll('일본 엔')));
      expect(log, ['JPY']);
      log.clear();
      await tester.pumpWidget(
        _host(Brightness.light, radioRows(value: 'KRW', onChanged: null)),
      );
      await tester.tap(findText(keepAll('일본 엔')));
      expect(log, isEmpty);
      final marks = tester
          .widgetList<PRadiomark>(find.byType(PRadiomark))
          .toList();
      expect(marks.every((m) => !m.enabled), isTrue);
      expect(marks.first.checked, isTrue);
    });

    testWidgets(
      '키보드 — 화살표로 옮기며 고르고(막힌 것은 건너뛴다), Space 로 고르고, Enter 는 고르지 않는다',
      (tester) async {
        final focus = {
          for (final v in ['KRW', 'USD', 'JPY']) v: FocusNode(debugLabel: v),
        };
        addTearDown(() {
          for (final node in focus.values) {
            node.dispose();
          }
        });
        var value = 'KRW';
        await tester.pumpWidget(
          _host(
            Brightness.light,
            StatefulBuilder(
              builder: (context, setState) => radioRows(
                value: value,
                onChanged: (v) => setState(() => value = v),
                focus: focus,
                disabled: 'USD',
              ),
            ),
          ),
        );
        focus['KRW']!.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(value, 'JPY', reason: '막힌 미국 달러를 건너뛴다');
        expect(focus['JPY']!.hasPrimaryFocus, isTrue);
        focus['KRW']!.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(value, 'JPY', reason: 'Enter 는 고르지 않는다');
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(value, 'KRW');
      },
    );

    testWidgets('묶음은 이름을 읽고 줄은 제목 + 설명 · 선택 여부 · 묶음 안임을 읽는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          radioRows(value: 'KRW', onChanged: (_) {}, disabled: 'JPY'),
        ),
      );
      final group = tester.getSemantics(find.bySemanticsLabel('기본 통화'));
      expect(group.getSemanticsData().role, SemanticsRole.radioGroup);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('대한민국 원'))),
        isSemantics(
          label: '대한민국 원\nKRW',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('미국 달러'))),
        isSemantics(
          label: '미국 달러\nUSD',
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('일본 엔'))),
        isSemantics(
          isEnabled: false,
          hasEnabledState: true,
          hasTapAction: false,
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: true,
          label: '일본 엔\nJPY',
        ),
      );
      semantics.dispose();
    });

    testWidgets('묶음의 이름은 필수다 · 묶음 밖에서는 쓸 수 없다', (tester) async {
      expect(
        () => PListRadioGroup<String>(
          semanticLabel: '',
          value: null,
          onChanged: null,
          children: const [],
        ),
        throwsAssertionError,
      );
    });
  });
}

// ── 부모 줄 ──────────────────────────────────────────────────

Widget _food({
  bool? open,
  bool defaultOpen = false,
  ValueChanged<bool>? onOpenChange,
  VoidCallback? onEdit = _noop,
  String? expandLabel = '식비 하위 카테고리',
  bool collapsible = true,
  PListAlign align = PListAlign.center,
  bool withChildren = true,
  VoidCallback? onChild,
}) => PList(
  semanticLabel: '지출 카테고리',
  children: [
    PListParentItem(
      align: align,
      prefix: const PListTile(
        background: Color(0xFFFAE0D5),
        color: Color(0xFFBE490D),
        child: Icon(LucideIcons.utensils),
      ),
      title: '식비',
      detail: '지출 · 하위 2개',
      collapsible: collapsible,
      expandLabel: collapsible ? expandLabel : null,
      open: open,
      defaultOpen: collapsible ? defaultOpen : null,
      onOpenChange: onOpenChange,
      onTap: onEdit,
      children: withChildren
          ? [
              PListButtonItem(
                prefix: const PListTile(
                  background: Color(0xFFFAE0D5),
                  color: Color(0xFFBE490D),
                  child: Icon(LucideIcons.tag),
                ),
                title: '외식',
                detail: '지출',
                onTap: onChild ?? _noop,
              ),
              PListButtonItem(
                prefix: const PListTile(
                  background: Color(0xFFFAE0D5),
                  color: Color(0xFFBE490D),
                  child: Icon(LucideIcons.tag),
                ),
                title: '배달음식',
                detail: '지출',
                onTap: _noop,
              ),
            ]
          : const [],
    ),
    PListParentItem(
      prefix: const PListTile(
        background: Color(0xFFEDEFF3),
        color: Color(0xFF62697A),
        child: Icon(LucideIcons.tag),
      ),
      title: '기타',
      detail: '지출 · 하위 없음',
      expandLabel: '기타 하위 카테고리',
      onTap: _noop,
    ),
  ],
);

Finder get _expandButton => find.byType(PListExpandButton);
Finder get _childRows => find.byType(PListButtonItem);

/// 포커스가 놓인 자리 — 꺾쇠 단추면 `단추`, 줄이면 제목.
String _focused() {
  final context = FocusManager.instance.primaryFocus!.context!;
  var label = '?';
  var inButton = false;
  context.visitAncestorElements((e) {
    if (e.widget is PListExpandButton) inButton = true;
    if (e.widget is PListRowFrame) {
      label = (e.widget as PListRowFrame).title;
      return false;
    }
    return true;
  });
  return inButton ? '단추 $label' : label;
}

void _parentTests() {
  group('부모 줄', () {
    testWidgets('꺾쇠 단추의 이름은 고정이고 펼침은 expanded 로 읽는다 — 상태마다 이름을 바꾸지 않는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_host(Brightness.light, _food()));
      SemanticsNode button() =>
          tester.getSemantics(find.bySemanticsLabel('식비 하위 카테고리'));
      expect(
        button(),
        isSemantics(
          label: '식비 하위 카테고리',
          isButton: true,
          hasTapAction: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );
      await tester.tap(_expandButton);
      await tester.pump();
      expect(
        button(),
        isSemantics(
          label: '식비 하위 카테고리',
          isButton: true,
          hasTapAction: true,
          hasExpandedState: true,
          isExpanded: true,
        ),
      );
      expect(button().getSemanticsData().controlsNodes, isNotEmpty);
      await tester.tap(_expandButton);
      await tester.pump();
      expect(button().label, '식비 하위 카테고리');
      semantics.dispose();
    });

    testWidgets('꺾쇠 단추는 줄과 따로 눌린다 — 단추를 눌러도 줄의 편집은 열리지 않고, 줄을 눌러도 접히지 않는다', (
      tester,
    ) async {
      var edit = 0;
      await tester.pumpWidget(
        _host(Brightness.light, _food(onEdit: () => edit++)),
      );
      await tester.tap(_expandButton);
      await tester.pump();
      expect(edit, 0);
      expect(_childRows, findsNWidgets(2));
      await tester.tap(findText(keepAll('지출 · 하위 2개')));
      await tester.pump();
      expect(edit, 1);
      expect(_childRows, findsNWidgets(2), reason: '줄을 눌러도 접히지 않는다');
    });

    testWidgets('접힘이 기본 — 하위 줄은 트리에 없다, 펼치면 생기고 접힘이 끝나면 다시 빠진다', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, _food()));
      expect(_childRows, findsNothing);
      expect(_subLists, findsNothing);
      await tester.tap(_expandButton);
      await tester.pump();
      expect(_childRows, findsNWidgets(2));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(_expandButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(_childRows, findsNWidgets(2), reason: '접히는 동안은 아직 그려져 있다');
      await tester.pump(const Duration(milliseconds: 160));
      expect(_childRows, findsNothing, reason: '접힘이 끝나면 트리에서 빠진다');
    });

    testWidgets('처음 펼침은 화면이 정한다 — defaultOpen', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _food(defaultOpen: true)),
      );
      expect(_childRows, findsNWidgets(2));
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        0.25,
      );
    });

    testWidgets(
      '쥐고 다루는 펼침 — open 을 따르고 onOpenChange 로 바꾸려는 값을 알린다(안 바꿔 주면 그대로)',
      (tester) async {
        final log = <bool>[];
        await tester.pumpWidget(
          _host(Brightness.light, _food(open: true, onOpenChange: log.add)),
        );
        await tester.tap(_expandButton);
        await tester.pump(const Duration(milliseconds: 400));
        expect(log, [false]);
        expect(_childRows, findsNWidgets(2), reason: '안 바꿔 주면 그대로');
        await tester.pumpWidget(
          _host(Brightness.light, _food(open: false, onOpenChange: log.add)),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(_childRows, findsNothing);
        await tester.tap(_expandButton);
        expect(log, [false, true]);
      },
    );

    testWidgets('스스로 다룰 때도 onOpenChange 를 부른다', (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(
        _host(Brightness.light, _food(onOpenChange: log.add)),
      );
      await tester.tap(_expandButton);
      await tester.pump();
      await tester.tap(_expandButton);
      await tester.pump();
      expect(log, [true, false]);
    });

    testWidgets(
      '부모 타일은 모두 52 에 서고 하위 타일은 부모 제목 자리 104 에 선다 — 하위가 없는 부모는 빈 자리',
      (tester) async {
        await tester.pumpWidget(
          _host(Brightness.light, _food(defaultOpen: true)),
        );
        final item = tester.getRect(_items.first);
        final prefixes = [
          for (var i = 0; i < 4; i++) tester.getRect(_prefixes.at(i)),
        ];
        // 부모 · 하위 · 하위 · 부모 순서
        expect(prefixes[0].left - item.left, 52);
        expect(prefixes[3].left - item.left, 52, reason: '하위 없는 부모도 같은 자리');
        expect(prefixes[1].left - item.left, 104);
        expect(prefixes[2].left - item.left, 104);
        expect(prefixes[1].left, tester.getRect(_titles.first).left);
        // 하위 없는 부모는 꺾쇠 단추 없이 같은 폭의 빈 자리
        expect(_expandButton, findsOneWidget);
        expect(_key('plist-expand-slot'), findsNWidgets(2));
        final slot = tester.getSize(_key('plist-expand-slot').last);
        expect(slot.width, 48);
      },
    );

    testWidgets('줄 높이는 그대로다 — 타일 40 줄은 64(꺾쇠 단추 44 가 위아래 2 를 여백에 겹친다)', (
      tester,
    ) async {
      const tile = PListTile(
        background: Color(0xFFFAE0D5),
        color: Color(0xFFBE490D),
        child: Icon(LucideIcons.utensils),
      );
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PList(
            semanticLabel: '지출 카테고리',
            children: [
              PListParentItem(
                prefix: tile,
                title: '식비',
                expandLabel: '식비 하위 카테고리',
                onTap: _noop,
                children: [PListButtonItem(title: '외식', onTap: _noop)],
              ),
              const PListItem(prefix: tile, title: '식비'),
            ],
          ),
        ),
      );
      expect(tester.getSize(_items.at(0)).height, 64);
      expect(
        tester.getSize(_items.at(0)).height,
        tester.getSize(_items.at(1)).height,
        reason: '꺾쇠 단추가 있어도 같은 높이',
      );
      final button = tester.getRect(_expandButton);
      final item = tester.getRect(_items.at(0));
      expect(button.top - item.top, 10);
      expect(item.bottom - button.bottom, 10);
    });

    testWidgets(
      'collapsible: false(늘 펼친 편집 모드) — 꺾쇠 자리를 비우고 하위 줄은 늘 보이며 expanded 로 읽히지 않는다',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(Brightness.light, _food(collapsible: false)),
        );
        expect(_expandButton, findsNothing);
        expect(_key('plist-expand-slot'), findsNWidgets(2));
        expect(_childRows, findsNWidgets(2));
        // 빈 자리는 접는 줄의 꺾쇠 자리와 같은 폭(44 + 뒤 4) — 타일은 접는 줄과 같은 52 에 선다
        expect(
          tester.getSize(_key('plist-expand-slot').first).width,
          kPListExpandSlot,
        );
        // 읽는 말에 꺾쇠 · 펼침 상태가 없다
        expect(find.bySemanticsLabel('식비 하위 카테고리'), findsNothing);
        expect(
          tester.getSemantics(_bodies.first),
          isNot(containsSemantics(hasExpandedState: true)),
        );
        handle.dispose();
      },
    );

    testWidgets('늘 펼친 줄 — 접힘이 없다(open · 누름 어느 것도 하위 줄을 감추지 않는다)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Brightness.light, _food(collapsible: false)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(_childRows, findsNWidgets(2));
      expect(_key('plist-sub-list-hidden'), findsNothing);
    });

    test('접는 줄은 하위가 없어도 expandLabel 이 필수다 — 늘 펼친 줄은 주지 않는다(생성자 assert)', () {
      // 접는 줄(기본) — expandLabel 없음 · 빈 문자열
      expect(
        () => PListParentItem(title: '기타', onTap: _noop),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PListParentItem(title: '기타', expandLabel: '', onTap: _noop),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PListParentItem(
          title: '기타',
          expandLabel: '기타 하위 카테고리',
          onTap: _noop,
        ),
        returnsNormally,
      );
      // 늘 펼친 줄 — 접는 줄의 속성이 하나라도 있으면 안 된다
      expect(
        () => PListParentItem(title: '취미', collapsible: false, onTap: _noop),
        returnsNormally,
      );
      expect(
        () => PListParentItem(
          title: '취미',
          collapsible: false,
          expandLabel: '취미 하위 카테고리',
          onTap: _noop,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PListParentItem(
          title: '취미',
          collapsible: false,
          open: true,
          onTap: _noop,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PListParentItem(
          title: '취미',
          collapsible: false,
          defaultOpen: false,
          onTap: _noop,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PListParentItem(
          title: '취미',
          collapsible: false,
          onOpenChange: (_) {},
          onTap: _noop,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('단추 가장자리를 눌러도 단추가 받는다', (tester) async {
      var edit = 0;
      await tester.pumpWidget(
        _host(Brightness.light, _food(onEdit: () => edit++)),
      );
      final button = tester.getRect(_expandButton);
      await tester.tapAt(Offset(button.center.dx, button.top + 1));
      await _settle(tester);
      expect(_childRows, findsNWidgets(2), reason: '위쪽 가장자리(콘텐츠 밖 2)');
      await tester.tapAt(Offset(button.center.dx, button.bottom - 1));
      await _settle(tester);
      expect(_childRows, findsNothing, reason: '아래쪽 가장자리');
      await tester.tapAt(Offset(button.left + 1, button.center.dy));
      await _settle(tester);
      expect(_childRows, findsNWidgets(2), reason: '왼쪽 가장자리');
      expect(edit, 0);
    });

    testWidgets('맞춤이 top 이면 꺾쇠 단추도 위에 선다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _food(align: PListAlign.top)),
      );
      final item = tester.getRect(_items.first);
      final button = tester.getRect(_expandButton);
      expect(button.top - item.top, 10, reason: '콘텐츠 위 12 − 2');
    });

    testWidgets('막힌 부모 줄 — 줄은 막히고 비활성 색, 꺾쇠 단추는 따로 눌린다', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, _food(onEdit: null)));
      expect(
        sameColor(
          PColors.light.fgDisabled,
          _textStyle(tester, _titles.first).color!,
        ),
        isTrue,
      );
      final gesture = await _press(tester, _titles.first);
      expect(_decoration(tester, _backgrounds.first).color!.a, 0);
      await gesture.up();
      await tester.tap(_expandButton);
      await tester.pump();
      expect(_childRows, findsNWidgets(2));
    });

    testWidgets('하위 줄은 누르는 줄이다 — 하위 줄의 동작은 그 줄이 연다', (tester) async {
      var child = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _food(defaultOpen: true, onChild: () => child++),
        ),
      );
      await tester.tap(findText(keepAll('외식')));
      expect(child, 1);
    });

    testWidgets('키보드 — 꺾쇠 단추에서 Enter · Space 로 펼치고 접는다', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, _food()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(_focused(), '단추 식비');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(_childRows, findsNWidgets(2));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _settle(tester);
      expect(_childRows, findsNothing);
    });

    testWidgets('Tab 은 꺾쇠 단추 → 그 줄 → 펼친 하위 줄 → 다음 부모의 줄 — 접힌 하위 줄은 건너뛴다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Brightness.light, _food(defaultOpen: true)),
      );
      final order = <String>[];
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        order.add(_focused());
      }
      expect(order, ['단추 식비', '식비', '외식', '배달음식', '기타']);
      // 접으면 하위 줄을 건너뛴다
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_host(Brightness.light, _food()));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      final collapsed = <String>[];
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        collapsed.add(_focused());
      }
      expect(collapsed, ['단추 식비', '식비', '기타']);
    });

    testWidgets('읽는 순서 — 꺾쇠 단추 → 줄 → 펼친 하위 줄 → 다음 부모', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, _food(defaultOpen: true)),
      );
      final labels = tester.semantics
          .simulatedAccessibilityTraversal(
            startNode: find.semantics.byLabel('지출 카테고리'),
          )
          .map((n) => n.label)
          .where((l) => l.isNotEmpty)
          .toList();
      expect(labels, [
        '지출 카테고리',
        '식비 하위 카테고리',
        '식비\n지출 · 하위 2개',
        '외식\n지출',
        '배달음식\n지출',
        '기타\n지출 · 하위 없음',
      ]);
      semantics.dispose();
    });

    testWidgets('접히면 하위 줄은 읽지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_host(Brightness.light, _food()));
      expect(find.bySemanticsLabel(RegExp('^외식')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^기타')), findsOneWidget);
      semantics.dispose();
    });
  });

  group('펼침 모션', () {
    double clipHeight(WidgetTester tester) =>
        tester.getSize(_key('plist-sub-list-clip')).height;

    testWidgets('펼침은 높이 300ms · motion-ease-easing — 0 에서 전체 높이까지', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, _food()));
      await tester.tap(_expandButton);
      await tester.pump();
      expect(clipHeight(tester), 0);
      await tester.pump(const Duration(milliseconds: 75));
      final quarter = clipHeight(tester);
      await tester.pump(const Duration(milliseconds: 225));
      final full = clipHeight(tester);
      expect(
        full,
        tester.getSize(_items.at(1)).height +
            tester.getSize(_items.at(2)).height,
        reason: '하위 줄 둘의 높이',
      );
      expect(
        quarter,
        closeTo(full * PEasing.easing.transform(0.25), 0.5),
        reason: '곡선을 따른다',
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(clipHeight(tester), full);
    });

    testWidgets('접힘은 지금 높이에서 0 까지 — 움직이는 도중에 다시 누르면 지금 높이에서 되돌아간다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Brightness.light, _food(defaultOpen: true)),
      );
      final natural =
          tester.getSize(_items.at(1)).height +
          tester.getSize(_items.at(2)).height;
      expect(clipHeight(tester), natural, reason: '처음 그릴 때는 움직이지 않는다');
      await tester.tap(_expandButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = clipHeight(tester);
      expect(mid, lessThan(natural));
      expect(mid, greaterThan(0));
      await tester.tap(_expandButton);
      await tester.pump();
      expect(clipHeight(tester), closeTo(mid, 0.5), reason: '되돌아갈 때 뛰지 않는다');
      await tester.pump(const Duration(milliseconds: 300));
      expect(clipHeight(tester), natural);
    });

    testWidgets('꺾쇠는 300ms 로 90° 돈다 — 모션 줄이기면 바로', (tester) async {
      double degrees() {
        final m = tester
            .renderObject(
              find.descendant(of: _expandIcons, matching: find.byType(Icon)),
            )
            .getTransformTo(null);
        return math.atan2(m.entry(1, 0), m.entry(0, 0)) * 180 / math.pi;
      }

      await tester.pumpWidget(_host(Brightness.light, _food()));
      expect(degrees(), closeTo(0, 0.01));
      await tester.tap(_expandButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(degrees(), closeTo(90 * PEasing.easing.transform(0.5), 0.5));
      await tester.pump(const Duration(milliseconds: 150));
      expect(degrees(), closeTo(90, 0.01));

      await tester.pumpWidget(
        _host(Brightness.light, _food(), reduceMotion: true),
      );
      expect(degrees(), closeTo(0, 0.01));
      await tester.tap(_expandButton);
      await tester.pump();
      expect(degrees(), closeTo(90, 0.01), reason: '움직임 없이 바로 돈다');
    });

    testWidgets('모션 줄이기면 높이를 움직이지 않고 150ms 서서히 나타나고 사라진다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _food(), reduceMotion: true),
      );
      await tester.tap(_expandButton);
      await tester.pump();
      expect(_key('plist-sub-list-clip'), findsNothing, reason: '높이 움직임이 없다');
      double opacity() =>
          tester.widget<Opacity>(_key('plist-sub-list-fade')).opacity;
      final natural = tester.getSize(_key('plist-sub-list')).height;
      expect(natural, greaterThan(100), reason: '높이는 처음부터 전체다');
      expect(opacity(), 0);
      await tester.pump(const Duration(milliseconds: 75));
      expect(opacity(), closeTo(PEasing.easing.transform(0.5), 0.01));
      await tester.pump(const Duration(milliseconds: 75));
      expect(opacity(), 1);
      // 접을 때도 서서히 — 끝나면 트리에서 빠진다
      await tester.tap(_expandButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(opacity(), closeTo(1 - PEasing.easing.transform(0.5), 0.01));
      expect(tester.getSize(_key('plist-sub-list')).height, natural);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_childRows, findsNothing);
    });

    testWidgets('꺾쇠 단추를 누르는 모습 — 단추만 누름 색 + 축소(기준 44)이고 줄은 눌리지 않는다', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, _food()));
      final gesture = await _press(tester, _expandButton);
      expect(
        sameColor(
          PColors.light.bgLayerDefaultPressed,
          _decoration(tester, _expandButtons).color!,
        ),
        isTrue,
      );
      expect(_paintedScale(tester, _expandButtons), closeTo(42 / 44, 1e-3));
      expect(_decoration(tester, _backgrounds.first).color!.a, 0);
      expect(_paintedScale(tester, _rows.first), closeTo(1, 1e-6));
      await gesture.up();
    });

    testWidgets('꺾쇠 단추를 눌러도 모션 줄이기면 축소 없이 색만 바뀐다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _food(), reduceMotion: true),
      );
      final gesture = await _press(tester, _expandButton);
      expect(_decoration(tester, _expandButtons).color!.a, 1);
      expect(_paintedScale(tester, _expandButtons), closeTo(1, 1e-6));
      await gesture.up();
    });

    testWidgets('카탈로그는 꺾쇠 단추의 누름도 멈춰 그린다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PListPressedPreview(
            target: PListPreviewTarget.expandButton,
            child: Text('x'),
          ),
        ),
      );
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PListPressedPreview(
            target: PListPreviewTarget.expandButton,
            child: _food(),
          ),
        ),
      );
      await _settle(tester);
      expect(_decoration(tester, _expandButtons).color!.a, 1);
      expect(_decoration(tester, _backgrounds.first).color!.a, 0);
    });
  });
}

// ── 가장 나쁜 값 ─────────────────────────────────────────────

void _worstTests() {
  group('가장 나쁜 값', () {
    testWidgets('아주 긴 제목 · 설명은 줄을 바꿔 끝까지 그린다 — 말줄임 · 줄 수 제한이 없다', (
      tester,
    ) async {
      const longTitle = '롯데백화점 본점 지하 1층 식품관 프리미엄 한우 선물세트 · 추석 명절 대량 구매 ';
      const longWord = 'porest-desk-front-design-system-list-component';
      await tester.pumpWidget(
        _host(
          Brightness.light,
          SingleChildScrollView(
            child: PList(
              semanticLabel: '거래',
              children: [
                PListButtonItem(
                  align: PListAlign.top,
                  title: longTitle * 3,
                  detail: longWord * 4,
                  suffix: const Text('-123,456,789원'),
                  onTap: _noop,
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      for (final text in tester.widgetList<Text>(
        find.descendant(of: _items, matching: find.byType(Text)),
      )) {
        expect(text.maxLines, isNull, reason: '줄 수 제한이 없다');
        expect(text.overflow, isNull, reason: '말줄임이 없다');
      }
      // 제목은 여러 줄 — 22 줄 높이 세 줄 이상
      expect(tester.getSize(_titles).height, greaterThanOrEqualTo(66));
      expect(tester.getSize(_details).height, greaterThanOrEqualTo(36));
      // 제목이 두 줄을 넘으면 앞 · 뒤를 위로 맞춘다
      final row = tester.getRect(_rows);
      expect(tester.getRect(_suffixes).top, row.top);
    });

    // 스펙(Q-001)의 값 — 같은 JSON 을 웹도 읽는다
    final want = _spec.resolve(const {
      'align': 'center',
      'highlight': 'none',
    }, 'enabled');

    testWidgets('스펙 값 — 본문은 제목의 가장 긴 낱말 폭 아래로 안 줄고, 글 값만 줄고 끝에서 끊는다', (
      tester,
    ) async {
      expect(want['body.flexGrow'], 1);
      // body.minWidth = min-content — 제목 keep-all 이라 가장 긴 낱말(코드의 listTitleMinWidth, 상한은 줄 안 폭 − 앞 자리의 절반)
      expect(want['body.minWidth'], 'min-content');
      expect(want['title.overflowWrap'], 'break-word');
      expect(want['title.wordBreak'], 'keep-all');
      expect(want['detail.overflowWrap'], 'anywhere');
      expect(want['suffix.shrink'], 0);
      expect(want['suffixText.shrink'], 1);
      expect(want['suffixText.overflowWrap'], 'anywhere');
      expect(want['suffixText.textAlign'], 'end');
      expect(kPListBodyTrailGap, 10);
    });

    for (final width in const [320.0, 360.0]) {
      testWidgets(
        '글로 넘긴 긴 값은 본문이 제목의 가장 긴 낱말 폭이 된 뒤에야 줄고 줄 끝에서 끊는다 — 폭 $width, 넘침 0',
        (tester) async {
          for (final value in const [
            'desk@example.kr',
            'porest-desk-front-design-system-list-component-with-a-very-long-name@example.kr',
            '2026년 10월 2일 오후 2:30 · 포레스트 체크카드 · 개인 사업자',
          ]) {
            await tester.pumpWidget(
              _host(
                Brightness.light,
                PList(
                  semanticLabel: '긴 값',
                  children: [
                    PListItem(
                      prefix: const Icon(LucideIcons.mail),
                      title: '이메일 주소',
                      suffix: Text(value),
                    ),
                  ],
                ),
                width: width,
              ),
            );
            expect(tester.takeException(), isNull, reason: '$value @ $width');
            final body = tester.getRect(_bodies);
            final suffix = tester.getRect(_suffixes);
            final row = tester.getRect(_rows);
            expect(body.width, greaterThanOrEqualTo(_minBody('이메일 주소') - 0.5));
            expect(
              body.right,
              lessThanOrEqualTo(suffix.left + 0.5),
              reason: '값이 본문 위로 넘치지 않는다',
            );
            expect(
              suffix.right,
              lessThanOrEqualTo(row.right + 0.5),
              reason: '값이 줄 밖으로 나가지 않는다',
            );
          }
        },
      );
    }

    // 금액 노드(PListValue.amount)도 글 값처럼 본문 최소 폭만 남기고 쉼표 뒤에서 줄을 바꾼다(03-D 결정 2 B) — 내리지 않는 줄(줄 안 폭 16em 이상)
    for (final width in const [304.0, 320.0, 360.0]) {
      testWidgets('금액 노드는 쉼표 뒤에서만 줄을 바꾸고 넘치지 않는다 — 폭 $width', (tester) async {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PList(
              semanticLabel: '금액',
              children: [
                PListItem(
                  prefix: const Icon(LucideIcons.wallet),
                  title: '가게',
                  suffix: PListValue.amount('−1,234,567,890원'),
                ),
              ],
            ),
            width: width,
          ),
        );
        expect(tester.takeException(), isNull, reason: '폭 $width');
        final body = tester.getRect(_bodies);
        final suffix = tester.getRect(_suffixes);
        final row = tester.getRect(_rows);
        expect(body.width, greaterThanOrEqualTo(_minBody('가게') - 0.5));
        expect(suffix.left, greaterThanOrEqualTo(body.right - 0.5));
        expect(suffix.right, lessThanOrEqualTo(row.right + 0.5));
        // 쉼표 뒤에서 접힌 것 — 한 줄(t5 22)보다 높거나 한 줄이다. 어느 쪽이든 글자 가운데에서 끊기지 않는다.
        final shown = find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.semanticsLabel == '−1,234,567,890원' &&
              w.data != null,
        );
        expect(shown, findsOneWidget);
        expect(shown.evaluate().single.widget, isA<Text>());
      });
    }

    testWidgets('금액 노드가 줄 안 값 폭을 넘으면 쉼표 자리에서 두 줄로 접힌다 — 글자 가운데에서 끊기지 않는다', (
      tester,
    ) async {
      const amount = '−1,234,567,890,123,456,789원';
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PList(
            semanticLabel: '금액',
            children: [
              PListItem(
                prefix: const Icon(LucideIcons.wallet),
                title: '가게',
                suffix: PListValue.amount(amount),
              ),
            ],
          ),
          width: 304,
        ),
      );
      expect(tester.takeException(), isNull);
      final shown = find.byWidgetPredicate(
        (w) => w is Text && w.semanticsLabel == amount && w.data != null,
      );
      expect(shown, findsOneWidget);
      final text = tester.widget<Text>(shown);
      // 보이는 글은 쉼표 뒤에만 줄바꿈 자리(U+200B)가 있다 — 읽는 이름(semanticsLabel)에는 없다
      expect(text.data!.replaceAll('\u2060', '').contains(',\u200B'), isTrue);
      expect(
        text.data!.replaceAll('\u2060', '').replaceAll('\u200B', ''),
        amount,
      );
      expect(text.semanticsLabel, amount);
      // 줄바꿈 자리는 쉼표 바로 뒤에만 있다(U+200B 앞은 늘 쉼표)
      final visible = text.data!.replaceAll('\u2060', '');
      expect(
        RegExp('\u200B')
            .allMatches(visible)
            .every((m) => m.start > 0 && visible[m.start - 1] == ','),
        isTrue,
      );
      // 한 줄(t5 22)보다 높다 = 접혔다
      expect(tester.getSize(shown).height, greaterThan(30));
      // 접힌 줄은 줄 안 폭을 넘지 않는다
      expect(
        tester.getRect(shown).right,
        lessThanOrEqualTo(tester.getRect(_rows).right + 0.5),
      );
    });

    testWidgets('글 값은 자리가 남으면 줄지 않는다 — 본문이 양보하는 쪽은 그다음이다', (tester) async {
      Future<Size> suffixSize(double width, String value) async {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PList(
              semanticLabel: '값',
              children: [PListItem(title: '이메일', suffix: Text(value))],
            ),
            width: width,
          ),
        );
        return tester.getSize(_suffixes);
      }

      // Q-001 은 줄 안 폭이 16em(256)이상일 때의 규칙이다(좁은 줄은 값이 아래로 간다 — p_list_narrow_test) — 그 폭에서
      // 값이 모자랄 만큼 긴 글을 쓴다
      const value = 'desk-long-address-name-and-more@example.kr';
      final wide = await suffixSize(800, value);
      final minBody = _minBody('이메일');
      expect(wide.width + minBody - 40, greaterThan(256));
      // 본문(이메일)이 눌려도 본문 최소 폭이 남는 폭 — 값은 그대로다
      final mid = await suffixSize(wide.width + 48 + minBody + 4, value);
      expect(mid.width, wide.width);
      // 더 좁아지면 값이 줄고 본문은 최소 폭에 머문다
      final narrow = await suffixSize(wide.width + 48 + minBody - 40, value);
      expect(narrow.width, lessThan(wide.width));
      expect(narrow.height, greaterThan(wide.height), reason: '줄이 바뀐다');
      final body = tester.getRect(_bodies);
      expect(body.width, closeTo(minBody, 0.5));
    });

    testWidgets('값 + 화살표는 본문이 먼저 양보하고(가장 긴 낱말 폭까지), 그다음에야 값이 줄을 바꾼다', (
      tester,
    ) async {
      Future<(Size, Size)> sizes(double width) async {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            const PList(
              semanticLabel: '자산',
              children: [
                PListItem(
                  title: '입출금 통장',
                  suffix: PListSuffix(
                    children: [
                      Text('-1,234,567,890원'),
                      Icon(LucideIcons.chevronRight),
                    ],
                  ),
                ),
              ],
            ),
            width: width,
          ),
        );
        return (tester.getSize(_suffixes), tester.getSize(_bodies));
      }

      final (wideSuffix, wideBody) = await sizes(800);
      for (final width in const [360.0, 320.0]) {
        final (suffix, body) = await sizes(width);
        // 값 + 화살표도 글 값과 같은 폭 제한을 받는다 — 본문이 제목의 가장 긴 낱말 폭까지 양보한 뒤에야 값이 줄을 바꾼다
        expect(suffix.width, lessThanOrEqualTo(wideSuffix.width));
        expect(body.width, lessThan(wideBody.width), reason: '본문이 양보한다');
        expect(
          body.width,
          greaterThanOrEqualTo(_minBody('입출금 통장') - 0.5),
          reason: '본문은 가장 긴 낱말 폭 아래로 안 준다',
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('아주 긴 제목 · 설명은 낱말보다 좁아질 때만 글자 사이에서 끊는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const SingleChildScrollView(
            child: PList(
              semanticLabel: '긴 낱말',
              children: [
                PListItem(
                  title: '입출금 통장 이름이 아주 긴 경우',
                  detail:
                      'porest-desk-front-design-system-list-component-with-a-very-long-name',
                  suffix: Text('desk@example.kr'),
                ),
              ],
            ),
          ),
          width: 320,
        ),
      );
      expect(tester.takeException(), isNull);
      // 제목 · 설명의 긴 낱말은 칸 끝에서 끊긴다(본문 밖으로 넘치지 않는다)
      expect(
        tester.getRect(_titles).right,
        lessThanOrEqualTo(tester.getRect(_bodies).right),
      );
      expect(
        tester.getRect(_details).right,
        lessThanOrEqualTo(tester.getRect(_bodies).right),
      );
    });

    testWidgets('접힌 하위 줄이 많은 부모는 줄 하나 — 펼치면 48 줄', (tester) async {
      Widget many(bool open) => PList(
        semanticLabel: '카테고리',
        children: [
          PListParentItem(
            title: '식비',
            expandLabel: '식비 하위 카테고리',
            open: open,
            onTap: _noop,
            children: [
              for (var i = 1; i <= 48; i++)
                PListButtonItem(title: '하위 $i', onTap: _noop),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        _host(Brightness.light, SingleChildScrollView(child: many(false))),
      );
      expect(find.byType(PListRowFrame), findsOneWidget);
      expect(_childRows, findsNothing);
      await tester.pumpWidget(
        _host(Brightness.light, SingleChildScrollView(child: many(true))),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(_childRows, findsNWidgets(48));
    });

    testWidgets('빈 목록 · 줄이 하나인 목록도 그린다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PList(semanticLabel: '빈 목록', children: []),
        ),
      );
      expect(tester.getSize(find.byType(PList)).height, 0);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PList(children: [PListItem(title: '하나')]),
        ),
      );
      expect(_items, findsOneWidget);
    });
  });

  group('견본', () {
    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 견본이 폰 폭 360 에서 그려진다(넘치지 않는다)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _host(
            mode,
            SingleChildScrollView(child: const ListDemo()),
            width: 390,
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
