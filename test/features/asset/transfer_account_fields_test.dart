// 이체 칸 공용 위젯 — 시트·반복 설정·프리셋 폼이 이 하나를 쓴다.
//
// 어제(#366)까지 같은 칸을 세 화면이 각자 그렸다. 규칙(`transfer_rules.dart`)만
// 공유해서 반은 맞고 반은 틀렸다 — 셀렉트 위젯도, 로딩 표시도, 수수료 상한도 달랐다.
// 화면이 갈리면 "어떤 계좌를 고를 수 있나 · 이자 칸이 언제 뜨나" 가 조용히 갈리고,
// 갈리는 순간 사용자는 시트에서 만든 이체를 반복으로는 못 만든다.
//
// 그래서 세 화면 대신 **이 위젯 하나**를 잰다. 세 화면의 저장 payload 테스트
// (`preset_transfer_payload_test` · `recurring_transfer_payload_test`)는 그대로 둔다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/transfer_account_fields.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_select.dart';
import '../../support/plain_text.dart';

const _bank = Asset(
  rowId: 1,
  assetName: 'QA예금',
  assetType: 'BANK_ACCOUNT',
  institution: '신한',
);
const _savings = Asset(
  rowId: 2,
  assetName: 'QA적금',
  assetType: 'SAVINGS',
  institution: '신한',
);
const _loan = Asset(
  rowId: 3,
  assetName: 'QA대출',
  assetType: 'LOAN',
  institution: '신한',
);
const _check = Asset(
  rowId: 4,
  assetName: 'QA체크',
  assetType: 'CHECK_CARD',
  institution: '신한',
);
const _credit = Asset(
  rowId: 5,
  assetName: 'QA신용',
  assetType: 'CREDIT_CARD',
  institution: '신한',
);

