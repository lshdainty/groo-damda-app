// 거래 추가 시트의 프리셋 칩 금액 — 축약은 차트 축과 **같은 함수** 하나다.
//
// 칩에 붙는 금액은 우리가 고른 값이 아니라 사용자가 프리셋을 만들 때 자유입력한
// 값이다(프리셋 편집창의 금액칸은 100억까지 아무 숫자나 받는다). 그런데 여기만
// `${(n / 1000).floor()}k` 로 따로 줄이고 있었다 —
//   · `k` 는 한국어 화면에서 쓰는 단위가 아니다(만·억·조, QA #73)
//   · floor 라 19,900 이 `19k`(=19,000)가 되어 900원이 사라졌다
//
// 에뮬레이터를 못 쓰는 환경이라(QA #23) 시트를 띄워 글자를 읽는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

const _category = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

/// 금액이 붙는 프리셋 — 칩에 금액을 보이려면 `lockAmount: 'Y'` + `amount > 0`.
ExpenseTemplate _preset(int amount) => ExpenseTemplate(
  rowId: 1,
  templateName: '점심',
  expenseType: 'EXPENSE',
  categoryRowId: _category.rowId,
  amount: amount,
  lockAmount: 'Y',
);

Future<void> _open(WidgetTester tester, ExpenseTemplate preset) async {
  // 기본 800x600 은 시트가 넘쳐 레이아웃 경고가 난다 — 실제 폰 크기로 맞춘다.
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => []),
        presetListProvider.overrideWith((ref) async => [preset]),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAddTxSheet(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1만 위 프리셋 금액은 `19k` 가 아니라 만 단위로 줄인다', (tester) async {
    await _open(tester, _preset(19900));

    expect(find.textContaining('19k'), findsNothing);
    // 소수 첫째 자리까지 반올림하고 `.0` 은 뗀다 — 1.99만 → `2만`.
    expect(find.textContaining('2만'), findsOneWidget);
  });

  testWidgets('억을 넘겨도 `k` 로 뻗지 않는다', (tester) async {
    // 옛 코드는 1.2억을 `120000k` 라고 했다 — 칩 안에서 읽을 수 있는 숫자가 아니다.
    await _open(tester, _preset(120000000));

    expect(find.textContaining('k'), findsNothing);
    expect(find.textContaining('1.2억'), findsOneWidget);
  });

  testWidgets('1만 아래는 예전과 같은 글자 — 천단위 콤마 정수', (tester) async {
    await _open(tester, _preset(9900));

    expect(find.textContaining('9,900'), findsOneWidget);
  });
}
