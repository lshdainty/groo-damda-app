import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/core/diagnostics/global_error_hooks.dart';

void main() {
  final origFlutter = FlutterError.onError;
  final origPlatform = PlatformDispatcher.instance.onError;
  tearDown(() {
    FlutterError.onError = origFlutter;
    PlatformDispatcher.instance.onError = origPlatform;
  });

  test('두 훅이 세워지고 프레임워크 오류는 기록 + presentError 로 간다', () {
    final logs = <String>[];
    final presented = <FlutterErrorDetails>[];
    installGlobalErrorHooks(log: logs.add, present: presented.add);

    expect(FlutterError.onError, isNot(same(origFlutter)));
    expect(PlatformDispatcher.instance.onError, isNotNull);

    FlutterError.onError!(
      FlutterErrorDetails(
        exception: StateError('boom'),
        stack: StackTrace.current,
      ),
    );
    expect(presented, hasLength(1));
    expect(logs.single, contains('boom'));
  });

  test('플랫폼 오류는 기록되고 처리됨(true)으로 표시된다', () {
    final logs = <String>[];
    installGlobalErrorHooks(log: logs.add, present: (_) {});
    final handled = PlatformDispatcher.instance.onError!(
      ArgumentError('async-fail'),
      StackTrace.current,
    );
    expect(handled, isTrue);
    expect(logs.single, contains('async-fail'));
  });
}
