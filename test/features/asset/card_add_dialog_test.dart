// 카드 폼의 입력 정책 — 이월 금액 칸(D7·D15), 결제일 변경 확인(D5), 별칭 상한(QA #16).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/asset/presentation/card_add_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';

import '../../support/plain_text.dart';
import 'asset_form_test_helpers.dart';

/// 지금 총 미결제 잔액 500,000 · 그 가운데 카드를 만들 때 적은 이월 9,000.
const _credit = Asset(
  rowId: 7,
  assetName: '신한 Deep Dream',
  assetType: 'CREDIT_CARD',
  balance: -500000,
  institution: '신한카드',
  isIncludedInTotal: 'Y',
  creditLimit: 5000000,
  paymentDay: 14,
  carryoverAmount: 9000,
  cardClosedThrough: '2026-08-31',
);

const _other = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 100,
);

const _emptyPage = CardCatalogPage(
  content: [],
  totalElements: 0,
  totalPages: 0,
  number: 0,
  size: 40,
  first: true,
  last: true,
  empty: true,
);

class _CapturingRepo extends AssetRepository {
  _CapturingRepo() : super(Dio());

  bool updated = false;
  int? balance;
  int? carryoverAmount;
  // 수정 본문에 어떤 상태로 실렸는지 — 값뿐 아니라 "키가 실렸나" 까지 본다(QA #99).
  Patch<int> creditLimit = const Patch.keep();
  Patch<int> paymentDay = const Patch.keep();
  Patch<int> paymentAssetRowId = const Patch.keep();
  Patch<String> memo = const Patch.keep();

  @override
  Future<Asset> update({
    required int id,
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    Patch<double> exchangeRate = const Patch.keep(),
    String? color,
    String? institution,
    Patch<String> memo = const Patch.keep(),
    String? isIncludedInTotal,
    String? isAmountHidden,
    int? cardCatalogRowId,
    Patch<int> creditLimit = const Patch.keep(),
    Patch<int> paymentDay = const Patch.keep(),
    Patch<int> paymentAssetRowId = const Patch.keep(),
    bool? isOverdraft,
    List<AssetHolding>? holdings,
    int? carryoverAmount,
    int? dueCarryoverAmount,
    bool silent = false,
  }) async {
    updated = true;
    this.balance = balance;
    this.carryoverAmount = carryoverAmount;
    this.creditLimit = creditLimit;
    this.paymentDay = paymentDay;
    this.paymentAssetRowId = paymentAssetRowId;
    this.memo = memo;
    return _credit;
  }
}

Finder _submitButton(String label) => buttonLabeled(label);

