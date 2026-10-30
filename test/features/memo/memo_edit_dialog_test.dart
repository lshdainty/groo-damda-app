// 메모 추가 · 수정 폼(I-15 13) — 줄 칸 폼: 제목 Input → 내용 Textarea → 선 → List 줄 [태그 · 색상 · 상단에 고정] · 바닥 [저장] 하나.
//
// 저장 페이로드는 화면이 실제로 그 값을 넘기는지로 고정한다(본문 비우기 QA #99 · 태그 선택지 출처 QA #98 · 새 메모 태그 없음 QA #105).
// 에뮬레이터를 쓸 수 없는 환경이라 위젯 테스트가 근거다. 시험은 작성만 했다(UI 이관이 끝날 때까지 돌리지 않는다).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/memo/application/memo_providers.dart';
import 'package:groo_damda_app/features/memo/data/memo_repository.dart';
import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/domain/memo_tag.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_edit_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';
import '../../support/plain_text.dart';
import '../todo/todo_test_support.dart';

const _memo = Memo(
  rowId: 3,
  title: 'QA 메모',
  content: '지워질 본문',
  tag: '개인',
  color: '#2c70bf',
  isPinned: 'N',
);

const _untagged = Memo(rowId: 4, title: '태그 없는 메모', isPinned: 'N');

MemoTag _tag(int rowId, String name) =>
    MemoTag(rowId: rowId, tagName: name, userRowId: 1);

/// update 로 넘어간 인자를 잡는 가짜 레포지토리.
class _CapturingRepo extends MemoRepository {
  _CapturingRepo() : super(Dio());

  Patch<String> content = const Patch.keep();
  Patch<String> tag = const Patch.keep();
  String? title;
  String? color;
  bool created = false;
  String? createdTag;
  bool failSave = false;
  int pinCalls = 0;
  int saves = 0;

  @override
  Future<Memo> update({
    required int id,
    String? title,
    Patch<String> content = const Patch.keep(),
    Patch<String> tag = const Patch.keep(),
    String? color,
  }) async {
    saves++;
    if (failSave) {
      throw ApiException(
        code: 'MEMO_500',
        message: 'RAW_SERVER_TEXT_4471',
        statusCode: 500,
      );
    }
    this.title = title;
    this.content = content;
    this.tag = tag;
    this.color = color;
    return _memo;
  }

  @override
  Future<Memo> create({
    String? title,
    String? content,
    String? tag,
    String? color,
  }) async {
    saves++;
    if (failSave) {
      throw ApiException(
        code: 'MEMO_500',
        message: 'RAW_SERVER_TEXT_4471',
        statusCode: 500,
      );
    }
    created = true;
    createdTag = tag;
    this.title = title;
    this.color = color;
    return _memo;
  }

  @override
  Future<void> pin(int id) async => pinCalls++;

  @override
  Future<List<Memo>> list({String? search}) async => const [];
}

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is PButton && w.label == label);

Finder _row(String title) =>
    find.ancestor(of: findPlain(title), matching: find.byType(PListItemBase));

