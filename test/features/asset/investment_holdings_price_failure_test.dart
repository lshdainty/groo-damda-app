// 자산 편집 보유 미리보기 — 연동 시세를 처음부터 못 받으면 평가액 · 합계가 비어 "평가 0" 처럼 읽히지 않게 그 자리
// Result Section medium + [다시 시도](디자인시스템 판단 5, B2a 분할 실패와 같은 꼴). 다시 받으면 걷힌다.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart';
import 'package:groo_damda_app/features/stocks/application/live_prices.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

import '../../support/plain_text.dart';

const _invest = Asset(
  rowId: 12,
  assetName: '숲길증권 위탁',
  assetType: 'INVESTMENT',
  balance: 5000000,
  institution: '키움증권',
  isIncludedInTotal: 'Y',
  holdings: [AssetHolding(linked: true, tossSymbol: '005930', quantity: '10')],
);

/// 나가는 요청 본문을 그대로 잡는다 — 시세를 모르는 채 저장하면 무엇이 서버로 가는지 본다.
class _BodyAdapter implements HttpClientAdapter {
  Map<String, dynamic>? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final d = options.data;
    if (d is Map) body = Map<String, dynamic>.from(d);
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'code': 'OK',
        'message': '',
        'data': {'rowId': 12, 'assetName': 'x', 'assetType': 'INVESTMENT'},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Widget _app(_BodyAdapter adapter, bool Function() priceFails) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    assetsProvider.overrideWith((ref) async => const [_invest]),
    myFeaturesProvider.overrideWith(
      (ref) async => const MyFeatures(
        features: ['SECURITIES'],
        connectedBrokers: ['TOSS'],
        primaryBroker: 'TOSS',
      ),
    ),
    assetRepositoryProvider.overrideWith(
      (ref) async => AssetRepository(Dio()..httpClientAdapter = adapter),
    ),
    livePricesProvider.overrideWith((ref, key) async {
      if (priceFails()) throw StateError('서버 원문');
      return const LivePrices.empty();
    }),
  ],
  child: MaterialApp(
    theme: GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showInvestmentEditDialog(ctx, _invest),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
}

final _failure = find.byKey(const ValueKey('holdings-price-failure'));

void main() {
  testWidgets('시세를 처음부터 못 받으면 합계도 "—"(0 아님) — 그대로 저장해도 평가액 · 잔액은 실리지 않는다', (
    tester,
  ) async {
    final adapter = _BodyAdapter();
    await _open(tester, _app(adapter, () => true));
    expect(_failure, findsOneWidget);
    expect(findText('시세를 불러오지 못했어요'), findsWidgets);
    expect(findTextContaining('서버 원문'), findsNothing);
    // 시세를 모르면 합계도 모른다 — 0 이라 하지 않는다(머리 요약 · 평가액 칸)
    expect(findText('1종목 · —'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('holdings-total-unknown')),
      findsOneWidget,
    );
    expect(findText('1종목 · 0원'), findsNothing);
    // 이 상태로 저장해도 평가액(0 · 옛 값)은 실리지 않는다 — 연동 줄은 심볼 · 수량만, 보유가 있으면 balance 키도 없다
    // (asset_repository.dart `_balanceBody` · `_holdingBody`, 서버는 linked 면 holdingValue 를 쓰지 않는다)
    await tester.tap(findText('저장').last);
    await tester.pumpAndSettle();
    final body = adapter.body!;
    expect(body.containsKey('balance'), isFalse);
    final holding = (body['holdings'] as List).single as Map;
    expect(holding['linked'], isTrue);
    expect(holding.containsKey('holdingValue'), isFalse);
    expect(holding['tossSymbol'], '005930');
    expect(holding['quantity'], '10');
  });

  testWidgets('실패 상자의 [다시 시도] 는 다시 받고, 받으면 걷힌다', (tester) async {
    var down = true;
    var calls = 0;
    await _open(
      tester,
      _app(_BodyAdapter(), () {
        calls++;
        return down;
      }),
    );
    expect(_failure, findsOneWidget);
    down = false;
    final before = calls;
    await tester.tap(
      find.descendant(of: _failure, matching: findText('다시 시도')),
    );
    await tester.pumpAndSettle();
    expect(calls, greaterThan(before));
    expect(_failure, findsNothing);
    expect(findText('1종목 · —'), findsNothing);
  });
}
