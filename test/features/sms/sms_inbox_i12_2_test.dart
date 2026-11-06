// I-12 12-2 G — 문자 함(안드로이드)을 실제 화면으로 잰다.
//
//  - 흰 화면 하나(띠 0) · 머리 = Top Navigation + [비우기] 글 버튼(문자 있을 때만)
//  - 안내 상자 = Callout actionable 둘(감지 꺼짐 warning · 알림 권한 꺼짐 informative) · 누르면 설정 · 권한 요청
//  - 날짜 = List Header "M월 d일 (E)" + 오늘이면 " · 오늘" · 다른 해면 연도
//  - 줄 = 회색 타일 · 금액 fg-neutral 700 · [×] ghost neutralSubtle small iconOnly(이름 "{대상} 삭제")
//  - × · 밀기 · [비우기] 모두 같은 확인창(취소하면 그대로, 삭제하면 지움)
//  - 0건 = Result Section empty large
//
// 시계는 고정한다(NowTick 대체) — 수신 시각도 같은 날에서 만든다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../support/plain_text.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/now_tick.dart';
import 'package:groo_damda_app/features/sms/data/sms_android.dart';
import 'package:groo_damda_app/features/sms/presentation/sms_inbox_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

final _now = DateTime(2026, 10, 29, 13);

class _FixedNow extends NowTick {
  @override
  DateTime build() => _now;
}

class _FakeSms {
  _FakeSms({this.noti = true, this.granted = true, required this.entries});
  final bool noti;
  final bool granted;
  final List<SmsInboxEntry> entries;
  final calls = <String>[];

  Future<Object?> handle(MethodCall c) async {
    calls.add(c.method);
    switch (c.method) {
      case 'hasPermissions':
        return granted;
      case 'hasNotificationAccess':
        return noti;
      case 'inbox':
        return [
          for (final e in entries)
            {
              'id': e.id,
              'text': e.text,
              'receivedAt': e.receivedAt.millisecondsSinceEpoch,
            },
        ];
      case 'removeFromInbox':
        entries.removeWhere((e) => e.id == (c.arguments as Map)['id']);
        return null;
      case 'clearInbox':
        entries.clear();
        return null;
    }
    return null;
  }
}

List<SmsInboxEntry> _entries() => [
  SmsInboxEntry(
    id: 1,
    text: '[Web발신]\n숲빛카드\n12,000원 일시불\n10/29 12:10\n골목 찌개집',
    receivedAt: DateTime(2026, 10, 29, 12, 10),
  ),
  SmsInboxEntry(
    id: 2,
    text: '[알림] 바람은행 입출금 안내 — 금액을 읽지 못한 알림',
    receivedAt: DateTime(2026, 10, 29, 7, 30),
  ),
  SmsInboxEntry(
    id: 3,
    text: '[Web발신]\n바람은행\n56,780원 일시불\n10/28 11:18\n열매마트',
    receivedAt: DateTime(2026, 10, 28, 11, 18),
  ),
  SmsInboxEntry(
    id: 4,
    text: '[Web발신]\n숲빛카드\n9,900원 일시불\n12/30 19:45\n별빛책방',
    receivedAt: DateTime(2025, 12, 30, 19, 45),
  ),
];

