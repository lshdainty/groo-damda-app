// 응답 형식 오류(I-wrap-b2b 3) — 저장소 공용 throwAsApiException 이 TypeError · FormatException 을 ApiException(PARSE) 으로
// 바꾼다. 화면 글은 고정 글이고 원문은 로그에만 남는다. 불러오기 · 저장 모두 zone 으로 빠지지 않는다.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';

class _BodyAdapter implements HttpClientAdapter {
  _BodyAdapter(this.body);
  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

Object? _thrown(void Function() f) {
  try {
    f();
  } catch (e) {
    return e;
  }
  return null;
}

void main() {
  const fixed = '요청을 처리하지 못했어요. 잠시 뒤 다시 시도해주세요.';

  group('throwAsApiException', () {
    test(
      'TypeError · FormatException → ApiException(PARSE) · 고정 글 · 원문은 cause 에만',
      () {
        final typeError = _thrown(() => ('글' as dynamic) as int)!;
        final format = const FormatException('날짜 원문 2026-13-45');
        for (final raw in [typeError, format]) {
          final e = _thrown(() => throwAsApiException(raw, StackTrace.current));
          expect(e, isA<ApiException>());
          final api = e! as ApiException;
          expect(api.code, kApiParseErrorCode);
          expect(api.message, fixed);
          expect(api.message, isNot(contains('2026-13-45')));
          expect(api.cause, same(raw));
        }
      },
    );

    test('DioException → fromDio, ApiException · 다른 오류는 그대로(같은 것)', () {
      final dio = DioException(requestOptions: RequestOptions(path: '/x'));
      final fromDio = _thrown(
        () => throwAsApiException(dio, StackTrace.current),
      );
      expect((fromDio! as ApiException).code, 'NETWORK');
      final api = ApiException(code: 'EXPENSE_404', message: '없음');
      expect(
        _thrown(() => throwAsApiException(api, StackTrace.current)),
        same(api),
      );
      final state = StateError('다른 오류');
      expect(
        _thrown(() => throwAsApiException(state, StackTrace.current)),
        same(state),
      );
    });
  });

  group('저장소 — 형이 다른 본문', () {
    ExpenseRepository repo(Object body) =>
        ExpenseRepository(Dio()..httpClientAdapter = _BodyAdapter(body));

    test('불러오기(list) — 목록 줄의 형이 다르면 ApiException(PARSE)', () async {
      final r = repo({
        'success': true,
        'code': 'OK',
        'message': '',
        'data': {
          'expenses': [
            {'rowId': '하나'},
          ],
        },
      });
      await expectLater(
        r.list(),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', kApiParseErrorCode),
        ),
      );
    });

    test('저장(create) — 돌려받은 거래의 형이 다르면 ApiException(PARSE)', () async {
      final r = repo({
        'success': true,
        'code': 'OK',
        'message': '',
        'data': {'rowId': '하나'},
      });
      await expectLater(
        r.create(
          categoryRowId: 1,
          expenseType: 'EXPENSE',
          amount: 1000,
          expenseDate: '2026-11-06T00:00:00',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', kApiParseErrorCode),
        ),
      );
    });

    test('success:false 는 지금처럼 서버 코드의 ApiException', () async {
      final r = repo({
        'success': false,
        'code': 'EXPENSE_001',
        'message': '서버 글',
        'data': null,
      });
      await expectLater(
        r.list(),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'EXPENSE_001'),
        ),
      );
    });
  });
}
