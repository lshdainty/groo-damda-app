// 할 일 태그 설정(I-10 5A · 10-1 앱 몫) — 흰 면 하나 · Callout · 목록 제목 + 글 버튼 · 색 타일 줄 · 수정 시트 [삭제].
//
// 화면을 실제로 띄워 값을 잰다. 가장 나쁜 값(12자 태그 · 0건 · 여섯 개)과 200% · 다크도 본다.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';
import 'package:groo_damda_app/features/todo/data/todo_tag_repository.dart';
import 'package:groo_damda_app/features/todo/domain/todo_tag.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_tag_management_screen.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import '../../support/plain_text.dart';
import 'todo_test_support.dart';

class _Repo extends TodoTagRepository {
  _Repo() : super(Dio());
  final List<int> deleted = [];
  final List<({int? id, String name, String? color})> saved = [];

  @override
  Future<void> delete(int id) async => deleted.add(id);

  @override
  Future<TodoTag> create({required String tagName, String? color}) async {
    saved.add((id: null, name: tagName, color: color));
    return tagOf(99, tagName);
  }

  @override
  Future<TodoTag> update({
    required int id,
    required String tagName,
    String? color,
  }) async {
    saved.add((id: id, name: tagName, color: color));
    return tagOf(id, tagName);
  }
}

final _six = [
  tagOf(1, '업무', usage: 14, color: '#3B82F6'),
  tagOf(2, '집안일', usage: 6, color: '#22C55E'),
  tagOf(3, '장기프로젝트자료모으기정', usage: 3, color: '#EC4899'),
  tagOf(4, '건강', usage: 0, color: '#F97316'),
  tagOf(5, '공부', usage: 2, color: '#8B5CF6'),
  tagOf(6, '여행', usage: 1, color: '#14B8A6'),
];

List<dynamic> _overrides(
  _Repo repo, {
  List<TodoTag>? tags,
  bool error = false,
}) => [
  todoTagRepositoryProvider.overrideWith((ref) async => repo),
  todoTagListProvider.overrideWith((ref) async {
    if (error) throw Exception('RAW_SERVER_TEXT_9137');
    return tags ?? _six;
  }),
  todoListProvider.overrideWith((ref, f) async => const []),
];

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is PButton && w.label == label);

Finder _tagRow(String name) =>
    find.ancestor(of: findPlain(name), matching: find.byType(PListButtonItem));

