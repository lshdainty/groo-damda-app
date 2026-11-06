// 할 일 상세(I-10 21) — ds Bottom Sheet 조회. 머리 카드 · 원 아이콘 · 가운데 맞춤 없음, 키-값 List 줄, 메모는 줄 아래 따로.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_detail_dialog.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import '../../support/plain_text.dart';
import 'todo_test_support.dart';

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is PButton && w.label == label);

Future<FakeTodoRepo> _open(
  WidgetTester tester,
  Todo t, {
  double scale = 1,
  Brightness brightness = Brightness.light,
}) async {
  final repo = FakeTodoRepo();
  await pumpApp(
    tester,
    Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showTodoDetailDialog(ctx, t),
          child: const Text('open'),
        ),
      ),
    ),
    overrides: todoOverrides(repo: repo),
    textScale: scale,
    brightness: brightness,
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUpAll(loadRealFonts);

  testWidgets('제목 t6 · 700 · 줄바꿈, 머리 카드(그라디언트) · 가운데 맞춤 없음', (tester) async {
    await _open(tester, todo(1, '상세 제목', due: today(), prio: 'HIGH'));
    final title = tester.widget<Text>(
      find.byKey(const ValueKey('todo-detail-title')),
    );
    expect(title.style!.fontSize, 18);
    expect(title.style!.fontWeight, FontWeight.w700);
    expect(title.textAlign, isNot(TextAlign.center));
    // 틴트 그라디언트 머리 카드가 없다
    final gradients = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).gradient != null,
    );
    expect(gradients, findsNothing);
    expect(findPlain('할 일 상세'), findsOneWidget);
  });

  testWidgets('키-값 List 줄 — 마감일 · 태그 · 우선순위(Badge) · 상태, 메모는 줄 아래 머리말 3', (
    tester,
  ) async {
    await _open(
      tester,
      todo(1, '키 값', due: today(), prio: 'HIGH', tag: '업무', content: '본문 한 줄'),
    );
    expect(find.byType(PListItem), findsNWidgets(4));
    expect(findPlain('마감일'), findsOneWidget);
    expect(findPlain('업무'), findsOneWidget);
    expect(findWidgetWithText(PBadge, '중요'), findsOneWidget);
    expect(
      tester.widget<PBadge>(findWidgetWithText(PBadge, '중요')).tone,
      PBadgeTone.critical,
    );
    final memo = find.byWidgetPredicate(
      (w) => w is PListHeader && w.title == '메모',
    );
    expect(memo, findsOneWidget);
    expect(tester.widget<PListHeader>(memo).headingLevel, 3);
    // 메모 줄은 키-값 줄(PListItem)이 아니다
    expect(find.byType(PListItem), findsNWidgets(4));
  });

  testWidgets('메모가 없으면 "없음" · 끝낸 할 일은 제목 취소선 + 완료 일시 줄', (tester) async {
    await _open(tester, todo(1, '끝낸 일', due: today(), done: true));
    final c = tester
        .element(find.byKey(const ValueKey('todo-detail-title')))
        .colors;
    final title = tester.widget<Text>(
      find.byKey(const ValueKey('todo-detail-title')),
    );
    expect(title.style!.decoration, TextDecoration.lineThrough);
    expect(title.style!.color, c.fgDisabled);
    expect(findPlain('없음'), findsOneWidget);
    expect(findPlain('완료 일시'), findsOneWidget);
  });

  testWidgets('지난 마감 — 값 글자 fg-critical + ", 마감 지남"', (tester) async {
    final n = DateTime.now();
    if (n.day == 1) return;
    await _open(tester, todo(1, '밀린 일', due: thisMonth(n.day - 1)));
    final c = tester
        .element(find.byKey(const ValueKey('todo-detail-title')))
        .colors;
    final value = tester.widget<Text>(findPlainContaining(', 마감 지남'));
    expect(value.style!.color, c.fgCritical);
  });

  testWidgets('바닥 = [삭제] neutralWeak · [수정] neutralSolid, large 48 반씩', (
    tester,
  ) async {
    await _open(tester, todo(1, '바닥', due: today()));
    final del = tester.widget<PButton>(_button('삭제'));
    final edit = tester.widget<PButton>(_button('수정'));
    expect(del.variant, PButtonVariant.neutralWeak);
    expect(edit.variant, PButtonVariant.neutralSolid);
    expect(del.size, PButtonSize.large);
    expect(tester.getSize(_button('삭제')).height, 48);
    final dr = tester.getRect(_button('삭제'));
    final er = tester.getRect(_button('수정'));
    expect(dr.left, 24);
    expect(er.right, 336);
    expect((dr.width - er.width).abs(), lessThan(1));
  });

  testWidgets('[수정] → 상세가 닫히고 수정 폼이 열린다', (tester) async {
    await _open(tester, todo(1, '고칠 일', due: today()));
    await tester.tap(_button('수정'));
    await tester.pumpAndSettle();
    expect(findPlain('할 일 상세'), findsNothing);
    expect(findPlain('할 일 수정'), findsOneWidget);
  });

  testWidgets('조회라 바깥을 누르면 닫힌다', (tester) async {
    await _open(tester, todo(1, '바깥', due: today()));
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(findPlain('할 일 상세'), findsNothing);
  });

  for (final scale in [1.0, 2.0]) {
    for (final dark in [false, true]) {
      testWidgets('x$scale ${dark ? "다크" : "라이트"} — 10,000자 메모 · 긴 제목에서 넘침 0', (
        tester,
      ) async {
        await _open(
          tester,
          todo(
            1,
            '아주 긴 제목 ' * 12,
            due: today(),
            tag: '장기프로젝트자료모으기정',
            content: '가나다라마바사아자차카타파하' * 700,
          ),
          scale: scale,
          brightness: dark ? Brightness.dark : Brightness.light,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
