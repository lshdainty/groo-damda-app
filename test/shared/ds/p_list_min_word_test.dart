// List 줄 값이 길 때 — 제목은 제목의 가장 긴 낱말 폭 아래로 줄지 않고 값이 남은 폭에서 줄을 바꾼다
// (list.md Q-001 B, 사용자 결정 2026-10-30). 띄어쓰기 없는 긴 제목은 본문 자리 폭의 절반에서 글자 사이로 끊는다.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import '../../support/plain_text.dart';

const _place = '서울특별시 강남구 테헤란로 427 위워크타워 12층 대회의실 B';
const _noSpace = '서울특별시강남구테헤란로427위워크타워12층대회의실B동편엘리베이터앞';

Widget _host(Widget child, {double width = 360, double scale = 1}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );

Finder _key(String k) => find.byKey(ValueKey(k));

Widget _arrowValue(String v) =>
    PListSuffix(children: [Text(v), const Icon(LucideIcons.chevronRight)]);

void main() {
  test('앞 자리 상수 셋 — 앞 붙이개 없음 0 · 있음 54 · 꺾쇠 자리는 더한다', () {
    expect(listLead(hasPrefix: false, hasExpandSlot: false), 0);
    expect(listLead(hasPrefix: true, hasExpandSlot: false), 54);
    expect(listLead(hasPrefix: false, hasExpandSlot: true), kPListExpandSlot);
    expect(
      listLead(hasPrefix: true, hasExpandSlot: true),
      54 + kPListExpandSlot,
    );
  });

  test(
    '줄마다 측정 콜백을 늘리지 않는다 — list_row.dart 의 post-frame 콜백은 멈춰 그리기(미리보기) 한 곳뿐',
    () {
      final src = File('lib/shared/ds/list/list_row.dart').readAsStringSync();
      expect('addPostFrameCallback'.allMatches(src).length, 1);
      expect(src.contains('GlobalKey'), isFalse);
    },
  );

  group('listTitleMinWidth', () {
    double w(String t, {double cap = 10000, double scale = 1}) =>
        listTitleMinWidth(
          title: t,
          style: PTypography.t5,
          scaler: TextScaler.linear(scale),
          direction: TextDirection.ltr,
          cap: cap,
        );

    test('가장 긴 낱말 폭 — 낱말이 여럿이면 제일 긴 것', () {
      expect(w('장소'), greaterThan(w('장')));
      expect(w('장소 알림 설정'), closeTo(w('알림'), 0.0001));
      expect(w('a bb ccc'), closeTo(w('ccc'), 0.0001));
    });

    test('상한 — 공백 없는 긴 제목은 상한에서 멈춘다', () {
      expect(w(_noSpace, cap: 150), 150);
      expect(w('장소', cap: 150), w('장소'));
    });

    test('글자 배율을 곱한다', () {
      expect(w('장소', scale: 2), closeTo(w('장소') * 2, 1.0));
    });
  });

  for (final scale in const [1.0, 2.0]) {
    testWidgets(
      '두 글자 제목 + 긴 값(PListSuffix 값+화살표) — 제목이 한 줄, 값이 줄 밖으로 안 넘친다 · 글자 $scale배',
      (tester) async {
        for (final value in const [_place, _noSpace]) {
          await tester.pumpWidget(
            _host(
              PList(
                semanticLabel: '폼',
                children: [
                  PListButtonItem(
                    title: '장소',
                    suffix: _arrowValue(value),
                    onTap: () {},
                  ),
                ],
              ),
              scale: scale,
            ),
          );
          expect(tester.takeException(), isNull, reason: '$value');
          final title = tester.getRect(_key('plist-title'));
          final row = tester.getRect(_key('plist-row'));
          // 제목이 한 줄 — 높이가 글자 한 줄(t5 줄 높이 × 배율) 근처
          expect(
            title.height,
            lessThan(PTypography.t5.height! * 16 * scale * 1.5 + 2),
            reason: '제목 한 줄 · 값 $value',
          );
          final valueRect = tester.getRect(findTextContaining('서울').first);
          expect(valueRect.right, lessThanOrEqualTo(row.right + 0.5));
          if (scale > 1) {
            // 200% — 줄 안 폭이 16em 보다 좁아 값이 제목 아래로 간다(규칙 그대로)
            expect(valueRect.top, greaterThanOrEqualTo(title.bottom - 0.5));
          } else {
            expect(valueRect.left, greaterThanOrEqualTo(title.right - 0.5));
          }
        }
      },
    );
  }

  testWidgets('값 + 화살표 — 폭 제한 전(1em 규칙)에는 넘쳤던 줄: 넘침 오류 없음 · 값이 여러 줄', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PList(
          semanticLabel: '폼',
          children: [
            PListButtonItem(
              title: '장소',
              suffix: _arrowValue(_place),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final value = tester.getRect(findTextContaining('서울'));
    expect(value.height, greaterThan(40), reason: '남은 폭에서 줄을 바꾼다');
  });

  testWidgets('공백 없는 긴 제목은 본문 자리 폭의 절반에서 끊는다', (tester) async {
    await tester.pumpWidget(
      _host(
        PList(
          semanticLabel: '폼',
          children: [
            PListButtonItem(
              title: _noSpace,
              suffix: _arrowValue(_place),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final body = tester.getRect(_key('plist-body'));
    final row = tester.getRect(_key('plist-row'));
    // 본문 자리 = 줄 안 폭 − 화살표(18) − 사이(4)… 절반 근처에서 끊는다 (+뒤 여백 10)
    expect(body.width, lessThanOrEqualTo(row.width / 2 + 10 + 24));
    expect(body.width, greaterThan(row.width / 2 - 40));
    final title = tester.getRect(_key('plist-title'));
    expect(title.height, greaterThan(40), reason: '제목이 여러 줄로 끊긴다');
  });

  testWidgets('글 값만 넘겨도(Text) 같은 하한 — 이메일 줄', (tester) async {
    await tester.pumpWidget(
      _host(
        const PList(
          semanticLabel: '계정',
          children: [
            PListItem(
              prefix: Icon(LucideIcons.mail),
              title: '이메일 주소',
              suffix: Text('porest-desk-front-design-system-list@example.kr'),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final body = tester.getRect(_key('plist-body'));
    final title = tester.getRect(_key('plist-title'));
    final longest = listTitleMinWidth(
      title: '이메일 주소',
      style: PTypography.t5,
      scaler: TextScaler.noScaling,
      direction: TextDirection.ltr,
      cap: 10000,
    );
    expect(
      body.width,
      greaterThanOrEqualTo(longest + kPListBodyTrailGap - 0.5),
    );
    expect(
      title.height,
      lessThanOrEqualTo(44),
      reason: '낱말 사이에서만 줄이 바뀐다(두 낱말 = 최대 두 줄)',
    );
  });

  testWidgets('제목 + 값은 한 Semantics 노드, 읽기 순서 제목 → 값', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        PList(
          semanticLabel: '폼',
          children: [
            PListButtonItem(
              title: '장소',
              suffix: _arrowValue(_place),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^장소')));
    final data = node.getSemanticsData();
    expect(data.label, '장소\n$_place');
    expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
    // 값이 따로 서는 노드가 없다
    expect(find.bySemanticsLabel(_place), findsNothing);
    handle.dispose();
  });

  testWidgets('글자 200% — 본문 아래로 내려온 값은 금액도 묶음도 왼쪽 맞춤(본문 칸 왼쪽과 같은 x)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PList(
          semanticLabel: '값',
          children: [
            PListItem(
              title: '일간 손익',
              suffix: PListValue(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('-1,234,567원', textAlign: TextAlign.end),
                    Wrap(
                      alignment: WrapAlignment.end,
                      children: const [Text('총액 제외')],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        scale: 2,
      ),
    );
    final title = tester.getRect(_key('plist-title'));
    final amount = tester.getRect(findText('-1,234,567원'));
    final badge = tester.getRect(findText('총액 제외'));
    expect(amount.left, closeTo(title.left, 0.5));
    expect(badge.left, closeTo(title.left, 0.5));
    expect(amount.top, greaterThanOrEqualTo(title.bottom - 0.5));
  });

  test('alignListValueStart — 끝 맞춤만 왼쪽으로, 나머지는 그대로', () {
    const plain = Text('a');
    expect(identical(alignListValueStart(plain), plain), isTrue);
    final end = alignListValueStart(const Text('a', textAlign: TextAlign.end));
    expect((end as Text).textAlign, TextAlign.start);
  });
}
