// 참여자 직접 추가 — 같은 이름이 조용히 빠지지 않게(QA #39) + 이름 길이(QA #40).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_create_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

/// step1 을 채우고 참여자 단계까지 넘어간다.
Future<AppLocalizations> _openStep2(WidgetTester tester) async {
  final l = await AppLocalizations.delegate.load(const Locale('ko'));
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dutchPayListProvider.overrideWith((ref) async => <DutchPay>[]),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showDutchPayCreateDialog(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.enterText(_field(l.dutchNamePlaceholder), '회식');
  await tester.enterText(_field('0'), '30000');
  await tester.pumpAndSettle();
  await tester.tap(_button(l.dutchNext));
  await tester.pumpAndSettle();
  return l;
}

Future<void> _add(WidgetTester tester, AppLocalizations l, String name) async {
  await tester.enterText(_field(l.dutchAddNamePlaceholder), name);
  await tester.pumpAndSettle();
  await tester.tap(_button(l.dutchAdd));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('직접 추가한 이름이 참여자로 들어간다', (tester) async {
    final l = await _openStep2(tester);
    await _add(tester, l, '철수');
    expect(find.text('철수'), findsOneWidget);
    expect(find.text(l.dutchNameAlreadyAdded), findsNothing);
  });

  testWidgets('같은 이름을 또 추가해도 사라지지 않고 안내가 뜬다', (tester) async {
    final l = await _openStep2(tester);
    await _add(tester, l, '철수');
    await _add(tester, l, '철수');
    // 웹은 토글로 빠져 참여자 0명이 됐고, 앱은 조용히 입력칸만 비웠다.
    expect(find.text('철수'), findsOneWidget);
    expect(find.text(l.dutchNameAlreadyAdded), findsOneWidget);
    expect(tester.widget<PButton>(_button(l.dutchCreate)).onPressed, isNotNull);
  });

  testWidgets('참여자를 빼면 만들기 전 안내가 뜬다', (tester) async {
    final l = await _openStep2(tester);
    await _add(tester, l, '철수');
    await tester.tap(find.bySemanticsLabel(l.dutchChipRemove('철수')));
    await tester.pumpAndSettle();
    await tester.tap(_button(l.dutchCreate));
    await tester.pumpAndSettle();
    expect(find.text(l.dutchNeedOne), findsOneWidget);
  });

  testWidgets('1단계에서 이름을 비우면 다음으로 안 넘어간다', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    await _openStep2(tester);
    await tester.tap(_button(l.dutchPrev));
    await tester.pumpAndSettle();
    await tester.enterText(_field(l.dutchNamePlaceholder), '');
    await tester.tap(_button(l.dutchNext));
    await tester.pumpAndSettle();
    expect(find.text(l.dutchTitleRequired), findsOneWidget);
  });

  testWidgets('참여자 이름은 20자에서 잘린다', (tester) async {
    final l = await _openStep2(tester);
    await tester.enterText(_field(l.dutchAddNamePlaceholder), 'ㄱ' * 25);
    await tester.pumpAndSettle();
    expect(find.text('ㄱ' * 20), findsOneWidget);
    expect(find.text('ㄱ' * 25), findsNothing);
  });
}
