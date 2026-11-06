// `SessionScope` — 로그인한 사람이 바뀌면 ProviderContainer 를 통째로 새로 만든다.
//
// 누가 바뀌었는지는 `SessionOwner` 가, 실제 앱에서 값이 안 넘어가는지는
// account_switch_test 가 본다. 여기서는 **컨테이너를 가는 장치 자체**만 본다 —
// 새로 만들었는데 옛 값이 남거나, 테스트용 override 가 빠지거나, 부르는 시점 때문에
// 던지면 위의 둘이 다 무너진다.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/session_scope.dart';
import '../support/plain_text.dart';

/// 컨테이너가 살아 있는 동안 값을 들고 있는 provider — autoDispose 가 아니다.
/// 앱의 조회 provider 들과 같은 수명이다.
final _cached = NotifierProvider<_Cached, String>(_Cached.new);

class _Cached extends Notifier<String> {
  @override
  String build() {
    ref.onDispose(() => _disposed++);
    return 'empty';
  }

  void put(String value) => state = value;
}

/// [_Cached] 가 폐기된 횟수 — 컨테이너가 버려졌는지 보는 창.
int _disposed = 0;

final _greeting = Provider<String>((ref) => 'real');

void main() {
  setUp(() => _disposed = 0);

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(_Probe)));

  /// 새로 만들어 달라고 하고, 새 컨테이너로 그려질 때까지 민다.
  ///
  /// 요청은 microtask 로 한 박자 미뤄진다(빌드 도중에 불려도 되게). 테스트의 가짜
  /// 시계에서는 첫 `pump` 가 그 microtask 를 돌리고, 다음 `pump` 가 새 프레임을 그린다.
  Future<void> restart(WidgetTester tester) async {
    containerOf(tester).read(sessionRestartProvider)!();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('새로 만들면 받아 둔 값이 하나도 안 남고, 옛 컨테이너는 버려진다', (tester) async {
    await tester.pumpWidget(const SessionScope(child: _Probe()));
    final first = containerOf(tester);
    first.read(_cached.notifier).put("alice's");
    await tester.pump();
    expect(findText("alice's"), findsOneWidget);

    await restart(tester);

    final second = containerOf(tester);
    expect(identical(first, second), isFalse);
    expect(findText("alice's"), findsNothing);
    expect(findText('empty'), findsOneWidget);
    expect(_disposed, 1, reason: '옛 컨테이너가 살아 있으면 값도 타이머도 계속 남는다');
  });

  testWidgets('override 는 새 컨테이너에도 그대로 걸린다', (tester) async {
    await tester.pumpWidget(
      SessionScope(
        overrides: [_greeting.overrideWithValue('fake')],
        child: const _Probe(),
      ),
    );
    expect(containerOf(tester).read(_greeting), 'fake');

    await restart(tester);

    expect(
      containerOf(tester).read(_greeting),
      'fake',
      reason: '가짜 서버가 첫 컨테이너에만 걸리면 그다음부터 진짜 네트워크를 탄다',
    );
  });

  testWidgets('새 컨테이너에서도 다시 새로 만들 수 있다', (tester) async {
    await tester.pumpWidget(const SessionScope(child: _Probe()));

    for (var i = 0; i < 3; i++) {
      final before = containerOf(tester);
      await restart(tester);
      expect(identical(before, containerOf(tester)), isFalse);
    }
    expect(_disposed, 3);
  });

  testWidgets('빌드 도중에 불려도 던지지 않고 빌드가 끝난 뒤에 바꾼다', (tester) async {
    // 인증 상태는 서버 응답 뒤에 바뀌므로 보통은 빌드 밖이다. 그래도 빌드 중에
    // setState 가 나가면 그 자리에서 던지므로, 그 길도 막아 둔다.
    var asked = false;
    await tester.pumpWidget(
      SessionScope(
        child: _Probe(
          onBuild: (ref) {
            if (asked) return;
            asked = true;
            ref.read(sessionRestartProvider)!();
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final first = containerOf(tester);

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(identical(first, containerOf(tester)), isFalse);
    expect(_disposed, 1, reason: '미뤘다가 잊으면 안 된다 — 빌드가 끝나면 바꿔야 한다');
  });

  testWidgets('SessionScope 밖에서는 바꿀 주체가 없다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: _Probe()));

    expect(containerOf(tester).read(sessionRestartProvider), isNull);
  });
}

class _Probe extends ConsumerWidget {
  const _Probe({this.onBuild});

  final void Function(WidgetRef ref)? onBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onBuild?.call(ref);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(ref.watch(_cached)),
    );
  }
}
