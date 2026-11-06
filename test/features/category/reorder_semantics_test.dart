// category_screen 의 정렬 저장 로직이 기대는 프레임워크 계약을 고정한다.
//
// Flutter 3.41 에서 ReorderableListView 의 onReorder 가 deprecated 되고
// onReorderItem 으로 바뀌었다. 둘은 타입이 같아서(ReorderCallback) 이름만 바꿔도
// 컴파일이 통과한다 — 다른 건 newIndex 의 의미다.
//
//   onReorder      : 아래로 옮길 때 "제거 전" 인덱스가 온다 → 직접 -1 보정 필요
//   onReorderItem  : 프레임워크가 이미 보정해서 준다        → 또 보정하면 한 칸 어긋난다
//
// 즉 이름만 바꾸고 기존 `if (newIndex > oldIndex) newIndex -= 1;` 를 남겨두면
// 조용히 한 칸씩 밀린 순서가 서버에 저장된다. 눈에 잘 안 띄는 종류의 버그다.
//
// 인덱스 숫자를 직접 단언하면 드래그 거리에 따라 흔들리므로, category_screen 과
// 같은 매핑을 적용한 뒤 **실제로 그려진 순서**를 본다 — 사용자가 보는 결과가 곧 계약이다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/plain_text.dart';

/// category_screen 의 두 onReorderItem 이 쓰는 것과 같은 매핑.
List<String> applyReorder(List<String> source, int oldIndex, int newIndex) {
  final reordered = [...source];
  final moved = reordered.removeAt(oldIndex);
  reordered.insert(newIndex, moved);
  return reordered;
}

void main() {
  const rowHeight = 56.0;

  /// 리스트를 띄우고 [from] 번째 항목을 [rows] 칸만큼 끌어 옮긴다.
  /// onReorderItem 이 준 인덱스에 [applyReorder] 를 적용해 실제로 순서를 바꾸고,
  /// 화면에 그려진 최종 순서를 돌려준다.
  Future<List<String>> dragAndRead(
    WidgetTester tester,
    List<String> initial, {
    required int from,
    required int rows,
  }) async {
    var items = [...initial];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ReorderableListView.builder(
              itemCount: items.length,
              onReorderItem: (oldIndex, newIndex) => setState(
                () => items = applyReorder(items, oldIndex, newIndex),
              ),
              itemBuilder: (_, i) => SizedBox(
                key: ValueKey(items[i]),
                height: rowHeight,
                child: Center(child: Text(items[i])),
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(findText(initial[from])),
    );
    // 기본 드래그 핸들은 롱프레스로 잡힌다 — 인식 시간(500ms)을 넉넉히 넘긴다.
    await tester.pump(const Duration(seconds: 1));

    // 한 번에 크게 옮기면 중간 갱신이 생략돼 실제 이동 칸수가 달라진다.
    // 반 칸씩 나눠 움직이며 리스트가 따라오게 한다.
    final steps = (rows.abs() * 2);
    final unit = rowHeight / 2 * (rows.isNegative ? -1 : 1);
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(0, unit));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    return items;
  }

  testWidgets('아래로 한 칸 끌면 그 아래 항목과 자리가 바뀐다', (tester) async {
    const initial = ['A', 'B', 'C', 'D'];

    final result = await dragAndRead(tester, initial, from: 0, rows: 1);

    // -1 보정을 중복으로 하면 A 가 제자리에 남아 ['A','B','C','D'] 가 된다.
    expect(result, ['B', 'A', 'C', 'D']);
  });

  testWidgets('위로 한 칸 끌면 그 위 항목과 자리가 바뀐다', (tester) async {
    const initial = ['A', 'B', 'C', 'D'];

    final result = await dragAndRead(tester, initial, from: 2, rows: -1);

    expect(result, ['A', 'C', 'B', 'D']);
  });

  testWidgets('아래로 두 칸 끌면 두 칸 내려간다', (tester) async {
    const initial = ['A', 'B', 'C', 'D'];

    final result = await dragAndRead(tester, initial, from: 0, rows: 2);

    expect(result, ['B', 'C', 'A', 'D']);
  });

  test('제자리 이동이면 순서가 그대로다', () {
    // onReorderItem 은 oldIndex == newIndex 일 때 아예 호출되지 않지만,
    // 매핑 자체도 항등이어야 한다 — 호출부에 별도 가드가 없어도 안전하다.
    const items = ['A', 'B', 'C'];

    expect(applyReorder(items, 1, 1), items);
  });
}
