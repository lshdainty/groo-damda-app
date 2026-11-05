// 저축 목표 만든 뒤 첫 납입 실패 — 만들기는 1회, 시트는 닫히고, critical 스낵바, [다시 시도] 는 납입만 다시.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/features/saving_goal/data/saving_goal_repository.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/features/saving_goal/presentation/saving_goal_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

import '../../support/plain_text.dart';

class _Repo extends SavingGoalRepository {
  _Repo() : super(Dio());
  int creates = 0;
  final contributes = <int>[];
  final silent = <bool>[];

  @override
  Future<SavingGoal> create({
    required String title,
    String? description,
    required int targetAmount,
    String? deadlineDate,
    String? icon,
    String? color,
    int? linkedAssetRowId,
    bool silent = false,
  }) async {
    creates++;
    return SavingGoal(rowId: 9, title: title, targetAmount: targetAmount);
  }

  @override
  Future<SavingGoal> contribute(
    int id, {
    required int amount,
    String? note,
    bool silent = false,
  }) async {
    contributes.add(id);
    this.silent.add(silent);
    if (contributes.length == 1) {
      throw ApiException(code: 'X', message: '서버 원문');
    }
    return SavingGoal(rowId: id, title: 't', targetAmount: 1);
  }
}

void main() {
  testWidgets('만들기 성공 · 첫 납입 실패 → 닫힘 · 스낵바 · 다시 시도는 납입만', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    final repo = _Repo();
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingGoalListProvider.overrideWith(
            (ref) async => const <SavingGoal>[],
          ),
          savingGoalRepositoryProvider.overrideWith((ref) async => repo),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          builder: (c, child) => PSnackbarHost(closeLabel: '닫기', child: child!),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showSavingGoalEditDialog(ctx, edit: null),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '비상금');
    await tester.enterText(find.byType(TextField).at(1), '1000000');
    await tester.enterText(find.byType(TextField).at(2), '50000');
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(
            of: findPlain(l.savingGoalSubmitAdd),
            matching: find.byType(PButton),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(repo.creates, 1);
    expect(repo.contributes, [9]);
    expect(repo.silent, [true]);
    // 시트는 닫혔고 스낵바가 한 문장으로 말한다.
    expect(findPlain(l.savingGoalSubmitAdd), findsNothing);
    expect(l.savingGoalFirstContributeFailed, '목표는 만들었지만 첫 납입을 기록하지 못했어요.');
    expect(findPlain(l.savingGoalFirstContributeFailed), findsOneWidget);
    expect(find.textContaining('서버 원문'), findsNothing);

    await tester.tap(findPlain(l.actionRetry));
    await tester.pumpAndSettle();
    expect(repo.creates, 1, reason: '만들기를 다시 부르면 같은 목표가 또 생긴다');
    expect(repo.contributes, [9, 9]);
  });
}
