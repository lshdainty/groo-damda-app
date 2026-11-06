// 차트 실패 — 화면에는 고정 한 문장 "차트를 불러오지 못했어요." + [다시 시도] 뿐이다(I-wrap-b1 β).
// 오류 코드 · 서버 글 · 예외 글은 사용자에게 내지 않는다(디버그 로그로만).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/features/stocks/presentation/chart_web_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

import '../../support/plain_text.dart';

/// 토큰 발급이 [respond] 대로 끝나는 Dio — 호출 횟수를 센다.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  var calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

Future<_Adapter> _pump(
  WidgetTester tester,
  ResponseBody Function(RequestOptions) respond,
) async {
  final adapter = _Adapter(respond);
  final dio = Dio()..httpClientAdapter = adapter;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dioProvider.overrideWith((ref) async => dio)],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const Scaffold(
          body: ChartWebView(
            symbol: '005930',
            isUs: false,
            range: '1D',
            height: kStockChartWebViewHeight,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

ResponseBody _status(int code, String body) => ResponseBody.fromString(
  body,
  code,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  testWidgets('토큰 발급이 500 으로 실패 — 한 문장 + [다시 시도], 서버 글 · 코드 없음', (
    tester,
  ) async {
    final a = await _pump(
      tester,
      (_) => _status(500, '{"message":"SERVER-LEAK-메시지"}'),
    );
    expect(findText('차트를 불러오지 못했어요.'), findsOneWidget);
    expect(findText('다시 시도'), findsOneWidget);
    expect(findTextContaining('SERVER-LEAK'), findsNothing);
    expect(findTextContaining('500'), findsNothing);
    expect(findTextContaining('토큰'), findsNothing);
    expect(a.calls, 1);

    await tester.tap(findText('다시 시도'));
    await tester.pumpAndSettle();
    expect(a.calls, 2, reason: '[다시 시도] 가 토큰부터 다시 받는다');
    expect(findText('차트를 불러오지 못했어요.'), findsOneWidget);
  });

  testWidgets('토큰이 비어 있어도 같은 한 문장', (tester) async {
    await _pump(tester, (_) => _status(200, '{"data":{"token":""}}'));
    expect(findText('차트를 불러오지 못했어요.'), findsOneWidget);
    expect(findTextContaining('토큰 발급 실패'), findsNothing);
  });

  testWidgets('응답이 이상해도(예외) 개발 용어 없이 같은 한 문장', (tester) async {
    await _pump(tester, (_) => throw StateError('boom-internal'));
    expect(findText('차트를 불러오지 못했어요.'), findsOneWidget);
    expect(findTextContaining('boom-internal'), findsNothing);
    expect(findTextContaining('초기화'), findsNothing);
  });
}
