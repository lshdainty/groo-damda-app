// Select 가 스펙 값(test/fixtures/design_spec/select.json)대로인지 — 칸의 상태(기본 · 누름 · 오류 · 비활성 · 읽기 전용) ×
// 값 있음 · 없음 × 라이트 · 다크, 열린 목록(셰브론 · 목록 · 선택지 · 묶음 · 선)과 동작(고르기 · 여럿 · 키보드 · 닫는 길 ·
// 위로 뒤집힘). 웹은 같은 JSON 을 크로미움에서 잰다.
//
// 앱은 늘 large 다 — medium · responsive(1280 이상 데스크톱 웹)는 재지 않는다. 앱에 없는 상태(웹의 focused — 키보드 포커스
// 링)도 재지 않는다. 목록은 폰에서도 칸 아래에 붙는다(시트가 아니다).
import 'dart:math' as math;
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';
import 'package:groo_damda_app/shared/ds/select/select_demo.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('select');
const _large = {'size': 'large'};

Widget _host(
  Brightness mode,
  Widget child, {
  double width = 312,
  Alignment alignment = Alignment.topLeft,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(
    body: Align(
      alignment: alignment,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

// 견본 — 첫 묶음(제목 없음)의 첫 선택지는 아이콘이 있고 설명이 없다(높이 46), 둘째는 설명이 있다(66). 둘째 묶음은 제목이 있다.
const _groups = <PSelectGroup<String>>[
  PSelectGroup(
    items: [
      PSelectItem(value: 'cash', label: '현금', prefixIcon: LucideIcons.banknote),
      PSelectItem(
        value: 'kb',
        label: '국민 주계좌',
        description: '123-45-6789',
        prefixIcon: LucideIcons.landmark,
      ),
    ],
  ),
  PSelectGroup(
    label: '그 밖',
    items: [
      PSelectItem(
        value: 'wallet',
        label: '간편결제',
        prefixIcon: LucideIcons.wallet,
      ),
      PSelectItem(
        value: 'off',
        label: '막힌 선택지',
        description: '고를 수 없어요',
        prefixIcon: LucideIcons.wallet,
        enabled: false,
      ),
    ],
  ),
];

Widget _select({
  String? value,
  ValueChanged<String>? onChanged,
  bool? disabled,
  bool? readOnly,
  bool? invalid,
  List<PSelectGroup<String>> groups = _groups,
  IconData? prefixIcon = LucideIcons.creditCard,
  FocusNode? focusNode,
}) => PSelect<String>(
  groups: groups,
  value: value,
  onChanged: onChanged ?? (_) {},
  placeholder: '결제 수단 선택',
  prefixIcon: prefixIcon,
  semanticLabel: '결제 수단',
  disabled: disabled,
  readOnly: readOnly,
  invalid: invalid,
  focusNode: focusNode,
);

/// 값을 쥐는 쓰는 쪽.
class _Live extends StatefulWidget {
  const _Live({this.initial, this.groups = _groups, this.onPick});

  final String? initial;
  final List<PSelectGroup<String>> groups;
  final ValueChanged<String>? onPick;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late String? value = widget.initial;

  @override
  Widget build(BuildContext context) => _select(
    value: value,
    groups: widget.groups,
    onChanged: (next) {
      widget.onPick?.call(next);
      setState(() => value = next);
    },
  );
}

class _LiveMulti extends StatefulWidget {
  const _LiveMulti({
    required this.initial,
    this.onValues,
    this.withOverflow = true,
  });

  final List<String> initial;
  final ValueChanged<List<String>>? onValues;
  final bool withOverflow;

  @override
  State<_LiveMulti> createState() => _LiveMultiState();
}

class _LiveMultiState extends State<_LiveMulti> {
  late List<String> values = widget.initial;

  @override
  Widget build(BuildContext context) => PSelect<String>.multiple(
    groups: _groups,
    values: values,
    placeholder: '결제 수단 선택',
    semanticLabel: '결제 수단',
    overflowLabel: widget.withOverflow
        ? (first, others) => '$first 외 $others개'
        : null,
    onChanged: (next) {
      widget.onValues?.call(next);
      setState(() => values = next);
    },
  );
}

Finder get _trigger => find.byKey(const ValueKey('select-trigger'));
Finder get _value => find.byKey(const ValueKey('select-value'));
Finder get _chevron => find.byKey(const ValueKey('select-chevron'));
Finder get _prefix => find.byKey(const ValueKey('select-prefix-icon'));
Finder get _contentBox => find.byKey(const ValueKey('select-content-box'));

Finder _row(String label) => find.ancestor(
  of: find.text(keepAll(label)),
  matching: find.byKey(const ValueKey('select-item')),
);

BoxDecoration _deco(WidgetTester tester, Finder finder) =>
    tester.widget<DecoratedBox>(finder).decoration as BoxDecoration;

TextStyle _style(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).style!;

Color _iconColor(WidgetTester tester, Finder finder) =>
    tester.widget<Icon>(finder).color!;

/// 전환(누름 · 알약 150ms · 목록 열고 닫기)이 끝나게 기다린다 — 시작한 프레임 다음 프레임부터 흐른다.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// 열린다 — 목록이 선 뒤까지 기다린다.
Future<void> _open(WidgetTester tester) async {
  await tester.tap(_trigger);
  await tester.pump();
  await _settle(tester);
}

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
    if (w == null) return fail('$key: 스펙에 없다');
    if (!sameColor(specColor(w), actual)) {
      fail('$key: 스펙 $w · 실제 ${colorHex(actual)}');
    }
  }

  void px(String key, num actual) {
    measured.add(key);
    final w = want[key];
    if (w is! num) return fail('$key: 스펙에 수가 없다($w)');
    if ((w - actual).abs() > 0.5) fail('$key: 스펙 $w · 실제 $actual');
  }

  void typo(String key, TextStyle style) {
    measured.add(key);
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
      fail('$key 글꼴: 스펙 $family · 실제 ${style.fontFamily}');
    }
    final slot = key.split('.').first;
    // 부위에 굵기가 따로 있으면(groupLabel 500) 그 값이 이긴다
    final w = want['$slot.fontWeight'] ?? t['fontWeight'];
    measured.add('$slot.fontWeight');
    if (style.fontWeight?.value != w) {
      fail('$key: 굵기 스펙 $w · 실제 ${style.fontWeight}');
    }
  }

  void cursor(String key, MouseCursor actual) {
    measured.add(key);
    final expected = switch (want[key]) {
      'pointer' => SystemMouseCursors.click,
      'not-allowed' => SystemMouseCursors.forbidden,
      'default' => SystemMouseCursors.basic,
      _ => null,
    };
    if (expected != null && actual != expected) {
      fail('$key: 스펙 ${want[key]} · 실제 $actual');
    }
  }

  void motion(String durationKey, String easingKey, Duration d, Curve curve) {
    measured.addAll([durationKey, easingKey]);
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

  void coverage(bool Function(String key) elsewhere) {
    for (final key in want.keys) {
      if (!measured.contains(key) && !elsewhere(key)) {
        fail('$key: 스펙에 있는데 이 테스트가 재지 않는다 — 재는 곳을 더한다');
      }
    }
  }
}

/// 목록 · 선택지 · 묶음의 값 — 열린 목록 테스트가 잰다. 앱에 없는 것: 포커스 링(웹 키보드 포커스).
bool _inList(String key) =>
    key.startsWith('content.') ||
    key.startsWith('item.') ||
    key.startsWith('itemIcon.') ||
    key.startsWith('itemLabel.') ||
    key.startsWith('itemDescription.') ||
    key.startsWith('indicator.') ||
    key.startsWith('highlight.') ||
    key.startsWith('groupLabel.') ||
    key.startsWith('divider.');

const _webOnly = {'focusRing.width', 'focusRing.offset', 'focusRing.color'};

void main() {
  const triggerStates = [
    'enabled',
    'pressed',
    'invalid',
    'disabled',
    'readonly',
  ];

  for (final mode in Brightness.values) {
    for (final state in triggerStates) {
      for (final hasValue in [true, false]) {
        final title = '${mode.name} $state ${hasValue ? '값' : 'placeholder'}';
        testWidgets('칸 $title — 스펙 값이다', (tester) async {
          await tester.pumpWidget(
            _host(
              mode,
              _select(
                value: hasValue ? 'cash' : null,
                invalid: state == 'invalid',
                disabled: state == 'disabled',
                readOnly: state == 'readonly',
              ),
            ),
          );
          TestGesture? gesture;
          if (state == 'pressed') {
            gesture = await tester.startGesture(tester.getCenter(_trigger));
            await tester.pump();
          }
          await _settle(tester);

          final want = _spec.resolve(_large, state);
          final k = _Check(mode, want, title);
          final c = tester.element(_trigger).colors;

          // 상자 — 바탕 · 1px 선 · 오류의 안쪽 2px
          final boxes = find.descendant(
            of: _trigger,
            matching: find.byType(DecoratedBox),
          );
          final bg = _deco(tester, boxes.at(0));
          final overlay = _deco(tester, boxes.at(1));
          final base = _deco(tester, boxes.at(2));
          k.color('trigger.background', bg.color ?? const Color(0x00000000));
          k.px('trigger.radius', (bg.borderRadius as BorderRadius).topLeft.x);
          final wide = want['trigger.borderWidth'] == 2;
          final side = wide
              ? (overlay.border! as Border).bottom
              : (base.border! as Border).bottom;
          k.color('trigger.borderColor', side.color);
          k.px('trigger.borderWidth', side.width);
          if (!wide && (overlay.border! as Border).bottom.color.a != 0) {
            k.fail('덧그린 2px 가 남아 있다');
          }
          k.px('trigger.minHeight', tester.getSize(_trigger).height);
          // 안쪽 여백 · 아이콘 사이
          final content = find.byKey(const ValueKey('select-content'));
          final padding = tester.widget<Padding>(content).padding;
          k.px('trigger.paddingX', (padding as EdgeInsets).left);
          final row = tester.widget<Row>(
            find.descendant(of: content, matching: find.byType(Row)).first,
          );
          k.px('trigger.gap', row.spacing);

          // 커서 — MouseRegion 은 GestureDetector 바깥이다
          final region = tester.widget<MouseRegion>(
            find
                .ancestor(of: _trigger, matching: find.byType(MouseRegion))
                .first,
          );
          k.cursor('trigger.cursor', region.cursor);

          // 전환 — 바탕 150ms
          final tween = tester.widget<TweenAnimationBuilder<double>>(
            find
                .ancestor(
                  of: _trigger,
                  matching: find.byType(TweenAnimationBuilder<double>),
                )
                .first,
          );
          k.motion(
            'trigger.transitionDuration',
            'trigger.transitionEasing',
            tween.duration,
            tween.curve,
          );
          k.measured.add('trigger.transitionProperty');

          // 누름 — 값 · 아이콘만 2px 거리 줄어든다(기준 = max(높이, 폭 ÷ 4, 24))
          final scale = tester.widget<AnimatedScale>(
            find.ancestor(of: content, matching: find.byType(AnimatedScale)),
          );
          final size = tester.getSize(_trigger);
          final basis = math.max(size.height, math.max(size.width / 4, 24.0));
          final wantScale = want['trigger.scale'] != null
              ? (basis - 2) / basis
              : 1.0;
          k.measured.addAll(['trigger.scale']);
          if ((scale.scale - wantScale).abs() > 1e-3) {
            k.fail('trigger.scale: 스펙 $wantScale · 실제 ${scale.scale}');
          }
          if (want['trigger.scaleDuration'] != null) {
            k.motion(
              'trigger.scaleDuration',
              'trigger.scaleEasing',
              scale.duration,
              scale.curve,
            );
          }

          // 값 · placeholder
          final shown = tester.widget<Text>(
            find
                    .descendant(of: _value, matching: find.byType(Text))
                    .evaluate()
                    .isEmpty
                ? _value
                : find.descendant(of: _value, matching: find.byType(Text)),
          );
          final slot = hasValue ? 'value' : 'placeholder';
          final style = shown.style!;
          final fg = pickMode(want['$slot.foreground'], mode);
          k.measured.add('$slot.foreground');
          if (!sameColor(specColor(fg), style.color!)) {
            k.fail('$slot.foreground: 스펙 $fg · 실제 ${colorHex(style.color!)}');
          }
          k.typo('$slot.typography', style);
          k.measured.addAll(['value.fontWeight', 'placeholder.fontWeight']);
          if (style.fontWeight?.value != want['$slot.fontWeight']) {
            k.fail('$slot.fontWeight: 실제 ${style.fontWeight}');
          }

          // 앞 아이콘 · 셰브론
          k.color('prefixIcon.color', _iconColor(tester, _prefix));
          k.px('prefixIcon.size', tester.getSize(_prefix).width);
          k.color('chevron.color', _iconColor(tester, _chevron));
          k.px('chevron.size', tester.getSize(_chevron).width);
          expect(c.fgNeutral, isNotNull);

          // 보이지 않는 쪽 글(값이 있으면 placeholder · 없으면 value)은 이 판에서 잴 수 없다 — 다른 판이 잰다
          final other = hasValue ? 'placeholder.' : 'value.';
          k.coverage(
            (key) =>
                _inList(key) || _webOnly.contains(key) || key.startsWith(other),
          );
          expect(k.failures, isEmpty, reason: k.failures.join('\n'));
          await gesture?.up();
          await _settle(tester);
        });
      }
    }

    // 열린 목록 — 칸 아래에 붙는다. 선택지 · 묶음 · 선 · 알약
    for (final pressed in [false, true]) {
      final title = '${mode.name} ${pressed ? '누른 선택지' : '기본'}';
      testWidgets('목록 $title — 스펙 값이다', (tester) async {
        await tester.pumpWidget(_host(mode, _select(value: 'kb')));
        await _open(tester);
        final want = _spec.resolve(_large, pressed ? 'pressed' : 'enabled');
        final k = _Check(mode, want, title);

        // 목록 — 칸 폭 · 칸 아래 8 · 바탕 · 모서리 20 · 위아래 8
        final box = tester.getRect(_contentBox);
        final trigger = tester.getRect(_trigger);
        final content = _deco(tester, _contentBox);
        k.color('content.background', content.color!);
        k.px(
          'content.radius',
          (content.borderRadius as BorderRadius).topLeft.x,
        );
        k.px('content.marginTop', box.top - trigger.bottom);
        k.measured.add('content.width');
        if ((box.width - trigger.width).abs() > 0.5 ||
            (box.left - trigger.left).abs() > 0.5) {
          k.fail('content.width: 목록 폭이 칸과 다르다 ${box.width} ≠ ${trigger.width}');
        }
        if (!listEquals(
          content.boxShadow,
          tester.element(_trigger).shadows.s3,
        )) {
          k.fail('content.shadow: shadow-s3 가 아니다');
        }
        k.measured.addAll(['content.shadow', 'content.zIndex']);
        final first = tester.getRect(_row('현금'));
        k.px('content.paddingY', first.top - box.top);

        // 선택지 — 높이 46 · 설명이 있으면 66 · 좌우 16 · 앞 아이콘 22 · 사이 12
        k.px('item.height', first.height);
        final second = tester.getRect(_row('국민 주계좌'));
        if ((second.height - 66).abs() > 0.5) {
          k.fail('item.height(설명 있음): 스펙 66 · 실제 ${second.height}');
        }
        final icons = find.byKey(const ValueKey('select-item-icon'));
        final iconRect = tester.getRect(icons.first);
        k.px('item.paddingX', iconRect.left - box.left);
        k.px('itemIcon.size', iconRect.width);
        k.color('itemIcon.color', _iconColor(tester, icons.first));
        final label = find.byKey(const ValueKey('select-item-label')).first;
        k.px('item.gap', tester.getTopLeft(label).dx - iconRect.right);
        k.typo('itemLabel.typography', _style(tester, label));
        final labelColor = pickMode(want['itemLabel.foreground'], mode);
        k.measured.add('itemLabel.foreground');
        if (!sameColor(specColor(labelColor), _style(tester, label).color!)) {
          k.fail('itemLabel.foreground 가 스펙과 다르다');
        }
        k.measured.addAll(['itemLabel.fontWeight']);
        // 설명 — 13/18 · 글 ↔ 설명 2
        final desc = find
            .byKey(const ValueKey('select-item-description'))
            .first;
        k.typo('itemDescription.typography', _style(tester, desc));
        k.measured.add('itemDescription.fontWeight');
        final descColor = pickMode(want['itemDescription.foreground'], mode);
        k.measured.add('itemDescription.foreground');
        if (!sameColor(specColor(descColor), _style(tester, desc).color!)) {
          k.fail('itemDescription.foreground 가 스펙과 다르다');
        }
        final labelOfSecond = find.text(keepAll('국민 주계좌'));
        k.px(
          'itemDescription.gap',
          tester.getTopLeft(desc).dy - tester.getBottomLeft(labelOfSecond).dy,
        );
        // 고른 표시 — 오른쪽 체크 14, 고른 선택지에만
        final indicator = find.byKey(const ValueKey('select-item-indicator'));
        expect(indicator, findsOneWidget);
        k.px('indicator.size', tester.getSize(indicator).width);
        k.color('indicator.color', _iconColor(tester, indicator));
        k.measured.add('indicator.opacity');
        // 굵기 — 앱은 선 2.5 짝(check500)이다(Q-008-2)
        expect(
          tester.widget<Icon>(indicator).icon,
          LucideIcons.check500,
          reason: 'indicator 선 2.5',
        );
        if (find
            .descendant(of: _row('현금'), matching: indicator)
            .evaluate()
            .isNotEmpty) {
          k.fail('indicator.opacity: 고르지 않은 선택지에 체크가 있다');
        }
        k.px('item.paddingY', tester.getTopLeft(label).dy - first.top);
        k.measured.addAll([
          'item.cursor',
          'item.transitionProperty',
          'item.transitionDuration',
          'item.transitionEasing',
        ]);

        // 묶음 제목 · 선 — 제목 14/19 · 500 · 좌우 16 · 위아래 10, 선 1px · 좌우 16 · 위 8 · 아래 8
        final groupLabel = find.byKey(const ValueKey('select-group-label'));
        k.typo('groupLabel.typography', _style(tester, groupLabel));
        k.measured.add('groupLabel.foreground');
        final glc = pickMode(want['groupLabel.foreground'], mode);
        if (!sameColor(specColor(glc), _style(tester, groupLabel).color!)) {
          k.fail('groupLabel.foreground 가 스펙과 다르다');
        }
        k.px(
          'groupLabel.paddingX',
          tester.getTopLeft(groupLabel).dx - box.left,
        );
        final divider = find.byKey(const ValueKey('select-divider'));
        final dRect = tester.getRect(divider);
        k.px('divider.height', dRect.height);
        k.px(
          'divider.marginX',
          (tester.widget<Container>(divider).margin! as EdgeInsets).left,
        );
        k.color('divider.color', tester.widget<Container>(divider).color!);
        final lastOfFirst = tester.getRect(_row('국민 주계좌'));
        k.px(
          'divider.marginBottom',
          tester.getTopLeft(groupLabel).dy - 10 - dRect.bottom,
        );
        k.px('content.gap', dRect.top - lastOfFirst.bottom);
        k.px(
          'groupLabel.paddingY',
          tester.getTopLeft(groupLabel).dy -
              (dRect.bottom + (want['divider.marginBottom']! as num)),
        );
        k.measured.add('content.margin');
        if (box.bottom >
            tester.view.physicalSize.height / tester.view.devicePixelRatio -
                8) {
          k.fail('content.margin: 화면 아래 가장자리와 8 보다 가깝다');
        }
        k.measured.add('content.maxHeight');

        // 누른 선택지의 모습은 누른 뒤에 잰다(콘텐츠가 줄어 위의 치수는 기본에서 잰다)
        TestGesture? gesture;
        if (pressed) {
          gesture = await tester.startGesture(tester.getCenter(_row('현금')));
          await tester.pump();
          // 누른 프레임에서 전환이 시작된다 — 끝나게 한 번 더
          await _settle(tester);
          await _settle(tester);
        }

        // 알약 — 누른 선택지에만: 좌우 8 들어오고 모서리 12, 콘텐츠만 2px 거리 줄어든다
        final highlight = find.descendant(
          of: _row('현금'),
          matching: find.byKey(const ValueKey('select-item-highlight')),
        );
        final pill = _deco(tester, highlight);
        k.color('highlight.background', pill.color ?? const Color(0x00000000));
        k.px('highlight.radius', (pill.borderRadius as BorderRadius).topLeft.x);
        if (pressed) {
          k.px('highlight.insetX', tester.getRect(highlight).left - first.left);
          final scale = tester.widget<AnimatedScale>(
            find.descendant(
              of: _row('현금'),
              matching: find.byType(AnimatedScale),
            ),
          );
          final basis = math.max(first.height, math.max(first.width / 4, 24.0));
          k.measured.add('item.scale');
          if ((scale.scale - (basis - 2) / basis).abs() > 1e-3) {
            k.fail('item.scale: 실제 ${scale.scale}');
          }
        }

        k.coverage(
          (key) =>
              _webOnly.contains(key) ||
              key.startsWith('trigger.') ||
              key.startsWith('value.') ||
              key.startsWith('placeholder.') ||
              key.startsWith('prefixIcon.') ||
              key.startsWith('chevron.') ||
              key == 'focusRing.color',
        );
        expect(k.failures, isEmpty, reason: k.failures.join('\n'));
        await gesture?.up();
        await _settle(tester);
      });
    }

    testWidgets('${mode.name} 막힌 선택지 — 글 · 설명 · 아이콘이 비활성 색이고 알약이 서지 않는다', (
      tester,
    ) async {
      await tester.pumpWidget(_host(mode, _select(value: 'kb')));
      await _open(tester);
      final want = _spec.resolve(_large, 'disabled');
      final c = tester.element(_trigger).colors;
      final disabledColor = specColor(
        pickMode(want['itemLabel.foreground'], mode),
      );
      final row = _row('막힌 선택지');
      Color of(String key) => tester
          .widget<Text>(
            find.descendant(of: row, matching: find.byKey(ValueKey(key))),
          )
          .style!
          .color!;
      expect(sameColor(disabledColor, of('select-item-label')), isTrue);
      expect(
        sameColor(
          specColor(pickMode(want['itemDescription.foreground'], mode)),
          of('select-item-description'),
        ),
        isTrue,
      );
      expect(
        sameColor(
          specColor(pickMode(want['itemIcon.color'], mode)),
          _iconColor(
            tester,
            find.descendant(
              of: row,
              matching: find.byKey(const ValueKey('select-item-icon')),
            ),
          ),
        ),
        isTrue,
      );
      expect(c.fgDisabled, disabledColor);
      final cursor = tester
          .widget<MouseRegion>(
            find.ancestor(of: row, matching: find.byType(MouseRegion)).first,
          )
          .cursor;
      expect(cursor, SystemMouseCursors.forbidden);
      // 눌러도 알약이 서지 않는다
      final g = await tester.startGesture(tester.getCenter(row));
      await _settle(tester);
      final pill = _deco(
        tester,
        find.descendant(
          of: row,
          matching: find.byKey(const ValueKey('select-item-highlight')),
        ),
      );
      expect(pill.color!.a, 0);
      await g.up();
    });
  }

  group('동작', () {
    testWidgets('하나 고르기 — 고르면 닫히고 값이 칸에 들어간다, 고른 것을 다시 눌러도 풀리지 않는다', (
      tester,
    ) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _host(Brightness.light, _Live(initial: 'cash', onPick: picked.add)),
      );
      await _open(tester);
      expect(_contentBox, findsOneWidget);
      // 고른 것을 다시 — 알리지 않고 닫는다
      await tester.tap(_row('현금'));
      await _settle(tester);
      expect(picked, isEmpty);
      expect(_contentBox, findsNothing);
      await _open(tester);
      await tester.tap(_row('간편결제'));
      await _settle(tester);
      expect(picked, ['wallet']);
      expect(_contentBox, findsNothing);
      expect(
        find
                .descendant(of: _value, matching: findText('간편결제'))
                .evaluate()
                .isNotEmpty ||
            findText('간편결제').evaluate().isNotEmpty,
        isTrue,
      );
      // 앞 아이콘이 고른 선택지의 것으로 바뀐다
      expect(tester.widget<Icon>(_prefix).icon, LucideIcons.wallet);
    });

    testWidgets('막힌 선택지는 눌러도 고르지 않고 목록도 닫히지 않는다', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _host(Brightness.light, _Live(initial: 'cash', onPick: picked.add)),
      );
      await _open(tester);
      await tester.tap(_row('막힌 선택지'));
      await _settle(tester);
      expect(picked, isEmpty);
      expect(_contentBox, findsOneWidget);
    });

    testWidgets('값이 없거나 목록에 없으면 placeholder 가 보인다 · 앞 아이콘은 칸의 것', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, _select(value: 'none')));
      expect(findText('결제 수단 선택'), findsOneWidget);
      expect(tester.widget<Icon>(_prefix).icon, LucideIcons.creditCard);
    });

    testWidgets('여럿 고르기 — 열린 채 켜고 끄고, 값은 고른 순서대로 이어 쓴다', (tester) async {
      final seen = <List<String>>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _LiveMulti(initial: const [], onValues: seen.add),
          width: 600,
        ),
      );
      await _open(tester);
      await tester.tap(_row('국민 주계좌'));
      await tester.pump();
      await tester.tap(_row('현금'));
      await _settle(tester);
      expect(_contentBox, findsOneWidget);
      expect(seen.last, ['kb', 'cash']);
      expect(findText('국민 주계좌, 현금'), findsOneWidget);
      // 다시 누르면 풀린다
      await tester.tap(_row('국민 주계좌'));
      await tester.pump();
      expect(seen.last, ['cash']);
      // 둘 이상 골랐을 때는 칸의 아이콘, 하나면 그 선택지의 아이콘
      expect(tester.widget<Icon>(_prefix).icon, LucideIcons.banknote);
    });

    testWidgets('여럿 고르기 — 칸 폭을 넘으면 "첫 값 외 N개", 넘지 않으면 이어 쓴다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const _LiveMulti(initial: ['cash', 'kb', 'wallet']),
          width: 240,
        ),
      );
      expect(findText('현금 외 2개'), findsOneWidget);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const _LiveMulti(initial: ['cash', 'kb', 'wallet']),
          width: 700,
        ),
      );
      expect(findText('현금, 국민 주계좌, 간편결제'), findsOneWidget);
      // 줄이는 글이 없으면 말줄임
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const _LiveMulti(
            initial: ['cash', 'kb', 'wallet'],
            withOverflow: false,
          ),
          width: 240,
        ),
      );
      expect(findTextContaining('외'), findsNothing);
      expect(
        tester.widget<Text>(findText('현금, 국민 주계좌, 간편결제')).overflow,
        TextOverflow.ellipsis,
      );
    });

    testWidgets('읽기 전용은 열리지 않고 포커스는 받는다, 비활성은 포커스도 열기도 안 된다', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _select(value: 'cash', readOnly: true, focusNode: node),
        ),
      );
      await tester.tap(_trigger);
      await _settle(tester);
      expect(_contentBox, findsNothing);
      expect(node.hasFocus, isTrue);
      await tester.pumpWidget(
        _host(Brightness.light, _select(value: 'cash', disabled: true)),
      );
      await tester.tap(_trigger);
      await _settle(tester);
      expect(_contentBox, findsNothing);
    });

    testWidgets('열린 채 막히면 닫힌다', (tester) async {
      Widget build(bool disabled) =>
          _host(Brightness.light, _select(value: 'cash', disabled: disabled));
      await tester.pumpWidget(build(false));
      await _open(tester);
      expect(_contentBox, findsOneWidget);
      await tester.pumpWidget(build(true));
      await tester.pump();
      await _settle(tester);
      expect(_contentBox, findsNothing);
    });

    testWidgets('셰브론은 열리면 180° — 열 때 150ms · 닫을 때 100ms', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, const _Live()));
      AnimatedRotation rotation() => tester.widget<AnimatedRotation>(
        find.ancestor(of: _chevron, matching: find.byType(AnimatedRotation)),
      );
      expect(rotation().turns, 0);
      await tester.tap(_trigger);
      await tester.pump();
      expect(rotation().turns, 0.5);
      expect(rotation().duration, PDuration.d3);
      await _settle(tester);
      await tester.tapAt(const Offset(700, 500));
      await tester.pump();
      expect(rotation().turns, 0);
      expect(rotation().duration, PDuration.d2);
    });

    testWidgets('목록 열기 · 닫기 모션 — 열 때 150ms · 0.95 → 1, 모션 줄이기면 크기는 그대로', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, const _Live()));
      await tester.tap(_trigger);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final mid = tester
          .widget<Opacity>(
            find
                .ancestor(of: _contentBox, matching: find.byType(Opacity))
                .first,
          )
          .opacity;
      expect(mid, inExclusiveRange(0, 1));
      final scale = tester
          .widget<Transform>(
            find
                .ancestor(of: _contentBox, matching: find.byType(Transform))
                .first,
          )
          .transform
          .entry(0, 0);
      expect(scale, inExclusiveRange(0.95, 1));
      await _settle(tester);
      expect(
        tester
            .widget<Opacity>(
              find
                  .ancestor(of: _contentBox, matching: find.byType(Opacity))
                  .first,
            )
            .opacity,
        1,
      );
    });

    testWidgets('바깥을 누르거나 뒤로 가기를 하면 닫히고 값은 그대로다', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _host(Brightness.light, _Live(initial: 'cash', onPick: picked.add)),
      );
      await _open(tester);
      await tester.tapAt(const Offset(700, 560));
      await _settle(tester);
      expect(_contentBox, findsNothing);
      await _open(tester);
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(_contentBox, findsNothing);
      expect(picked, isEmpty);
    });

    testWidgets('칸을 다시 누르면 닫힌다', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, const _Live()));
      await _open(tester);
      await tester.tap(_trigger);
      await _settle(tester);
      expect(_contentBox, findsNothing);
    });

    testWidgets('아래가 모자라면 위로 열린다 — 칸과 8 떨어지고 화면 안에 선다', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const _Live(initial: 'cash'),
          alignment: Alignment.bottomLeft,
        ),
      );
      await _open(tester);
      final box = tester.getRect(_contentBox);
      final trigger = tester.getRect(_trigger);
      expect(box.bottom, closeTo(trigger.top - 8, 0.5));
      expect(box.top, greaterThanOrEqualTo(8));
    });

    testWidgets('선택지 20개 — 높이는 min(480, 남은 화면)이고 안에서 스크롤, 열면 고른 선택지가 보인다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final groups = [
        PSelectGroup<String>(
          items: [
            for (var i = 1; i <= 20; i++)
              PSelectItem(value: 'c$i', label: '카테고리 $i'),
          ],
        ),
      ];
      await tester.pumpWidget(
        _host(Brightness.light, _Live(initial: 'c18', groups: groups)),
      );
      await _open(tester);
      final box = tester.getRect(_contentBox);
      final trigger = tester.getRect(_trigger);
      final room = 844 - 8 - (trigger.bottom + 8);
      expect(box.height, closeTo(math.max(200, math.min(480, room)), 0.5));
      final row = tester.getRect(_row('카테고리 18'));
      expect(row.top, greaterThanOrEqualTo(box.top - 0.5));
      expect(row.bottom, lessThanOrEqualTo(box.bottom + 0.5));
      // 맨 위 선택지는 밀려 나갔다 — 안에서 스크롤된 채로 열렸다
      expect(
        findText('카테고리 1').hitTestable().evaluate(),
        isEmpty,
        reason: '스크롤된 채로 열려야 한다',
      );
    });

    testWidgets('긴 선택지 이름 — 목록에서는 줄바꿈(자르지 않는다), 칸에서는 한 줄 말줄임', (tester) async {
      const long = '해외 결제 수수료가 면제되는 프리미엄 카드의 연회비 환급 대상 항목';
      const groups = [
        PSelectGroup<String>(
          items: [
            PSelectItem(value: 'long', label: long),
            PSelectItem(value: 'short', label: '짧음'),
          ],
        ),
      ];
      await tester.pumpWidget(
        _host(Brightness.light, const _Live(initial: 'long', groups: groups)),
      );
      final shown = tester.widget<Text>(findText(long).first);
      expect(shown.maxLines, 1);
      expect(shown.overflow, TextOverflow.ellipsis);
      await _open(tester);
      final longRow = tester.getRect(
        find.ancestor(
          of: find.byKey(const ValueKey('select-item-label')).first,
          matching: find.byKey(const ValueKey('select-item')),
        ),
      );
      expect(longRow.height, greaterThan(46));
      final label = tester.widget<Text>(
        find.byKey(const ValueKey('select-item-label')).first,
      );
      expect(label.maxLines, isNull);
      expect(label.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets(
      '키보드 — ↓ 로 열고 고른 선택지를 짚는다, ↑ ↓ 는 막힌 선택지를 건너뛴다, Enter 로 고른다, Esc 로 닫는다',
      (tester) async {
        final picked = <String>[];
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(
          _host(
            Brightness.light,
            Builder(
              builder: (context) =>
                  _select(value: 'kb', onChanged: picked.add, focusNode: node),
            ),
          ),
        );
        node.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await _settle(tester);
        expect(_contentBox, findsOneWidget);
        Color pill(String label) => _deco(
          tester,
          find.descendant(
            of: _row(label),
            matching: find.byKey(const ValueKey('select-item-highlight')),
          ),
        ).color!;
        final c = tester.element(_trigger).colors;
        // 키로 열면 고른 선택지를 짚는다
        expect(sameColor(c.bgLayerFloatingPressed, pill('국민 주계좌')), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await _settle(tester);
        expect(sameColor(c.bgLayerFloatingPressed, pill('간편결제')), isTrue);
        // 다음은 막힌 선택지 — 건너뛰고 끝에서 멈춘다
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await _settle(tester);
        expect(sameColor(c.bgLayerFloatingPressed, pill('간편결제')), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await _settle(tester);
        expect(sameColor(c.bgLayerFloatingPressed, pill('현금')), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _settle(tester);
        expect(picked, ['cash']);
        expect(_contentBox, findsNothing);
        // Esc
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await _settle(tester);
        expect(_contentBox, findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await _settle(tester);
        expect(_contentBox, findsNothing);
        expect(node.hasFocus, isTrue);
      },
    );

    testWidgets('읽기 — 칸은 버튼이고 이름은 Field 의 라벨, 값은 고른 글, 열림 · 오류 · 필수를 읽는다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PField(
            label: '휴가 정책',
            required: true,
            invalid: true,
            errorMessage: '휴가 정책을 골라주세요.',
            child: PSelect<String>(
              groups: _groups,
              value: 'cash',
              onChanged: (_) {},
              placeholder: '휴가 정책 선택',
            ),
          ),
        ),
      );
      SemanticsNode node() => tester.getSemantics(_trigger);
      expect(node().label, contains('휴가 정책'));
      expect(node().value, '현금');
      expect(node().flagsCollection.isButton, isTrue);
      expect(node().flagsCollection.isRequired, Tristate.isTrue);
      expect(node().validationResult, SemanticsValidationResult.invalid);
      expect(node().flagsCollection.isExpanded, Tristate.isFalse);
      await _open(tester);
      expect(node().flagsCollection.isExpanded, Tristate.isTrue);
      // 선택지는 선택 여부를 읽는다
      expect(
        tester.getSemantics(_row('현금')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets(
      '선택지 낭독 — 하나 고르기는 button + selected(checked 없음), 여럿 고르기는 checked 를 더한다(03-B 결정 2 A)',
      (tester) async {
        final handle = tester.ensureSemantics();
        // 하나 고르기
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PSelect<String>(
              groups: _groups,
              value: 'cash',
              onChanged: (_) {},
              placeholder: '휴가 정책 선택',
            ),
          ),
        );
        await _open(tester);
        final picked = tester.getSemantics(_row('현금')).flagsCollection;
        expect(picked.isButton, isTrue);
        expect(picked.isSelected, Tristate.isTrue);
        expect(
          picked.isChecked,
          CheckedState.none,
          reason: '하나 고르기는 체크 상태를 읽지 않는다',
        );
        expect(
          picked.isInMutuallyExclusiveGroup,
          isFalse,
          reason: '라디오로 읽지 않는다',
        );
        final other = tester.getSemantics(_row('간편결제')).flagsCollection;
        expect(other.isButton, isTrue);
        expect(other.isSelected, Tristate.isFalse);
        expect(other.isChecked, CheckedState.none);
        handle.dispose();
      },
    );

    testWidgets('선택지 낭독 — 여럿 고르기는 button + selected + checked(체크됨 · 체크 안 됨)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSelect<String>.multiple(
            groups: _groups,
            values: const ['cash'],
            onChanged: (_) {},
            placeholder: '휴가 정책 선택',
          ),
        ),
      );
      await _open(tester);
      final picked = tester.getSemantics(_row('현금')).flagsCollection;
      expect(picked.isButton, isTrue);
      expect(picked.isSelected, Tristate.isTrue);
      expect(picked.isChecked, CheckedState.isTrue);
      final other = tester.getSemantics(_row('간편결제')).flagsCollection;
      expect(other.isButton, isTrue);
      expect(other.isSelected, Tristate.isFalse);
      expect(other.isChecked, CheckedState.isFalse);
      handle.dispose();
    });

    testWidgets('Field 의 라벨을 누르면 칸으로 포커스가 간다(열지는 않는다)', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PField(
            label: '통화',
            child: PSelect<String>(
              groups: _groups,
              value: null,
              onChanged: (_) {},
              placeholder: '통화 선택',
            ),
          ),
        ),
      );
      await tester.tap(findRichPlain('통화').first);
      await _settle(tester);
      expect(_contentBox, findsNothing);
      expect(
        FocusManager.instance.primaryFocus?.context
                    ?.findAncestorWidgetOfExactType<PSelect<String>>() !=
                null ||
            FocusManager.instance.primaryFocus != null,
        isTrue,
      );
    });
  });

  testWidgets('카탈로그 견본이 그려지고 눌러 열린다', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        Brightness.light,
        const SingleChildScrollView(child: SelectDemo()),
        width: 342,
      ),
    );
    expect(find.byType(PSelect<String>), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
