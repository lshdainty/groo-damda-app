// I-29 웹 · 앱 같은 장면 — P7 달 줄: 100% 는 한 줄(달 글 왼쪽 · 동작 오른쪽 끝), 큰 글자는 동작이 아래 줄 오른쪽 끝(달 글은 왼쪽).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/shared/forms/month_row.dart';
import '../support/plain_text.dart';

const _key = Key('trailing');

Future<void> _pump(
  WidgetTester tester,
  double scale, {
  bool tabular = false,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: MonthRow(
          month: DateTime(2026, 10),
          tabularFigures: tabular,
          onPick: () {},
          trailing: const SizedBox(key: _key, width: 94, height: 36),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          labelStyle: const TextStyle(fontSize: 16),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('100% — 달 글과 동작이 같은 줄, 동작은 오른쪽 끝(336)', (tester) async {
    await _pump(tester, 1.0);
    final box = tester.getRect(find.byKey(_key));
    final title = tester.getRect(findTextContaining('2026').first);
    expect(box.center.dy, closeTo(title.center.dy, 4), reason: '같은 줄');
    expect(box.right, closeTo(336, 0.5));
    expect(title.left, lessThan(40), reason: '달 글은 왼쪽');
  });

  testWidgets('200% — 동작이 아래 줄 오른쪽 끝(336), 달 글은 왼쪽', (tester) async {
    await _pump(tester, 2.0);
    final box = tester.getRect(find.byKey(_key));
    final title = tester.getRect(findTextContaining('2026').first);
    expect(box.top, greaterThanOrEqualTo(title.bottom - 1), reason: '아래 줄');
    expect(box.right, closeTo(336, 0.5));
    expect(title.left, lessThan(40), reason: '달 글은 왼쪽');
  });

  testWidgets('달 글 숫자 — tabularFigures 켜면 고정폭, 기본(캘린더)은 끔', (tester) async {
    bool tab(WidgetTester t) {
      final text = t.widget<Text>(findTextContaining('2026').first);
      return text.style?.fontFeatures?.any(
            (f) => f == const FontFeature.tabularFigures(),
          ) ??
          false;
    }

    await _pump(tester, 1.0, tabular: true);
    expect(tab(tester), isTrue);
    await _pump(tester, 1.0);
    expect(tab(tester), isFalse);
  });

  testWidgets('달 글 폭 — Pretendard 16/700 "2026년 10월" 고정폭 94.2(웹 화면 약 93.5)', (
    tester,
  ) async {
    final l = FontLoader('Pretendard')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/PretendardVariable.ttf').readAsBytesSync(),
          ),
        ),
      );
    await tester.runAsync(l.load);
    await _pump(tester, 1.0, tabular: true);
    final w = tester.getSize(findTextContaining('2026').first).width;
    expect(w, closeTo(94.2, 0.5));
  });

  testWidgets('가계부 · 할 일 달 글(LedgerMonthNav)도 고정폭', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: LedgerMonthNav(
            label: '2026년 10월',
            onPick: () {},
            onOpenFilter: () {},
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(findText('2026년 10월'));
    expect(
      text.style!.fontFeatures!.contains(const FontFeature.tabularFigures()),
      isTrue,
    );
  });
}