Future<void> _pump(
  WidgetTester tester, {
  int? fromAssetRowId,
  int? toAssetRowId,
  int? amountForHint,
  bool? interestEnabled,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TransferAccountFields(
              assets: const AsyncValue.data([
                _bank,
                _savings,
                _loan,
                _check,
                _credit,
              ]),
              fromAssetRowId: fromAssetRowId,
              toAssetRowId: toAssetRowId,
              feeController: TextEditingController(),
              interestController: TextEditingController(text: '20000'),
              amountForHint: amountForHint,
              interestEnabled: interestEnabled ?? true,
              onFromChanged: (_) {},
              onToChanged: (_) {},
              labelBuilder: (text) => Text(text),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSelect(WidgetTester tester, int index) async {
  await tester.tap(find.byType(PSelect<int>).at(index));
  await tester.pumpAndSettle();
}

/// 열린 메뉴 **안의** 항목만 본다. 전역 `find.text` 는 셀렉트 트리거에 그려진
/// "고른 값" 까지 잡아서, 보내는 계좌가 받는 목록에서 빠졌는지 가릴 수 없다.
Finder _menuOption(String label) =>
    find.descendant(of: find.byType(ListView), matching: findText(label));

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('카드는 어느 쪽에도 후보로 안 뜬다', (tester) async {
    await _pump(tester);
    await _openSelect(tester, 0);

    expect(_menuOption('신한 · QA예금'), findsOneWidget);
    expect(_menuOption('신한 · QA적금'), findsOneWidget);
    expect(_menuOption('신한 · QA대출'), findsOneWidget);
    expect(_menuOption('신한 · QA체크'), findsNothing);
    expect(_menuOption('신한 · QA신용'), findsNothing);
  });

  testWidgets('받는 계좌 후보에서 보내는 계좌가 빠진다', (tester) async {
    await _pump(tester, fromAssetRowId: 1);
    await _openSelect(tester, 1);

    expect(_menuOption('신한 · QA예금'), findsNothing);
    expect(_menuOption('신한 · QA적금'), findsOneWidget);
  });

  testWidgets('받는 계좌가 대출이면 이자 칸이 뜬다', (tester) async {
    await _pump(tester, fromAssetRowId: 1, toAssetRowId: 3);

    expect(findText(l.expInterest), findsOneWidget);
  });

  testWidgets('받는 계좌가 대출이 아니면 이자 칸이 없다', (tester) async {
    await _pump(tester, fromAssetRowId: 1, toAssetRowId: 2);

    expect(findText(l.expInterest), findsNothing);
  });

  testWidgets('금액이 없으면 이자 안내를 쪼개지 않는다 — 프리셋은 금액이 없는 게 정상', (tester) async {
    await _pump(tester, fromAssetRowId: 1, toAssetRowId: 3);

    expect(findText(l.expInterestHint), findsOneWidget);
  });

  testWidgets('금액이 있으면 원금·이자로 쪼개 보여 준다', (tester) async {
    await _pump(
      tester,
      fromAssetRowId: 1,
      toAssetRowId: 3,
      amountForHint: 100000,
    );

    expect(findText(l.expInterestHint), findsNothing);
    expect(findText(l.expInterestSplit('80,000', '20,000')), findsOneWidget);
  });

  group('이자 칸 조건은 호스트가 정한다 (2026-09-15)', () {
    // 이자는 받는 자산이 대출일 때만 뜨는데, 프리셋 폼은 그 위에 "금액을 고정했을
    // 때만" 이라는 조건이 하나 더 붙는다. 그 조건을 이 위젯 안에 넣으면 거래 시트와
    // 반복 설정에서 이자 칸이 통째로 사라진다 — 둘에는 "금액 고정" 이라는 게 없다.
    // 대출 상환 이체에 이자를 못 적으면 이자 지출이 안 생기고 원금이 과다 상환된
    // 것으로 기록된다. 그래서 기본은 켜짐이고 프리셋 폼만 끈다.
    testWidgets('인자를 안 주면 켜진다 — 거래 시트·반복 설정이 쓰는 기본값', (tester) async {
      await _pump(tester, fromAssetRowId: 1, toAssetRowId: 3);
      expect(findText(l.expInterest), findsOneWidget);
    });

    testWidgets('호스트가 끄면 대출이어도 안 뜬다 — 프리셋 폼이 금액 미고정일 때', (tester) async {
      await _pump(
        tester,
        fromAssetRowId: 1,
        toAssetRowId: 3,
        interestEnabled: false,
      );
      expect(findText(l.expInterest), findsNothing);
    });
  });

  group('받는 계좌가 대출이 아니게 되면 이자도 버린다 (#177)', () {
    // 이자 칸은 대출이 아닐 때 숨겨지지만 컨트롤러 값은 남아 있었다. 다시 대출로
    // 바꾸면 옛 이자가 되살아나, 화면이 "이 이자가 저장돼 있다" 고 말한다.
    // 저장값은 호스트가 `_showInterest` 로 걸러 맞았지만 화면이 틀렸다.
    //
    // 세 화면(거래 시트·반복 설정·프리셋 폼)이 같은 위젯을 쓰므로 여기서 한 번만 잰다.
    testWidgets('대출 → 적금 → 대출 로 되돌아오면 이자 칸이 비어 있다', (tester) async {
      final interest = TextEditingController(text: '20000');
      addTearDown(interest.dispose);
      int? to = 3; // 대출

      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => SingleChildScrollView(
                  child: TransferAccountFields(
                    assets: const AsyncValue.data([_bank, _savings, _loan]),
                    fromAssetRowId: 1,
                    toAssetRowId: to,
                    feeController: TextEditingController(text: '500'),
                    interestController: interest,
                    onFromChanged: (_) {},
                    onToChanged: (v) => setState(() => to = v),
                    labelBuilder: (text) => Text(text),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(findText(l.expInterest), findsOneWidget);
      expect(interest.text, '20000');

      // 적금으로 바꾼다 — 이자 칸이 사라진다.
      await tester.tap(find.byType(PSelect<int>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(findText('신한 · QA적금').last);
      await tester.pumpAndSettle();
      expect(findText(l.expInterest), findsNothing);
      expect(interest.text, '', reason: '칸만 감추고 값을 두면 다시 대출로 바꿀 때 되살아난다');

      // 다시 대출로 — 빈 칸으로 열려야 한다.
      await tester.tap(find.byType(PSelect<int>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(findText('신한 · QA대출').last);
      await tester.pumpAndSettle();
      expect(findText(l.expInterest), findsOneWidget);
      expect(interest.text, '');
    });

    testWidgets('반대편 — 수수료는 받는 계좌를 바꿔도 남는다', (tester) async {
      final fee = TextEditingController(text: '500');
      addTearDown(fee.dispose);
      int? to = 3;

      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => SingleChildScrollView(
                  child: TransferAccountFields(
                    assets: const AsyncValue.data([_bank, _savings, _loan]),
                    fromAssetRowId: 1,
                    toAssetRowId: to,
                    feeController: fee,
                    interestController: TextEditingController(),
                    onFromChanged: (_) {},
                    onToChanged: (v) => setState(() => to = v),
                    labelBuilder: (text) => Text(text),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PSelect<int>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(findText('신한 · QA적금').last);
      await tester.pumpAndSettle();

      expect(fee.text, '500');
    });
  });
}
