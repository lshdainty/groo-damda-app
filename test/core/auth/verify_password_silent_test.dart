// verifyPassword 는 silent 표식을 싣는다(I-14 43) — 그루 계정이 쓴 글이 화면에 그대로 닿지 않는다. 가짜 저장소가 아니라 진짜 저장소 ·
// 가짜 어댑터로 요청 옵션을 잠근다.
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/auth/auth_repository.dart';
import 'package:groo_damda_app/core/network/silent_error_toast.dart';

class _Capture implements HttpClientAdapter {
  final extras = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    extras.add(Map.of(options.extra));
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('verifyPassword 가 kSilentErrorToast 를 싣는다', () async {
    final adapter = _Capture();
    final dio = Dio()..httpClientAdapter = adapter;
    await AuthRepository(dio).verifyPassword('pw');
    expect(adapter.extras, hasLength(1));
    expect(adapter.extras.single[kSilentErrorToast], isTrue);
  });
}
