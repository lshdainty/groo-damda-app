// 자산별 금액 숨김 — **화면이 실제로 가리는가**, 그리고 문구가 화면 단위 토글과
// 섞이지 않는가.
//
// 화면 카드 가리기는 "이 화면의 이 묶음을 가린다" 는 사용자 설정이고, 자산 숨김은
// "이 자산은 늘 가린다" 는 자산의 속성이다. 두 축은 합집합이다.
//
// 예전엔 이 파일이 `MaskedAmount(force:)` 를 검사했는데, 그 위젯은 앱 화면에서
// 부르는 자리가 하나도 없다 — 통과해도 화면이 가린다는 근거가 아니었다(QA 22차 #6).
// 그래서 **실제 화면**(계좌·카드 관리)을 띄워 본다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/account_card_manage_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_en.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';
import '../../support/plain_text.dart';

const _shown = Asset(
  rowId: 8,
  assetName: '주거래 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
  isAmountHidden: 'N',
);

const _hiddenAsset = Asset(
  rowId: 9,
  assetName: '비상금 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 470000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
  isAmountHidden: 'Y',
);

Future<void> _pump(
  WidgetTester tester, {
  required List<Asset> assets,
  bool cardHidden = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => assets),
        hideCardProvider.overrideWith((ref, card) => cardHidden),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const AccountCardManageScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('관리 행 — 자산 플래그만으로 가려진다', () {
    // 화면 카드는 **안 가린 상태**다. 그래도 자산 플래그가 켜진 행만 가려져야 한다.
    testWidgets('숨긴 자산만 가려지고 옆 행은 그대로 보인다', (tester) async {
      await _pump(tester, assets: [_shown, _hiddenAsset]);

      expect(findPlain('1,200,000원'), findsOneWidget);
      expect(findPlain('470,000원'), findsNothing);
      expect(findPlain('••••'), findsOneWidget);
    });

    // 카드로 가려진 것과 이 자산이라서 가려진 것을 사용자가 구분할 수 있어야 한다 —
    // 안 그러면 화면 토글을 풀어도 왜 안 보이는지 알 수 없다.
    testWidgets('숨긴 행에만 배지가 붙는다', (tester) async {
      await _pump(tester, assets: [_shown, _hiddenAsset]);
      expect(
        findText(AppLocalizationsKo().assetAmountHiddenBadge),
        findsOneWidget,
      );
    });

    testWidgets('화면 카드를 가리면 둘 다 가려지지만 배지는 숨긴 행만', (tester) async {
      await _pump(tester, assets: [_shown, _hiddenAsset], cardHidden: true);

      expect(findPlain('1,200,000원'), findsNothing);
      // 줄 둘 + 묶음 합계 둘(계좌·예금, 카드)
      expect(findPlain('••••'), findsNWidgets(4));
      expect(
        findText(AppLocalizationsKo().assetAmountHiddenBadge),
        findsOneWidget,
      );
    });
  });

  group('문구', () {
    test('배지와 스위치 문구가 ko·en 양쪽에 있다', () {
      for (final l in [AppLocalizationsKo(), AppLocalizationsEn()]) {
        expect(l.assetAmountHiddenBadge, isNotEmpty);
        expect(l.assetHideThisAmount, isNotEmpty);
        expect(l.assetHideThisAmountDesc, isNotEmpty);
      }
    });

    // 합계는 이 값을 보지 않는다(사용자 결정) — 설명이 그걸 분명히 해야 한다.
    test('설명이 "합계는 그대로" 를 말한다', () {
      expect(AppLocalizationsKo().assetHideThisAmountDesc, contains('합계'));
      expect(AppLocalizationsEn().assetHideThisAmountDesc, contains('Totals'));
    });

    // 화면 단위 토글(`assetHideAmount`)과 뜻이 다르므로 키를 갈라 둔다. 이름은 둘 다 "금액 가리기" 로 맞췄으니(I-17 17, 사용자
    // 결정 10-23) 뜻은 설명이 가른다 — 이 자산 하나만 가리고 합계는 그대로 보인다.
    test('화면 단위 토글과 키가 갈리고 설명이 이 자산 하나를 말한다', () {
      final ko = AppLocalizationsKo();
      expect(ko.assetHideThisAmount, '금액 가리기');
      expect(ko.assetHideThisAmountDesc, contains('이 자산'));
    });
  });
}