void main() {
  setUpAll(loadRealFonts);

  testWidgets('흰 면 하나 — Scaffold bg-layer-default · 상단 바 56 · 띠 · AppBar 0', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const TodoTagManagementScreen(),
      overrides: [..._overrides(_Repo())].cast(),
    );
    final c = tester.element(find.byType(TodoTagManagementScreen)).colors;
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      c.bgLayerDefault,
    );
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('screen-band-body')), findsNothing);
    expect(tester.getSize(find.byType(PTopNavigation)).height, 56);
    // T5 — 상단 바 바로 아래부터 본문(안내 상자 위 16 은 면 안 여백)
    final body = find.byKey(const ValueKey('todo-tags-body'));
    expect(
      tester.getRect(body).top,
      tester.getRect(find.byType(PTopNavigation)).bottom,
    );
    final callout = tester.getRect(find.byType(PCallout));
    expect(callout.top - tester.getRect(body).top, 16);
  });

  testWidgets('안내 = Callout informative · 제목 없음 · 새 글(분포 없음 · 지우기 안내)', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const TodoTagManagementScreen(),
      overrides: [..._overrides(_Repo())].cast(),
    );
    final callout = tester.widget<PCallout>(find.byType(PCallout));
    expect(callout.tone, PCalloutTone.informative);
    expect(callout.interaction, PCalloutInteraction.display);
    expect(callout.title, isNull);
    expect(callout.icon, isNull, reason: 'informative 기본 아이콘(ⓘ)');
    expect(callout.description, contains('태그별 개수'));
    expect(callout.description, isNot(contains('분포')));
    expect(callout.description, contains("'태그 없음'으로 남아요"));
    // 좌우 24
    final r = tester.getRect(find.byType(PCallout));
    expect(r.left, 24);
    expect(r.right, 336);
  });

  testWidgets('목록 제목 "할 일 태그 · 6" boldSolid + 오른쪽 글 버튼 "태그 추가"(여백 24 안)', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const TodoTagManagementScreen(),
      overrides: [..._overrides(_Repo())].cast(),
    );
    final header = tester.widget<PListHeader>(find.byType(PListHeader));
    expect(header.title, '할 일 태그 · 6');
    expect(header.variant, PListHeaderVariant.boldSolid);
    expect(header.action, isA<PTextButton>());
    // 글 끝이 오른쪽 여백(360 − 24) 안에 선다 — 버튼 상자는 14 밖으로 나간다
    final label = tester.getRect(
      find.byKey(const ValueKey('text-button-label')),
    );
    expect(label.right, closeTo(336, 0.5));
    expect(tester.widget<PTextButton>(find.byType(PTextButton)).label, '태그 추가');
  });

  testWidgets('줄 = 색 타일 40 · 이름 줄바꿈 · "N건에 사용 중" · ⋮ 없음 · 밀기 [수정, 삭제]', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const TodoTagManagementScreen(),
      overrides: [..._overrides(_Repo())].cast(),
    );
    expect(find.byType(PListTile), findsNWidgets(6));
    expect(tester.getSize(find.byType(PListTile).first), const Size(40, 40));
    expect(findPlain('14건에 사용 중'), findsOneWidget);
    expect(findPlain('0건에 사용 중'), findsOneWidget);
    final long = tester.widget<Text>(findPlain('장기프로젝트자료모으기정'));
    expect(long.overflow, isNot(TextOverflow.ellipsis));
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
    expect(find.byType(PSwipeActionsMore), findsNothing);
    final swipe = tester.widget<PSwipeActions>(
      find.byType(PSwipeActions).first,
    );
    expect(swipe.actions.map((a) => a.label), ['수정', '삭제']);
    // 줄이 화면 끝까지
    final row = tester.getRect(_tagRow('업무'));
    expect(row.left, 0);
    expect(row.right, 360);
  });

  testWidgets('비어 있음 — Result Section empty medium · 첫 태그 안내 · 버튼 없음', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const TodoTagManagementScreen(),
      overrides: [..._overrides(_Repo(), tags: const [])].cast(),
    );
    final r = tester.widget<PResultSection>(find.byType(PResultSection));
    expect(r.kind, PResultKind.empty);
    expect(r.size, PResultSize.medium);
    expect(r.primaryAction, isNull);
    expect(r.title, '태그가 없어요');
    expect(r.description, "\"태그 추가\" 버튼으로 첫 태그를 만들어보세요.");
    expect(
      tester.widget<PListHeader>(find.byType(PListHeader)).title,
      '할 일 태그 · 0',
    );
  });

  testWidgets('실패 — Result Section failure · 원문 없음 · 다시 시도', (tester) async {
    await pumpApp(
      tester,
      const TodoTagManagementScreen(),
      overrides: [..._overrides(_Repo(), error: true)].cast(),
    );
    final r = tester.widget<PResultSection>(find.byType(PResultSection));
    expect(r.kind, PResultKind.failure);
    expect(r.title, '태그를 불러오지 못했어요');
    expect(findTextContaining('RAW_SERVER_TEXT_9137'), findsNothing);
    expect(findText('다시 시도'), findsOneWidget);
    // 불러오는 동안에도 "태그 추가" 는 진짜 버튼이다
    expect(find.byType(PTextButton), findsOneWidget);
  });

  group('수정 시트 [삭제]', () {
    testWidgets(
      '수정 — 바닥 왼쪽 ghost critical large(48) [삭제] + 나머지 폭 [저장] large(48) · 빨간 글',
      (tester) async {
        await pumpApp(
          tester,
          const TodoTagManagementScreen(),
          overrides: [..._overrides(_Repo())].cast(),
        );
        await tester.tap(_tagRow('업무'));
        await tester.pumpAndSettle();
        expect(findPlain('태그 수정'), findsOneWidget);
        final del = _button('삭제');
        final save = _button('저장');
        final delButton = tester.widget<PButton>(del);
        expect(delButton.variant, PButtonVariant.ghost);
        expect(delButton.ghostColor, PButtonGhostColor.critical);
        expect(delButton.size, PButtonSize.large);
        expect(delButton.flush, isNull, reason: 'flush 는 빨간 글을 회색으로 덮는다');
        expect(tester.getSize(del).height, 48);
        expect(tester.getSize(save).height, 48);
        // 삭제는 왼쪽 여백선(24)에서 · 저장은 오른쪽 여백선(336)까지
        expect(tester.getRect(del).left, 24);
        expect(tester.getRect(save).right, 336);
        expect(tester.getRect(del).right, lessThan(tester.getRect(save).left));
        // 글 색 = fg-critical
        final c = tester.element(find.byType(TodoTagManagementScreen)).colors;
        final text = tester.widget<Text>(
          find.descendant(of: del, matching: find.byType(Text)),
        );
        expect(text.style!.color, c.fgCritical);
      },
    );

    testWidgets('새 태그에는 [삭제] 가 없고 주 버튼은 "저장" 하나', (tester) async {
      await pumpApp(
        tester,
        const TodoTagManagementScreen(),
        overrides: [..._overrides(_Repo())].cast(),
      );
      await tester.tap(findText('태그 추가'));
      await tester.pumpAndSettle();
      expect(_button('삭제'), findsNothing);
      expect(_button('저장'), findsOneWidget);
      expect(tester.getRect(_button('저장')).left, 24);
      expect(tester.getRect(_button('저장')).right, 336);
    });

    testWidgets('[삭제] 를 누르면 시트가 닫히고 확인이 한 번 묻는다 → 지운다', (tester) async {
      final repo = _Repo();
      await pumpApp(
        tester,
        const TodoTagManagementScreen(),
        overrides: [..._overrides(repo)].cast(),
      );
      await tester.tap(_tagRow('업무'));
      await tester.pumpAndSettle();
      await tester.tap(_button('삭제'));
      await tester.pumpAndSettle();
      // 시트는 닫혔고(수정 제목 없음) 확인 하나가 떠 있다
      expect(findPlain('태그 수정'), findsNothing);
      expect(findPlain('태그 삭제'), findsOneWidget);
      expect(
        findPlain(
          '"업무" 태그를 삭제하면 이 태그를 쓰는 할 일 14건은 태그 없음으로 남아요. 삭제한 태그는 되돌릴 수 없어요.',
        ),
        findsOneWidget,
      );
      await tester.tap(_button('삭제').last);
      await tester.pumpAndSettle();
      expect(repo.deleted, [1]);
    });

    testWidgets('확인에서 취소하면 지우지 않는다', (tester) async {
      final repo = _Repo();
      await pumpApp(
        tester,
        const TodoTagManagementScreen(),
        overrides: [..._overrides(repo)].cast(),
      );
      await tester.tap(_tagRow('업무'));
      await tester.pumpAndSettle();
      await tester.tap(_button('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(_button('취소'));
      await tester.pumpAndSettle();
      expect(repo.deleted, isEmpty);
    });

    testWidgets('이름을 비운 채 저장하면 막히고 오류 글이 선다 · 바뀐 채 닫으면 묻는다', (tester) async {
      final repo = _Repo();
      await pumpApp(
        tester,
        const TodoTagManagementScreen(),
        overrides: [..._overrides(repo)].cast(),
      );
      await tester.tap(findText('태그 추가'));
      await tester.pumpAndSettle();
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(findText(keepAll('이름을 입력해주세요.')), findsOneWidget);
      expect(repo.saved, isEmpty);
      await tester.enterText(find.byType(PInput).first, '새 태그');
      await tester.pumpAndSettle();
      // 바뀐 채 닫기
      await tester.tap(find.bySemanticsLabel('닫기').first);
      await tester.pumpAndSettle();
      expect(findPlain('작성한 내용이 사라져요'), findsOneWidget);
      await tester.tap(findPlain('계속 작성'));
      await tester.pumpAndSettle();
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(repo.saved.single.name, '새 태그');
    });
  });

  group('이름 12자 · 겹침 검사 (웹과 같은 규칙 · 글)', () {
    testWidgets('같은 이름이면 칸 아래 오류가 서고 저장하지 않는다', (tester) async {
      final repo = _Repo();
      await pumpApp(
        tester,
        const TodoTagManagementScreen(),
        overrides: [..._overrides(repo)].cast(),
      );
      await tester.tap(findText('태그 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(PInput).first, '업무');
      await tester.pumpAndSettle();
      expect(findText(keepAll('같은 이름의 태그가 이미 있어요.')), findsOneWidget);
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(repo.saved, isEmpty);
      expect(findText(keepAll('같은 이름의 태그가 이미 있어요.')), findsOneWidget);
    });

    testWidgets('고칠 때 자기 이름은 겹침이 아니다', (tester) async {
      final repo = _Repo();
      await pumpApp(
        tester,
        const TodoTagManagementScreen(),
        overrides: [..._overrides(repo)].cast(),
      );
      await tester.tap(_tagRow('업무'));
      await tester.pumpAndSettle();
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(repo.saved.single.id, 1);
      expect(repo.saved.single.name, '업무');
    });

    testWidgets('D5 — 안 바꾼 12자 넘는 옛 이름은 12자 검사에서 빠져 색만 고쳐 저장된다', (
      tester,
    ) async {
      final repo = _Repo();
      await pumpApp(
        tester,
        const TodoTagManagementScreen(),
        overrides: [
          ..._overrides(repo, tags: [tagOf(1, '아주아주긴옛태그이름열세자', usage: 2)]),
        ].cast(),
      );
      await tester.tap(_tagRow('아주아주긴옛태그이름열세자'));
      await tester.pumpAndSettle();
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(repo.saved.single.name, '아주아주긴옛태그이름열세자');
    });

    testWidgets('입력은 12자에서 멈추고 칸 아래에 n/12 가 보인다', (tester) async {
      await pumpApp(
        tester,
        const TodoTagManagementScreen(),
        overrides: [..._overrides(_Repo())].cast(),
      );
      await tester.tap(findText('태그 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(PInput).first, '가나다라마바사아자차카타파하');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PInput>(find.byType(PInput).first)
            .controller!
            .text
            .length,
        12,
      );
      expect(findText('12/12'), findsOneWidget);
    });

    testWidgets('이름이 비면 "이름을 입력해주세요." — 서버 원문은 없다', (tester) async {
      await pumpApp(
        tester,
        const TodoTagManagementScreen(),
        overrides: [..._overrides(_Repo())].cast(),
      );
      await tester.tap(findText('태그 추가'));
      await tester.pumpAndSettle();
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(findText(keepAll('이름을 입력해주세요.')), findsOneWidget);
    });
  });

  for (final scale in [1.0, 2.0]) {
    for (final dark in [false, true]) {
      testWidgets('x$scale ${dark ? "다크" : "라이트"} — 가장 나쁜 값에서 넘침 오류 0', (
        tester,
      ) async {
        await pumpApp(
          tester,
          const TodoTagManagementScreen(),
          overrides: [..._overrides(_Repo())].cast(),
          textScale: scale,
          brightness: dark ? Brightness.dark : Brightness.light,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(_tagRow('장기프로젝트자료모으기정'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
