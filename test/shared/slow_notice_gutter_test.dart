// 5초 "오래 걸림" 글의 자리 — skeleton.md "오래 걸림 글": 스켈레톤 영역이면 첫 스켈레톤 위에 왼쪽 맞춤으로 16 띄워 둔다.
//
// 화면 여백(좌우 24)을 스켈레톤 안에 넣어 두면 기다리는 영역의 왼쪽 끝은 화면 끝(0)이라, 영역이 붙이는 글만 여백 밖에 서
// 화면 왼쪽 끝에 붙는다(QA 2026-11-19 자산 탭). 여백은 기다리는 영역 밖에 둔다. 글자 크기와 상관없는 배치라 100% 로 본다.
// 각 영역이 화면의 첫 기다림이 되는 경우(그 영역이 글을 맡는다)를 본다 — 시험에는 알림이(PLoadingAnnouncer) 없어 모든 영역이
// 글을 보이므로, 그 영역의 글을 직접 찾는다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_parts.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/budget/domain/budget_compliance.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_day_group.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

import '../support/plain_text.dart';

const _slow = '평소보다 오래 걸리고 있어요';

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  // 5초가 지나 글이 붙는다(10초 실패 전)
  await tester.pump(const Duration(seconds: 6));
  expect(tester.takeException(), isNull);
}

/// [slow] 글이 화면 여백 24 에 서고, 바로 아래 첫 스켈레톤과 왼쪽이 같으며, 16 위에 있다.
void _expectAboveFirstSkeleton(WidgetTester tester, Finder slow) {
  final text = tester.getRect(slow);
  final region = find.ancestor(of: slow, matching: find.byType(PLoadingRegion));
  final first = tester.getRect(
    find.descendant(of: region.first, matching: find.byType(PSkeleton)).first,
  );
  expect(text.left, PSpacing.globalGutter, reason: '화면 여백 24 에 선다');
  expect(text.left, first.left, reason: '첫 스켈레톤과 같은 왼쪽');
  expect(
    first.top - text.bottom,
    closeTo(PSpacing.x4, 0.01),
    reason: '첫 스켈레톤 위로 16',
  );
}

void main() {
  for (final width in [320.0, 402.0]) {
    group('${width.round()} · 100%', () {
      testWidgets('자산 탭 요약 자리', (tester) async {
        await _pump(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: AssetSummarySection(
                loading: true,
                failed: false,
                assetsFailed: false,
                onRetry: () {},
                netWorth: 0,
                changeAmount: 0,
                changePercent: 0,
                hasLastMonth: false,
                accountsTotal: 0,
                investmentsTotal: 0,
                cardsTotal: 0,
                masked: false,
                onToggleMask: () {},
              ),
            ),
          ),
          width: width,
        );
        final slow = findPlainContaining(_slow);
        expect(slow, findsOneWidget);
        _expectAboveFirstSkeleton(tester, slow);
      });

      testWidgets('예산 탭 총 예산 자리(달 줄 아래 첫 기다림)', (tester) async {
        await _pump(
          tester,
          const BudgetScreen(),
          width: width,
          overrides: [
            hideCardProvider.overrideWith((ref, card) => false),
            monthBudgetsProvider.overrideWith(
              (ref, key) => Completer<List<Budget>>().future,
            ),
            rangeSummaryProvider.overrideWith(
              (ref, r) => Completer<RangeSummary>().future,
            ),
            categoriesProvider.overrideWith(
              (ref) async => const <ExpenseCategory>[],
            ),
            budgetComplianceProvider.overrideWith(
              (ref, months) => Completer<List<BudgetComplianceMonth>>().future,
            ),
          ],
        );
        final slows = findPlainContaining(_slow);
        expect(slows, findsWidgets);
        // 위에서 첫 글 — 총 예산 자리(화면의 첫 기다림)
        final all =
            [for (var i = 0; i < slows.evaluate().length; i++) slows.at(i)]
              ..sort(
                (a, b) =>
                    tester.getRect(a).top.compareTo(tester.getRect(b).top),
              );
        _expectAboveFirstSkeleton(tester, all.first);
      });

      testWidgets('가계부 목록 자리(날짜 묶음 스켈레톤)', (tester) async {
        await _pump(
          tester,
          Scaffold(body: SingleChildScrollView(child: ledgerListLoading())),
          width: width,
        );
        final slow = findPlainContaining(_slow);
        expect(slow, findsOneWidget);
        _expectAboveFirstSkeleton(tester, slow);
      });
    });
  }
}
