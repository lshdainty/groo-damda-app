// 표시 설정의 '기본 통화' 는 **계정에 저장한다** (D7 · QA #124).
//
// 종전엔 기기 `SharedPreferences` 에만 넣었고 **읽는 곳이 하나도 없었다**. 고르면
// 저장된 것처럼 보이는데 폰을 바꾸면 사라지고, 새 자산·거래 어디에서도 아무 일이
// 일어나지 않았다. 지역 설정과 같은 자리(`/me/preferences` 의 `defaultCurrency`,
// desk-back #328)로 옮겼다 — 웹도 같은 자리를 읽는다(desk-front #368).
//
// 여기서 잠그는 것 셋:
//   ① 고른 값이 **서버로 나간다** — 그 키 하나만(부분 수정이라 나머지는 무변경)
//   ② **서버가 준 값으로 그린다** — 웹에서 고른 값이 폰에서도 보여야 한다
//   ③ 아직 못 읽었으면 값 자리는 Skeleton 이고 줄을 막는다(원화로 그리지 않는다 — I-14 21). 받기에 실패하면
//      설명 자리 안내 + [다시 시도]
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/notification/data/user_preferences_repository.dart';
import 'package:groo_damda_app/features/settings/presentation/appearance_section.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';
import '../../support/plain_text.dart';

/// 서버 대신 값을 들고 있는 가짜 — 무엇이 나갔는지까지 잡는다.
class _FakePrefsRepo extends UserPreferencesRepository {
  _FakePrefsRepo(this._current) : super(Dio());

  UserPreferences _current;

  /// PATCH 본문들 — 몇 번, 무엇이 나갔는지.
  final List<Map<String, dynamic>> patches = [];

  /// GET 을 영영 안 끝내고 싶을 때(아직 못 읽은 상태) 쓴다.
  bool hang = false;

  /// GET 이 실패하는 상태.
  bool fail = false;

  @override
  Future<UserPreferences> get() async {
    if (fail) throw StateError('x');
    if (hang) return Completer<UserPreferences>().future;
    return _current;
  }

  @override
  Future<UserPreferences> update(
    Map<String, dynamic> fields, {
    bool silent = false,
  }) async {
    patches.add(fields);
    _current = _current.copyWith(
      defaultCurrency: fields['defaultCurrency'] as String?,
    );
    return _current;
  }
}

UserPreferences _prefs({String defaultCurrency = 'KRW'}) => UserPreferences(
  pushEnabled: true,
  notifyPayment: true,
  notifyBudget: true,
  notifyAutoRecord: true,
  notifyDutchPay: true,
  notifyCalendar: true,
  notifyWeeklyReport: false,
  notifyMonthlyReport: false,
  budgetAlertThreshold: 85,
  quietHoursEnabled: false,
  quietHoursStart: '22:00',
  quietHoursEnd: '07:00',
  notificationSound: NotificationSound.defaultSound,
  vibrationEnabled: true,
  emailEnabled: false,
  emailFrequency: EmailFrequency.weekly,
  timezone: 'Asia/Seoul',
  defaultCurrency: defaultCurrency,
);

Future<_FakePrefsRepo> _pump(
  WidgetTester tester, {
  String serverCurrency = 'KRW',
  bool hang = false,
  bool fail = false,
}) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final repo = _FakePrefsRepo(_prefs(defaultCurrency: serverCurrency))
    ..hang = hang
    ..fail = fail;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userPreferencesRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const AppearanceScreen(),
      ),
    ),
  );
  if (hang) {
    // 받는 중이면 Skeleton 이 늘 돈다 — 가라앉기를 기다리지 않는다
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  } else {
    await tester.pumpAndSettle();
  }
  return repo;
}

