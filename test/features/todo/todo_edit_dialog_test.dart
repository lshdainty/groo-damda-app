// 할 일 편집 시트 — 태그 표기(QA #103·#105) + 하위 할 일이 사라진 자리(D5).
//
// ① 태그 없는 할 일을 '개인' 이라 부르지 않는다. 종전엔 편집기가 빈 `category` 를
//    '개인' 으로 채워 열었고, 제목만 고쳐 저장해도 그 이름이 실려 **서버가 '개인'
//    태그를 새로 만들었다**(`TodoServiceImpl.resolveCategoryTag`). 삭제 확인창은
//    "태그 없음으로 남아요" 라고 약속해 놓고 화면이 그 말을 어긴 상태였다.
// ② '태그 없음' 선택지가 없어 **한 번 붙은 태그를 앱에서 뗄 수 없었다.** 뗄 수
//    있으려면 키를 빼지 말고 명시적 null 을 실어야 한다(PUT 은 "키 없음=유지").
// ③ 하위 할 일 개념을 걷어냈다 — 이 시트의 하위 목록·빠른 추가가 통째로 없다.
//    부모를 실을 자리도 `TodoRepository.create` 에서 사라졌다.
//
// I-10 20 — 폼이 ds Bottom Sheet(입력 폼)로 옮겨졌다: 제목 · 마감일(Input Button) · 태그(Select) · 우선순위(Chip) · 메모.
// 새 할 일의 마감일은 오늘, 수정의 주 버튼은 "저장", 바뀐 채 닫으면 "작성한 내용이 사라져요" 를 묻는다.
//
// 에뮬레이터를 쓸 수 없는 환경이라(QA #23) 저장 페이로드를 위젯 테스트로 고정한다.
// 리포지토리 단위 검증은 `test/features/put_clear_payload_test.dart` 에 있고,
// 여기서는 **화면이 실제로 그 값을 넘기는지**를 본다. 메모 편집기 테스트
// (`test/features/memo/memo_edit_dialog_test.dart`)와 같은 모양이다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';
import 'package:groo_damda_app/features/todo/data/todo_repository.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/domain/todo_tag.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';

const _todo = Todo(rowId: 7, title: 'QA 할 일', category: '개인');
const _untagged = Todo(rowId: 8, title: '태그 없는 할 일');

TodoTag _tag(int rowId, String name) =>
    TodoTag(rowId: rowId, tagName: name, userRowId: 1);

/// update·create 로 넘어간 인자를 잡는 가짜 레포지토리.
class _CapturingRepo extends TodoRepository {
  _CapturingRepo() : super(Dio());

  Patch<String> category = const Patch.keep();
  Patch<String> dueDate = const Patch.keep();
  String? priority;
  String? title;
  bool created = false;
  String? createdCategory;
  String? createdDue;
  String? createdPriority;

  @override
  Future<Todo> update({
    required int id,
    required String title,
    Patch<String> content = const Patch.keep(),
    String? priority,
    Patch<String> category = const Patch.keep(),
    Patch<String> dueDate = const Patch.keep(),
    bool silent = false,
  }) async {
    this.title = title;
    this.category = category;
    this.dueDate = dueDate;
    this.priority = priority;
    return _todo;
  }

  @override
  Future<Todo> create({
    required String title,
    String? content,
    String? priority,
    String? category,
    String? dueDate,
    String? type,
    bool silent = false,
  }) async {
    created = true;
    createdCategory = category;
    createdDue = dueDate;
    createdPriority = priority;
    return _todo;
  }
}

/// ds 글은 낱말 단위 줄바꿈(U+2060 · U+200B)을 글자 사이에 넣는다 — 그 글자를 뺀 글로 찾는다.
String _plain(String s) => s.replaceAll('\u2060', '').replaceAll('\u200B', '');

Finder _t(String s) => find.byWidgetPredicate((w) {
  if (w is! Text) return false;
  return _plain(w.data ?? w.textSpan?.toPlainText() ?? '') == s;
});

Finder _titleField() => find.byType(PInput).first;

Finder _submitButton(String label) =>
    find.byWidgetPredicate((w) => w is PButton && w.label == label);

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 태그 select 를 펼친다 — 항목은 OverlayPortal 안에 뜬다.
Future<void> _openTagSelect(WidgetTester tester) async {
  await tester.tap(find.byType(PSelect<String>));
  await tester.pumpAndSettle();
}

