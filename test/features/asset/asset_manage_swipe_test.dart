// 계좌·카드 관리 행의 스와이프 — 셰브론을 지우고 트레이를 붙였다.
//
// 눈으로 확인하기 어려운 조합이라 테스트로 고정한다. 특히 <b>안 일어나야 하는 일</b>:
// 삭제를 눌러도 확인 없이는 지워지지 않는다. 스와이프는 삭제까지의 거리를 줄이므로
// 줄인 만큼을 확인 단계로 되돌려 두지 않으면 밀다가 자산이 사라진다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/account_card_manage_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

const _account = Asset(
  rowId: 8,
  assetName: '주거래 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => [_account]),
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

/// 트레이가 열릴 만큼 왼쪽으로 민다.
Future<void> _swipeOpen(WidgetTester tester) async {
  await tester.drag(findPlain('주거래 통장'), const Offset(-250, 0));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('행 우측 셰브론이 없다 — 관리 줄 끝은 동작 자리(Q2 B)', (tester) async {
    await _pump(tester);
    expect(findPlain('주거래 통장'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
  });

  testWidgets('밀면 수정·삭제가 드러난다', (tester) async {
    await _pump(tester);

    await _swipeOpen(tester);

    expect(findText('수정'), findsOneWidget);
    expect(findText('삭제'), findsOneWidget);
  });

  testWidgets('삭제는 확인을 거친다 — 누른다고 바로 지워지지 않는다', (tester) async {
    await _pump(tester);
    await _swipeOpen(tester);

    await tester.tap(findText('삭제'));
    await tester.pumpAndSettle();

    // 확인 다이얼로그가 떴을 뿐 아직 아무것도 지워지지 않았다.
    // (repository 를 주지 않았으므로 실제로 호출됐다면 여기서 터진다)
    expect(
      findPlain(
        '"주거래 통장"을(를) 목록에서 삭제해요. 연결된 거래 내역은 그대로 남아요. 삭제한 자산은 되돌릴 수 없어요.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('확인창 문구가 상세 경로와 같다 — 제목은 액션 라벨이 아니다', (tester) async {
    await _pump(tester);
    await _swipeOpen(tester);

    await tester.tap(findText('삭제'));
    await tester.pumpAndSettle();

    // spec alert-dialog: 같은 동작이면 어디서 불렀든 제목·설명이 같다.
    // 상세에서 지울 때와 같은 '계좌 삭제' 여야 한다 — 예전엔 트레이 라벨을 그대로
    // 써서 스와이프만 '삭제' 로 떴다.
    expect(findPlain('계좌 삭제'), findsOneWidget);

    // 그리고 설명은 대상을 이름으로 짚는다 — 리스트에서 잘못된 행을 눌렀다면
    // 여기 말고는 알아챌 곳이 없다.
    expect(findPlainContaining('"주거래 통장"'), findsWidgets);
  });

  testWidgets('끝까지 밀어도 실행되지 않는다 — 트레이만 열린다', (tester) async {
    await _pump(tester);

    await tester.drag(findPlain('주거래 통장'), const Offset(-2000, 0));
    await tester.pumpAndSettle();

    // 확인 다이얼로그가 뜨지 않았다 = 삭제가 실행되지 않았다.
    expect(findText('계좌 삭제'), findsNothing);
    expect(findPlain('주거래 통장'), findsOneWidget);
  });
}
