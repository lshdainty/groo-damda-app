import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/core/storage/prefs_provider.dart';

import 'package:groo_damda_app/app/app.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_summary.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'support/plain_text.dart';

void main() {
  // 라벨을 한글로 검증하므로 로케일을 못 박는다. 안 그러면 테스트 환경(en)을 따라가
  // 'Home' 이 렌더되고 '홈' 을 못 찾는다 — i18n 도입 뒤 이 테스트가 깨져 있던 이유다.
  setUp(() {
    SharedPreferences.setMockInitialValues({PrefsKeys.locale: 'ko'});
  });

  testWidgets('logged-in user lands on home shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_FakeAuth.new),
          // 테스트는 백엔드를 띄우지 않으므로 데이터 provider 를 빈 값으로 직접 채움
          categoriesProvider.overrideWith(
            (_) => Future.value(<ExpenseCategory>[]),
          ),
          assetsProvider.overrideWith((_) => Future.value(<Asset>[])),
          assetSummaryProvider.overrideWith(
            (_, _) => Future.value(const AssetSummary()),
          ),
          monthExpensesProvider.overrideWith(
            (_, _) => Future.value(<Expense>[]),
          ),
        ],
        child: const GrooDamdaApp(),
      ),
    );
    // pumpAndSettle 은 못 쓴다 — 로딩 중 스켈레톤이 `..repeat()` 무한 애니메이션이라
    // 영원히 안 끝난다. 프레임을 몇 번 밀어 provider 를 해소시킨다.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(findText('홈'), findsAtLeastNWidgets(1));
    expect(findText('가계부'), findsAtLeastNWidgets(1));
    // 하단 탭은 홈·가계부·캘린더·전체 — '통계' 는 예전 구성이라 더는 없다.
    expect(findText('캘린더'), findsAtLeastNWidgets(1));
    expect(findText('전체'), findsAtLeastNWidgets(1));
    // Dashboard hero
    expect(findPlain('순자산'), findsOneWidget);
    expect(findPlain('자산'), findsAtLeastNWidgets(1));
  });
}

class _FakeAuth extends AuthNotifier {
  @override
  Future<User?> build() async => const User(
    rowId: 1,
    userId: 'tester',
    userName: 'Tester',
    userEmail: 'tester@example.com',
  );
}
