// 할 일 화면 시험이 함께 쓰는 하네스 — 실제 글꼴, 가짜 레포지토리, 이번 달 기준 지어낸 데이터.
// 고정한 오늘은 쓰지 않는다 — 날짜는 오늘 기준 상대(이번 달 안)로 만든다(고정한 오늘 + 벽시계 = 시한폭탄).
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/constellation/application/constellation_providers.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';
import 'package:groo_damda_app/features/todo/data/todo_repository.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/domain/todo_tag.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

export '../../support/real_fonts.dart' show loadRealFonts;

String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 이번 달 [day] 일(오늘보다 앞이어도 뒤여도 같은 달 안이다 — 28 일까지만 쓴다).
String thisMonth(int day) {
  final n = DateTime.now();
  return ymd(DateTime(n.year, n.month, day));
}

String today() => ymd(DateTime.now());

Todo todo(
  int id,
  String title, {
  String? due,
  String prio = 'MEDIUM',
  bool done = false,
  String? tag,
  String? content,
}) => Todo(
  rowId: id,
  type: 'TASK',
  title: title,
  priority: prio,
  status: done ? 'COMPLETED' : 'PENDING',
  dueDate: due,
  category: tag,
  content: content,
  completedAt: done ? '${today()}T08:00:00' : null,
);

TodoTag tagOf(int id, String name, {int usage = 0, String? color}) => TodoTag(
  rowId: id,
  userRowId: 1,
  tagName: name,
  color: color ?? '#3B82F6',
  usageCount: usage,
);

const _star =
    '{"pts":[[0.1,0.2],[0.3,0.35],[0.5,0.3],[0.7,0.5],[0.9,0.8]],"edges":[[0,1],[1,2],[2,3],[3,4]]}';

ConstellationToday constToday({bool collected = false, int points = 3}) =>
    ConstellationToday(
      constellation: const ConstellationInfo(
        rowId: 1,
        constellationKey: 'cassiopeia',
        name: '카시오페이아',
        nameEn: 'Cassiopeia',
        description: null,
        descriptionEn: null,
        colorKey: 'blue',
        starCount: 5,
        starMapRaw: _star,
        sortOrder: 1,
      ),
      points: points,
      goal: 5,
      collected: collected,
      todoPoints: 2,
      memoPoints: 1,
      streak: 12,
      guardCount: 1,
      totalCollected: 37,
    );

/// 완료 요청을 가로채는 가짜 레포지토리 — 응답 시점은 시험이 정한다.
class FakeTodoRepo extends TodoRepository {
  FakeTodoRepo() : super(Dio());

  /// 서버가 쥔 목록 — 완료 요청이 성공하면 상태가 바뀌고, 다시 받으면 그 값이 온다.
  List<Todo> todos = const [];

  /// null 이면 바로 답한다. 주면 그 Completer 가 끝날 때까지 기다린다.
  Completer<int>? gate;
  bool fail = false;
  final List<(int, String)> statusCalls = [];
  int listReads = 0;

  @override
  Future<int> setStatus(int id, String status) async {
    statusCalls.add((id, status));
    final g = gate;
    if (g != null) await g.future;
    if (fail) {
      throw ApiException(
        code: 'TODO_500',
        message: 'RAW_SERVER_TEXT_4471',
        statusCode: 500,
      );
    }
    todos = [
      for (final t in todos)
        if (t.rowId == id) t.copyWith(status: status) else t,
    ];
    return 0;
  }
}

/// 할 일 화면을 띄운다. 목록은 [todos] 그대로(서버 차례), 실패 · 불러오는 중은 [listError] · [hang].
Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
  Brightness brightness = Brightness.light,
  double textScale = 1,
  String locale = 'ko',
  Size size = const Size(360, 780),
  bool disableAnimations = false,
  bool settle = true,
  bool snackbarHost = false,
}) async {
  tester.view.physicalSize = Size(size.width * 2, size.height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides,
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? GrooTheme.dark()
            : GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          // 스낵바 호스트 — 앱 맨 위(app.dart)와 같은 자리(길잡이 바깥). 실패 알림 시험이 쓴다
          child: snackbarHost
              ? Material(
                  type: MaterialType.transparency,
                  child: PSnackbarHost(closeLabel: '닫기', child: child!),
                )
              : child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  if (settle) await tester.pump(const Duration(milliseconds: 400));
}

/// 할 일 목록 · 태그 · 별자리 · 가짜 레포지토리를 한 번에 꽂는다.
List<Override> todoOverrides({
  List<Todo> todos = const [],
  List<TodoTag> tags = const [],
  FakeTodoRepo? repo,
  bool listError = false,
  bool hang = false,
  ConstellationToday? sky,
  List<SkyDay> skyDays = const [],
  bool tagsError = false,
  bool skyError = false,
  bool skyDaysError = false,
}) {
  final r = repo ?? FakeTodoRepo();
  r.todos = todos;
  return [
    todoRepositoryProvider.overrideWith((ref) async => r),
    todoListProvider.overrideWith((ref, filter) async {
      r.listReads++;
      if (hang) return Completer<List<Todo>>().future;
      if (listError) {
        throw ApiException(
          code: 'TODO_500',
          message: 'RAW_SERVER_TEXT_9137',
          statusCode: 500,
        );
      }
      return r.todos;
    }),
    todoTagListProvider.overrideWith((ref) async {
      if (tagsError) {
        throw ApiException(
          code: 'TODO_500',
          message: 'RAW_SERVER_TEXT_9137',
          statusCode: 500,
        );
      }
      return tags;
    }),
    constellationTodayProvider.overrideWith(
      (ref) async => skyError ? throw 'x' : (sky ?? constToday()),
    ),
    constellationSkyProvider.overrideWith(
      (ref) async => skyDaysError ? throw 'x' : skyDays,
    ),
  ];
}
