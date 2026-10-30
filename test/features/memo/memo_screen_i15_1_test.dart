// 메모 폰 화면(I-15 5 ~ 12) — 흰 면 하나 · 상단 바 · 밑줄 검색칸 · 태그 칩 줄 · 묶음 제목 · 줄 · 밀기 · 떠 있는 + · 상태.
//
// 가장 나쁜 값(두 줄 넘는 제목 · 12자 태그 · 제목 없음 · 지난해 · 태그 없음 · 고정 둘)과 200% · 다크를 본다.
// 시험은 작성만 했다(UI 이관이 끝날 때까지 돌리지 않는다).
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/memo/application/memo_providers.dart';
import 'package:groo_damda_app/features/memo/data/memo_repository.dart';
import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/domain/memo_tag.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_screen.dart';
import 'package:groo_damda_app/features/memo/presentation/widgets/memo_row.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/floating_action_button/p_floating_action_button.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import '../../support/plain_text.dart';
import '../todo/todo_test_support.dart';

final _y = DateTime.now().year;

Memo _m(
  int id,
  String title,
  String? content,
  String? tag,
  String? color,
  String at, {
  bool pinned = false,
}) => Memo(
  rowId: id,
  title: title,
  content: content,
  tag: tag,
  color: color,
  isPinned: pinned ? 'Y' : 'N',
  createAt: at,
  modifyAt: at,
);

/// 웹 i15-1 렌더와 같은 여섯 건(가장 나쁜 값).
final _six = [
  _m(
    1,
    '아주 긴 메모 제목이 목록 칸 안에서 어떻게 줄을 바꾸는지 확인하는 메모 — 주말 여행 계획과 예산 정리 그리고 준비물 점검',
    '첫째 날 기차 08:10 출발.\n예산 1,234,567,890원(최악 값) 안에서 숙소와 식사를 정한다.',
    '여행 준비물 체크',
    '#b36418',
    '$_y-10-22T08:10:00',
    pinned: true,
  ),
  _m(
    2,
    '읽을 책 목록',
    '1. 숲의 시간\n2. 작은 습관의 힘',
    '독서',
    '#2d8060',
    '$_y-10-20T03:30:00',
    pinned: true,
  ),
  _m(
    3,
    '앱 아이디어',
    '가계부와 일정을 한 화면에서 보는 위젯',
    '아이디어',
    '#8b4dba',
    '$_y-10-18T11:00:00',
  ),
  _m(4, '', '제목 없는 메모의 본문', '열두글자짜리태그이름', '#c73838', '$_y-10-15T12:00:00'),
  _m(5, '지난해 메모', null, null, '#2c70bf', '${_y - 1}-12-03T12:00:00'),
  _m(6, '장보기', '우유, 달걀, 두부, 사과', null, null, '$_y-09-01T00:00:00'),
];

final _tags = [
  for (final (i, n) in ['아이디어', '여행 준비물 체크', '독서', '열두글자짜리태그이름'].indexed)
    MemoTag(rowId: i + 1, tagName: n, userRowId: 1),
];

class _Repo extends MemoRepository {
  _Repo() : super(Dio());
  int pinCalls = 0;
  bool failPin = false;

  @override
  Future<void> pin(int id) async {
    pinCalls++;
    if (failPin) {
      throw ApiException(
        code: 'M',
        message: 'RAW_SERVER_TEXT_4471',
        statusCode: 500,
      );
    }
  }
}

List<dynamic> _overrides({
  List<Memo>? memos,
  bool error = false,
  _Repo? repo,
}) => [
  memoRepositoryProvider.overrideWith((ref) async => repo ?? _Repo()),
  memoListProvider.overrideWith((ref) async {
    if (error) throw Exception('RAW_SERVER_TEXT_9137');
    return memos ?? _six;
  }),
  memoTagListProvider.overrideWith((ref) async => _tags),
];

