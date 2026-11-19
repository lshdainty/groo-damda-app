// 가계부 · 할 일 원장 머리의 금액 줄 — 금액이 먼저다(card.md "금액 옆 동작은 금액이 먼저", groo-design #265). 금액 한 줄 폭 +
// 사이 12 + 단추 폭이 줄 폭에 들 때만 단추를 옆에 두고, 넘으면 단추를 금액 아래 줄 오른쪽 끝으로 내린다. 폭은 지금 글자 배율
// (iOS 선형 · 안드로이드 비선형)을 넣어 잰다 — 카드 머리의 "반 폭" 은 쓰지 않는다.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

import '../../support/android_font_scale.dart';

Future<void> _loadFonts() async {
  final bytes = File('assets/fonts/PretendardVariable.ttf').readAsBytesSync();
  for (final family in const ['Pretendard', 'FlutterTest']) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  }
}

const _slot = ValueKey('ledger-summary-slot');

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required TextScaler scaler,
  required String locale,
  required String total,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(locale),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 1200), textScaler: scaler),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: LedgerTotalRow(
              key: const ValueKey('row'),
              total: total,
              insight: const Text('이번 달 교통에 가장 많이 썼어요'),
              summaryOpen: false,
              onToggleSummary: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

RenderParagraph _amount(WidgetTester tester, String total) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is Text && w.semanticsLabel == total,
        ),
        matching: find.byType(RichText),
      ),
    );

/// 금액이 한 줄이다 — 그린 높이가 줄 높이 하나.
void _expectOneLine(WidgetTester tester, String total, String reason) {
  final rp = _amount(tester, total);
  final style = rp.text.style!;
  final line = rp.textScaler.scale(style.fontSize!) * style.height!;
  expect(rp.size.height, closeTo(line, 0.5), reason: '$reason 금액 한 줄');
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('iOS 선형 AX4 · 402 · 한국어 — 단추는 금액 아래 줄 오른쪽 끝, 금액은 한 줄', (
    tester,
  ) async {
    const total = '29,430원';
    await _pump(
      tester,
      width: 402,
      scaler: const TextScaler.linear(47 / 17),
      locale: 'ko',
      total: total,
    );
    final slot = tester.getRect(find.byKey(_slot));
    final amount = tester.getRect(
      find.byWidgetPredicate((w) => w is Text && w.semanticsLabel == total),
    );
    final button = tester.getRect(find.byType(PButton));
    expect(slot.top, greaterThan(amount.bottom), reason: '단추가 금액 아래');
    // 오른쪽 끝 — 화면 여백 24 안쪽 끝
    expect(button.right, closeTo(402 - 24, 0.5), reason: '오른쪽 끝');
    _expectOneLine(tester, total, 'AX4');
  });

  testWidgets(
    '안드로이드 비선형 200% · 411 · 영어 "Spending summary" — 단추는 금액 아래 줄 오른쪽 끝',
    (tester) async {
      const total = '₩29,430';
      await _pump(
        tester,
        width: 411,
        scaler: const AndroidNonlinearTextScaler(),
        locale: 'en',
        total: total,
      );
      expect(find.text('Spending summary'), findsOneWidget);
      final slot = tester.getRect(find.byKey(_slot));
      final amount = tester.getRect(
        find.byWidgetPredicate((w) => w is Text && w.semanticsLabel == total),
      );
      final button = tester.getRect(find.byType(PButton));
      expect(slot.top, greaterThan(amount.bottom), reason: '단추가 금액 아래');
      expect(button.right, closeTo(411 - 24, 0.5), reason: '오른쪽 끝');
      _expectOneLine(tester, total, '안드로이드 200%');
    },
  );

  testWidgets('100% — 단추는 금액 옆(같은 줄), 금액은 한 줄', (tester) async {
    for (final (locale, total) in [('ko', '29,430원'), ('en', '₩29,430')]) {
      await _pump(
        tester,
        width: 402,
        scaler: TextScaler.noScaling,
        locale: locale,
        total: total,
      );
      final slot = tester.getRect(find.byKey(_slot));
      final amount = tester.getRect(
        find.byWidgetPredicate((w) => w is Text && w.semanticsLabel == total),
      );
      expect(slot.top, closeTo(amount.top, 0.5), reason: '$locale 같은 줄');
      expect(slot.left, greaterThan(amount.right), reason: '$locale 옆');
      _expectOneLine(tester, total, '$locale 100%');
    }
  });

  testWidgets('금액 한 줄이 줄 폭보다 길면 단추를 내리고 금액만 쉼표 뒤에서 꺾는다', (tester) async {
    const total = '−123,456,789,012원';
    await _pump(
      tester,
      width: 320,
      scaler: const TextScaler.linear(47 / 17),
      locale: 'ko',
      total: total,
    );
    final slot = tester.getRect(find.byKey(_slot));
    final amount = tester.getRect(
      find.byWidgetPredicate((w) => w is Text && w.semanticsLabel == total),
    );
    expect(slot.top, greaterThan(amount.bottom));
    final rp = _amount(tester, total);
    final style = rp.text.style!;
    final line = rp.textScaler.scale(style.fontSize!) * style.height!;
    expect(rp.size.height, greaterThan(line * 1.5), reason: '여러 줄');
  });
}
