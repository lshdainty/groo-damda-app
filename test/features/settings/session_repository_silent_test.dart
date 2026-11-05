// revoke · revokeAll 은 전역 오류 알림을 끈다(I-12 31) — 화면이 알림 하나만 띄운다.
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/network/silent_error_toast.dart';
import 'package:groo_damda_app/features/settings/data/session_repository.dart';

class _Capture implements HttpClientAdapter {
  final extras = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    extras.add(Map.of(options.extra));
    return ResponseBody.fromString('', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('revoke · revokeAll 이 kSilentErrorToast 를 싣는다', () async {
    final adapter = _Capture();
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = SessionRepository(dio);
    await repo.revoke('s1');
    await repo.revokeAll();
    expect(adapter.extras, hasLength(2));
    for (final e in adapter.extras) {
      expect(e[kSilentErrorToast], isTrue);
    }
  });
}