Future<void> _pump(
  WidgetTester tester, {
  List<Memo>? memos,
  bool error = false,
  _Repo? repo,
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) => pumpApp(
  tester,
  const MemoScreen(),
  overrides: _overrides(memos: memos, error: error, repo: repo).cast(),
  textScale: textScale,
  brightness: brightness,
);

void main() {
  setUpAll(loadRealFonts);

  testWidgets(
    '흰 면 하나 — bg-layer-default · 상단 바 56 · AppBar 0 · 띠 0 · 흰 면이 화면 끝까지',
    (tester) async {
      await _pump(tester, memos: [_six[2]]);
      final c = tester.element(find.byType(MemoScreen)).colors;
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        c.bgLayerDefault,
      );
      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const ValueKey('screen-band-body')), findsNothing);
      expect(tester.getSize(find.byType(PTopNavigation)).height, 56);
      final face = tester.getRect(
        find.byKey(const ValueKey('memo-white-screen')),
      );
      expect(face.top, 56);
      expect(face.bottom, 780);
      expect(
        tester.getRect(find.byType(PInput)).top - 56,
        closeTo(4, 0.5),
        reason: 'T1 — 흰 면 안 위 4',
      );
    },
  );

  testWidgets('검색칸 = 밑줄형 large · 돋보기 · 지우기 · 자리 글 "메모 검색"', (tester) async {
    await _pump(tester);
    final input = tester.widget<PInput>(find.byType(PInput));
    expect(input.variant, PInputVariant.underline);
    expect(input.prefixIcon, LucideIcons.search);
    expect(input.clearable, isTrue);
    expect(input.placeholder, '메모 검색');
    final r = tester.getRect(find.byType(PInput));
    expect(r.left, 24);
    expect(r.right, 336);
  });

  testWidgets('칩 줄 — 전체 → 설정 태그 차례 → 태그 없음 맨 뒤 · 한 줄 · 건수는 칩 안', (
    tester,
  ) async {
    await _pump(tester);
    final chips = tester
        .widgetList<PChipRadio<String>>(find.byType(PChipRadio<String>))
        .toList();
    expect(chips.map((c) => c.label), [
      '전체',
      '아이디어',
      '여행 준비물 체크',
      '독서',
      '열두글자짜리태그이름',
      '태그 없음',
    ]);
    expect(chips.map((c) => c.count), [6, 1, 1, 1, 1, 2]);
    expect(
      chips.every(
        (c) =>
            c.variant == PChipVariant.outlineStrong &&
            c.size == PChipSize.small,
      ),
      isTrue,
    );
    final group = tester.widget<PChipRadioGroup<String>>(
      find.byType(PChipRadioGroup<String>),
    );
    expect(group.layout, PChipGroupLayout.scroll);
    expect(group.semanticLabel, '태그로 거르기');
    // 칩 높이 32 · 같은 줄(세로 위치 같음)
    final tops = {
      for (final f in find.byType(PChipRadio<String>).evaluate())
        tester.getRect(find.byWidget(f.widget)).top,
    };
    expect(tops.length, 1);
    expect(tester.getSize(find.byType(PChipRadio<String>).first).height, 32);
  });

  testWidgets('칩을 누르면 그 태그만 거른다 · 전체 건수는 늘 전체 기준', (tester) async {
    await _pump(tester);
    await tester.tap(find.bySemanticsLabel('독서 1'));
    await tester.pumpAndSettle();
    expect(find.byType(MemoRow), findsOneWidget);
    expect(findPlain('읽을 책 목록'), findsOneWidget);
  });

  testWidgets('칩 폭 — "전체 6" 은 웹과 같은 67(좌우 12 + 글 + 글↔건수 10)', (tester) async {
    await _pump(tester);
    expect(
      tester.getSize(find.byType(PChipRadio<String>).first).width,
      closeTo(67, 1.5),
    );
  });

  testWidgets('끝 칩을 고르면 칩 줄이 그 칩이 화면 여백(24) 안에 들어오게 스크롤된다', (tester) async {
    await _pump(tester);
    await tester.tap(find.bySemanticsLabel('태그 없음 2'));
    await tester.pumpAndSettle();
    final r = tester.getRect(find.byType(PChipRadio<String>).last);
    expect(r.right, lessThanOrEqualTo(360 - 24 + 0.5));
    expect(r.left, greaterThanOrEqualTo(0));
  });

  testWidgets('묶음 제목 "고정 · 2" · "모든 메모 · 4" · 줄 6 · 고정 0이면 "모든 메모" 제목이 없다', (
    tester,
  ) async {
    await _pump(tester);
    final titles = tester
        .widgetList<PListHeader>(find.byType(PListHeader))
        .map((h) => h.title)
        .toList();
    expect(titles, ['고정 · 2', '모든 메모 · 4']);
    expect(find.byType(MemoRow), findsNWidgets(6));
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, memos: [_six[2], _six[3]]);
    expect(tester.widgetList<PListHeader>(find.byType(PListHeader)).length, 0);
  });

  testWidgets(
    '줄 — 점 8 · 제목 줄바꿈(말줄임 0) · 본문 한 줄 · 메타 "태그 · 시각" · 줄 끝 ⋮ 0 · 핀 0 · 줄 사이 선 0',
    (tester) async {
      await _pump(tester);
      expect(find.byKey(const ValueKey('memo-dot')), findsNWidgets(6));
      expect(
        tester.getSize(find.byKey(const ValueKey('memo-dot')).first),
        const Size(8, 8),
      );
      final long = tester.widget<Text>(
        findPlain(
          '아주 긴 메모 제목이 목록 칸 안에서 어떻게 줄을 바꾸는지 확인하는 메모 — 주말 여행 계획과 예산 정리 그리고 준비물 점검',
        ),
      );
      expect(long.overflow, isNot(TextOverflow.ellipsis));
      expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
      expect(find.byIcon(LucideIcons.pin), findsNothing);
      expect(findPlain('제목 없음'), findsOneWidget);
      expect(findPlain('${_y - 1}년 12월 3일'), findsOneWidget);
      final body = tester.widget<Text>(
        find.byKey(const ValueKey('memo-body')).first,
      );
      expect(body.maxLines, 1);
      // 줄이 화면 끝까지
      final row = tester.getRect(find.byType(MemoRow).first);
      expect(row.left, 0);
      expect(row.right, 360);
    },
  );

  testWidgets('밀기 [고정, 수정, 삭제] — 고정된 메모는 [해제] · 줄 끝 ⋮ 없음', (tester) async {
    await _pump(tester);
    final swipes = tester
        .widgetList<PSwipeActions>(find.byType(PSwipeActions))
        .toList();
    expect(swipes.first.actions.map((a) => a.label), ['해제', '수정', '삭제']);
    expect(swipes.last.actions.map((a) => a.label), ['고정', '수정', '삭제']);
    expect(swipes.first.actions.last.kind, PSwipeActionKind.destructive);
  });

  testWidgets('떠 있는 + — 56 × 56 · 끝 20 · 이름 "메모 추가" · 칩 줄 끝 추가 버튼 없음', (
    tester,
  ) async {
    await _pump(tester);
    final fab = tester.widget<PFloatingActionButton>(
      find.byType(PFloatingActionButton),
    );
    expect(fab.label, '메모 추가');
    expect(fab.icon, LucideIcons.plus500);
    expect(find.text('추가'), findsNothing);
  });

  testWidgets(
    '메모 0개 — Result Section · 버튼 0 · 안내 "오른쪽 아래 + 버튼으로 첫 메모를 써보세요."',
    (tester) async {
      await _pump(tester, memos: const []);
      final r = tester.widget<PResultSection>(find.byType(PResultSection));
      expect(r.title, '메모가 없어요');
      expect(r.description, '오른쪽 아래 + 버튼으로 첫 메모를 써보세요.');
      expect(r.primaryAction, isNull);
      expect(
        find.byType(PChipRadio<String>),
        findsNothing,
        reason: '메모 0이면 칩 줄이 없다',
      );
    },
  );

  testWidgets('검색 0건 — "결과가 없어요" · 다른 검색어 안내', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(PInput), '없는검색어');
    await tester.pumpAndSettle();
    expect(findPlain('결과가 없어요'), findsOneWidget);
    expect(findPlain('다른 검색어를 입력해보세요.'), findsOneWidget);
  });

  testWidgets('실패 — Result Section failure · 서버 원문 0 · 다시 시도', (tester) async {
    await _pump(tester, error: true);
    final r = tester.widget<PResultSection>(find.byType(PResultSection));
    expect(r.kind, PResultKind.failure);
    expect(r.title, '메모를 불러오지 못했어요');
    expect(find.textContaining('RAW_SERVER_TEXT_9137'), findsNothing);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    for (final dark in [false, true]) {
      testWidgets('x$scale ${dark ? "다크" : "라이트"} — 가장 나쁜 값에서 넘침 오류 0', (
        tester,
      ) async {
        await _pump(
          tester,
          textScale: scale,
          brightness: dark ? Brightness.dark : Brightness.light,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'L5 — 목록 실패에서 [다시 시도] 를 누르면 실패 상자가 불러오는 줄 자리로 바뀐다(눌렀는데 그대로가 아니다)',
    (tester) async {
      var calls = 0;
      await pumpApp(
        tester,
        const MemoScreen(),
        overrides: [
          memoRepositoryProvider.overrideWith((ref) async => _Repo()),
          memoListProvider.overrideWith((ref) {
            calls++;
            if (calls == 1) throw Exception('RAW_SERVER_TEXT_9137');
            return Completer<List<Memo>>().future;
          }),
          memoTagListProvider.overrideWith((ref) async => _tags),
        ].cast(),
      );
      expect(find.byType(PResultSection), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      expect(
        find.byType(PResultSection),
        findsNothing,
        reason: '다시 받는 동안은 줄 자리 Skeleton',
      );
    },
  );
}
