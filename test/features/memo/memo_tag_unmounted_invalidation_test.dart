// 메모 태그를 저장·삭제하는 도중에 화면을 닫아도 **터지지 않고, 목록은 걷힌다**.
//
// 할 일 태그 화면(`todo_tag_unmounted_invalidation_test.dart`)과 같은 자리다 — 두 화면이 한 부품([TagSettings])을 쓴다.
//
// 두 가지가 한꺼번에 걸린 자리다.
//
// 1) `flutter_riverpod` 의 `WidgetRef` 는 unmount 뒤에 쓰면 `StateError` 를 **던진다**
//    (`core/consumer.dart:454` `_assertNotDisposed`). 저장이 끝나기 전에 뒤로 가면
//    `await` 뒤의 `ref.invalidate(...)` 가 그대로 처리되지 않은 비동기 에러가 된다.
// 2) 그렇다고 `if (mounted)` 로 막으면 **무효화 자체가 안 일어난다.** 서버엔 이미
//    들어간 이름이 목록에는 옛 값으로 남는다 — `memoTagListProvider` 는 keepAlive 이고
//    `memoListProvider` 도 autoDispose 가 아니라, 둘 다 화면보다 오래 살기 때문이다.
//    포그라운드 복귀 전까지 아무도 안 걷는다.
//
// 그래서 화면이 아니라 `ProviderContainer` 로 비운다(#348·#351 과 같은 방식). 컨테이너는
// `ProviderScope` 의 것이라 화면 수명과 무관하다.
//
// 여기서 잠그는 것은 **화면이 사라진 뒤에도 목록이 새 값이 된다**는 것 하나다.
// 가드를 되돌리면(=`if (mounted) ref.invalidate`) 목록이 옛 값으로 남아 깨지고,
// 가드를 아예 빼면(=`ref.invalidate`) 예외가 나서 깨진다. 양쪽 다 걸린다.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/memo/application/memo_providers.dart';
import 'package:groo_damda_app/features/memo/data/memo_tag_repository.dart';
import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/domain/memo_tag.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_tag_management_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import '../../support/plain_text.dart';

MemoTag _tag(int rowId, String name) =>
    MemoTag(rowId: rowId, tagName: name, userRowId: 1, usageCount: 0);

/// 서버 역할 — 태그 마스터를 들고 있고, **응답 시점은 테스트가 정한다**.
///
/// 저장이 나가고 아직 안 돌아온 그 사이에 화면을 닫는 것이 이 테스트의 전부다.
class _SlowRepo extends MemoTagRepository {
  _SlowRepo() : super(Dio());

  final List<MemoTag> server = [_tag(11, '회의록')];
  final Completer<void> inflight = Completer<void>();

  @override
  Future<List<MemoTag>> list() async => List.of(server);

  @override
  Future<MemoTag> create({required String tagName, String? color}) async {
    await inflight.future;
    final created = _tag(99, tagName);
    server.add(created);
    return created;
  }

  @override
  Future<void> delete(int id) async {
    await inflight.future;
    server.removeWhere((t) => t.rowId == id);
  }
}

Finder _field() => find.byType(PInput).first;

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is PButton && w.label == label);

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  late _SlowRepo repo;
  late ProviderContainer container;

  /// `memoListProvider` 가 **다시 조회된 횟수**. 태그를 고치면 메모의 `tag`
  /// 문자열도 서버가 함께 옮기므로 이쪽도 같이 걷혀야 한다.
  late int memoReads;

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    repo = _SlowRepo();
    memoReads = 0;
    container = ProviderContainer(
      overrides: [
        memoTagRepositoryProvider.overrideWith((ref) async => repo),
        memoTagListProvider.overrideWith((ref) => repo.list()),
        memoListProvider.overrideWith((ref) async {
          memoReads++;
          return const <Memo>[];
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const MemoTagManagementScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 메모 목록은 이 화면 밖(메모 화면)에서 이미 캐시돼 있다 — 안 걷으면 옛 값이
    // 남는 바로 그 자리다. 캐시를 만들어 둬야 "걷혔다" 를 잴 수 있다.
    await container.read(memoListProvider.future);
    expect(memoReads, 1);
  }

  /// 화면을 닫는다 — 트리에서 빼면 `_BodyState` 가 unmount 된다.
  Future<void> closeScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        // 새 키 — 같은 모양이면 Navigator 가 재사용돼 열린 시트가 로컬라이제이션 없는 새 앱 아래 남는다
        child: MaterialApp(key: UniqueKey(), home: const Scaffold()),
      ),
    );
    await tester.pump();
    expect(find.byType(MemoTagManagementScreen), findsNothing);
  }

  testWidgets('저장이 끝나기 전에 화면을 닫아도 목록이 새 이름으로 걷힌다', (tester) async {
    await open(tester);

    // 목록 제목의 글 버튼 "태그 추가" — 새 태그 폼이 시트로 뜬다.
    await tester.tap(findText(l.memoNewTag));
    await tester.pumpAndSettle();
    await tester.enterText(_field(), '아이디어');
    await tester.pumpAndSettle();
    await tester.tap(_button(l.actionSave));
    // 저장이 나갔고 서버는 아직 대답하지 않았다 — 저장 버튼이 로딩이라 가라앉지 않는다.
    await tester.pump(const Duration(milliseconds: 100));

    await closeScreen(tester);

    // 이제 서버가 대답한다 — 화면은 이미 없다.
    repo.inflight.complete();
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: '화면이 사라진 뒤 `ref` 를 쓰면 StateError 가 난다 — 컨테이너로 비워야 한다',
    );
    expect(
      (await container.read(memoTagListProvider.future)).map((t) => t.tagName),
      contains('아이디어'),
      reason: '서버엔 들어갔는데 목록이 옛 값이다 — 닫혔다고 무효화를 건너뛰면 이렇게 남는다',
    );
    // 무효화는 표시만 남기고 실제 재조회는 다음에 읽을 때 일어난다 — 걷혔으면
    // 여기서 한 번 더 조회되고, 안 걷혔으면 캐시 그대로라 조회 수가 그대로다.
    await container.read(memoListProvider.future);
    expect(memoReads, 2, reason: '개명이면 메모의 `tag` 문자열도 옮겨진다 — 메모 목록도 걷혀야 한다');
  });

  testWidgets('삭제가 끝나기 전에 화면을 닫아도 목록에서 사라진다', (tester) async {
    await open(tester);

    // 스와이프 트레이의 '삭제' — 제스처 대신 그 행이 건 콜백을 그대로 탄다.
    final actions = tester
        .widget<PSwipeActions>(find.byType(PSwipeActions))
        .actions;
    expect(actions.last.label, l.actionDelete);
    actions.last.onSelect();
    await tester.pumpAndSettle();

    await tester.tap(_button(l.actionDelete).last);
    // 확정 버튼이 끝날 때까지 로딩이라 가라앉지 않는다.
    await tester.pump(const Duration(milliseconds: 100));

    await closeScreen(tester);

    repo.inflight.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      await container.read(memoTagListProvider.future),
      isEmpty,
      reason: '서버에선 지워졌는데 목록엔 남아 있다 — 닫혔다고 무효화를 건너뛴 것이다',
    );
    await container.read(memoListProvider.future);
    expect(
      memoReads,
      2,
      reason: '삭제는 그 태그를 쓰던 메모의 `tag` 를 비운다 — 메모 목록도 걷혀야 한다',
    );
  });
}
