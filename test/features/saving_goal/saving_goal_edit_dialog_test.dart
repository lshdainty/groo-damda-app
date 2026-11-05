// 저축 목표 폼(I-19 D) — 이름 정책 · 누를 때 검증 · 색 · 목표일 · 닫기 확인.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/features/saving_goal/data/saving_goal_repository.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/features/saving_goal/presentation/saving_goal_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

const _existing = SavingGoal(
  rowId: 1,
  title: '비상금',
  targetAmount: 1000000,
  color: '#2c70bf',
);

class _FakeRepo extends SavingGoalRepository {
  _FakeRepo() : super(Dio());
  final calls = <String>[];
  Map<String, Object?> last = {};

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
    calls.add('create');
    last = {
      'title': title,
      'targetAmount': targetAmount,
      'deadlineDate': deadlineDate,
      'icon': icon,
      'color': color,
    };
    return SavingGoal(rowId: 9, title: title, targetAmount: targetAmount);
  }

  @override
  Future<SavingGoal> update({
    required int id,
    required String title,
    String? description,
    required int targetAmount,
    Patch<String> deadlineDate = const Patch.keep(),
    String? icon,
    String? color,
    int? linkedAssetRowId,
    bool silent = false,
  }) async {
    calls.add('update');
    last = {
      'title': title,
      'targetAmount': targetAmount,
      'deadline': deadlineDate.present ? deadlineDate.value : 'keep',
      'icon': icon,
      'color': color,
    };
    return SavingGoal(rowId: id, title: title, targetAmount: targetAmount);
  }

  @override
  Future<SavingGoal> contribute(
    int id, {
    required int amount,
    String? note,
    bool silent = false,
  }) async {
    calls.add('contribute:$amount');
    return _existing;
  }
}

String _plain(String s) => s
    .replaceAll('\u2060', '')
    .replaceAll('\u200B', '')
    .replaceAll('\uFFFC', '');

Finder _t(String s) => find.byWidgetPredicate(
  (w) => w is Text && _plain(w.data ?? w.textSpan?.toPlainText() ?? '') == s,
  description: 'Text "$s"',
);

String _text(WidgetTester t, int i) =>
    t.widget<TextField>(_inputs().at(i)).controller!.text;

Finder _inputs() => find.byType(TextField);

