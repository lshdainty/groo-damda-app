// 금액 숨김을 **푸는** 저장은 본인 확인을 거친다 (QA 22차 #2).
//
// 앱은 자산 상세에 이 토글이 없어(사용자 결정) 수정 폼이 **유일한 해제 경로**다.
// 확인이 없으면 "풀 때는 본인 확인" 규칙 자체가 없는 것과 같다 — 스위치를 끄고
// 저장만 누르면 그냥 풀렸다.
//
// I-17 21 부터 확인은 폼 위에 따로 띄우는 확인창이 아니라 **같은 시트의 다음 단계**("금액 보기 인증")다. 앱은 생체인증이 먼저고,
// 안 되면 그 단계로 바뀐다. 여기서 잠그는 건 — 확인이 끝나기 전에는 저장 요청이 **나가지 않는다**, ← 면 저장도 안 하고 체크는 끈 채로
// 남는다, 틀린 비밀번호는 서버 글 없이 칸 아래에 알린다, 맞으면 같은 값으로 저장이 이어진다.
//
// 폼이 이 값을 싣는지도 함께 잠근다. 서버 PUT 은 "키가 없으면 유지" 라 폼이 칸을
// 빼먹어도 겉으론 아무 일도 안 나지만, **껐는데 안 꺼지는** 쪽은 조용히 실패한다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/auth_repository.dart';
import 'package:groo_damda_app/core/lock/app_lock.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

import '../../support/plain_text.dart';
import 'asset_form_test_helpers.dart';

const _hidden = Asset(
  rowId: 8,
  assetName: 'QA 비상금',
  assetType: 'BANK_ACCOUNT',
  balance: 470000,
  institution: 'KB국민',
  isIncludedInTotal: 'Y',
  isAmountHidden: 'Y',
);

const _shown = Asset(
  rowId: 9,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: 'KB국민',
  isIncludedInTotal: 'Y',
  isAmountHidden: 'N',
);

const _hiddenCard = Asset(
  rowId: 10,
  assetName: 'QA 비밀 카드',
  assetType: 'CHECK_CARD',
  balance: 0,
  institution: '가람카드',
  isIncludedInTotal: 'Y',
  isAmountHidden: 'Y',
);

const _hiddenInvest = Asset(
  rowId: 11,
  assetName: 'QA 비밀 투자',
  assetType: 'INVESTMENT',
  balance: 100,
  institution: '삼성증권',
  isIncludedInTotal: 'Y',
  isAmountHidden: 'Y',
);

class _CapturingRepo extends AssetRepository {
  _CapturingRepo() : super(Dio());

  String? updatedHidden;
  bool updateCalled = false;

  Asset _fake() => const Asset(rowId: 1, assetName: 'x', assetType: 'CASH');

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
    updateCalled = true;
    updatedHidden = isAmountHidden;
    return _fake();
  }
}

/// 비밀번호 검증 — [wrong] 이 있으면 그 코드의 오류(서버 글은 일부러 눈에 띄게).
class _FakeAuthRepo extends AuthRepository {
  _FakeAuthRepo() : super(Dio());

  String? wrongCode;
  final tried = <String>[];

  @override
  Future<void> verifyPassword(String password) async {
    tried.add(password);
    final code = wrongCode;
    if (code != null) {
      throw ApiException(code: code, message: 'RAW_SERVER_TEXT_9137');
    }
  }
}

/// OS 프롬프트 없이 정해진 결과만 돌려주는 가짜 인증.
class _FakeBio extends AppLockAuth {
  _FakeBio(this.result) : super(LocalAuthentication());

  final AppLockAuthResult result;
  int calls = 0;

  @override
  Future<AppLockAuthResult> authenticate({
    required String reason,
    required String signInTitle,
    required String cancelLabel,
  }) async {
    calls++;
    return result;
  }
}

typedef _Host = ({_CapturingRepo repo, _FakeAuthRepo auth, _FakeBio? bio});

