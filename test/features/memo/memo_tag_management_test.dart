// 메모 태그 설정(I-15 20 ~ 24) — 할 일 태그와 같은 한 부품([TagSettings])을 쓴다. 글 키만 다르다(메모 `mtag*` · 할 일 `ttag*`).
// 여기서 고정하는 것은 ① 메모 글 ② 화면이 저장소의 어느 메서드를 무슨 인자로 부르는지 ③ 실패 안내(저장 = 시트 안 Callout, 삭제 = 확인창을
// 닫고 다시 시도) ④ 두 화면이 한 부품을 import 하는 것이다. 시험은 작성만 했다(UI 이관이 끝날 때까지 돌리지 않는다).
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/memo/application/memo_providers.dart';
import 'package:groo_damda_app/features/memo/data/memo_tag_repository.dart';
import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/domain/memo_tag.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_tag_management_screen.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import '../../support/plain_text.dart';
import '../todo/todo_test_support.dart';

MemoTag _tag(int rowId, String name, {String? color, int usage = 0}) => MemoTag(
  rowId: rowId,
  tagName: name,
  userRowId: 1,
  color: color ?? '#2c70bf',
  usageCount: usage,
);

class _Repo extends MemoTagRepository {
  _Repo() : super(Dio());

  String? createdName;
  String? createdColor;
  int? updatedId;
  String? updatedName;
  final deleted = <int>[];
  bool fail = false;

