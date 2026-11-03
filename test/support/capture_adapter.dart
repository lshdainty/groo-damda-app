import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 나가는 요청 본문을 그대로 잡는 어댑터 — 가짜 저장소로는 "키를 실었는가" 가 안 보인다(`'key': ?value` 는 null 이면 키가 없다).
class CaptureAdapter implements HttpClientAdapter {
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
    final body = jsonEncode({
      'success': true,
      'code': 'OK',
      'message': '',
      'data': {'rowId': 1, 'templateName': 'x', 'expenseType': 'EXPENSE'},
    });
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