Future<_CapturingRepo> _open(
  WidgetTester tester, {
  Memo? edit = _memo,
  List<MemoTag> tags = const [],
  bool tagsFail = false,
  double textScale = 1,
}) async {
  final repo = _CapturingRepo();
  await pumpApp(
    tester,
    Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showMemoEditDialog(ctx, edit: edit),
          child: const Text('open'),
        ),
      ),
    ),
    overrides: [
      memoRepositoryProvider.overrideWith((ref) async => repo),
      memoTagListProvider.overrideWith(
        (ref) async => tagsFail ? throw Exception('메모 태그 조회 실패') : tags,
      ),
    ].cast(),
    textScale: textScale,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUpAll(loadRealFonts);

  testWidgets(
    '구조 — 제목 Input · 내용 Textarea · 선 · 태그 · 색상 · 상단에 고정 줄 · 바닥 [저장] 하나 · 꺾쇠 0',
    (tester) async {
      await _open(tester, edit: null);
      expect(findPlain('메모 추가'), findsWidgets);
      expect(find.byType(PInput), findsOneWidget);
      expect(find.byType(PTextarea), findsOneWidget);
      expect(_row('태그'), findsOneWidget);
      expect(_row('색상'), findsOneWidget);
      expect(_row('상단에 고정'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
      // 바닥은 [저장] 하나 · 취소 없음
      expect(_button('저장'), findsOneWidget);
      expect(_button('취소'), findsNothing);
      expect(tester.getSize(_button('저장')).height, 48);
      // 새 메모의 태그 줄 값은 "태그 없음", 색은 파랑
      expect(findPlain('태그 없음'), findsOneWidget);
      expect(findPlain('파랑'), findsOneWidget);
    },
  );

  testWidgets('시트 머리 아래 → 제목 칸 12 · 스위치 줄 아래 → [저장] 위 12 (끝 흐림 여백 없음)', (
    tester,
  ) async {
    await _open(tester, edit: null);
    final header = tester.getRect(
      find.byKey(const ValueKey('p-bottom-sheet-header')),
    );
    expect(
      tester.getRect(find.byType(PInput)).top - header.bottom,
      closeTo(12, 1.5),
      reason: '필드 위 12',
    );
    expect(
      tester.getRect(_button('저장')).top - tester.getRect(_row('상단에 고정')).bottom,
      closeTo(12, 1),
    );
  });

  testWidgets('줄 높이 — 태그 · 색상 줄 46 (보이는 줄) · 누르는 칸 44 이상', (tester) async {
    await _open(tester, edit: null);
    expect(tester.getSize(_row('태그')).height, 46);
    expect(tester.getSize(_row('색상')).height, 46);
  });

  testWidgets('내용 칸 최대 높이는 화면 높이의 32% (780 → 249.6)', (tester) async {
    await _open(tester, edit: null);
    expect(
      tester.widget<PTextarea>(find.byType(PTextarea)).maxHeight,
      closeTo(780 * 0.32, 0.01),
    );
  });

  testWidgets('본문을 지우고 저장하면 content 가 명시적 null 로 실린다', (tester) async {
    final repo = await _open(tester);
    expect(findPlain('지워질 본문'), findsOneWidget);

    await tester.enterText(find.byType(PTextarea), '');
    await tester.pumpAndSettle();
    await tester.tap(_button('저장'));
    await tester.pumpAndSettle();

    expect(
      repo.content.present,
      isTrue,
      reason: 'content 키가 빠지면 서버가 옛 본문을 지킨다 — QA #99 의 그 증상이다',
    );
    expect(repo.content.value, isNull);
  });

  testWidgets('본문을 고쳐 저장하면 고친 값이 실리고 시트가 닫힌다', (tester) async {
    final repo = await _open(tester);

    await tester.enterText(find.byType(PTextarea), '새 본문');
    await tester.pumpAndSettle();
    await tester.tap(_button('저장'));
    await tester.pumpAndSettle();

    expect(repo.content.value, '새 본문');
    expect(find.byType(PTextarea), findsNothing, reason: '저장을 마치면 시트가 닫힌다');
  });

  testWidgets('제목을 비우고 저장하면 칸 아래 오류 "제목을 입력해주세요." 로 막힌다 · 저장은 켜 둔 채', (
    tester,
  ) async {
    final repo = await _open(tester);

    await tester.enterText(find.byType(PInput), '');
    await tester.pumpAndSettle();
    expect(tester.widget<PButton>(_button('저장')).onPressed, isNotNull);
    await tester.tap(_button('저장'));
    await tester.pumpAndSettle();

    expect(findPlain('제목을 입력해주세요.'), findsOneWidget);
    expect(repo.saves, 0, reason: '저장 자체가 안 나가야 한다');
  });

  testWidgets('바뀐 값이 있는 채 닫으면 "작성한 내용이 사라져요" 를 묻고, 바깥을 눌러도 안 닫힌다', (
    tester,
  ) async {
    await _open(tester, edit: null);
    await tester.enterText(find.byType(PInput), '쓰던 글');
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();
    expect(find.byType(PTextarea), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('닫기').first);
    await tester.pumpAndSettle();
    expect(findPlain('작성한 내용이 사라져요'), findsOneWidget);
  });

  group('저장 실패 — 서버 원문 없이 시트 안 Callout', () {
    testWidgets('실패하면 시트가 열린 채 critical Callout 이 서고 쓴 값이 남는다', (tester) async {
      final repo = await _open(tester, edit: null);
      repo.failSave = true;
      await tester.enterText(find.byType(PInput), '새 메모');
      await tester.pumpAndSettle();
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();

      final callout = tester.widget<PCallout>(find.byType(PCallout));
      expect(callout.tone, PCalloutTone.critical);
      expect(callout.description, '저장하지 못했어요. 잠시 뒤 다시 시도해주세요.');
      expect(find.textContaining('RAW_SERVER_TEXT_4471'), findsNothing);
      expect(
        tester.widget<PInput>(find.byType(PInput)).controller!.text,
        '새 메모',
      );
      expect(tester.widget<PButton>(_button('저장')).onPressed, isNotNull);
    });
  });

  group('태그 줄 (QA #98)', () {
    testWidgets('고르기 시트의 선택지가 서버 목록에서 온다 — "태그 없음" 맨 앞 · 하드코딩 7종 없음', (
      tester,
    ) async {
      await _open(tester, edit: null, tags: [_tag(11, '업무'), _tag(12, '회의록')]);
      await tester.tap(_row('태그'));
      await tester.pumpAndSettle();

      expect(findPlain('업무'), findsOneWidget);
      expect(findPlain('회의록'), findsOneWidget);
      expect(findPlain('가계부'), findsNothing);
      final none = tester.getRect(findPlain('태그 없음').last).top;
      expect(none, lessThan(tester.getRect(findPlain('업무')).top));
    });

    testWidgets('서버에 없는 지금 태그도 남는다 — 편집하다 태그를 잃지 않는다', (tester) async {
      await _open(tester, tags: [_tag(11, '회의록')]);
      await tester.tap(_row('태그'));
      await tester.pumpAndSettle();
      expect(findPlain('개인'), findsWidgets);
      expect(findPlain('회의록'), findsOneWidget);
    });

    testWidgets('태그가 0개면 "태그는 설정 › 메모 태그에서 만들어요." 안내가 선다', (tester) async {
      await _open(tester, edit: _untagged);
      await tester.tap(_row('태그'));
      await tester.pumpAndSettle();
      expect(findPlain('태그는 설정 › 메모 태그에서 만들어요.'), findsOneWidget);
    });

    testWidgets('조회가 실패해도 죽지 않고 지금 태그를 지킨다', (tester) async {
      final repo = await _open(tester, tagsFail: true);
      expect(tester.takeException(), isNull);
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(repo.tag.value, '개인');
    });

    testWidgets('"태그 없음" 을 고르면 tag 가 명시적 null 로 실린다', (tester) async {
      final repo = await _open(tester, tags: [_tag(11, '업무')]);
      await tester.tap(_row('태그'));
      await tester.pumpAndSettle();
      await tester.tap(findPlain('태그 없음').last);
      await tester.pumpAndSettle();
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(
        repo.tag.present,
        isTrue,
        reason: 'tag 키가 빠지면 서버가 지금 이름으로 태그를 다시 이어 준다',
      );
      expect(repo.tag.value, isNull);
    });

    testWidgets('태그 없는 메모를 그대로 저장해도 이름이 지어지지 않는다', (tester) async {
      final repo = await _open(tester, edit: _untagged, tags: [_tag(11, '업무')]);
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(repo.tag.present, isTrue);
      expect(repo.tag.value, isNull);
    });

    testWidgets('새 메모의 기본값도 태그 없음이다', (tester) async {
      final repo = await _open(tester, edit: null, tags: [_tag(11, '업무')]);
      await tester.enterText(find.byType(PInput), '새 메모');
      await tester.pumpAndSettle();
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(repo.created, isTrue);
      expect(repo.createdTag, isNull);
    });
  });

  group('색상 줄', () {
    testWidgets('값 글은 색 이름이다 — hex 가 아니다', (tester) async {
      await _open(tester);
      expect(findPlain('파랑'), findsOneWidget);
      expect(find.textContaining('#2c70bf'), findsNothing);
    });

    testWidgets('팔레트 밖 색은 "지금 색" 이고 고르지 않으면 저장 값이 바뀌지 않는다', (tester) async {
      final repo = await _open(tester, edit: _memo.copyWith(color: '#9e9e9e'));
      expect(findPlain('지금 색'), findsOneWidget);
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(repo.color, '#9e9e9e');
    });
  });

  group('상단에 고정 스위치', () {
    testWidgets('스위치 줄 높이는 56 (ds Switch 가 정한다 — 일정 폼 종일 줄과 같다)', (
      tester,
    ) async {
      await _open(tester, edit: null);
      expect(tester.getSize(_row('상단에 고정')).height, 56);
    });

    testWidgets('고정이 지금과 다르면 저장 뒤 고정 길을 한 번 더 부른다', (tester) async {
      final repo = await _open(tester);
      await tester.tap(_row('상단에 고정'));
      await tester.pumpAndSettle();
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(repo.pinCalls, 1);
    });

    testWidgets('고정을 안 바꿨으면 고정 길을 부르지 않는다', (tester) async {
      final repo = await _open(tester);
      await tester.tap(_button('저장'));
      await tester.pumpAndSettle();
      expect(repo.pinCalls, 0);
    });
  });

  testWidgets('x2 글자 — 넘침 오류 0', (tester) async {
    await _open(tester, edit: null, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