Future<_CapturingRepo> _openEdit(
  WidgetTester tester, {
  Todo? edit = _todo,
  List<TodoTag> tags = const [],
  bool tagsFail = false,
}) async {
  final repo = _CapturingRepo();
  // 시트 본문이 세로로 길다 — 좁은 화면에서는 아래 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todoRepositoryProvider.overrideWith((ref) async => repo),
        todoTagListProvider.overrideWith(
          (ref) async => tagsFail ? throw Exception('할 일 태그 조회 실패') : tags,
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
              onPressed: () => showTodoEditDialog(ctx, edit: edit),
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

  group('태그 표기 (QA #103)', () {
    testWidgets('선택지가 서버 목록에서 온다 — 하드코딩 기본 태그는 없다', (tester) async {
      await _openEdit(
        tester,
        edit: _untagged,
        tags: [_tag(11, '업무'), _tag(12, '집안일')],
      );
      await _openTagSelect(tester);

      expect(_t('업무'), findsOneWidget);
      expect(_t('집안일'), findsOneWidget);
      // 이 계정에 없는 이름 — 뜨면 앱이 이름을 지어낸 것이다.
      expect(_t('개인'), findsNothing);
    });

    testWidgets('"태그 없음" 은 맨 앞 선택지다', (tester) async {
      await _openEdit(tester, edit: _untagged, tags: [_tag(11, '업무')]);
      await _openTagSelect(tester);

      final none = tester.getTopLeft(_t(l.todoTagNone).last).dy;
      final first = tester.getTopLeft(_t('업무')).dy;
      expect(none, lessThan(first));
    });

    testWidgets('서버에 없는 지금 태그도 남는다 — 편집하다 태그를 잃지 않는다', (tester) async {
      // 할 일은 '개인' 을 들고 있는데 계정 태그는 '업무' 뿐 (백필 전 옛 행).
      await _openEdit(tester, tags: [_tag(11, '업무')]);
      await _openTagSelect(tester);

      expect(_t('개인'), findsWidgets);
      expect(_t('업무'), findsOneWidget);
    });

    testWidgets('태그가 0개여도 select 가 비지 않고 어디서 만드는지 알린다', (tester) async {
      await _openEdit(tester, edit: _untagged);
      expect(_t(l.todoTagEmptyHint), findsOneWidget);
      await _openTagSelect(tester);

      expect(_t(l.todoTagNone), findsWidgets);
    });

    testWidgets('조회가 실패해도 죽지 않고 지금 태그를 지킨다', (tester) async {
      final repo = await _openEdit(tester, tagsFail: true);
      expect(tester.takeException(), isNull);

      await _openTagSelect(tester);
      expect(_t('개인'), findsWidgets);

      // 닫고 그대로 저장 — 조회 실패가 태그를 지우면 안 된다.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.category.present, isTrue);
      expect(repo.category.value, '개인');
    });

    testWidgets('"태그 없음" 을 고르면 category 가 명시적 null 로 실린다', (tester) async {
      final repo = await _openEdit(tester, tags: [_tag(11, '업무')]);
      await _openTagSelect(tester);

      await tester.tap(_t(l.todoTagNone).last);
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(
        repo.category.present,
        isTrue,
        reason: 'category 키가 빠지면 서버가 옛 태그를 지킨다 — 앱에서 태그를 못 뗀다',
      );
      expect(repo.category.value, isNull);
    });

    testWidgets('태그 없는 할 일을 그대로 저장해도 이름이 지어지지 않는다', (tester) async {
      // 옛 코드는 빈 category 를 '개인' 으로 채워 저장했다 — 서버가 그 이름의
      // 태그를 새로 만드는 경로다(QA #105).
      final repo = await _openEdit(
        tester,
        edit: _untagged,
        tags: [_tag(11, '업무')],
      );
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.category.present, isTrue);
      expect(repo.category.value, isNull);
    });

    testWidgets('새 할 일의 기본값도 태그 없음이다', (tester) async {
      final repo = await _openEdit(tester, edit: null, tags: [_tag(11, '업무')]);

      await tester.enterText(_titleField(), '새 할 일');
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created, isTrue);
      expect(repo.createdCategory, isNull);
    });
  });

  group('I-10 20 폼', () {
    testWidgets('새 할 일 — 마감일은 오늘 · 주 버튼은 "추가" · 우선순위는 보통', (tester) async {
      final repo = await _openEdit(tester, edit: null);

      expect(_t(l.todoAdd), findsOneWidget);
      expect(_submitButton(l.calAdd), findsOneWidget);
      expect(_submitButton(l.actionEdit), findsNothing);
      await tester.enterText(_titleField(), '오늘 낼 일');
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created, isTrue);
      expect(repo.createdDue, _ymd(DateTime.now()));
      expect(repo.createdPriority, 'MEDIUM');
    });

    testWidgets('고치는 폼의 주 버튼은 "저장" 이다 — "수정" 이 아니다', (tester) async {
      await _openEdit(tester);
      expect(_submitButton(l.actionSave), findsOneWidget);
      expect(_submitButton(l.actionEdit), findsNothing);
    });

    testWidgets('제목이 비면 저장이 막히고 칸 아래에 오류 글이 선다', (tester) async {
      final repo = await _openEdit(tester, edit: null);

      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created, isFalse);
      expect(_t('제목을 입력해주세요.'), findsOneWidget);
      // 글을 치면 오류가 걷힌다
      await tester.enterText(_titleField(), '가');
      await tester.pumpAndSettle();
      expect(_t('제목을 입력해주세요.'), findsNothing);
    });

    testWidgets('마감일을 지운 채 저장하면 dueDate 가 명시적 null 로 실린다 (QA #99)', (
      tester,
    ) async {
      final repo = await _openEdit(
        tester,
        edit: const Todo(rowId: 9, title: '기한 있음', dueDate: '2026-10-22'),
      );
      await tester.tap(find.bySemanticsLabel(l.todoDueClear));
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.dueDate.present, isTrue);
      expect(repo.dueDate.value, isNull);
    });

    testWidgets('우선순위는 칩 하나 고르기 — 중요를 고르면 HIGH 가 실린다', (tester) async {
      final repo = await _openEdit(tester);
      expect(find.byType(PChipRadio<String>), findsNWidgets(3));
      await tester.tap(_t(l.todoPriorityImportant));
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.priority, 'HIGH');
    });

    testWidgets('제목은 200자까지만 들어간다', (tester) async {
      await _openEdit(tester, edit: null);
      await tester.enterText(_titleField(), '가' * 250);
      await tester.pumpAndSettle();
      final field = tester.widget<PInput>(_titleField());
      expect(field.controller!.text.length, 200);
    });

    testWidgets('값이 바뀐 채 닫으면 "작성한 내용이 사라져요" 를 묻고, 안 바뀌었으면 바로 닫힌다', (
      tester,
    ) async {
      await _openEdit(tester, edit: null);
      // 안 바뀜 — 기본값(오늘 · 태그 없음 · 보통 · 빈 칸)
      await tester.tap(find.bySemanticsLabel(l.actionClose).first);
      await tester.pumpAndSettle();
      expect(_t(l.sheetLeaveTitle), findsNothing);
      expect(_t(l.todoAdd), findsNothing, reason: '시트가 닫혔다');

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(_titleField(), '쓰던 글');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l.actionClose).first);
      await tester.pumpAndSettle();
      expect(_t(l.sheetLeaveTitle), findsOneWidget);
      // 계속 작성
      await tester.tap(_t(l.sheetLeaveStay));
      await tester.pumpAndSettle();
      expect(_t(l.todoAdd), findsOneWidget);
    });

    testWidgets('바깥을 눌러도 입력 폼은 닫히지 않는다', (tester) async {
      await _openEdit(tester, edit: null);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(_t(l.todoAdd), findsOneWidget);
    });

    testWidgets('메모 편집 ↔ 미리보기는 Segmented Control 이다 (앱에만 있다)', (tester) async {
      await _openEdit(tester, edit: null);
      expect(_t(l.todoEditMode), findsOneWidget);
      expect(_t(l.todoPreview), findsOneWidget);
      await tester.tap(_t(l.todoPreview));
      await tester.pumpAndSettle();
      expect(_t(l.todoNoContent), findsOneWidget);
    });

    testWidgets('마감일 칸은 Input Button 이다 — 값은 "10월 22일 (목)" 꼴', (tester) async {
      await _openEdit(
        tester,
        edit: const Todo(rowId: 9, title: '기한', dueDate: '2026-10-22'),
      );
      expect(find.byType(PInputButton), findsOneWidget);
      expect(_t('10월 22일 (목)'), findsOneWidget);
    });
  });

  // 하위 할 일은 걷어냈다(D5). 시트를 열면 저장 버튼 하나만 있어야 한다 —
  // 하위 섹션이 살아 있으면 '추가' 버튼이 하나 더 떠서 여기서 걸린다.
  group('하위 할 일', () {
    testWidgets('편집 시트에 하위 목록도 빠른 추가도 없다', (tester) async {
      await _openEdit(tester);

      expect(
        _t(l.calAdd),
        findsNothing,
        reason: '하위 빠른 추가의 \'추가\' 버튼이 남아 있다 — 화면만 걷어야 개념이 사라진다',
      );
      expect(_submitButton(l.actionSave), findsOneWidget);
    });
  });
}