Future<_Host> _open(
  WidgetTester tester,
  Asset edit, {
  AppLockAuthResult? biometric,
}) async {
  final repo = _CapturingRepo();
  final auth = _FakeAuthRepo();
  final bio = biometric == null ? null : _FakeBio(biometric);
  // 폼 본문은 스크롤이다 — 기본 800x600 에서는 체크 줄이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => [edit]),
        assetRepositoryProvider.overrideWith((ref) async => repo),
        authRepositoryProvider.overrideWith((ref) async => auth),
        if (bio != null) ...[
          appLockAuthProvider.overrideWithValue(bio),
          appLockEnabledProvider.overrideWithValue(true),
        ],
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAssetEditForm(ctx, edit),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return (repo: repo, auth: auth, bio: bio);
}

/// "금액 가리기" 체크 줄 — 줄 어디를 눌러도 바뀐다.
Future<void> _toggleHide(WidgetTester tester) async {
  await tester.tap(findPlain(AppLocalizationsKo().assetHideThisAmount));
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester, String label) async {
  await tester.tap(buttonLabeled(label));
  await tester.pumpAndSettle();
}

Finder get _sheets => find.byKey(const ValueKey('p-bottom-sheet-root'));

String _title(WidgetTester tester) => plainOf(
  tester
      .widget<Text>(find.byKey(const ValueKey('p-bottom-sheet-title')).last)
      .data!,
);