Future<_CapturingRepo> _openEdit(
  WidgetTester tester,
  Asset asset, {
  List<Asset> assets = const [_credit, _other],
}) async {
  final repo = _CapturingRepo();
  // 시트 본문은 스크롤이다 — 좁은 화면에서는 사용액 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => assets),
        assetRepositoryProvider.overrideWith((ref) async => repo),
        cardCatalogPageProvider.overrideWith((ref, key) async => _emptyPage),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showCardEditDialog(ctx, asset),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  // 이 칸은 "이전 미결제 사용액" — 카드를 만들 때 적은 이월 금액이다(D7). 지금 총
  // 미결제 잔액으로 채우면 저장만 해도 이월이 잔액만큼 새로 생겨 빚이 두 배가 됐다
  // (QA 23차 1 — 출시 차단). 잔액은 옆에 읽기 전용으로만 보인다.
  testWidgets('신용카드 편집은 이월 금액으로 채우고, 지금 잔액은 옆에 읽기 전용', (tester) async {
    await _openEdit(tester, _credit);
    expect(textOf(tester, l.assetCurrentUsage), '9,000');
    expect(findPlain('500,000'), findsNothing);
    expect(findPlain('-500,000'), findsNothing);
    // 읽기 전용 잔액에 음수 부호가 붙지 않는다 — ASCII 도 U+2212 도(양수로 보인다).
    expect(findPlain('−500,000'), findsNothing);
    expect(
      find.textContaining(RegExp(r'-\d'), findRichText: true),
      findsNothing,
    );
    expect(findRichPlain('지금 미결제 잔액 500,000원'), findsOneWidget);
  });

  testWidgets('이월 금액이 없는 카드(옛 서버 포함)는 0 으로 연다', (tester) async {
    await _openEdit(tester, _credit.copyWith(carryoverAmount: null));
    expect(textOf(tester, l.assetCurrentUsage), '0');
    expect(findPlain('500,000'), findsNothing);
  });

  testWidgets('저장하면 carryoverAmount 키로 보내고 balance 는 안 싣는다', (tester) async {
    final repo = await _openEdit(tester, _credit);
    await typeInto(tester, l.assetCurrentUsage, '32000');
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.updated, isTrue);
    expect(repo.carryoverAmount, 32000);
    expect(repo.balance, isNull, reason: '서버는 신용카드 balance 를 무시한다 — 싣지 않는다');
  });

  testWidgets('이름만 고쳐 저장해도 이월은 그대로 실린다 — 빚이 늘지 않는다', (tester) async {
    final repo = await _openEdit(tester, _credit);
    await typeInto(tester, l.assetNickname, '생활비 카드');
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.carryoverAmount, 9000);
    expect(repo.balance, isNull);
  });

  group('이월이 든 회차의 결제일이 지났으면(D15)', () {
    const locked = Asset(
      rowId: 7,
      assetName: '신한 Deep Dream',
      assetType: 'CREDIT_CARD',
      balance: -500000,
      paymentDay: 14,
      carryoverAmount: 9000,
      carryoverLocked: true,
    );

    testWidgets('칸이 읽기 전용이고 이유를 말한다', (tester) async {
      await _openEdit(tester, locked);
      expect(readOnlyOf(tester, l.assetCurrentUsage), isTrue);
      expect(findRichPlain('결제가 끝나 고칠 수 없어요'), findsOneWidget);
    });

    testWidgets('저장해도 이월 키를 안 싣는다 — 값이 같아도', (tester) async {
      final repo = await _openEdit(tester, locked);
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();
      expect(repo.updated, isTrue);
      expect(repo.carryoverAmount, isNull);
      expect(repo.balance, isNull);
    });
  });

  group('결제일 변경은 다음 회차부터(D5)', () {
    Future<void> pickDay(WidgetTester tester, int day) async {
      // 첫 Select 가 결제일이다(둘째는 결제 출금계좌)
      await tester.tap(find.byType(PSelect<int>).first);
      await tester.pumpAndSettle();
      // 목록은 칸 아래에 붙고 31줄이라 보이는 자리까지 굴린다
      await tester.ensureVisible(findPlain(l.dayN(day)).last);
      await tester.pumpAndSettle();
      await tester.tap(findPlain(l.dayN(day)).last);
      await tester.pumpAndSettle();
    }

    testWidgets('바꾸면 옛 결제일로 결제되는 회차를 말하고 확인받는다', (tester) async {
      final repo = await _openEdit(tester, _credit);
      await pickDay(tester, 5);
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      // 8월까지 닫혔다 → 9월분은 옛 결제일(14일)인 10월 14일에 결제된다.
      // 폼 시트 위에 ds 확인창이 뜬다(시트는 그대로 하나)
      expect(findPlain('결제일을 바꿀까요?'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('p-bottom-sheet-root')),
        findsOneWidget,
        reason: '확인창은 폼 시트 위에 뜰 뿐 시트를 더하지 않는다',
      );
      expect(
        findRichPlain('바꾼 결제일은 다음 회차부터 적용돼요. 9월분은 10월 14일에 결제돼요.'),
        findsOneWidget,
      );
      expect(repo.updated, isFalse, reason: '확인 전에는 보내지 않는다');

      await tester.tap(buttonLabeled(l.actionSave).last);
      await tester.pumpAndSettle();
      expect(repo.updated, isTrue);
      expect(repo.paymentDay.value, 5);
    });

    // 결제일을 이미 한 번 바꿔 둔 카드(25 → 14): 8월분은 아직 옛 결제일 9/25 에 나간다.
    // 지금 결제일(14일)로 세면 "8월분은 9월 14일" 이라는 틀린 날짜를 말한다(QA 26 4).
    testWidgets('결제일 변경이 대기 중이면 서버가 준 그 회차의 결제일을 말한다', (tester) async {
      await _openEdit(
        tester,
        _credit.copyWith(
          cardClosedThrough: '2026-07-31',
          nextPaymentDate: '2026-09-25',
        ),
      );
      await pickDay(tester, 5);
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(
        findRichPlain('바꾼 결제일은 다음 회차부터 적용돼요. 8월분은 9월 25일에 결제돼요.'),
        findsOneWidget,
      );
    });

    testWidgets('물러나면 저장하지 않는다', (tester) async {
      final repo = await _openEdit(tester, _credit);
      await pickDay(tester, 5);
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();
      await tester.tap(buttonLabeled(l.actionCancel).last);
      await tester.pumpAndSettle();
      expect(repo.updated, isFalse);
    });

    testWidgets('결제일을 안 바꾸면 묻지 않는다', (tester) async {
      final repo = await _openEdit(tester, _credit);
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();
      expect(findRichPlain('다음 회차부터'), findsNothing);
      expect(repo.updated, isTrue);
    });
  });

  testWidgets('사용액 칸에 `-` 는 타이핑되지 않는다', (tester) async {
    await _openEdit(tester, _credit);
    await typeInto(tester, l.assetCurrentUsage, '-320000');
    expect(textOf(tester, l.assetCurrentUsage), '320,000');
  });

  // 카드를 신용에서 체크로 바꾸면 한도·결제일이 **실제로 지워져야** 청구 사이클이
  // 남지 않는다. 종전엔 null 인 칸을 키째 빼서 서버가 옛 한도·결제일을 지켰다(QA #99).
  testWidgets('신용→체크로 바꿔 저장하면 한도·결제일이 명시적 null 로 실린다', (tester) async {
    final repo = await _openEdit(tester, _credit);
    await tester.tap(findPlain(l.assetTypeCheckCard));
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(
      repo.creditLimit.present,
      isTrue,
      reason: '한도 키가 빠지면 5,000,000 이 그대로 남는다',
    );
    expect(repo.creditLimit.value, isNull);
    expect(repo.paymentDay.present, isTrue, reason: '결제일 키가 빠지면 14 일이 그대로 남는다');
    expect(repo.paymentDay.value, isNull);
  });

  // 이 화면엔 메모 칸이 없다. 없는 칸을 null 로 실으면 계좌 화면에서 적어 둔 메모가
  // 카드를 고칠 때마다 사라진다 — 이게 이 수정의 제일 큰 위험이다.
  testWidgets('이 화면에 없는 메모 칸은 아예 안 실린다', (tester) async {
    final repo = await _openEdit(tester, _credit);
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.memo.present, isFalse);
  });

  testWidgets('별칭 30자 초과·중복은 안내가 뜨고 저장이 막힌다', (tester) async {
    // 30자를 넘어 저장돼 있던 옛 별칭 — 입력은 30자에서 멈추므로 옛 값으로 연다
    final longName = _credit.copyWith(assetName: 'ㄱ' * 31);
    final repo = await _openEdit(tester, longName, assets: [longName, _other]);
    await typeInto(tester, l.assetNickname, 'ㄱ' * 31);
    expect(findRichPlain(l.nameTooLong(30)), findsOneWidget);
    // 단추는 늘 켜 둔다 — 눌러도 요청은 안 나간다
    expect(
      tester.widget<PButton>(_submitButton(l.actionSave)).onPressed,
      isNotNull,
    );
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.updated, isFalse);

    await typeInto(tester, l.assetNickname, 'QA 주거래');
    expect(findRichPlain(l.assetNicknameDuplicate), findsOneWidget);
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.updated, isFalse);

    // 자기 이름은 중복이 아니다 — 저장이 나간다.
    await typeInto(tester, l.assetNickname, 'ㄱ' * 31);
    await typeInto(tester, l.assetNickname, '신한 Deep Dream');
    expect(findRichPlain(l.assetNicknameDuplicate), findsNothing);
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.updated, isTrue);
  });

  group('필수가 비어도 단추는 켜 두고 누르면 칸마다 알린다', () {
    Future<_CapturingRepo> openAdd(WidgetTester tester) async {
      final repo = _CapturingRepo();
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetsProvider.overrideWith((ref) async => const [_credit, _other]),
            assetRepositoryProvider.overrideWith((ref) async => repo),
            cardCatalogPageProvider.overrideWith(
              (ref, key) async => _emptyPage,
            ),
          ],
          child: MaterialApp(
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => showCardAddDialog(ctx),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('새 신용카드 — 상품 · 결제일이 비면 누를 때 두 칸 아래 안내, 요청은 안 나간다', (
      tester,
    ) async {
      final repo = await openAdd(tester);
      // 처음엔 오류가 없다
      expect(findRichPlain(l.assetFormErrCard), findsNothing);
      expect(findRichPlain(l.assetFormErrPaymentDay), findsNothing);
      expect(
        tester.widget<PButton>(_submitButton(l.calAdd)).onPressed,
        isNotNull,
      );
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();
      expect(findRichPlain(l.assetFormErrCard), findsOneWidget);
      expect(findRichPlain(l.assetFormErrPaymentDay), findsOneWidget);
      expect(repo.updated, isFalse);
    });

    testWidgets('새로 추가할 때는 자리 글이고, 없음을 고르면 칸에 그 글이 남는다', (tester) async {
      await openAdd(tester);
      expect(findPlain(l.assetPaymentAccountSelect), findsOneWidget);
      expect(findPlain(l.assetNoPaymentAccount), findsNothing);
      await tester.tap(find.byType(PSelect<int>).last);
      await tester.pumpAndSettle();
      await tester.tap(findPlain(l.assetNoPaymentAccount).last);
      await tester.pumpAndSettle();
      expect(findPlain(l.assetNoPaymentAccount), findsOneWidget);
      expect(findPlain(l.assetPaymentAccountSelect), findsNothing);
    });

    testWidgets('결제일을 고르면 그 안내가 저절로 걷힌다', (tester) async {
      await openAdd(tester);
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PSelect<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(findPlain(l.dayN(1)).last);
      await tester.pumpAndSettle();
      expect(findRichPlain(l.assetFormErrPaymentDay), findsNothing);
      expect(findRichPlain(l.assetFormErrCard), findsOneWidget);
    });
  });

  testWidgets('결제 출금계좌는 "없음" 으로 비울 수 있고 명시적 null 로 실린다', (tester) async {
    final withAccount = _credit.copyWith(paymentAssetRowId: 8);
    final repo = await _openEdit(
      tester,
      withAccount,
      assets: [withAccount, _other],
    );
    // 둘째 Select 가 결제 출금계좌다(첫째는 결제일)
    await tester.tap(find.byType(PSelect<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(findPlain(l.assetNoPaymentAccount).last);
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.paymentAssetRowId.present, isTrue);
    expect(repo.paymentAssetRowId.value, isNull);
  });

  testWidgets('저장된 카드의 결제 출금계좌가 null 이면 처음부터 "없음" 이 보이고 안 바꾸면 그대로 null 이다', (
    tester,
  ) async {
    final repo = await _openEdit(tester, _credit, assets: [_credit, _other]);
    expect(findPlain(l.assetNoPaymentAccount), findsOneWidget);
    expect(findPlain(l.assetPaymentAccountSelect), findsNothing);
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.paymentAssetRowId.value, isNull);
  });
}
