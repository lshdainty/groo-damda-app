import 'package:flutter/foundation.dart';

/// 처리되지 않은 오류를 로컬 로그에만 남긴다. 화면에 아무것도 띄우지 않고 어디로도 보내지 않는다.
///
/// - 프레임워크 오류: 원래 핸들러(기본 [FlutterError.presentError])를 그대로 부르고, 로그를 더한다.
/// - 비동기·플랫폼 오류: 기록하고 처리된 것으로 표시한다(true).
///
/// 시험이 갈아끼울 수 있게 [log] · [present] 를 인자로 받는다.
void installGlobalErrorHooks({
  void Function(String message)? log,
  void Function(FlutterErrorDetails details)? present,
}) {
  final write = log ?? (m) => debugPrint(m);
  final show = present ?? FlutterError.presentError;

  FlutterError.onError = (details) {
    show(details);
    write(
      '[FlutterError] ${details.exceptionAsString()}\n${details.stack ?? ''}',
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    write('[Unhandled] $error\n$stack');
    return true;
  };
}