Future<void> _enterPassword(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  group('끄고 저장 — 같은 시트의 "금액 보기 인증" 단계', () {
    testWidgets('앱 잠금이 꺼져 있으면 시트가 인증 단계로 바뀐다 — 확인창을 따로 띄우지 않고 요청도 안 나간다', (
      tester,
    ) async {
      final h = await _open(tester, _hidden);
      await _toggleHide(tester);
      await _tapSave(tester, l.actionSave);

      expect(_title(tester), l.unlockTitle);
      expect(_sheets, findsOneWidget, reason: '단계가 바뀌어도 표면은 하나다');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const ValueKey('alert-dialog-title')), findsNothing);
      expect(h.repo.updateCalled, isFalse);
      // 머리에 ←, 바닥에 [금액 보기]
      expect(find.byKey(const ValueKey('p-bottom-sheet-back')), findsOneWidget);
      expect(buttonLabeled(l.unlockViewAmounts), findsOneWidget);
    });

    testWidgets('← 는 저장 없이 2단계로 — 체크는 끈 채로 남는다', (tester) async {
      final h = await _open(tester, _hidden);
      await _toggleHide(tester);
      await _tapSave(tester, l.actionSave);

      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-back')));
      await tester.pumpAndSettle();

      expect(_title(tester), l.assetFormTitleEdit(l.assetTypeBankAccount));
      expect(h.repo.updateCalled, isFalse);
      // 체크를 끈 채라 다시 저장하면 또 인증 단계다
      await _tapSave(tester, l.actionSave);
      expect(_title(tester), l.unlockTitle);
    });

    testWidgets('맞는 비밀번호면 같은 값으로 저장이 이어지고 시트가 닫힌다', (tester) async {
      final h = await _open(tester, _hidden);
      await _toggleHide(tester);
      await _tapSave(tester, l.actionSave);

      await _enterPassword(tester, 'correct-horse');
      await tester.tap(buttonLabeled(l.unlockViewAmounts));
      await tester.pumpAndSettle();

      expect(h.auth.tried, ['correct-horse']);
      expect(h.repo.updateCalled, isTrue);
      expect(h.repo.updatedHidden, 'N');
      expect(_sheets, findsNothing);
    });

    testWidgets('틀린 비밀번호는 서버 글 없이 칸 아래에 알리고 칸을 비운다', (tester) async {
      final h = await _open(tester, _hidden);
      h.auth.wrongCode = 'USER_004';
      await _toggleHide(tester);
      await _tapSave(tester, l.actionSave);

      await _enterPassword(tester, 'nope');
      await tester.tap(buttonLabeled(l.unlockViewAmounts));
      await tester.pumpAndSettle();

      expect(findRichPlain(l.unlockMismatch), findsOneWidget);
      expect(findTextContaining('RAW_SERVER_TEXT_9137'), findsNothing);
      expect(h.repo.updateCalled, isFalse);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      // 다시 치기 시작하면 오류가 걷힌다
      await _enterPassword(tester, 'x');
      expect(findRichPlain(l.unlockMismatch), findsNothing);
    });

    testWidgets('그 밖의 실패는 다시 시도를 부탁한다 — 서버 글은 안 낸다', (tester) async {
      final h = await _open(tester, _hidden);
      h.auth.wrongCode = 'COMMON_500';
      await _toggleHide(tester);
      await _tapSave(tester, l.actionSave);

      await _enterPassword(tester, 'whatever');
      await tester.tap(buttonLabeled(l.unlockViewAmounts));
      await tester.pumpAndSettle();

      expect(findRichPlain(l.unlockVerifyFailed), findsOneWidget);
      expect(findTextContaining('RAW_SERVER_TEXT_9137'), findsNothing);
      expect(h.repo.updateCalled, isFalse);
    });

    testWidgets('비밀번호를 안 쓰고 눌러도 단추는 켜져 있고 칸 아래에 알린다', (tester) async {
      final h = await _open(tester, _hidden);
      await _toggleHide(tester);
      await _tapSave(tester, l.actionSave);
      expect(
        tester.widget<PButton>(buttonLabeled(l.unlockViewAmounts)).onPressed,
        isNotNull,
      );
      await tester.tap(buttonLabeled(l.unlockViewAmounts));
      await tester.pumpAndSettle();
      expect(findRichPlain(l.unlockPasswordRequired), findsOneWidget);
      expect(h.auth.tried, isEmpty);
      expect(h.repo.updateCalled, isFalse);
    });
  });

  group('앱 — 생체인증이 먼저', () {
    testWidgets('성공하면 단계 없이 바로 저장된다', (tester) async {
      final h = await _open(
        tester,
        _hidden,
        biometric: AppLockAuthResult.success,
      );
      await _toggleHide(tester);
      await _tapSave(tester, l.actionSave);

      expect(h.bio!.calls, 1);
      expect(h.repo.updateCalled, isTrue);
      expect(h.repo.updatedHidden, 'N');
      expect(_sheets, findsNothing);
    });

    testWidgets('취소 · 실패면 같은 시트의 비밀번호 단계로 물러선다', (tester) async {
      final h = await _open(
        tester,
        _hidden,
        biometric: AppLockAuthResult.failure,
      );
      await _toggleHide(tester);
      await _tapSave(tester, l.actionSave);

      expect(h.bio!.calls, 1);
      expect(_title(tester), l.unlockTitle);
      expect(h.repo.updateCalled, isFalse);
    });

    testWidgets('인증 수단이 없는 기기도 비밀번호 단계로 물러선다', (tester) async {
      await _open(tester, _hidden, biometric: AppLockAuthResult.unavailable);
      await _toggleHide(tester);
      await _tapSave(tester, l.actionSave);
      expect(_title(tester), l.unlockTitle);
    });
  });

  // 세 폼이 같은 길을 쓴다 — 계좌 하나만 잠그면 카드 · 투자 폼에서 규칙이 무력해진다(메모리 desk-asset-amount-hidden)
  for (final (name, asset) in [('카드', _hiddenCard), ('투자', _hiddenInvest)]) {
    testWidgets('$name 폼도 끄고 저장하면 같은 시트의 인증 단계로 바뀌고 요청이 안 나간다', (tester) async {
      final h = await _open(tester, asset);
      await _toggleHide(tester);
      await _tapSave(tester, l.actionSave);
      expect(_title(tester), l.unlockTitle);
      expect(h.repo.updateCalled, isFalse);

      await _enterPassword(tester, 'pw');
      await tester.tap(buttonLabeled(l.unlockViewAmounts));
      await tester.pumpAndSettle();
      expect(h.repo.updateCalled, isTrue);
      expect(h.repo.updatedHidden, 'N');
    });
  }

  testWidgets('켜는 쪽은 확인 없이 Y 로 저장된다', (tester) async {
    final h = await _open(tester, _shown);
    await _toggleHide(tester);
    await _tapSave(tester, l.actionSave);

    expect(findPlain(l.unlockTitle), findsNothing);
    expect(h.repo.updatedHidden, 'Y');
  });

  testWidgets('숨김을 안 건드린 저장은 묻지 않고 Y 를 그대로 싣는다', (tester) async {
    final h = await _open(tester, _hidden);
    await _tapSave(tester, l.actionSave);

    expect(findPlain(l.unlockTitle), findsNothing);
    expect(h.repo.updatedHidden, 'Y');
  });
}
