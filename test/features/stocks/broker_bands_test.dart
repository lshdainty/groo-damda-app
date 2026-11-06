// 증권사 공통 맞춤 띠(I-13b 13b-1) — 오늘 시세 · 투자자별 · 나무 장 상태 글 · 주문 가능 줄 · 경고 이름표.
// 결함을 잡는 단언: 값 없는 줄은 그리지 않는다 · 0 은 "0" 옅게 · null 은 "—" · 모르는 장 상태는 항목 없음.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart'
    show StocksQuotesCard;
import 'package:groo_damda_app/features/stocks/presentation/market_state.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_broker_parts.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import '../../support/plain_text.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget Function(BuildContext) build, {
  double width = 360,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, 2400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(
          c,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(child: Builder(builder: build)),
      ),
    ),
  );
  await tester.pump();
}

String _plain(Text w) => (w.data ?? w.textSpan?.toPlainText() ?? '')
    .replaceAll('⁠', '')
    .replaceAll('​', '');
Finder _t(String s) =>
    find.byWidgetPredicate((w) => w is Text && _plain(w) == s);

void main() {
  group('호가 · 체결 줄은 큰 글자에서 글자를 따라 늘어난다(앱 검수)', () {
    final book = TossOrderbook(
      currency: 'KRW',
      asks: [
        for (var i = 1; i <= 5; i++)
          TossOrderbookEntry(
            price: '${75000 + i * 100}',
            volume: '${4000 + i}',
          ),
      ],
      bids: [
        for (var i = 1; i <= 5; i++)
          TossOrderbookEntry(
            price: '${75000 - i * 100}',
            volume: '${3900 + i}',
          ),
      ],
    );
    Widget card() => Consumer(
      builder: (c, ref, _) => StocksQuotesCard(
        symbol: 'A',
        currency: 'KRW',
        lastPrice: 75000,
        changePct: -3.85,
        watchBook: (_) => AsyncData<TossOrderbook?>(book),
        watchTrades: (_) => AsyncData<List<TossTrade>?>([
          for (var i = 0; i < 4; i++)
            TossTrade(
              price: '${75000 + i * 100}',
              volume: '${100 + i}',
              timestamp: '2026-10-29T13:0$i:00+09:00',
            ),
        ]),
      ),
    );

    testWidgets('가격이 끝까지 보이고(글자 200% · 360) 줄이 서로 겹치지 않는다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: GrooTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(
                c,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(body: SingleChildScrollView(child: card())),
          ),
        ),
      );
      tester.view.physicalSize = const Size(360 * 3, 2400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pump();
      expect(tester.takeException(), isNull);
      final prices = [
        for (final p in ['75,100원', '75,500원', '74,900원', '74,500원']) _t(p),
      ];
      for (final f in prices) {
        expect(f, findsOneWidget, reason: '가격 글이 잘려 사라졌다');
      }
      final r1 = tester.getRect(_t('75,500원'));
      final r2 = tester.getRect(_t('75,400원'));
      expect(r2.top, greaterThanOrEqualTo(r1.bottom - 1), reason: '위아래 줄이 겹쳤다');
      expect(r1.right, lessThanOrEqualTo(360));
    });

    testWidgets(
      'N5 가장 나쁜 값(1,234,000원 · 320 · 200%) — 체결 가격이 끝까지 보이고 호가 가운데 현재가 줄이 넘치지 않는다',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 2400 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final worst = TossOrderbook(
          currency: 'KRW',
          asks: [const TossOrderbookEntry(price: '1234100', volume: '4259')],
          bids: [const TossOrderbookEntry(price: '1233900', volume: '3986')],
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: GrooTheme.light(),
              locale: const Locale('ko'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(
                  c,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: StocksQuotesCard(
                    symbol: 'A',
                    currency: 'KRW',
                    lastPrice: 1234000,
                    changePct: 12.34,
                    watchBook: (_) => AsyncData<TossOrderbook?>(worst),
                    watchTrades: (_) => const AsyncData<List<TossTrade>?>([
                      TossTrade(
                        price: '1234000',
                        volume: '123456',
                        timestamp: '2026-10-29T12:59:00+09:00',
                      ),
                      TossTrade(
                        price: '1234100',
                        volume: '7',
                        timestamp: '2026-10-29T13:00:00+09:00',
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '호가 가운데 현재가 줄이 넘쳤다');
        await tester.tap(_t('체결').first);
        await tester.pump();
        expect(tester.takeException(), isNull);
        final price = tester.getRect(findTextContaining('1,234,000원').first);
        expect(
          price.right,
          lessThanOrEqualTo(320),
          reason: '체결 가격 끝이 화면 밖으로 잘렸다',
        );
        final fm = tester.renderObject<RenderBox>(
          findTextContaining('1,234,000원').first,
        );
        expect(fm.size.width, greaterThanOrEqualTo(price.width - 0.5));
        final second = tester.getRect(findTextContaining('1,234,100원').first);
        expect(
          second.top,
          greaterThanOrEqualTo(price.bottom - 1),
          reason: '위아래 줄이 겹쳤다',
        );
      },
    );

    testWidgets('체결 탭도 200% 에서 줄이 겹치지 않는다', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 2400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: GrooTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(
                c,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(body: SingleChildScrollView(child: card())),
          ),
        ),
      );
      await tester.tap(_t('체결').first);
      await tester.pump();
      expect(tester.takeException(), isNull);
      final a = tester.getRect(_t('75,000원'));
      final b = tester.getRect(_t('75,100원'));
      expect(b.top, greaterThanOrEqualTo(a.bottom - 1));
    });
  });

  group('오늘 시세 띠', () {
    testWidgets('값 있는 줄만 그리고 상한가 · 하한가는 색이 다르다', (tester) async {
      late List<TodayRow> rows;
      await _pump(tester, (c) {
        rows = todayRowsOf(
          c,
          currency: 'KRW',
          open: 71200,
          volume: 1234567,
          upper: 92300,
          lower: 49700,
        );
        return StocksTodayBand(rows: rows);
      });
      expect(rows.map((r) => r.label), ['시가', '거래량', '상한가', '하한가']);
      expect(_t('고가'), findsNothing, reason: '값 없는 줄은 그리지 않는다');
      expect(_t('1,234,567주'), findsOneWidget);
      expect(rows[2].color, isNot(rows[3].color));
      expect(rows[0].color, isNull);
    });

    testWidgets('여섯 줄이 다 없으면 띠가 없다 · 불러오는 중이면 Skeleton · 실패면 실패 한 벌', (
      tester,
    ) async {
      await _pump(tester, (_) => const StocksTodayBand(rows: []));
      expect(_t('오늘 시세'), findsNothing);
      await _pump(
        tester,
        (_) => const StocksTodayBand(rows: [], loading: true),
      );
      expect(_t('오늘 시세'), findsOneWidget);
      expect(find.byType(PListItem), findsNothing);
      await _pump(
        tester,
        (_) => const StocksTodayBand(rows: [], failTitle: '오늘 시세를 불러오지 못했어요'),
      );
      expect(_t('오늘 시세를 불러오지 못했어요'), findsOneWidget);
      expect(_t('잠시 뒤 다시 시도해주세요.'), findsOneWidget);
    });

    testWidgets('미국은 달러, 가장 나쁜 값(거래량 12자리)도 넘치지 않는다 — 글자 200%', (tester) async {
      await _pump(
        tester,
        (c) => StocksTodayBand(
          rows: todayRowsOf(
            c,
            currency: 'USD',
            open: 408.2,
            high: 12345.67,
            volume: 123456789012,
          ),
        ),
        textScale: 2,
      );
      expect(_t('\$408.20'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('투자자별 매매동향 띠', () {
    List<InvestorTradingDay> days() => [
      const InvestorTradingDay(
        date: '2026-10-29',
        individual: null,
        foreigner: 4321000,
        institution: -987654,
      ),
      const InvestorTradingDay(
        date: '2026-10-28',
        individual: 0,
        foreigner: 12345678,
        institution: 1,
      ),
    ];

    testWidgets('날짜 · 개인 · 외국인 · 기관, 부호 없는 쉼표 숫자, null 은 "—", 0 은 "0"', (
      tester,
    ) async {
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: days(),
          loading: false,
          failed: false,
          onRetry: () {},
        ),
      );
      expect(_t('투자자별 매매동향'), findsOneWidget);
      expect(_t('▲ 순매수 · ▼ 순매도 · 주'), findsOneWidget);
      expect(_t('10월 29일'), findsOneWidget);
      expect(_t('—'), findsOneWidget, reason: '당일 잠정 개인은 null');
      expect(_t('0'), findsOneWidget);
      expect(findTextContaining('-'), findsNothing, reason: '음수에도 부호를 쓰지 않는다');
      expect(findTextContaining('4,321,000'), findsOneWidget);
      expect(findTextContaining('987,654'), findsOneWidget);
    });

    testWidgets('M12 머리 제목과 단위 글은 좁은 폭 · 글자 200% 에서 줄을 나눠 쌓고 넘치지 않는다', (
      tester,
    ) async {
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: days(),
          loading: false,
          failed: false,
          onRetry: () {},
        ),
        width: 320,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final title = tester.getRect(_t('투자자별 매매동향'));
      final unit = tester.getRect(_t('▲ 순매수 · ▼ 순매도 · 주'));
      // 한 줄에 못 들어가면 단위 글이 제목 아래로 내려온다 — 둘이 같은 줄에서 겹치지 않는다
      expect(
        title.bottom <= unit.top + 1 || unit.left >= title.right - 1,
        isTrue,
        reason: '제목과 단위 글이 겹쳤다',
      );
      expect(unit.right <= 320, isTrue);
    });

    testWidgets('D3 · D2 줄 이름이 낱말 단위로 끝까지 보인다 — 200% 에서 한 글자씩 쪼개지지 않는다', (
      tester,
    ) async {
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: [
            const InvestorTradingDay(
              date: '2026-10-29',
              individual: 12345678,
              foreigner: -12345678,
              institution: 1234567800,
            ),
          ],
          loading: false,
          failed: false,
          onRetry: () {},
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      for (final label in ['개인', '외국인', '기관']) {
        final r = tester.getRect(_t(label));
        // 한 글자씩 쪼개지면 높이가 글자 수만큼 커진다 — 한 줄 높이(글자 26 × 줄 높이)보다 작아야 한다
        expect(r.height, lessThan(48), reason: '$label 이 여러 줄로 꺾였다');
        expect(r.width, greaterThanOrEqualTo(40));
      }
    });

    testWidgets(
      'D2 영어 줄 이름("Individual" · "Foreign" · "Institution")이 낱말 중간에서 꺾이지 않는다',
      (tester) async {
        tester.view.physicalSize = const Size(360 * 3, 2400 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: GrooTheme.light(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(
                c,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: StocksInvestorBand(
                  days: const [
                    InvestorTradingDay(
                      date: '2026-10-29',
                      individual: 12345678,
                      foreigner: 4321000,
                      institution: -987654,
                    ),
                  ],
                  loading: false,
                  failed: false,
                  onRetry: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        for (final label in ['Individual', 'Foreign', 'Institution']) {
          final f = findText(label);
          expect(f, findsOneWidget, reason: '$label 이 한 낱말로 남아 있어야 한다');
          expect(
            tester.getRect(f).height,
            lessThan(30),
            reason: '$label 이 낱말 중간에서 꺾였다',
          );
        }
      },
    );

    // 같은 묶음의 세 줄은 모두 한 줄이거나 모두 이름 아래 — 두 모양이 섞이지 않는다(웹 60cqw 상한 해제와 같다)
    Future<List<(Rect, Rect)>> pairsAt(
      WidgetTester tester,
      double width,
      List<String> labels,
      List<String> values,
    ) async {
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: const [
            InvestorTradingDay(
              date: '2026-10-29',
              individual: 12345678,
              foreigner: -87654321,
              institution: 98765432,
            ),
          ],
          loading: false,
          failed: false,
          onRetry: () {},
        ),
        width: width,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      return [
        for (var i = 0; i < 3; i++)
          (
            tester.getRect(_t(labels[i])),
            tester.getRect(findTextContaining(values[i])),
          ),
      ];
    }

    testWidgets('200% 360 에서 8자리 값도 세 줄 모두 "이름 값" 한 줄이다', (tester) async {
      final r = await pairsAt(
        tester,
        360,
        ['개인', '외국인', '기관'],
        ['12,345,678', '87,654,321', '98,765,432'],
      );
      for (final (label, value) in r) {
        expect(
          (value.center.dy - label.center.dy).abs(),
          lessThan(10),
          reason: '이름과 값이 한 줄이 아니다 — 60% 폭 상한이 남아 있다',
        );
      }
    });

    Future<void> pumpNullZero(WidgetTester tester, double width) => _pump(
      tester,
      (_) => StocksInvestorBand(
        days: const [
          InvestorTradingDay(
            date: '2026-10-29',
            individual: null,
            foreigner: 0,
            institution: 12345678,
          ),
        ],
        loading: false,
        failed: false,
        onRetry: () {},
      ),
      width: width,
      textScale: 2,
    );

    testWidgets('"—" · "0" 줄은 값 칸 오른쪽 끝에 붙어 숫자 끝과 나란하다(웹과 같다)', (tester) async {
      await pumpNullZero(tester, 360);
      final number = tester.getRect(findTextContaining('12,345,678'));
      final dash = tester.getRect(_t('—'));
      final zero = tester.getRect(_t('0'));
      expect(dash.right, closeTo(number.right, 1.5), reason: '"—" 이 이름 옆에 붙었다');
      expect(zero.right, closeTo(number.right, 1.5), reason: '"0" 이 이름 옆에 붙었다');
    });

    testWidgets('값이 이름 아래로 내려간 모양(스택)에서는 "—" · "0" 도 왼쪽(List 규칙)', (
      tester,
    ) async {
      await pumpNullZero(tester, 240);
      final label = tester.getRect(_t('개인'));
      final dash = tester.getRect(_t('—'));
      expect(dash.top, greaterThanOrEqualTo(label.bottom - 1));
      expect(dash.left, closeTo(label.left, 1.5));
      final zero = tester.getRect(_t('0'));
      expect(zero.left, closeTo(tester.getRect(_t('외국인')).left, 1.5));
    });

    testWidgets('칸이 모자라면 세 줄 모두 값이 이름 아래로 — 한 묶음에 두 모양이 섞이지 않는다', (
      tester,
    ) async {
      final r = await pairsAt(
        tester,
        240,
        ['개인', '외국인', '기관'],
        ['12,345,678', '87,654,321', '98,765,432'],
      );
      for (final (label, value) in r) {
        expect(value.top, greaterThanOrEqualTo(label.bottom - 1));
      }
    });

    testWidgets('빈 목록은 안내 줄 · 실패는 실패 한 벌 · 값이 있으면 실패해도 값을 남긴다', (tester) async {
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: const [],
          loading: false,
          failed: false,
          onRetry: () {},
        ),
      );
      expect(_t('집계된 매매동향이 없어요'), findsOneWidget);
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: null,
          loading: false,
          failed: true,
          onRetry: () {},
        ),
      );
      expect(_t('투자자별 매매동향을 불러오지 못했어요'), findsOneWidget);
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: days(),
          loading: false,
          failed: true,
          onRetry: () {},
        ),
      );
      expect(_t('투자자별 매매동향을 불러오지 못했어요'), findsNothing);
      expect(_t('10월 28일'), findsOneWidget);
    });

    testWidgets('다섯 줄까지만 · 순매수 천만 단위 × 세 줄도 360 · 200% 에서 넘치지 않는다', (
      tester,
    ) async {
      await _pump(
        tester,
        (_) => StocksInvestorBand(
          days: [
            for (var i = 0; i < 8; i++)
              InvestorTradingDay(
                date: '2026-10-${20 + i}',
                individual: 12345678,
                foreigner: -12345678,
                institution: 12345678,
              ),
          ],
          loading: false,
          failed: false,
          onRetry: () {},
        ),
        textScale: 2,
      );
      expect(find.byType(PListItem), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  });

  group('나무 장 상태 글', () {
    testWidgets('여덟 가지 상태 + 모르는 값은 null', (tester) async {
      stocksNow = () => DateTime.utc(2026, 10, 29, 4, 5); // 한국 13:05
      addTearDown(() => stocksNow = DateTime.now);
      late AppLocalizations l;
      await _pump(tester, (c) {
        l = AppLocalizations.of(c);
        return const SizedBox();
      });
      expect(namuMarketStateText(l, 'REGULAR')!.open, isTrue);
      expect(namuMarketStateText(l, 'REGULAR')!.text, '장중 · 오후 1:05');
      const expected = {
        'PRE': '프리마켓',
        'AFTER': '애프터마켓',
        'DAYTIME': '주간거래',
        'SINGLE_PRICE': '단일가',
        'HALTED': '일시 마감',
        'BEFORE_OPEN': '개장 전',
        'CLOSED': '장마감',
      };
      expected.forEach((state, text) {
        final r = namuMarketStateText(l, state)!;
        expect(r.text, text, reason: state);
        expect(r.open, isFalse, reason: '열려 있는 것은 정규장뿐');
      });
      expect(namuMarketStateText(l, 'WHAT'), isNull);
      expect(namuMarketStateText(l, null), isNull);
    });
  });

  group('주문 가능 줄', () {
    testWidgets('값 · 가리기 · 실패 "—" · 불러오는 중', (tester) async {
      await _pump(
        tester,
        (c) => PList(
          children: [
            stocksBuyingPowerRow(
              c,
              title: '주문 가능 · 원화',
              state: const AsyncValue3(amount: 200000000),
              masked: false,
              format: (v) => '${v.round()}원',
            ),
            stocksBuyingPowerRow(
              c,
              title: '주문 가능 · 달러',
              state: const AsyncValue3(amount: 12.5),
              masked: true,
              format: (v) => '\$$v',
            ),
            stocksBuyingPowerRow(
              c,
              title: '예수금 · 달러',
              state: const AsyncValue3(failed: true),
              masked: false,
              format: (v) => '',
            ),
          ],
        ),
      );
      expect(_t('200000000원'), findsOneWidget);
      expect(_t('••••'), findsOneWidget);
      expect(_t('—'), findsOneWidget);
      expect(
        const AsyncValue3().hasRow,
        isFalse,
        reason: '값도 로딩도 실패도 아니면 줄을 만들지 않는다',
      );
      expect(const AsyncValue3(loading: true).hasRow, isTrue);
    });
  });

  group('달러 시가총액(환율 없을 때)', () {
    testWidgets('1만 달러 미만은 외화 규칙(소수 둘째 자리), 그 위는 줄임 + "달러"', (tester) async {
      await _pump(tester, (_) => const SizedBox());
      expect(fmtCapUsd(1234.5), '\$1,234.50');
      expect(fmtCapUsd(9999.999), '\$10,000.00');
      expect(fmtCapUsd(9.9e11), '9,900억 달러');
      expect(fmtCapUsd(2.5e12), '2.5조 달러');
      expect(fmtCapUsd(12345678), '1,234.6만 달러');
      expect(
        fmtCapUsd(9.9e11).contains('\$'),
        isFalse,
        reason: '"\$9,900억" 처럼 두 표기를 섞지 않는다',
      );
    });
  });

  testWidgets('경고 이름표 — 투자유의(새) · 단기과열 · VI', (tester) async {
    late AppLocalizations l;
    await _pump(tester, (c) {
      l = AppLocalizations.of(c);
      return const SizedBox();
    });
    expect(stocksWarningLabel(l, 'INVESTMENT_ATTENTION'), '투자유의');
    expect(stocksWarningLabel(l, 'SHORT_TERM_OVERHEAT'), '단기과열');
    expect(stocksWarningLabel(l, 'VI'), 'VI 발동');
  });
}
