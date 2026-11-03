import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 나가는 요청 본문을 그대로 잡는 어댑터 — 가짜 저장소로는 "키를 실었는가" 가 안 보인다(`'key': ?value` 는 null 이면 키가 없다).
class CaptureAdapter implements HttpClientAdapter {
  /// 응답 상태 — 200 이 아니면 실패 본문을 돌려준다(저장 실패 시험).
  int status = 200;
  final List<RequestOptions> requests = [];

  Map<String, dynamic>? get lastBody {
    final d = requests.isEmpty ? null : requests.last.data;
    return d is Map ? Map<String, dynamic>.from(d) : null;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final ok = status == 200;
    final body = jsonEncode({
      'success': ok,
      'code': ok ? 'OK' : 'ERR',
      'message': '',
      'data': {'rowId': 1, 'templateName': 'x', 'expenseType': 'EXPENSE'},
    });
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
