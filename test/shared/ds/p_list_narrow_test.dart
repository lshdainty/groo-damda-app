// List 의 좁은 줄(03-D 결정 1 B, list.yaml content.stackBelow · width narrow) — 줄 안 폭이 제목 글자 16개(16em)보다
// 좁으면 값(글 값 · 금액)이 본문 아래로, 조작 요소는 줄 끝 그대로. 문턱은 글자 배율을 따라 커진다(16 × t5 × 배율).
// 금액 줄바꿈(결정 2 B)도 여기서 본다 — 쉼표 뒤에서만 줄이 바뀌고 읽는 이름은 원래 글이다.
//
// 폰은 띠 화면이라 줄은 카드 안(294)이 아니라 띠 안(360 − 48 = 312)으로 그린다.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_parent_item.dart';
import 'package:groo_damda_app/shared/ds/switch/p_switch.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';

// 포매터가 \\u 이스케이프를 보이지 않는 글자로 풀어 버려 코드 값으로 만든다
final _zwsp = String.fromCharCode(0x200B);
final _wj = String.fromCharCode(0x2060);
final _spec = DesignSpec.load('list');
final _wide = _spec.resolve({'width': 'regular'}, 'enabled');
final _narrow = _spec.resolve({'width': 'narrow'}, 'enabled');

Widget _host(Widget child, {double width = 360, Brightness? mode}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );

void _noop() {}

Finder _key(String name) => find.byKey(ValueKey(name));
Finder get _below => _key('plist-value-below');

Widget _tile() => const PListTile(
  background: Color(0xFFFFE3D1),
  color: Color(0xFFB4501A),
  child: Icon(LucideIcons.utensils),
);

PList _list(List<Widget> children) =>
    PList(semanticLabel: '거래', children: children);

/// 값이 글인 줄 — 앞 타일 · 제목 · 설명 · 글 값 + 화살표.
Widget _textRow({bool arrow = true}) => _list([
  PListButtonItem(
    prefix: _tile(),
    title: '점심 식사',
    detail: '지출 · 식비',
    suffix: PListSuffix(
      children: [
        const Text('대한민국 원', key: ValueKey('value')),
        if (arrow) const Icon(LucideIcons.chevronRight, key: ValueKey('arrow')),
      ],
    ),
    onTap: _noop,
  ),
]);