Future<_FakeRepo> _open(
  WidgetTester tester, {
  SavingGoal? edit,
  List<SavingGoal> existing = const [_existing],
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final repo = _FakeRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        savingGoalListProvider.overrideWith((ref) async => existing),
        savingGoalRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Consumer(
            builder: (ctx, ref, _) {
              ref.watch(savingGoalListProvider);
              return TextButton(
                onPressed: () => showSavingGoalEditDialog(ctx, edit: edit),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _press(WidgetTester tester, String label) async {
  await tester.tap(
    find.ancestor(of: _t(label), matching: find.byType(PButton)).last,
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('이름 카운터가 0/12 로 시작하고 목표일 이름 · 예시 글이 바뀌었다', (tester) async {
    await _open(tester);
    expect(_t('0/12'), findsOneWidget);
    expect(_t('예: 유럽 여행'), findsOneWidget);
    expect(_t('목표일'), findsOneWidget);
    expect(_t('없음'), findsOneWidget);
    // 미리보기 카드는 없다
    expect(_t('선택'), findsOneWidget);
  });

  testWidgets('이름 입력은 12자에서 멈춘다', (tester) async {
    await _open(tester);
    await tester.enterText(_inputs().at(0), 'ㄱ' * 13);
    await tester.pumpAndSettle();
    expect(_t('12/12'), findsOneWidget);
  });

  testWidgets('빈 채 [추가] 를 누르면 칸마다가 아니라 빠진 칸 아래에 오류 · 요청 0', (tester) async {
    final repo = await _open(tester);
    await _press(tester, l.savingGoalSubmitAdd);
    expect(_t(l.savingGoalErrName), findsOneWidget);
    expect(_t(l.savingGoalErrAmount), findsOneWidget);
    expect(repo.calls, isEmpty);
    // 버튼은 꺼지지 않는다
    expect(
      tester
          .widget<PButton>(
            find
                .ancestor(
                  of: _t(l.savingGoalSubmitAdd),
                  matching: find.byType(PButton),
                )
                .last,
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('같은 이름은 누를 때 오류가 난다', (tester) async {
    final repo = await _open(tester);
    await tester.enterText(_inputs().at(0), '비상금');
    await tester.enterText(_inputs().at(1), '1000');
    await tester.pumpAndSettle();
    expect(_t(l.savingGoalNameDuplicate), findsNothing);
    await _press(tester, l.savingGoalSubmitAdd);
    expect(_t(l.savingGoalNameDuplicate), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('현재 > 목표 는 현재 칸 아래에 말이 나온다', (tester) async {
    final repo = await _open(tester);
    await tester.enterText(_inputs().at(0), '여행');
    await tester.enterText(_inputs().at(1), '1000');
    await tester.enterText(_inputs().at(2), '2000');
    await _press(tester, l.savingGoalSubmitAdd);
    expect(_t(l.savingGoalErrCurrentExceeds), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('금액 칸에 쓰는 동안 쉼표가 찍히고 저장 본문은 숫자다', (tester) async {
    final repo = await _open(tester);
    await tester.enterText(_inputs().at(0), '여행');
    await tester.enterText(_inputs().at(1), '1234567');
    await tester.pumpAndSettle();
    expect(_text(tester, 1), '1,234,567');
    await _press(tester, l.savingGoalSubmitAdd);
    expect(repo.calls, ['create']);
    expect(repo.last['targetAmount'], 1234567);
    expect(repo.last['deadlineDate'], isNull);
    expect(repo.last['icon'], 'piggy-bank');
    // 같은 목록이 파랑을 쓰고 있으니 쓰지 않은 첫 색(파랑 → 초록)은 초록
    expect(repo.last['color'], '#2d8060');
  });

  testWidgets('자기 이름을 그대로 두면 중복이 아니고, 이름만 고쳐도 색은 그대로', (tester) async {
    const foreign = SavingGoal(
      rowId: 2,
      title: '가져온 목표',
      targetAmount: 500000,
      color: '#9e9e9e',
      icon: '🎯',
    );
    final repo = await _open(tester, edit: foreign, existing: [foreign]);
    expect(_t(l.dsColorCurrent), findsOneWidget);
    expect(_t(l.dsIconCurrent), findsOneWidget);
    await tester.enterText(_inputs().at(0), '가져온 목표2');
    await _press(tester, l.actionSave);
    expect(repo.calls, ['update']);
    expect(repo.last['color'], '#9e9e9e');
    expect(repo.last['icon'], '🎯');
    expect(repo.last['deadline'], isNull);
  });

  testWidgets('수정 — 목표일을 지우면 지움 값이 가고 지우기 버튼은 값이 있을 때만', (tester) async {
    const dated = SavingGoal(
      rowId: 3,
      title: '여행',
      targetAmount: 500000,
      deadlineDate: '2035-12-31',
      color: '#2c70bf',
    );
    final repo = await _open(tester, edit: dated, existing: [dated]);
    expect(_t('2035년 12월 31일'), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.circleX));
    await tester.pumpAndSettle();
    expect(_t('없음'), findsOneWidget);
    expect(find.byIcon(LucideIcons.circleX), findsNothing);
    await _press(tester, l.actionSave);
    expect(repo.last['deadline'], isNull);
    expect(repo.calls.first, 'update');
  });

  testWidgets('목표일은 2031년 뒤도 고를 수 있다', (tester) async {
    final repo = await _open(tester);
    await tester.enterText(_inputs().at(0), '여행');
    await tester.enterText(_inputs().at(1), '1000');
    await tester.tap(_t('없음'));
    await tester.pumpAndSettle();
    // 달력 연 · 월 제목을 눌러 휠로 가는 대신 이전/다음 달 이동 없이 오늘 달의 날을 하나 고른다
    await tester.tap(find.bySemanticsLabel(RegExp(r'^\d+년 \d+월 15일')).first);
    await tester.pumpAndSettle();
    await tester.tap(_t(l.actionDone));
    await tester.pumpAndSettle();
    expect(_t('없음'), findsNothing);
    await _press(tester, l.savingGoalSubmitAdd);
    expect(repo.last['deadlineDate'], isNotNull);
  });

  testWidgets('2030년 뒤의 날도 고를 수 있다 — 2035년 12월 15일', (tester) async {
    final handle = tester.ensureSemantics();
    const dated = SavingGoal(
      rowId: 3,
      title: '여행',
      targetAmount: 500000,
      deadlineDate: '2035-12-31',
      color: '#2c70bf',
    );
    final repo = await _open(tester, edit: dated, existing: [dated]);
    await tester.tap(_t('2035년 12월 31일'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^2035년 12월 15일')).first);
    await tester.pumpAndSettle();
    await tester.tap(_t(l.actionDone));
    await tester.pumpAndSettle();
    expect(_t('2035년 12월 15일'), findsOneWidget);
    await _press(tester, l.actionSave);
    expect(repo.calls.first, 'update');
    handle.dispose();
  });

  testWidgets('저장된 색이 없던 목표는 안 쓴 첫 색이 골라진 채 열린다', (tester) async {
    const noColor = SavingGoal(rowId: 4, title: '색 없음', targetAmount: 1000);
    final repo = await _open(
      tester,
      edit: noColor,
      existing: [_existing, noColor],
    );
    // 목록이 파랑을 쓰고 있으니 초록
    expect(_t(l.dsColorGreen), findsOneWidget);
    await _press(tester, l.actionSave);
    expect(repo.last['color'], '#2d8060');
  });

  testWidgets('12자 넘게 저장된 옛 이름은 열 때는 그대로, 누를 때 목표 이름 글로 알린다', (tester) async {
    const long = SavingGoal(
      rowId: 5,
      title: '가나다라마바사아자차카타파',
      targetAmount: 1000,
      color: '#2c70bf',
    );
    final repo = await _open(tester, edit: long, existing: [long]);
    expect(_text(tester, 0), '가나다라마바사아자차카타파');
    expect(_t(l.savingGoalErrNameTooLong(12)), findsNothing);
    await _press(tester, l.actionSave);
    expect(_t('목표 이름은 12자 이내로 입력해주세요.'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('바뀐 채 닫으면 확인창이 뜨고 계속 작성하면 값이 남는다', (tester) async {
    await _open(tester);
    await tester.enterText(_inputs().at(0), '여행');
    await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
    await tester.pumpAndSettle();
    expect(_t(l.sheetLeaveTitle), findsOneWidget);
    await tester.tap(_t(l.sheetLeaveStay));
    await tester.pumpAndSettle();
    expect(_text(tester, 0), '여행');
  });

  testWidgets('안 바뀐 채 닫으면 묻지 않는다', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
    await tester.pumpAndSettle();
    expect(_t(l.sheetLeaveTitle), findsNothing);
    expect(_t(l.savingGoalAdd), findsNothing);
  });
}