Future<_FakeSms> _pump(
  WidgetTester tester, {
  bool noti = true,
  bool granted = true,
  List<SmsInboxEntry>? entries,
  bool dark = false,
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(360 * 2, 800 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final fake = _FakeSms(
    noti: noti,
    granted: granted,
    entries: entries ?? _entries(),
  );
  SmsAndroid.debugSupported = true;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('porest/sms_android'),
    fake.handle,
  );
  addTearDown(() {
    SmsAndroid.debugSupported = null;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('porest/sms_android'),
      null,
    );
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [nowTickProvider.overrideWith(_FixedNow.new)],
      child: MaterialApp(
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const SmsInboxScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

PColors _colors(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(SmsInboxScreen))).extension<PColors>()!;

void main() {
  testWidgets('흰 화면 하나 · 머리는 Top Navigation + 글 버튼 [비우기] 하나', (tester) async {
    await _pump(tester);
    final c = _colors(tester);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, c.bgLayerDefault);
    expect(find.byType(PScreenBandBody), findsNothing);
    expect(find.byType(PTopNavigation), findsOneWidget);
    expect(findText('결제 알림 수신함'), findsOneWidget);
    expect(find.byType(PTopNavigationTextButton), findsOneWidget);
    expect(findText('비우기'), findsOneWidget);
  });

  testWidgets('문자가 없으면 [비우기] 도 없고 Result Section empty 가 선다', (tester) async {
    await _pump(tester, entries: []);
    expect(find.byType(PTopNavigationTextButton), findsNothing);
    final result = tester.widget<PResultSection>(find.byType(PResultSection));
    expect(result.kind, PResultKind.empty);
    expect(result.size, PResultSize.large);
    expect(result.icon, LucideIcons.creditCard300);
    expect(result.title, '아직 받은 결제 알림이 없어요');
    expect(result.primaryAction, isNull);
  });

  testWidgets('안내 상자는 Callout actionable — 감지 꺼짐 warning · 누르면 알림 접근 설정', (
    tester,
  ) async {
    final fake = await _pump(tester, noti: false);
    final callout = tester.widget<PCallout>(find.byType(PCallout));
    expect(callout.tone, PCalloutTone.warning);
    expect(callout.interaction, PCalloutInteraction.actionable);
    expect(callout.title, '결제 감지가 꺼져 있어요');
    await tester.tap(find.byType(PCallout));
    await tester.pump();
    expect(fake.calls, contains('openNotificationAccessSettings'));
    // 옛 PAlert 의 [켜기] 버튼은 없다
    expect(findText('켜기'), findsNothing);
  });

  testWidgets('알림 권한 꺼짐은 같은 모양에 톤만 informative · 누르면 권한 요청', (tester) async {
    final fake = await _pump(tester, granted: false);
    final callout = tester.widget<PCallout>(find.byType(PCallout));
    expect(callout.tone, PCalloutTone.informative);
    expect(callout.interaction, PCalloutInteraction.actionable);
    expect(callout.title, '결제를 감지해도 알려드릴 수 없어요');
    await tester.tap(find.byType(PCallout));
    await tester.pump();
    expect(fake.calls, contains('requestPermissions'));
  });

  testWidgets('감지가 꺼져 있으면 알림 권한 상자는 두지 않는다(상자는 하나)', (tester) async {
    await _pump(tester, noti: false, granted: false);
    expect(find.byType(PCallout), findsOneWidget);
  });

  testWidgets('날짜 제목 — 오늘은 " · 오늘" · 다른 해는 연도', (tester) async {
    await _pump(tester);
    final titles = [
      for (final h in tester.widgetList<PListHeader>(find.byType(PListHeader)))
        h.title,
    ];
    expect(titles.map(plainOf), [
      '10월 29일 (목) · 오늘',
      '10월 28일 (수)',
      '2025년 12월 30일 (화)',
    ]);
    // 첫 묶음 위 8 · 나머지 위 16
    final tops = [
      for (final h in tester.widgetList<PListHeader>(find.byType(PListHeader)))
        h.topInset,
    ];
    expect(tops, [8, 16, 16]);
  });

  testWidgets('줄 — 회색 타일 · 금액 fg-neutral 700 · 제목 말줄임 0', (tester) async {
    await _pump(tester);
    final c = _colors(tester);
    final tile = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('plist-tile')).first,
    );
    expect((tile.decoration as BoxDecoration).color, c.chartGrayWeak);
    final amount = tester.widget<Text>(findPlain('−12,000원'));
    expect(amount.style!.color, c.fgNeutral);
    expect(amount.style!.fontWeight, FontWeight.w700);
    expect(findPlain('골목 찌개집'), findsOneWidget);
    // 말줄임 · 줄 수 제한 없음
    for (final t in tester.widgetList<Text>(findPlain('골목 찌개집'))) {
      expect(t.overflow, isNot(TextOverflow.ellipsis));
      expect(t.maxLines, isNull);
    }
    // 못 읽은 알림은 첫 줄이 제목이고 금액이 없다
    expect(findPlainContaining('입출금 안내'), findsOneWidget);
  });

  testWidgets('[×] 는 ghost neutralSubtle small iconOnly · 이름은 "{대상} 삭제"', (
    tester,
  ) async {
    await _pump(tester);
    final xs = tester
        .widgetList<PButton>(find.byType(PButton))
        .where((b) => b.icon == LucideIcons.x)
        .toList();
    expect(xs, hasLength(4));
    expect(xs.first.variant, PButtonVariant.ghost);
    expect(xs.first.ghostColor, PButtonGhostColor.neutralSubtle);
    expect(xs.first.size, PButtonSize.small);
    expect(xs.first.semanticLabel, '골목 찌개집 12,000원 삭제');
    // 금액을 못 읽은 줄의 대상은 받은 시각
    expect(xs[1].semanticLabel, '오전 7:30 삭제');
  });

  // I-28-4 — [×] 의 누르는 영역 44: 중심에서 네 방향으로 21.5(한 변 43 이상) 눌러도 줄(상세로 이동)이 아니라 [×](확인창)가 받는다.
  for (final probe in const {
    '오른쪽': Offset(21.5, 0),
    '왼쪽': Offset(-21.5, 0),
    '아래': Offset(0, 21.5),
    '위': Offset(0, -21.5),
  }.entries) {
    testWidgets('[×] 누르는 영역 44 — 중심에서 ${probe.key} 21.5 도 [×] 가 받는다', (
      tester,
    ) async {
      await _pump(tester);
      final c = tester.getCenter(find.byIcon(LucideIcons.x).first);
      await tester.tapAt(c + probe.value);
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
    });
  }

  testWidgets('× 를 누르면 바로 지우지 않고 확인창 — 취소하면 그대로', (tester) async {
    final fake = await _pump(tester);
    await tester.tap(find.byIcon(LucideIcons.x).first);
    await tester.pumpAndSettle();
    expect(find.byType(PAlertDialogView), findsOneWidget);
    expect(findPlain('문자를 삭제할까요?'), findsOneWidget);
    expect(
      findPlain("'골목 찌개집 12,000원' 문자를 목록에서 삭제해요. 기록으로 남기지 않아요."),
      findsOneWidget,
    );
    expect(fake.calls, isNot(contains('removeFromInbox')));
    await tester.tap(findText('취소'));
    await tester.pumpAndSettle();
    expect(fake.entries, hasLength(4));
    expect(fake.calls, isNot(contains('removeFromInbox')));
  });

  testWidgets('확인창에서 [삭제] 하면 그 문자만 지운다', (tester) async {
    final fake = await _pump(tester);
    await tester.tap(find.byIcon(LucideIcons.x).first);
    await tester.pumpAndSettle();
    final dialog = tester.widget<PAlertDialogView>(
      find.byType(PAlertDialogView),
    );
    expect(dialog.destructive, isTrue);
    await tester.tap(
      find.descendant(
        of: find.byType(PAlertDialogView),
        matching: findText('삭제'),
      ),
    );
    await tester.pumpAndSettle();
    expect(fake.entries.map((e) => e.id), [2, 3, 4]);
  });

  testWidgets('밀어서 지우기도 같은 확인창을 거친다', (tester) async {
    final fake = await _pump(tester);
    await tester.drag(
      find.byIcon(LucideIcons.creditCard).first,
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.trash2).first);
    await tester.pumpAndSettle();
    expect(findPlain('문자를 삭제할까요?'), findsOneWidget);
    expect(fake.entries, hasLength(4));
    await tester.tap(findText('취소'));
    await tester.pumpAndSettle();
    expect(fake.entries, hasLength(4));
  });

  testWidgets('[비우기] 는 새 확인창 — 건수를 말하고, 취소하면 그대로 · 확인하면 모두 지운다', (
    tester,
  ) async {
    final fake = await _pump(tester);
    await tester.tap(findText('비우기'));
    await tester.pumpAndSettle();
    expect(findPlain('문자를 모두 삭제할까요?'), findsOneWidget);
    expect(findPlain('수신함의 문자 4건을 모두 삭제해요. 기록으로 남기지 않아요.'), findsOneWidget);
    await tester.tap(findText('취소'));
    await tester.pumpAndSettle();
    expect(fake.calls, isNot(contains('clearInbox')));
    expect(fake.entries, hasLength(4));

    await tester.tap(findText('비우기'));
    await tester.pumpAndSettle();
    // 확인창의 확정 버튼도 "비우기" — 머리 글 버튼은 가려져 있으니 대화상자 안의 것을 누른다
    await tester.tap(
      find.descendant(
        of: find.byType(PAlertDialogView),
        matching: findText('비우기'),
      ),
    );
    await tester.pumpAndSettle();
    expect(fake.entries, isEmpty);
    expect(find.byType(PResultSection), findsOneWidget);
  });

  testWidgets('목록은 PList 묶음 — 날짜마다 하나', (tester) async {
    await _pump(tester);
    expect(find.byType(PList), findsNWidgets(3));
  });

  testWidgets('다크 · 글자 200% 에서도 넘침 없이 그려진다', (tester) async {
    await _pump(tester, dark: true, scale: 2, noti: false);
    expect(tester.takeException(), isNull);
    expect(find.byType(PCallout), findsOneWidget);
  });
}