Future<void> _scale(WidgetTester tester, double s) async {
  tester.platformDispatcher.textScaleFactorTestValue = s;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

void main() {
  group('문턱 = 줄 안 폭 < 16 × t5 × 글자 배율', () {
    test('스펙 값 — 16em', () {
      expect(_wide.containsKey('content.stackBelow'), isTrue);
      expect(_wide['content.stackBelow'], '16em');
      expect(kPListStackBelowEm, 16);
    });

    // 폭 360 · 줄 안 312: 배율 1.0 → 256, 1.2 → 307.2 (한 줄) / 1.3 → 332.8, 2.0 → 512 (아래로)
    for (final (scale, stacked) in [
      (1.0, false),
      (1.2, false),
      (1.3, true),
      (2.0, true),
    ]) {
      testWidgets('폭 360 · 글자 ${(scale * 100).round()}% — 값이 '
          '${stacked ? '본문 아래' : '옆'}', (tester) async {
        await _scale(tester, scale);
        await tester.pumpWidget(_host(_textRow()));
        expect(_below, stacked ? findsOneWidget : findsNothing);
        final value = tester.getRect(_key('value'));
        final title = tester.getRect(_key('plist-title'));
        if (stacked) {
          expect(value.top, greaterThan(title.bottom));
        } else {
          expect(value.left, greaterThan(title.right));
        }
        expect(tester.takeException(), isNull);
      });
    }

    // 정확한 경계 — 보통 글자에서 줄 안 폭 256 (폭 304) 이 문턱
    for (final (width, stacked) in [(303.0, true), (304.0, false)]) {
      testWidgets(
        '줄 폭 $width (줄 안 ${width - 48}) 글자 100% — ${stacked ? '아래' : '옆'}',
        (tester) async {
          await tester.pumpWidget(_host(_textRow(), width: width));
          expect(_below, stacked ? findsOneWidget : findsNothing);
        },
      );
    }

    // 단계마다 좌우 여백이 달라 줄 안 폭의 문턱도 다르다 — 부모 줄 4 · 24, 하위 줄 104 · 24
    Widget parentList() => _list([
      PListParentItem(
        prefix: _tile(),
        title: '식비',
        detail: '지출 · 하위 1개',
        suffix: const Text('12,000원', key: ValueKey('parent-value')),
        expandLabel: '식비 하위 카테고리',
        defaultOpen: true,
        onTap: _noop,
        children: [
          PListButtonItem(
            title: '외식',
            suffix: const Text('8,000원', key: ValueKey('child-value')),
            onTap: _noop,
          ),
        ],
      ),
    ]);
    testWidgets('부모 줄(좌우 4 · 24) · 하위 줄(104 · 24)의 문턱은 줄마다 다르다', (
      tester,
    ) async {
      // 폭 283 → 부모 줄 안 255 < 256 아래 / 하위 줄 안 155 아래
      await tester.pumpWidget(_host(parentList(), width: 283));
      expect(
        tester.getTopLeft(_key('parent-value')).dy,
        greaterThan(tester.getBottomLeft(_key('plist-title').first).dy),
      );
      // 폭 284 → 부모 줄 안 256 은 옆
      await tester.pumpWidget(_host(parentList(), width: 284));
      final parentTitle = tester.getRect(_key('plist-title').first);
      expect(
        tester.getRect(_key('parent-value')).left,
        greaterThan(parentTitle.right),
      );
      // 하위 줄: 폭 383 → 안 255 아래, 384 → 안 256 옆
      await tester.pumpWidget(_host(parentList(), width: 383));
      var childTitle = tester.getRect(_key('plist-title').at(1));
      expect(
        tester.getRect(_key('child-value')).top,
        greaterThan(childTitle.bottom),
      );
      await tester.pumpWidget(_host(parentList(), width: 384));
      childTitle = tester.getRect(_key('plist-title').at(1));
      expect(
        tester.getRect(_key('child-value')).left,
        greaterThan(childTitle.right),
      );
    });
  });

  group('좁은 줄의 모양 — 폭 360 · 글자 130% · 띠 안 줄 312', () {
    testWidgets('값은 설명 아래 4 · 본문 왼쪽, 조작 요소는 줄 끝 그대로 · 앞 타일은 위', (tester) async {
      await _scale(tester, 1.3);
      await tester.pumpWidget(_host(_textRow()));
      final want = _narrow;
      final title = tester.getRect(_key('plist-title'));
      final detail = tester.getRect(_key('plist-detail'));
      final value = tester.getRect(_key('value'));
      final arrow = tester.getRect(_key('arrow'));
      final tile = tester.getRect(_key('plist-tile'));
      final item = tester.getRect(_key('plist-item'));
      // suffix.marginTop 2 + 본문 사이 2 = 설명 ↔ 값 4
      expect(want['suffix.marginTop'], 2);
      expect(value.top - detail.bottom, closeTo(4, 0.5));
      // suffix.placement · textAlign — 본문 칸 안 왼쪽
      expect(want['suffix.placement'], '본문 아래');
      expect(want['suffix.textAlign'], 'start');
      // 평소의 suffixText.textAlign end 를 이 자리에서 start 로 바꾼다(rule 3)
      expect(want['suffixText.textAlign'], 'start');
      expect(value.left, closeTo(title.left, 0.5));
      // item.alignItems flex-start — 앞 타일 · 조작 요소가 위에 맞는다 (줄 위 여백 12)
      expect(want['item.alignItems'], 'flex-start');
      expect(tile.top - item.top, closeTo(12, 0.5));
      expect(arrow.top - item.top, closeTo(12, 0.5));
      // 화살표는 줄 끝(오른쪽 여백 24) 그대로
      expect(arrow.right, closeTo(360 - 24, 0.5));
      // 본문은 앞 타일 뒤에서 시작해 화살표 앞까지
      expect(title.left, greaterThan(tile.right));
      expect(title.left, closeTo(24 + 40 + 12, 0.5));
    });

    testWidgets('옆에 뒤 붙이개가 없으면 본문이 줄 안 폭을 다 쓴다 — body.paddingRight 0', (
      tester,
    ) async {
      await _scale(tester, 1.3);
      await tester.pumpWidget(
        _host(
          _list([
            PListButtonItem(
              title: '점심 식사',
              detail: '지출 · 식비',
              suffix: const Text('대한민국 원', key: ValueKey('value')),
              onTap: _noop,
            ),
          ]),
        ),
      );
      expect(_narrow['body.paddingRight'], 0);
      final body = tester.getRect(_key('plist-body'));
      expect(body.right, closeTo(360 - 24, 0.5));
      // 보통 글자 · 넓은 줄에서는 본문 뒤 여백 10 이 그대로 있다
      expect(_wide['body.paddingRight'], 10);
    });

    testWidgets('값 없이 조작 요소만 있는 줄 — 스위치는 줄 끝 위에 선다', (tester) async {
      await _scale(tester, 1.3);
      await tester.pumpWidget(
        _host(
          _list([
            PListSwitchItem(
              title: '결제 알림',
              detail: '결제 예정일 하루 전에 알려요',
              checked: true,
              onChanged: (_) {},
            ),
          ]),
        ),
      );
      expect(_below, findsNothing);
      final item = tester.getRect(_key('plist-item'));
      final track = tester.getRect(find.byType(PSwitchmark));
      expect(track.right, closeTo(360 - 24, 0.5));
      expect(track.top - item.top, closeTo(12, 0.5));
    });

    testWidgets('부모 줄 — 꺾쇠 단추도 위에 맞춘다(폭 360 · 글자 200%), 넓은 줄은 가운데', (
      tester,
    ) async {
      Widget parent() => _list([
        PListParentItem(
          prefix: _tile(),
          title: '식비',
          detail: '지출 · 하위 1개',
          suffix: const Text('12,000원', key: ValueKey('v')),
          expandLabel: '식비 하위 카테고리',
          defaultOpen: false,
          onTap: _noop,
          children: [PListButtonItem(title: '외식', onTap: _noop)],
        ),
      ]);
      await _scale(tester, 2.0);
      await tester.pumpWidget(_host(parent()));
      expect(_below, findsOneWidget);
      var item = tester.getRect(_key('plist-item').first);
      var button = tester.getRect(_key('plist-expand-button'));
      // list.yaml item.alignItems flex-start — 위 10(= 줄 위 여백 12 − 단추가 겹치는 2)
      expect(button.top - item.top, closeTo(10, 0.5));
      // 보통 글자 — 한 줄이라 가운데
      await _scale(tester, 1.0);
      await tester.pumpWidget(_host(parent(), width: 361));
      item = tester.getRect(_key('plist-item').first);
      button = tester.getRect(_key('plist-expand-button'));
      expect(button.center.dy, closeTo(item.center.dy, 0.5));
    });

    testWidgets('보통 글자 · 넓은 줄은 지금과 같다 — 값은 옆, 가운데 맞춤', (tester) async {
      await tester.pumpWidget(_host(_textRow()));
      expect(_below, findsNothing);
      final item = tester.getRect(_key('plist-item'));
      final tile = tester.getRect(_key('plist-tile'));
      // 앞 타일이 줄 세로 가운데
      expect(tile.center.dy, closeTo(item.center.dy, 0.5));
    });

    testWidgets('가장 나쁜 값 — 글자 200% · 폭 360 · 긴 제목 · 긴 이메일 값 · 넘치지 않는다', (
      tester,
    ) async {
      await _scale(tester, 2.0);
      await tester.pumpWidget(
        _host(
          _list([
            PListButtonItem(
              prefix: _tile(),
              title: '숲길마트 본점 식품관 선물세트 정산',
              detail: '지출 · 식비 · 추석 명절',
              suffix: const Text(
                'very-long-address-for-the-worst-case@example.kr',
                key: ValueKey('value'),
              ),
              onTap: _noop,
            ),
          ]),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_below, findsOneWidget);
      final value = tester.getRect(_key('value'));
      final body = tester.getRect(_key('plist-body'));
      expect(value.left, greaterThanOrEqualTo(body.left - 0.5));
      expect(value.right, lessThanOrEqualTo(body.right + 0.5));
    });
  });

  group('금액 — 쉼표 뒤에서만 줄이 바뀐다 (03-D 결정 2 B)', () {
    const amount = '−1,234,567,890원';

    test('보이는 글에만 U+200B 가 들어가고, 지우면 원래 글이다', () {
      final shown = keepAllAmount(amount);
      expect(shown.contains(',$_zwsp'), isTrue);
      expect(shown.contains(',$_wj'), isFalse);
      expect(shown.replaceAll(_zwsp, '').replaceAll(_wj, ''), amount);
      // 숫자 사이는 이어 붙는다
      expect(shown.contains('2${_wj}3'), isTrue);
      expect(keepAllAmount('9,999원'), '9$_wj,${_zwsp}9${_wj}9${_wj}9${_wj}원');
    });

    List<String> lines(WidgetTester tester, Finder text) {
      final para = tester.renderObject<RenderParagraph>(
        find.descendant(of: text, matching: find.byType(RichText)).first,
      );
      final plain = para.text.toPlainText();
      // 글자마다 놓인 줄(위쪽 y)로 묶는다
      final byTop = <int, StringBuffer>{};
      for (var i = 0; i < plain.length; i++) {
        final boxes = para.getBoxesForSelection(
          TextSelection(baseOffset: i, extentOffset: i + 1),
        );
        if (boxes.isEmpty) {
          // 너비 0 인 글자(U+200B · U+2060)는 앞 글자의 줄에 붙는다
          if (byTop.isNotEmpty) byTop.values.last.write(plain[i]);
          continue;
        }
        byTop
            .putIfAbsent(boxes.first.top.round(), StringBuffer.new)
            .write(plain[i]);
      }
      return [for (final e in byTop.entries) e.value.toString()];
    }

    String clean(String s) => s.replaceAll(RegExp('[$_zwsp$_wj]'), '');

    Widget amountRow(String shown) => _list([
      PListItem(
        title: '이번 달 지출',
        suffix: PListValue(
          child: Text(
            shown,
            semanticsLabel: amount,
            key: const ValueKey('amount'),
            style: PTypography.t5.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ]);

    testWidgets('좁은 줄에서 쉼표 뒤에서만 끊긴다 — 숫자 한가운데는 끊지 않는다', (tester) async {
      await _scale(tester, 1.3);
      // 줄 안 폭 150: 금액이 한 줄에 안 든다
      await tester.pumpWidget(
        _host(amountRow(keepAllAmount(amount)), width: 198),
      );
      expect(_below, findsOneWidget);
      final got = lines(tester, _below).map(clean).toList();
      expect(got.length, greaterThan(1), reason: '줄이 바뀌어야 비교가 된다 $got');
      for (final line in got.take(got.length - 1)) {
        expect(
          line.endsWith(','),
          isTrue,
          reason: '줄 끝은 쉼표 — ${got.join("|")}',
        );
      }
      expect(got.join(), amount);
    });

    testWidgets('쉼표 뒤 이음 처리가 없으면(keepAll 만) 숫자 한가운데서 끊긴다 — 이 검사가 잡는다', (
      tester,
    ) async {
      await _scale(tester, 1.3);
      await tester.pumpWidget(_host(amountRow(keepAll(amount)), width: 198));
      final got = lines(tester, _below).map(clean).toList();
      expect(got.length, greaterThan(1));
      expect(
        got.take(got.length - 1).every((l) => l.endsWith(',')),
        isFalse,
        reason: 'keepAll 만으로는 쉼표 자리가 아닌 곳에서 끊긴다 $got',
      );
    });

    for (final (name, build) in <(String, Widget Function())>[
      ('지표 숫자', () => const PCardStat(label: '이번 달 지출', value: amount)),
      ('순자산 금액', () => const PCardHeroAmount(amount)),
    ]) {
      testWidgets('$name 도 쉼표 뒤에서만 끊기고 읽는 이름은 원래 글이다', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_host(build(), width: 170));
        final text = find.descendant(
          of: find.byType(Scaffold),
          matching: find.byWidgetPredicate(
            (w) => w is Text && w.semanticsLabel == amount,
          ),
        );
        expect(text, findsOneWidget);
        final got = lines(tester, text).map(clean).toList();
        expect(got.length, greaterThan(1), reason: '$got');
        for (final line in got.take(got.length - 1)) {
          expect(
            line.endsWith(','),
            isTrue,
            reason: '줄 끝은 쉼표 — ${got.join("|")}',
          );
        }
        expect(got.join(), amount);
        handle.dispose();
      });
    }

    testWidgets('PListValue.amount — 부품이 쉼표 끊기와 읽는 이름을 챙긴다', (tester) async {
      final handle = tester.ensureSemantics();
      await _scale(tester, 1.3);
      await tester.pumpWidget(
        _host(
          _list([
            PListItem(
              title: '이번 달 지출',
              suffix: PListValue.amount(
                amount,
                key: const ValueKey('amount'),
                style: PTypography.t5.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          width: 198,
        ),
      );
      final got = lines(tester, _below).map(clean).toList();
      expect(got.length, greaterThan(1), reason: '$got');
      for (final line in got.take(got.length - 1)) {
        expect(
          line.endsWith(','),
          isTrue,
          reason: '줄 끝은 쉼표 — ${got.join("|")}',
        );
      }
      expect(got.join(), amount);
      final text = tester.widget<Text>(
        find.descendant(of: _below, matching: find.byType(Text)),
      );
      expect(text.semanticsLabel, amount);
      expect(text.data!.contains(_zwsp), isTrue);
      // 줄 하나 = 한 노드 — 이름은 원래 금액
      expect(
        find.bySemanticsLabel(RegExp('^이번 달 지출\n−1,234,567,890원\$')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('읽는 이름은 원래 글이다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(amountRow(keepAllAmount(amount))));
      final text = tester.widget<Text>(_key('amount'));
      expect(text.semanticsLabel, amount);
      expect(text.data!.contains(_zwsp), isTrue);
      handle.dispose();
    });
  });

  testWidgets('스펙의 좁은 줄 값 일곱 줄을 모두 잰다', (tester) async {
    // 위 묶음이 잰 키 — 스펙에 새 줄이 생기면 여기서 빨개져 잴 곳을 더하게 한다
    const measured = {
      'item.alignItems',
      'body.paddingRight',
      'suffix.placement',
      'suffix.marginTop',
      'suffix.textAlign',
      'suffix.lineBreak',
      'suffixText.textAlign',
    };
    final changed = {
      for (final e in _narrow.entries)
        if ('${_wide[e.key]}' != '${e.value}') e.key,
    };
    expect(changed, measured);
  });
}