/// 줄을 눌러 고르기 시트를 열고 항목을 고른다 — 시트는 고르면 바로 닫힌다.
Future<void> _choose(WidgetTester tester, String row, String option) async {
  await tester.tap(findText(row));
  await tester.pumpAndSettle();
  await tester.tap(findText(option).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('고른 통화가 서버로 나간다 — 그 키 하나만', (tester) async {
    final repo = await _pump(tester);

    await _choose(tester, '기본 통화', '미국 달러');

    expect(repo.patches, [
      {'defaultCurrency': 'USD'},
    ], reason: '기기에만 넣으면 폰을 바꾸는 순간 사라지고 새 자산·거래도 못 읽는다');
    // 줄 끝 값이 바로 바뀐다
    expect(findText('미국 달러'), findsOneWidget);
  });

  testWidgets('서버가 준 값으로 그린다', (tester) async {
    await _pump(tester, serverCurrency: 'EUR');

    expect(findText('유로'), findsOneWidget);
  });

  testWidgets('같은 값을 다시 고르면 아무것도 안 보낸다', (tester) async {
    final repo = await _pump(tester, serverCurrency: 'USD');

    await _choose(tester, '기본 통화', '미국 달러');

    expect(repo.patches, isEmpty);
  });

  // I-wrap-b3 가.6 — 하나 고르기 시트에서 이미 고른 줄을 다시 눌러도 시트가 닫힌다(값은 그대로 · 저장 요청 없음)
  for (final (row, option) in const [
    ('테마', '시스템'),
    ('언어', '시스템'),
    ('기준 지역', '대한민국 (서울)'),
    ('기본 통화', '대한민국 원'),
  ]) {
    testWidgets('$row — 고른 "$option" 을 다시 누르면 시트가 닫히고 아무것도 안 보낸다', (
      tester,
    ) async {
      final repo = await _pump(tester);

      await tester.tap(findText(row).first);
      await tester.pumpAndSettle();
      expect(find.byType(PBottomSheetContent), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(PBottomSheetContent),
          matching: findText(option),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PBottomSheetContent), findsNothing, reason: '시트가 닫혔다');
      expect(repo.patches, isEmpty);
    });
  }

  testWidgets('아직 못 읽었으면 원화로 그리지 않고 줄을 막는다', (tester) async {
    final repo = await _pump(tester, hang: true);

    // 못 읽은 것을 원화로 그리지 않는다 — 값 자리는 Skeleton
    expect(findText('대한민국 원'), findsNothing);
    await tester.tap(findText('기본 통화'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(findText('미국 달러'), findsNothing);
    expect(repo.patches, isEmpty);
  });

  testWidgets('받기에 실패하면 설명 자리 안내 + [다시 시도]', (tester) async {
    await _pump(tester, fail: true);

    expect(findText('기본 통화를 불러오지 못했어요'), findsOneWidget);
    expect(findText('기준 지역을 불러오지 못했어요'), findsOneWidget);
    expect(findText('다시 시도'), findsNWidgets(2));
    expect(findText('대한민국 원'), findsNothing);
  });

  testWidgets('기기에는 아무것도 안 남긴다', (tester) async {
    // 값이 두 벌이 되면 어느 쪽이 참인지 모르게 된다 — 계정 값 하나만 둔다.
    await _pump(tester);

    await _choose(tester, '기본 통화', '미국 달러');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pd-currency'), isNull);
  });

  testWidgets('줄 차례는 테마 · 언어 · 기준 지역 · 기본 통화이고 꺾쇠가 없다', (tester) async {
    await _pump(tester);

    final ys = [
      for (final t in ['테마', '언어', '기준 지역', '기본 통화'])
        tester.getTopLeft(findText(t).first).dy,
    ];
    expect(ys, [...ys]..sort());
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
  });

  testWidgets('끝 흐림은 지역 고르기(18개)만 켠다 — 위 20 · 아래 80', (tester) async {
    await _pump(tester);

    await tester.tap(findText('기준 지역'));
    await tester.pumpAndSettle();
    final fog = tester.widget<PScrollFogMask>(find.byType(PScrollFogMask));
    expect(fog.start, 20);
    expect(fog.end, 80);

    // 테마 · 통화 고르기는 줄이 적어 흐림을 끈다
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(findText('기본 통화'));
    await tester.pumpAndSettle();
    expect(find.byType(PScrollFogMask), findsNothing);
  });
}