  void _maybeFail() {
    if (fail) {
      throw ApiException(
        code: 'M',
        message: 'RAW_SERVER_TEXT_4471',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MemoTag> create({required String tagName, String? color}) async {
    _maybeFail();
    createdName = tagName;
    createdColor = color;
    return _tag(99, tagName, color: color);
  }

  @override
  Future<MemoTag> update({
    required int id,
    required String tagName,
    String? color,
  }) async {
    _maybeFail();
    updatedId = id;
    updatedName = tagName;
    return _tag(id, tagName, color: color);
  }

  @override
  Future<void> delete(int id) async {
    _maybeFail();
    deleted.add(id);
  }
}

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is PButton && w.label == label);

Finder _tagRow(String name) =>
    find.ancestor(of: findPlain(name), matching: find.byType(PListButtonItem));

Future<_Repo> _open(
  WidgetTester tester, {
  List<MemoTag> tags = const [],
  bool snackbarHost = false,
}) async {
  final repo = _Repo();
  await pumpApp(
    tester,
    const MemoTagManagementScreen(),
    overrides: [
      memoTagRepositoryProvider.overrideWith((ref) async => repo),
      memoTagListProvider.overrideWith((ref) async => tags),
      memoListProvider.overrideWith((ref) async => const <Memo>[]),
    ].cast(),
    snackbarHost: snackbarHost,
  );
  return repo;
}

void main() {
  setUpAll(loadRealFonts);

  testWidgets('안내 Callout 은 메모 글 — "태그별 묶음" 이 없고 "태그 없음" 으로 남는다고 말한다', (
    tester,
  ) async {
    await _open(tester, tags: [_tag(11, '회의록', usage: 3)]);
    final callout = tester.widget<PCallout>(find.byType(PCallout));
    expect(callout.tone, PCalloutTone.informative);
    expect(callout.title, isNull);
    expect(callout.icon, isNull, reason: 'informative 기본 아이콘(ⓘ)');
    expect(
      callout.description,
      "메모에 붙이는 태그예요. 메모 화면의 거르기에 쓰여요. 태그를 지우면 그 메모는 '태그 없음' 으로 남아요.",
    );
    expect(callout.description, isNot(contains('태그별 묶음')));
  });

  testWidgets('목록 제목 "메모 태그 · 1" boldSolid + 글 버튼 "태그 추가" · 줄 "3건에 사용 중"', (
    tester,
  ) async {
    await _open(tester, tags: [_tag(11, '회의록', usage: 3)]);
    final header = tester.widget<PListHeader>(find.byType(PListHeader));
    expect(header.title, '메모 태그 · 1');
    expect(header.variant, PListHeaderVariant.boldSolid);
    expect(tester.widget<PTextButton>(find.byType(PTextButton)).label, '태그 추가');
    expect(findPlain('3건에 사용 중'), findsOneWidget);
    expect(find.byType(PListTile), findsOneWidget);
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
  });

  testWidgets('새 태그를 만들면 create 가 불리고 목록을 다시 받은 뒤 시트가 닫힌다', (tester) async {
    final repo = await _open(tester);
    await tester.tap(find.text('태그 추가'));
    await tester.pumpAndSettle();
    expect(_button('삭제'), findsNothing);
    await tester.enterText(find.byType(PInput).first, '아이디어');
    await tester.pumpAndSettle();
    await tester.tap(_button('저장'));
    await tester.pumpAndSettle();
    expect(repo.createdName, '아이디어');
    expect(repo.createdColor, isNotNull);
    expect(findPlain('작성한 내용이 사라져요'), findsNothing);
  });

  testWidgets('행을 눌러 이름을 고치면 update 가 그 rowId 로 불린다 · 수정 시트엔 왼쪽 [삭제]', (
    tester,
  ) async {
    final repo = await _open(tester, tags: [_tag(11, '회의록')]);
    await tester.tap(_tagRow('회의록'));
    await tester.pumpAndSettle();
    expect(_button('삭제'), findsOneWidget);
    await tester.enterText(find.byType(PInput).first, '회의 기록');
    await tester.pumpAndSettle();
    await tester.tap(_button('저장'));
    await tester.pumpAndSettle();
    expect(repo.updatedId, 11);
    expect(repo.updatedName, '회의 기록');
    expect(repo.createdName, isNull);
  });

  testWidgets('저장이 실패하면 시트 안 critical Callout(고정 글) — 시트는 열려 있고 서버 원문은 없다', (
    tester,
  ) async {
    final repo = await _open(tester);
    repo.fail = true;
    await tester.tap(find.text('태그 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(PInput).first, '아이디어');
    await tester.pumpAndSettle();
    await tester.tap(_button('저장'));
    await tester.pumpAndSettle();
    final callouts = tester
        .widgetList<PCallout>(find.byType(PCallout))
        .toList();
    final fail = callouts.firstWhere((c) => c.tone == PCalloutTone.critical);
    expect(fail.description, '저장하지 못했어요. 잠시 뒤 다시 시도해주세요.');
    expect(find.textContaining('RAW_SERVER_TEXT_4471'), findsNothing);
    expect(
      tester.widget<PInput>(find.byType(PInput).first).controller!.text,
      '아이디어',
    );
  });

  testWidgets('삭제는 확인 한 번 → 지운다 · 글에 건수를 넣는다', (tester) async {
    final repo = await _open(tester, tags: [_tag(11, '회의록', usage: 4)]);
    await tester.tap(_tagRow('회의록'));
    await tester.pumpAndSettle();
    await tester.tap(_button('삭제'));
    await tester.pumpAndSettle();
    expect(find.byType(PAlertDialogView), findsOneWidget);
    expect(
      findPlain(
        '"회의록" 태그를 삭제하면 이 태그를 쓰는 메모 4건은 태그 없음으로 남아요. 삭제한 태그는 되돌릴 수 없어요.',
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(PAlertDialogView),
        matching: find.text('삭제'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.deleted, [11]);
  });

  testWidgets('삭제가 실패하면 확인창이 닫힌다 · 서버 원문은 없다', (tester) async {
    final repo = await _open(tester, tags: [_tag(11, '회의록')]);
    repo.fail = true;
    await tester.tap(_tagRow('회의록'));
    await tester.pumpAndSettle();
    await tester.tap(_button('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(PAlertDialogView),
        matching: find.text('삭제'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PAlertDialogView), findsNothing);
    expect(find.textContaining('RAW_SERVER_TEXT_4471'), findsNothing);
    expect(_tagRow('회의록'), findsOneWidget);
  });

  test('메모 태그 · 할 일 태그 두 화면이 한 부품(TagSettings)을 import 한다', () {
    for (final path in const [
      'lib/features/memo/presentation/memo_tag_management_screen.dart',
      'lib/features/todo/presentation/todo_tag_management_screen.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src, contains("shared/forms/tag_settings.dart"), reason: path);
      expect(src, contains('TagSettings('), reason: path);
    }
  });

  testWidgets('삭제 실패 — 스낵바 "삭제하지 못했어요…" + [다시 시도], 누르면 다시 지운다', (tester) async {
    final repo = await _open(
      tester,
      tags: [_tag(11, '회의록')],
      snackbarHost: true,
    );
    repo.fail = true;
    await tester.tap(_tagRow('회의록'));
    await tester.pumpAndSettle();
    await tester.tap(_button('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(PAlertDialogView),
        matching: find.text('삭제'),
      ),
    );
    await tester.pumpAndSettle();
    expect(findPlain('삭제하지 못했어요. 잠시 뒤 다시 시도해주세요.'), findsOneWidget);
    repo.fail = false;
    await tester.tap(findPlain('다시 시도'));
    await tester.pumpAndSettle();
    expect(repo.deleted, [11]);
  });

  testWidgets('L4 — 팔레트 밖 색 태그는 격자를 고른 뒤에도 "지금 색" 칸이 남고, 다시 고르면 저장 값으로 돌아간다', (
    tester,
  ) async {
    final repo = await _open(tester, tags: [_tag(11, '옛색', color: '#9e9e9e')]);
    await tester.tap(_tagRow('옛색'));
    await tester.pumpAndSettle();
    expect(findPlain('지금 색'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('빨강'));
    await tester.pumpAndSettle();
    expect(findPlain('지금 색'), findsOneWidget, reason: '격자를 골라도 칸이 사라지지 않는다');
    await tester.tap(find.bySemanticsLabel('지금 색'));
    await tester.pumpAndSettle();
    await tester.tap(_button('저장'));
    await tester.pumpAndSettle();
    expect(repo.updatedId, 11);
  });

  testWidgets('L2 — 불러오는 동안 목록 제목은 "메모 태그 · " + Skeleton, 버튼은 진짜', (
    tester,
  ) async {
    final repo = _Repo();
    await pumpApp(
      tester,
      const MemoTagManagementScreen(),
      overrides: [
        memoTagRepositoryProvider.overrideWith((ref) async => repo),
        memoTagListProvider.overrideWith(
          (ref) => Completer<List<MemoTag>>().future,
        ),
        memoListProvider.overrideWith((ref) async => const <Memo>[]),
      ].cast(),
      settle: false,
    );
    final header = tester.widget<PListHeader>(find.byType(PListHeader));
    expect(header.titleSuffix, isNotNull);
    expect(find.byType(PTextButton), findsOneWidget);
  });
}
