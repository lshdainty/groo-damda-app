// 화면의 "지금" 은 clockProvider 하나다 — 시계를 고정하면 화면이 그 날짜를 쓴다(B6 다.8).
// 벽시계가 아니라 고정한 날짜(2026-09-16 12:00Z)에 기대므로 어느 날 돌려도 같다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/clock/clock.dart';
import 'package:groo_damda_app/core/format/now_tick.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_screen.dart';
import '../../support/plain_text.dart';
import 'todo_test_support.dart';

void main() {
  setUpAll(loadRealFonts);

  final fixed = DateTime.utc(2026, 9, 16, 12);

  testWidgets('할 일 화면 — 시계를 고정하면 달 줄이 그 달을 가리킨다', (tester) async {
    await pumpApp(
      tester,
      const TodoScreen(),
      overrides: [
        ...todoOverrides(todos: [todo(1, '고정한 날 일', due: '2026-09-16')]),
        clockProvider.overrideWithValue(() => fixed),
      ],
    );
    expect(findText('2026년 9월'), findsOneWidget);
    expect(findPlain('고정한 날 일'), findsWidgets);
  });

  test(
    'clockProvider — 기본은 벽시계, override 하면 고정 · nowTick 도 같은 시계를 눈금으로 내린다',
    () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final before = DateTime.now();
      final got = c.read(clockProvider)();
      expect(got.isBefore(before), isFalse);

      final pinned = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(
            () => DateTime.utc(2026, 9, 16, 12, 0, 45),
          ),
        ],
      );
      addTearDown(pinned.dispose);
      expect(
        pinned.read(clockProvider)(),
        DateTime.utc(2026, 9, 16, 12, 0, 45),
      );
      expect(
        pinned.read(nowTickProvider),
        DateTime.fromMillisecondsSinceEpoch(
          DateTime.utc(2026, 9, 16, 12).millisecondsSinceEpoch,
        ),
      );
    },
  );
}
