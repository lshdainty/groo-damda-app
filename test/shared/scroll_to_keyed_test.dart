// 목록 안 특정 항목으로 스크롤 — **화면 밖이어도 간다.**
//
// 가계부 달력에서 오래된 날짜를 눌러도 아무 일이 없었다(2026-09-17). `ListView` 는
// 보이는 범위에만 element 를 만들어서, 멀리 있는 그룹의 `GlobalKey.currentContext` 가
// null 이고 `Scrollable.ensureVisible` 이 조용히 no-op 이 됐기 때문이다.
//
// 여기서 잠그는 것은 셋이다.
// - 화면 밖 항목은 애초에 context 가 없다(문제의 뿌리 — 이게 깨지면 이 헬퍼가 필요 없어진다)
// - 그런 항목도 헬퍼를 거치면 화면에 들어온다
// - 목록에 없는 항목을 불러도 죽지 않는다
//
// `ensureVisibleWhenReady` 는 그 다음 자리다 — 그룹까지는 갔고 행이 만들어지기만
// 기다리는 경우. 그룹 이동이 두 홉 이상 걸리면 한 프레임 뒤 한 번의 시도는 아직 없는
// 행을 만나 조용히 건너뛴다(QA 22차 추정).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/shared/scroll/scroll_to_keyed.dart';
import '../support/plain_text.dart';

const _rows = 40;
const _rowHeight = 120.0;

void main() {
  late Map<int, GlobalKey> keys;
  late ScrollController ctrl;

  Future<void> pumpList(WidgetTester tester) async {
    keys = {for (var i = 0; i < _rows; i++) i: GlobalKey()};
    ctrl = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: ctrl,
            children: [
              for (var i = 0; i < _rows; i++)
                KeyedSubtree(
                  key: keys[i],
                  child: SizedBox(height: _rowHeight, child: Text('day $i')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  tearDown(() => ctrl.dispose());

  testWidgets('화면 밖 항목은 context 가 없다 — 이게 문제의 뿌리다', (tester) async {
    await pumpList(tester);
    expect(keys[0]!.currentContext, isNotNull);
    expect(keys[_rows - 1]!.currentContext, isNull);
  });

  testWidgets('맨 아래 항목으로 간다', (tester) async {
    await pumpList(tester);
    const target = _rows - 1;

    scrollToKeyedItem(
      controller: ctrl,
      key: keys[target],
      index: target,
      count: _rows,
    );
    await tester.pumpAndSettle();

    expect(findText('day $target'), findsOneWidget);
    expect(keys[target]!.currentContext, isNotNull);
  });

  testWidgets('가운데 항목으로 간다 — 아래로 갔다가 위로도 돌아온다', (tester) async {
    await pumpList(tester);

    scrollToKeyedItem(
      controller: ctrl,
      key: keys[_rows - 1],
      index: _rows - 1,
      count: _rows,
    );
    await tester.pumpAndSettle();

    // 이제 위쪽이 화면 밖이다 — 반대 방향도 되어야 한다.
    expect(keys[2]!.currentContext, isNull);
    scrollToKeyedItem(controller: ctrl, key: keys[2], index: 2, count: _rows);
    await tester.pumpAndSettle();

    expect(findText('day 2'), findsOneWidget);
  });

  testWidgets('이미 보이는 항목은 그대로 보인다', (tester) async {
    await pumpList(tester);

    scrollToKeyedItem(controller: ctrl, key: keys[0], index: 0, count: _rows);
    await tester.pumpAndSettle();

    expect(findText('day 0'), findsOneWidget);
  });

  testWidgets('목록에 없는 항목을 불러도 죽지 않는다', (tester) async {
    await pumpList(tester);

    scrollToKeyedItem(controller: ctrl, key: null, index: 3, count: _rows);
    scrollToKeyedItem(
      controller: ctrl,
      key: GlobalKey(),
      index: -1,
      count: _rows,
    );
    await tester.pumpAndSettle();

    // 아무 일도 안 일어났고 화면은 처음 그대로다.
    expect(findText('day 0'), findsOneWidget);
  });

  group('ensureVisibleWhenReady — 만들어지기를 기다린다', () {
    testWidgets('이미 만들어진 항목은 바로 맞춘다', (tester) async {
      await pumpList(tester);

      ensureVisibleWhenReady(key: keys[2]);
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byKey(keys[2]!)).top, lessThan(600.0));
    });

    testWidgets('아직 안 만들어진 항목은 만들어진 뒤에 맞춘다', (tester) async {
      await pumpList(tester);
      expect(keys[30]!.currentContext, isNull);

      ensureVisibleWhenReady(key: keys[30]);
      // 아직 없다 — 여기서 포기하면 사용자 눈에는 "눌러도 반응이 없다" 다.
      await tester.pump();
      expect(ctrl.offset, 0.0);

      // 앞선 그룹 이동이 몇 프레임 뒤에 끝나는 상황. 행 30 은 화면 바로 위에
      // 만들어지지만(cacheExtent) 보이지는 않는다.
      ctrl.jumpTo(31 * _rowHeight);
      await tester.pump();
      await tester.pumpAndSettle();

      final rect = tester.getRect(find.byKey(keys[30]!));
      expect(rect.top, greaterThanOrEqualTo(0.0));
      expect(rect.top, lessThan(600.0));
    });

    testWidgets('끝까지 안 만들어져도 죽지 않는다', (tester) async {
      await pumpList(tester);

      ensureVisibleWhenReady(key: GlobalKey());
      ensureVisibleWhenReady(key: null);
      for (var i = 0; i < 12; i++) {
        await tester.pump();
      }

      expect(ctrl.offset, 0.0);
    });
  });
}
