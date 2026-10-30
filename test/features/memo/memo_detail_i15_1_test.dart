// 메모 상세(I-15 14 + 후속) — 읽기 시트: 머리 제목 = 메모 제목 · 메타 · 본문 · 머리 ⋮ [고정 / 고정 해제, 삭제] · 바닥 [수정] 하나 ·
// 삭제 확인은 ds Alert Dialog(웹 · #508 짝 표와 글자까지 같다) · 삭제 실패는 확인창을 닫고 스낵바 + [다시 시도].
// 시험은 작성만 했다(UI 이관이 끝날 때까지 돌리지 않는다).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/memo/application/memo_providers.dart';
import 'package:groo_damda_app/features/memo/data/memo_repository.dart';
import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_detail_dialog.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import '../../support/plain_text.dart';
import '../todo/todo_test_support.dart';

final _y = DateTime.now().year;

var _memos = <Memo>[];

Memo _memo({bool pinned = false, String? content = '본문 첫 줄\n둘째 줄'}) => Memo(
  rowId: 7,
  title: '앱 아이디어',
  content: content,
  tag: '아이디어',
  color: '#8b4dba',
  isPinned: pinned ? 'Y' : 'N',
  modifyAt: '$_y-10-18T11:00:00',
);

class _Repo extends MemoRepository {
  _Repo() : super(Dio());
  int pinCalls = 0;
  final deleted = <int>[];
  bool failDelete = false;

  @override
  Future<void> pin(int id) async {
    pinCalls++;
    _memos = [
      for (final m in _memos)
        if (m.rowId == id) m.copyWith(isPinned: m.pinned ? 'N' : 'Y') else m,
    ];
  }

  @override
  Future<void> delete(int id) async {
    if (failDelete) {
      throw ApiException(
        code: 'M',
        message: 'RAW_SERVER_TEXT_4471',
        statusCode: 500,
      );
    }
    deleted.add(id);
    _memos = [
      for (final m in _memos)
        if (m.rowId != id) m,
    ];
  }
}

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is PButton && w.label == label);

Future<_Repo> _open(
  WidgetTester tester,
  Memo memo, {
  double textScale = 1,
}) async {
  final repo = _Repo();
  _memos = [memo];
  await pumpApp(
    tester,
    Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showMemoDetailDialog(ctx, memo),
          child: const Text('open'),
        ),
      ),
    ),
    overrides: [
      memoRepositoryProvider.overrideWith((ref) async => repo),
      memoListProvider.overrideWith((ref) async => _memos),
    ].cast(),
    textScale: textScale,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('앱 아이디어 더보기'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadRealFonts);

  testWidgets('머리 제목 = 메모 제목 · 색 카드 0 · 바닥은 [수정] 하나 · [삭제] 0', (tester) async {
    await _open(tester, _memo());
    expect(findPlain('앱 아이디어'), findsWidgets);
    expect(findPlain('메모 상세'), findsNothing);
    expect(_button('수정'), findsOneWidget);
    expect(_button('삭제'), findsNothing);
    expect(tester.getSize(_button('수정')).height, 48);
    expect(findPlain('본문 첫 줄\n둘째 줄'), findsOneWidget);
  });

  testWidgets('본문은 낱말 단위 줄바꿈(v114) — 낱말 안 글자 사이에 이음 문자(U+2060), 읽는 이름은 원래 글', (
    tester,
  ) async {
    await _open(tester, _memo());
    final t = tester.widget<Text>(
      find.byKey(const ValueKey('memo-detail-content')),
    );
    expect(t.data, contains('\u2060'));
    expect(t.semanticsLabel, '본문 첫 줄\n둘째 줄');
  });

  testWidgets('메타 — "{태그} · {시각} 수정" · 고정이면 마지막에 "고정"', (tester) async {
    await _open(tester, _memo(pinned: true));
    expect(findPlain('아이디어'), findsOneWidget);
    expect(findPlain('고정'), findsOneWidget);
    expect(find.textContaining('수정'), findsWidgets);
  });

  testWidgets('본문이 없으면 "내용 없음"', (tester) async {
    await _open(tester, _memo(content: null));
    expect(findPlain('내용 없음'), findsOneWidget);
  });

  testWidgets('머리 ⋮ = [고정, 삭제] — 고정된 메모는 [고정 해제] · 삭제는 빨강 줄', (tester) async {
    await _open(tester, _memo());
    await _openMenu(tester);
    expect(findPlain('고정'), findsOneWidget);
    expect(findPlain('삭제'), findsOneWidget);
    expect(find.byType(PMenuSheetContent), findsOneWidget);
  });

  testWidgets('고정을 바꾸면 상세가 목록 최신 값을 따라 메타 "고정" 과 메뉴 글이 바뀐다', (tester) async {
    final repo = await _open(tester, _memo());
    await _openMenu(tester);
    await tester.tap(findPlain('고정'));
    await tester.pumpAndSettle();
    expect(repo.pinCalls, 1);
    expect(findPlain('고정'), findsOneWidget, reason: '메타 조각 "고정"');
    await _openMenu(tester);
    expect(findPlain('고정 해제'), findsOneWidget);
  });

  testWidgets(
    '삭제 = Alert Dialog "메모 삭제" + 글 + [취소] [삭제](critical) → 지우고 시트를 닫는다',
    (tester) async {
      final repo = await _open(tester, _memo());
      await _openMenu(tester);
      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
      expect(findPlain('메모 삭제'), findsOneWidget);
      expect(
        findPlain('"앱 아이디어" 메모를 삭제할까요? 삭제한 메모는 되돌릴 수 없어요.'),
        findsOneWidget,
      );
      expect(_button('취소'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: find.text('삭제'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.deleted, [7]);
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(_button('수정'), findsNothing, reason: '지운 뒤 상세를 닫는다');
    },
  );

  testWidgets('삭제가 실패하면 확인창을 닫고 상세는 그대로 · 서버 원문 0', (tester) async {
    final repo = await _open(tester, _memo());
    repo.failDelete = true;
    await _openMenu(tester);
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(PAlertDialogView),
        matching: find.text('삭제'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PAlertDialogView), findsNothing);
    expect(_button('수정'), findsOneWidget);
    expect(find.textContaining('RAW_SERVER_TEXT_4471'), findsNothing);
  });

  testWidgets('x2 글자 — 넘침 오류 0', (tester) async {
    await _open(tester, _memo(), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
