// 계좌 폼의 입력 정책 — 마이너스 통장(QA #17) · 부호(QA #19) · 별칭(QA #16).
//
// 에뮬레이터를 쓸 수 없는 환경이라(QA #23) 라벨·저장 페이로드를 전부 위젯 테스트로 고정한다. 칸을 찾는 길만 새 폼(I-17)에 맞췄고
// 저장 본문(payload)의 기대는 그대로다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/shared/brand/bank_colors.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_kind.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';

import '../../support/plain_text.dart';
import 'asset_form_test_helpers.dart';

const _existing = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

const _overdraft = Asset(
  rowId: 9,
  assetName: '마통',
  assetType: 'BANK_ACCOUNT',
  balance: -50000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

/// 메모가 들어 있는 계좌 — 그 메모를 지우고 저장하는 경로를 본다(QA #99).
const _withMemo = Asset(
  rowId: 11,
  assetName: 'QA 메모계좌',
  assetType: 'BANK_ACCOUNT',
  balance: 500000,
  institution: '국민은행',
  memo: '110-123-456789',
  isIncludedInTotal: 'Y',
);

const _loan = Asset(
  rowId: 10,
  assetName: '주택담보',
  assetType: 'LOAN',
  balance: -3000000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

/// create/update 로 넘어간 인자를 잡는 가짜 레포지토리.
/// (네트워크를 태우지 않으려고 Dio 는 쓰이지 않는 자리만 채운다)
class _CapturingRepo extends AssetRepository {
  _CapturingRepo() : super(Dio());

  Map<String, Object?>? captured;

  Asset _fake() => const Asset(rowId: 1, assetName: 'x', assetType: 'CASH');

  @override
  Future<Asset> create({
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    double? exchangeRate,
    String? color,
    String? institution,
    String? memo,
    String? isIncludedInTotal,
    String? isAmountHidden,
    int? sortOrder,
    int? cardCatalogRowId,
    int? creditLimit,
    int? paymentDay,
    int? paymentAssetRowId,
    bool? isOverdraft,
    List<AssetHolding>? holdings,
    int? dueCarryoverAmount,
    bool silent = false,
  }) async {
    captured = {
      'assetName': assetName,
      'assetType': assetType,
      'balance': balance,
      'creditLimit': creditLimit,
      'isOverdraft': isOverdraft,
      'memo': memo,
      'institution': institution,
    };
    return _fake();
  }

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
    captured = {
      'institution': institution,
      'assetName': assetName,
      'assetType': assetType,
      'balance': balance,
      'creditLimit': creditLimit,
      'isOverdraft': isOverdraft,
      // 이 화면이 소유한 칸이 "어떤 상태로" 실렸는지까지 본다(QA #99).
      'memo': memo,
      'exchangeRate': exchangeRate,
      'paymentDay': paymentDay,
      'paymentAssetRowId': paymentAssetRowId,
    };
    return _fake();
  }
}

Future<_CapturingRepo> _open(
  WidgetTester tester, {
  Asset? edit,
  AssetKind kind = AssetKind.checking,
  List<Asset> assets = const [_existing],
}) async {
  final repo = _CapturingRepo();
  // 시트 본문은 ListView 다 — 기본 800x600 에서는 계좌 종류 아래가 아예 안
  // 만들어져 findsNothing 이 거짓으로 통과한다. 폼 전체를 한 화면에 올린다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => assets),
        assetRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => edit == null
                  ? showAssetKindForm(ctx, kind)
                  : showAssetEditForm(ctx, edit),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return repo;
}

Finder _submitButton(String label) => buttonLabeled(label);

Future<void> _tapSubmit(WidgetTester tester, String label) async {
  await tester.tap(_submitButton(label));
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('수정의 종류 칸은 계좌 여섯을 낸다 — 마이너스 통장은 띄어 쓴다', (tester) async {
    await _open(tester, edit: _existing);
    await tester.tap(find.byType(PSelect<AssetKind>));
    await tester.pumpAndSettle();
    for (final k in [
      AssetKind.checking,
      AssetKind.deposit,
      AssetKind.installment,
      AssetKind.overdraft,
      AssetKind.cash,
      AssetKind.loan,
    ]) {
      expect(findPlain(k.label(l)), findsWidgets, reason: k.name);
    }
    expect(l.assetSubtypeOverdraft, '마이너스 통장');
  });

  testWidgets('마이너스 통장은 사용 중인 금액을 양수로 받아 음수로 저장한다', (tester) async {
    final repo = await _open(tester, kind: AssetKind.overdraft);
    // 라벨이 '잔액' 이 아니라 '사용 중인 금액' 으로 바뀐다.
    expect(fieldWithLabel(l.assetOverdraftUsedLabel), findsOneWidget);
    expect(fieldWithLabel(l.assetBalanceLabel), findsNothing);

    await typeInto(tester, l.assetOverdraftUsedLabel, '50000');
    await typeInto(tester, l.assetNickname, 'QA 별칭');
    await _tapSubmit(tester, l.calAdd);

    expect(repo.captured?['assetType'], 'BANK_ACCOUNT');
    expect(repo.captured?['balance'], -50000);
    expect(repo.captured?['isOverdraft'], isTrue);
  });

  testWidgets('잔액이 1,000억 위(상한 전 옛 값)면 칸 아래에 말이 나오고 저장은 요청을 보내지 않는다', (
    tester,
  ) async {
    final repo = await _open(
      tester,
      edit: _existing.copyWith(balance: 200000000000),
    );
    const msg = '금액은 1,000억원까지 입력할 수 있어요.';
    expect(findPlain(msg), findsOneWidget);
    await _tapSubmit(tester, l.actionSave);
    expect(repo.captured, isNull, reason: '서버에 보내지 않는다(깎지도 않는다)');
    expect(findPlain(msg), findsOneWidget);
  });

  // 상한 검사는 지금 보이는 칸만 센다 — 종류를 바꿔 한도 칸이 사라지면 옛 한도(1,000억 위)는 저장을 막지 않는다
  testWidgets('마이너스 통장 한도가 1,000억 위면 막고, 입출금으로 바꿔 한도 칸이 사라지면 저장된다', (
    tester,
  ) async {
    final repo = await _open(
      tester,
      edit: _overdraft.copyWith(creditLimit: 200000000000),
      assets: const [_overdraft],
    );
    await _tapSubmit(tester, l.actionSave);
    expect(repo.captured, isNull, reason: '보이는 한도 칸이 상한 위면 여전히 막힌다');

    await tester.tap(find.byType(PSelect<AssetKind>));
    await tester.pumpAndSettle();
    await tester.tap(findPlain(AssetKind.checking.label(l)).last);
    await tester.pumpAndSettle();
    await _tapSubmit(tester, l.actionSave);
    expect(repo.captured, isNotNull, reason: '사라진 칸의 옛 값은 세지 않는다');
    expect(repo.captured!['isOverdraft'], isFalse);
    final limit = repo.captured!['creditLimit']! as Patch<int>;
    expect(limit.present, isTrue);
    expect(limit.value, isNull, reason: '사라진 칸의 값은 요청에 실리지 않는다');
  });

  testWidgets('입출금은 같은 값을 양수로 저장한다', (tester) async {
    final repo = await _open(tester);
    await typeInto(tester, l.assetBalanceLabel, '50000');
    await typeInto(tester, l.assetNickname, 'QA 별칭');
    await _tapSubmit(tester, l.calAdd);

    expect(repo.captured?['balance'], 50000);
    expect(repo.captured?['isOverdraft'], isFalse);
  });

  testWidgets('대출은 남은 빚을 양수로 받아 음수로 저장한다', (tester) async {
    final repo = await _open(tester, kind: AssetKind.loan);
    expect(fieldWithLabel(l.assetLoanRemainingLabel), findsOneWidget);
    await typeInto(tester, l.assetLoanRemainingLabel, '3000000');
    await typeInto(tester, l.assetNickname, 'QA 별칭');
    await _tapSubmit(tester, l.calAdd);

    expect(repo.captured?['assetType'], 'LOAN');
    expect(repo.captured?['balance'], -3000000);
  });

  testWidgets('잔액칸에 `-` 는 타이핑되지 않고, 쓰는 동안 쉼표가 찍힌다', (tester) async {
    await _open(tester);
    await typeInto(tester, l.assetBalanceLabel, '-50000');
    expect(textOf(tester, l.assetBalanceLabel), '50,000');
  });

  testWidgets('1,000억을 넘는 잔액은 입력이 막힌다', (tester) async {
    await _open(tester);
    // QA 가 저장했던 99조.
    await typeInto(tester, l.assetBalanceLabel, '99999999999999');
    expect(textOf(tester, l.assetBalanceLabel), isNot(contains('99,999,999')));
    expect(textOf(tester, l.assetBalanceLabel), isEmpty);
  });

  testWidgets('음수 잔액 입출금을 열면 마이너스 통장이고 금액이 양수로 보인다', (tester) async {
    await _open(tester, edit: _overdraft, assets: const [_overdraft]);
    expect(fieldWithLabel(l.assetOverdraftUsedLabel), findsOneWidget);
    expect(textOf(tester, l.assetOverdraftUsedLabel), '50,000');
    expect(findPlain('-50,000'), findsNothing);
    expect(findPlain('−50,000'), findsNothing);
    expect(
      findTextContaining(RegExp(r'-\d'), findRichText: true),
      findsNothing,
    );
  });

  testWidgets('대출 수정도 남은 빚을 양수로 보여 준다', (tester) async {
    await _open(tester, edit: _loan, assets: const [_loan]);
    expect(fieldWithLabel(l.assetLoanRemainingLabel), findsOneWidget);
    expect(textOf(tester, l.assetLoanRemainingLabel), '3,000,000');
  });

  // 별칭은 Field 글자 수가 세고 30자에서 멈춘다.
  testWidgets('별칭은 30자에서 멈춘다', (tester) async {
    await _open(tester);
    await typeInto(tester, l.assetNickname, 'ㄱ' * 31);
    expect(textOf(tester, l.assetNickname).length, 30);
  });

  // 30자를 넘어 저장돼 있던 옛 별칭은 열자마자가 아니라 만졌을 때 알린다.
  testWidgets('넘게 저장된 옛 별칭은 고치면 알리고 저장이 막힌다', (tester) async {
    final longName = _existing.copyWith(assetName: 'ㄴ' * 31);
    final repo = await _open(tester, edit: longName, assets: [longName]);
    // 열자마자 빨갛게 하지 않는다
    expect(findRichPlain(l.nameTooLong(30)), findsNothing);
    await typeInto(tester, l.assetNickname, 'ㄴ' * 31);
    expect(findRichPlain(l.nameTooLong(30)), findsOneWidget);
    // 단추는 늘 켜 둔다 — 눌러도 요청은 안 나가고 별칭 칸으로 초점이 간다
    expect(
      tester.widget<PButton>(_submitButton(l.actionSave)).onPressed,
      isNotNull,
    );
    await _tapSubmit(tester, l.actionSave);
    expect(repo.captured, isNull);
    expect(
      tester.widget<TextField>(inputOf(l.assetNickname)).focusNode!.hasFocus,
      isTrue,
    );
  });

  testWidgets('이미 있는 별칭은 안내가 뜨고 저장이 막힌다', (tester) async {
    final repo = await _open(tester);
    await typeInto(tester, l.assetNickname, 'QA 주거래');
    expect(findRichPlain(l.assetNicknameDuplicate), findsOneWidget);
    // 단추는 켜져 있고, 눌러도 요청은 안 나간다
    expect(
      tester.widget<PButton>(_submitButton(l.calAdd)).onPressed,
      isNotNull,
    );
    await _tapSubmit(tester, l.calAdd);
    expect(repo.captured, isNull);
  });

  testWidgets('별칭은 필수다 — 비우고 누르면 안내가 뜨고 요청은 안 나간다(자동 이름은 없다)', (tester) async {
    final repo = await _open(tester);
    expect(findRichPlain(l.assetNicknameRequired), findsNothing);
    await _tapSubmit(tester, l.calAdd);
    expect(findRichPlain(l.assetNicknameRequired), findsOneWidget);
    expect(repo.captured, isNull, reason: '"{기관} {종류}" 자동 이름으로 저장되면 안 된다');
    // 쓰면 저장된다.
    await typeInto(tester, l.assetNickname, 'QA 생활비');
    await _tapSubmit(tester, l.calAdd);
    expect(repo.captured?['assetName'], 'QA 생활비');
  });

  testWidgets('편집에서 별칭을 비우고 저장해도 막힌다', (tester) async {
    final repo = await _open(tester, edit: _existing);
    await typeInto(tester, l.assetNickname, '');
    await _tapSubmit(tester, l.actionSave);
    expect(findRichPlain(l.assetNicknameRequired), findsOneWidget);
    expect(repo.captured, isNull);
  });

  // 기관이 없는 자산(현금 · 대출)을 고치면 첫 은행이 채워져 저장되던 결함 — 비워 둔 채 두고 키도 안 보낸다.
  testWidgets('기관이 없는 자산을 고치면 기관을 비워 두고 institution 을 안 보낸다', (tester) async {
    const cash = Asset(
      rowId: 12,
      assetName: '지갑',
      assetType: 'CASH',
      balance: 30000,
      isIncludedInTotal: 'Y',
    );
    final repo = await _open(tester, edit: cash, assets: const [cash]);
    expect(findPlain(l.assetInstitutionPlaceholder), findsWidgets);
    expect(findPlain(bankEntries.first.name), findsNothing);
    await _tapSubmit(tester, l.actionSave);
    expect(repo.captured, isNotNull);
    expect(repo.captured?['institution'], isNull);
  });

  testWidgets('기관이 있는 자산은 그대로 싣고, 새 자산은 첫 은행이 기본이다', (tester) async {
    final last = bankEntries.last.name;
    final withBank = Asset(
      rowId: 13,
      assetName: '주거래',
      assetType: 'BANK_ACCOUNT',
      balance: 1000,
      institution: last,
      isIncludedInTotal: 'Y',
    );
    final edit = await _open(tester, edit: withBank, assets: [withBank]);
    await _tapSubmit(tester, l.actionSave);
    expect(edit.captured?['institution'], last);
  });

  testWidgets('목록에 없는 기관 이름의 자산을 고치면 칸에 그 이름이 보이고 이름만 고쳐도 기관이 그대로다', (
    tester,
  ) async {
    const odd = Asset(
      rowId: 15,
      assetName: '옛 계좌',
      assetType: 'BANK_ACCOUNT',
      balance: 1000,
      institution: '목록에 없는 은행',
      isIncludedInTotal: 'Y',
    );
    final repo = await _open(tester, edit: odd, assets: const [odd]);
    expect(findPlain('목록에 없는 은행'), findsOneWidget);
    expect(findPlain(bankEntries.first.name), findsNothing);
    await typeInto(tester, l.assetNickname, '옛 계좌 2');
    await _tapSubmit(tester, l.actionSave);
    expect(repo.captured?['assetName'], '옛 계좌 2');
    expect(repo.captured?['institution'], '목록에 없는 은행');
  });

  testWidgets('새 자산의 기관 기본값은 첫 은행이다', (tester) async {
    final repo = await _open(tester);
    await typeInto(tester, l.assetNickname, 'QA 새 계좌');
    await _tapSubmit(tester, l.calAdd);
    expect(repo.captured?['institution'], bankEntries.first.name);
  });

  // 메모를 지우고 저장하면 **지워져야** 한다. 종전엔 null 인 칸을 키째 빼서
  // 서버가 옛 메모를 지켰다(QA #99).
  testWidgets('편집에서 메모를 지우고 저장하면 명시적 null 로 실린다', (tester) async {
    final repo = await _open(
      tester,
      edit: _withMemo,
      assets: const [_existing, _withMemo],
    );
    // 메모 칸에 기존 값이 실려 있다.
    expect(textOf(tester, l.assetMemo), '110-123-456789');
    await typeInto(tester, l.assetMemo, '');
    await _tapSubmit(tester, l.actionSave);

    final memo = repo.captured?['memo'] as Patch<String>;
    expect(memo.present, isTrue, reason: '메모 키가 빠지면 옛 메모가 그대로 남는다');
    expect(memo.value, isNull);
  });

  // 메모 칸은 하나다(Q1 결정 A) — 추가에서도 보이고, 적은 글이 그대로 메모로 저장된다.
  testWidgets('추가에서도 메모 칸이 하나 보이고 적은 글이 메모로 저장된다', (tester) async {
    final repo = await _open(tester);
    expect(fieldWithLabel(l.assetMemo), findsOneWidget);
    expect(fieldWithLabel('계좌번호'), findsNothing);
    await typeInto(tester, l.assetMemo, '110-***-123456');
    await typeInto(tester, l.assetNickname, 'QA 별칭');
    await _tapSubmit(tester, l.calAdd);
    expect(repo.captured?['memo'], '110-***-123456');
  });

  // 카드 전용 칸은 이 화면에 없다 — null 로 실으면 카드 화면에서 정해 둔
  // 결제일·결제 계좌가 계좌를 고칠 때마다 지워진다.
  testWidgets('이 화면에 없는 결제일·결제 계좌는 아예 안 실린다', (tester) async {
    final repo = await _open(tester, edit: _existing);
    await _tapSubmit(tester, l.actionSave);

    expect((repo.captured?['paymentDay'] as Patch<int>).present, isFalse);
    expect(
      (repo.captured?['paymentAssetRowId'] as Patch<int>).present,
      isFalse,
    );
  });

  testWidgets('편집에서 자기 별칭을 그대로 두면 중복이 아니다', (tester) async {
    final repo = await _open(tester, edit: _existing);
    await typeInto(tester, l.assetNickname, 'QA 주거래');
    expect(findRichPlain(l.assetNicknameDuplicate), findsNothing);
    await _tapSubmit(tester, l.actionSave);
    expect(repo.captured?['assetName'], 'QA 주거래');
  });

  testWidgets('마이너스 통장 약정 한도는 선택이고 사용액보다 작으면 안내만 한다(저장은 막지 않는다)', (
    tester,
  ) async {
    final repo = await _open(tester, kind: AssetKind.overdraft);
    expect(fieldWithLabel(l.assetOverdraftLimitLabel), findsOneWidget);
    await typeInto(tester, l.assetOverdraftUsedLabel, '300000');
    await typeInto(tester, l.assetOverdraftLimitLabel, '100000');
    expect(findRichPlain('한도보다'), findsOneWidget);
    await typeInto(tester, l.assetNickname, 'QA 별칭');
    await _tapSubmit(tester, l.calAdd);
    expect(repo.captured?['balance'], -300000);
    expect(repo.captured?['creditLimit'], 100000);
  });
}
