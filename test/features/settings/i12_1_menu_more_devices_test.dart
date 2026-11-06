// I-12 12-1 — 설정 메뉴 · 전체 · 기기(폰)를 실제 화면으로 잰다.
//
//  - 설정: 흰 면 하나(띠 0) · 계정 줄 Avatar 42 · 묶음 제목 boldSolid 위 16 · 줄 아이콘 22 · 저장공간 줄 0 ·
//    계정 → 도움말 차례 · 누름에 불투명도 0
//  - 전체: 흰 면 · 메뉴 검색 밑줄 · 칸 글 400 · 말줄임 0 · 0건 Result Section · 표시 설정 → /settings/appearance
//  - 기기: 안내 · 줄 사이 선 0 · 배지 outline positive · [모든 기기에서 로그아웃] ghost critical large ·
//    갈래(불러오는 중 · 빈 · 실패) · 확인창 · 끊기 실패 알림 하나 · 지난 시간 글
//
// 시계는 고정한다(NowTick 대체) — 데이터의 now() 도 같은 값에서 만든다.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/plain_text.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/format/now_tick.dart';
import 'package:groo_damda_app/features/more/presentation/more_screen.dart';
import 'package:groo_damda_app/features/settings/application/session_providers.dart';
import 'package:groo_damda_app/features/settings/data/session_repository.dart';
import 'package:groo_damda_app/features/settings/domain/device_session.dart';
import 'package:groo_damda_app/features/settings/presentation/devices_screen.dart';
import 'package:groo_damda_app/features/settings/presentation/settings_screen.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

final _now = DateTime(2026, 10, 23, 12);

class _FixedNow extends NowTick {
  @override
  DateTime build() => _now;
}

class _Auth extends AuthNotifier {
  _Auth(this.user, {this.loading = false});
  final User? user;
  final bool loading;

  @override
  Future<User?> build() {
    if (loading) return Completer<User?>().future;
    return Future.value(user);
  }

  @override
  Future<void> logout() async {
    loggedOut = true;
  }

  static bool loggedOut = false;
}

const _longName = '남궁하늘별빛가람솔나래';
const _longEmail = 'namgung.haneul.byeolbit.garam.solnarae@example.com';
const _user = User(
  rowId: 1,
  userId: 'u1',
  userName: _longName,
  userEmail: _longEmail,
);

class _Repo extends SessionRepository {
  _Repo({
    this.devices = const [],
    this.fail = false,
    this.listFails = false,
    this.noResponse = false,
  }) : super(Dio());
  final List<DeviceSession> devices;
  final bool fail;
  final bool listFails;

  /// 끊기 요청이 나갔는데 응답을 못 받았다(NO_RESPONSE)
  final bool noResponse;
  final revoked = <String>[];
  int revokeAllCalls = 0;
  int listCalls = 0;

  @override
  Future<List<DeviceSession>> list() async {
    listCalls++;
    if (listFails) throw Exception('서버 원문 오류 XYZ');
    return devices;
  }

  @override
  Future<void> revoke(String sessionId) async {
    if (noResponse) {
      throw ApiException(code: kApiNoResponseCode, message: 'x');
    }
    if (fail) throw Exception('x');
    revoked.add(sessionId);
  }

  @override
  Future<void> revokeAll() async {
    if (fail) throw Exception('x');
    revokeAllCalls++;
  }
}

String _utc(Duration ago) {
  final s = _now.toUtc().subtract(ago).toIso8601String();
  return s.endsWith('Z') ? s.substring(0, s.length - 1) : s;
}

List<DeviceSession> _devices() => [
  DeviceSession(
    sessionId: 's1',
    deviceLabel: 'Android 15 · 그루 담다 앱 · SM-X0000 아주 긴 모델 이름 테스트 기기',
    deviceKind: DeviceKind.mobile,
    lastUsedAt: _utc(const Duration(seconds: 30)),
    current: true,
  ),
  DeviceSession(
    sessionId: 's2',
    deviceLabel: 'Windows 11 · Chrome',
    deviceKind: DeviceKind.desktop,
    lastUsedAt: _utc(const Duration(hours: 3)),
  ),
  DeviceSession(
    sessionId: 's3',
    deviceLabel: 'macOS 15 · Firefox',
    deviceKind: DeviceKind.desktop,
    lastUsedAt: _utc(const Duration(days: 10)),
  ),
  DeviceSession(
    sessionId: 's4',
    deviceKind: DeviceKind.unknown,
    lastUsedAt: _utc(const Duration(days: 399)),
  ),
];

Future<GoRouter> _pump(
  WidgetTester tester,
  Widget screen, {
  bool dark = false,
  double scale = 1,
  User? user = _user,
  bool authLoading = false,
  _Repo? repo,
  bool securities = true,
}) async {
  tester.view.physicalSize = const Size(360 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  _Auth.loggedOut = false;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: SizedBox()),
      ),
      GoRoute(path: '/s', builder: (_, _) => screen),
      GoRoute(
        path: '/settings/appearance',
        builder: (_, _) => const Scaffold(body: Text('APPEARANCE')),
      ),
      GoRoute(
        path: '/account',
        builder: (_, _) => const Scaffold(body: Text('ACCOUNT')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authProvider.overrideWith(() => _Auth(user, loading: authLoading)),
        nowTickProvider.overrideWith(_FixedNow.new),
        hasSecuritiesProvider.overrideWithValue(securities),
        if (repo != null)
          sessionRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: PSnackbarHost(closeLabel: '닫기', child: child!),
        ),
      ),
    ),
  );
  router.push('/s');
  await tester.pump();
  await _go(tester);
  return router;
}

Future<void> _go(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  group('설정 메뉴', () {
    for (final dark in [false, true]) {
      testWidgets('${dark ? "다크" : "라이트"} 흰 면 하나 · 띠 0 · T1 0', (tester) async {
        await _pump(tester, const SettingsScreen(), dark: dark);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
        expect(
          scaffold.backgroundColor,
          (dark ? GrooTheme.dark() : GrooTheme.light())
              .extension<PColors>()!
              .bgLayerDefault,
        );
        expect(find.byType(AppBar), findsNothing);
        expect(find.byKey(const ValueKey('screen-band-body')), findsNothing);
        expect(find.byType(PScreenBand), findsNothing);
        final bar = find.byType(PTopNavigation);
        expect(tester.getSize(bar).height, 56);
        expect(
          tester
              .getRect(find.byKey(const ValueKey('settings-account-row')))
              .top,
          tester.getRect(bar).bottom,
          reason: 'T1 상단 바 ↔ 계정 줄 0',
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('계정 줄 Avatar 42 · 이름 · 이메일 · 목록 제목 위 16', (tester) async {
      await _pump(tester, const SettingsScreen());
      final av = find.descendant(
        of: find.byKey(const ValueKey('settings-account-row')),
        matching: find.byType(PAvatar),
      );
      expect(tester.getSize(av), const Size(42, 42));
      expect(findPlain(_longName), findsOneWidget);
      expect(findPlain(_longEmail), findsOneWidget);
      // T2 — 계정 줄 끝 ↔ 첫 목록 제목: 위 16 + 제목 위 8
      final row = tester.getRect(
        find.byKey(const ValueKey('settings-account-row')),
      );
      final firstHeader = tester.getRect(find.byType(PListHeader).first);
      expect(firstHeader.top - row.bottom, 16);
      final h = tester.widget<Text>(
        find.byKey(const ValueKey('plist-header-title')).first,
      );
      expect(h.style!.fontWeight, FontWeight.w700);
    });

    testWidgets('묶음 차례 · 이름 · 줄 — 저장공간 0 · 계정 → 도움말 · 계정 줄 이름 "계정"', (
      tester,
    ) async {
      await _pump(tester, const SettingsScreen());
      final headers = tester
          .widgetList<PListHeader>(find.byType(PListHeader))
          .map((h) => h.title)
          .toList();
      expect(headers.take(7).toList(), [
        '데이터 관리',
        '태그 · 라벨',
        '공유',
        '앱 환경',
        '데이터',
        '계정',
        '도움말',
      ]);
      expect(findPlain('저장공간'), findsNothing);
      expect(findPlain('계정 관리'), findsNothing);
      expect(findPlain('할일 태그'), findsNothing);
      expect(findPlain('할 일 태그'), findsOneWidget);
      expect(findPlain('데이터 내보내기'), findsOneWidget);
    });

    testWidgets('줄 앞 아이콘 22 · 뒤 화살표 18 · 불투명도로 누름을 알리지 않는다', (tester) async {
      await _pump(tester, const SettingsScreen());
      final items = find.byWidgetPredicate(
        (w) => w is PListButtonItem || w is PListLinkItem,
      );
      expect(items, findsWidgets);
      expect(
        find.byType(PListLinkItem),
        findsNWidgets(2),
        reason: '처리방침 · 설명서',
      );
      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(find.byType(Opacity), findsNothing);
      final prefix = find.byKey(const ValueKey('plist-prefix')).first;
      final icon = tester.widget<IconTheme>(
        find.descendant(of: prefix, matching: find.byType(IconTheme)).first,
      );
      expect(icon.data.size, 22);
      final suffix = tester.widget<DefaultTextStyle>(
        find.byKey(const ValueKey('plist-suffix')).first,
      );
      expect(suffix, isNotNull);
    });

    testWidgets('표시 설정 줄을 누르면 표시 설정으로 간다 · 계정 줄은 /account', (tester) async {
      final router = await _pump(tester, const SettingsScreen());
      await tester.tap(find.byKey(const ValueKey('settings-account-row')));
      await _go(tester);
      expect(findPlain('ACCOUNT'), findsOneWidget);
      router.pop();
      await _go(tester);
      await _go(tester);
      await tester.ensureVisible(findPlain('표시 설정'));
      await tester.tap(findPlain('표시 설정'));
      await _go(tester);
      await _go(tester);
      expect(findPlain('APPEARANCE'), findsOneWidget);
    });

    testWidgets('정보를 받는 동안 Skeleton 줄 · 없으면 줄 숨김', (tester) async {
      await _pump(tester, const SettingsScreen(), authLoading: true);
      expect(
        find.byKey(const ValueKey('settings-account-skeleton')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('settings-account-row')), findsNothing);
    });

    testWidgets('정보가 없으면 계정 줄을 숨긴다', (tester) async {
      await _pump(tester, const SettingsScreen(), user: null);
      expect(find.byKey(const ValueKey('settings-account-row')), findsNothing);
      expect(
        find.byKey(const ValueKey('settings-account-skeleton')),
        findsNothing,
      );
    });

    testWidgets('글자 200% 에서 넘침 0', (tester) async {
      await _pump(tester, const SettingsScreen(), scale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('전체', () {
    for (final dark in [false, true]) {
      testWidgets('${dark ? "다크" : "라이트"} 흰 면 · 검색 밑줄 · 띠 0', (tester) async {
        await _pump(tester, const MoreScreen(), dark: dark);
        expect(find.byType(PScreenBand), findsNothing);
        final input = tester.widget<PInput>(find.byType(PInput));
        expect(input.variant, PInputVariant.underline);
        expect(input.clearable, isTrue);
        expect(input.semanticLabel, '메뉴 검색');
        final face = tester.widget<ColoredBox>(
          find.byKey(const ValueKey('more-face')),
        );
        expect(
          face.color,
          (dark ? GrooTheme.dark() : GrooTheme.light())
              .extension<PColors>()!
              .bgLayerDefault,
        );
        // T4 — 흰 면 안 위 4
        expect(
          tester.getRect(find.byType(PInput)).top -
              tester.getRect(find.byKey(const ValueKey('more-face'))).top,
          4,
        );
        // T5 — 검색 ↔ 첫 목록 제목 8
        expect(
          tester.getRect(find.byType(PListHeader).first).top -
              tester.getRect(find.byType(PInput)).bottom,
          8,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('칸 이름 — 통계 · 반복 거래 · 칸 글 400 · 한 행 두 칸', (tester) async {
      await _pump(tester, const MoreScreen());
      expect(findPlain('통계'), findsOneWidget);
      expect(findPlain('통계·분석'), findsNothing);
      expect(findPlain('반복 거래'), findsOneWidget);
      expect(findPlain('반복 거래 관리'), findsNothing);
      final t = tester.widget<Text>(findPlain('가계부'));
      expect(t.style!.fontWeight, FontWeight.w400);
      expect(t.style!.fontSize, 16);
      // 글 시작이 화면 끝 24
      expect(tester.getTopLeft(findPlain('가계부')).dx, closeTo(24, 0.5));
      // 2열 — 같은 행의 두 칸은 같은 y
      expect(
        tester.getTopLeft(findPlain('가계부')).dy,
        tester.getTopLeft(findPlain('자산')).dy,
      );
      expect(find.byType(AnimatedOpacity), findsNothing);
    });

    testWidgets('검색 "통계" 한 칸 · "없는말" 0건 = Result Section', (tester) async {
      await _pump(tester, const MoreScreen());
      await tester.enterText(find.byType(EditableText), '통계');
      await tester.pump();
      expect(findPlain('통계'), findsWidgets);
      expect(findPlain('가계부'), findsNothing);
      await tester.enterText(find.byType(EditableText), '없는말');
      await tester.pump();
      expect(find.byType(PResultSection), findsOneWidget);
      expect(findPlain('검색 결과가 없어요'), findsOneWidget);
      expect(findPlain('검색 결과가 없습니다'), findsNothing);
    });

    testWidgets('표시 설정 칸 → /settings/appearance', (tester) async {
      await _pump(tester, const MoreScreen());
      await tester.ensureVisible(findPlain('표시 설정'));
      await tester.tap(findPlain('표시 설정'));
      await _go(tester);
      await _go(tester);
      expect(findPlain('APPEARANCE'), findsOneWidget);
    });

    testWidgets('글자 200% · 360 에서 칸 글이 잘리지 않고 넘침 0', (tester) async {
      await _pump(tester, const MoreScreen(), scale: 2);
      expect(tester.takeException(), isNull);
      // 말줄임 없음
      for (final t in tester.widgetList<Text>(
        find.descendant(
          of: find.byType(IntrinsicHeight),
          matching: find.byType(Text),
        ),
      )) {
        expect(t.overflow, isNot(TextOverflow.ellipsis));
      }
    });
  });

  group('기기', () {
    testWidgets('흰 면 · 안내 · 줄 사이 선 0 · 모두 로그아웃 ghost critical large', (
      tester,
    ) async {
      await _pump(
        tester,
        const DevicesScreen(),
        repo: _Repo(devices: _devices()),
      );
      expect(find.byKey(const ValueKey('screen-band-body')), findsNothing);
      expect(find.byType(PListDivider), findsNothing);
      final bar = tester.getRect(find.byType(PTopNavigation));
      final intro = tester.getRect(find.byKey(const ValueKey('devices-intro')));
      expect(intro.top - bar.bottom, 16, reason: 'T8 안내 위 16');
      expect(
        findPlain('이 계정으로 로그인된 기기예요. 낯선 기기가 있으면 로그아웃해주세요.'),
        findsOneWidget,
      );
      // 이름 말줄임 0 — 긴 이름이 다 보인다
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              plainOf(
                w.text.toPlainText(),
              ).contains('SM-X0000 아주 긴 모델 이름 테스트 기기'),
        ),
        findsOneWidget,
      );
      final badge = tester.widget<PBadge>(find.byType(PBadge));
      expect(badge.variant, PBadgeVariant.outline);
      expect(badge.tone, PBadgeTone.positive);
      final all = tester.widget<PButton>(
        findWidgetWithText(PButton, '모든 기기에서 로그아웃'),
      );
      expect(all.variant, PButtonVariant.ghost);
      expect(all.ghostColor, PButtonGhostColor.critical);
      expect(all.size, PButtonSize.large);
      final lastRow = tester.getRect(find.byType(PListItem).last);
      final allRect = tester.getRect(
        findWidgetWithText(PButton, '모든 기기에서 로그아웃'),
      );
      expect(allRect.top - lastRow.bottom, 24, reason: 'T11 위 24');
      expect(allRect.width, 360 - 48, reason: '화면 폭 − 좌우 24');
      expect(tester.takeException(), isNull);
    });

    testWidgets('마지막 사용 글 — 방금 전 · 3시간 전 · 10월 13일 · 2025년 9월 19일', (
      tester,
    ) async {
      await _pump(
        tester,
        const DevicesScreen(),
        repo: _Repo(devices: _devices()),
      );
      expect(findPlain('마지막 사용 방금 전'), findsOneWidget);
      expect(findPlain('마지막 사용 3시간 전'), findsOneWidget);
      expect(findPlain('마지막 사용 10월 13일'), findsOneWidget);
      expect(findPlain('마지막 사용 2025년 9월 19일'), findsOneWidget);
    });

    testWidgets('[로그아웃] 이름은 "{기기} 로그아웃"', (tester) async {
      await _pump(
        tester,
        const DevicesScreen(),
        repo: _Repo(devices: _devices()),
      );
      expect(find.bySemanticsLabel('Windows 11 · Chrome 로그아웃'), findsOneWidget);
    });

    testWidgets('[로그아웃] 글 fg-neutral · 글 끝이 화면 끝 24 · flush 없음', (
      tester,
    ) async {
      await _pump(
        tester,
        const DevicesScreen(),
        repo: _Repo(devices: _devices()),
      );
      final btn = find.descendant(
        of: find.byType(PListItem).at(1),
        matching: find.byType(PButton),
      );
      final w = tester.widget<PButton>(btn);
      expect(w.flush, isNull);
      expect(w.size, PButtonSize.small);
      final label = find.descendant(of: btn, matching: findPlain('로그아웃'));
      expect(tester.getRect(label).right, closeTo(360 - 24, 1));
      final c = GrooTheme.light().extension<PColors>()!;
      expect(tester.widget<Text>(label).style!.color, c.fgNeutral);
    });

    testWidgets('[로그아웃] 누르는 영역 — 블리드 끝 · 위 · 아래 44 가 onPressed 에 닿는다', (
      tester,
    ) async {
      await _pump(
        tester,
        const DevicesScreen(),
        repo: _Repo(devices: _devices()),
      );
      final btn = find.descendant(
        of: find.byType(PListItem).at(1),
        matching: find.byType(PButton),
      );
      final r = tester.getRect(btn);
      expect(r.height, 36);
      final points = {
        '블리드 끝': Offset(r.right - 2, r.center.dy),
        '위 끝(36 밖 4)': Offset(r.center.dx, r.top - 3.5),
        '아래 끝(36 밖 4)': Offset(r.center.dx, r.bottom + 3.5),
      };
      for (final e in points.entries) {
        await tester.tapAt(e.value);
        await _go(tester);
        expect(
          find.byType(PAlertDialogView),
          findsOneWidget,
          reason: '${e.key} ${e.value}',
        );
        expect(findPlain('Windows 11 · Chrome에서 로그아웃할까요?'), findsOneWidget);
        await tester.tap(findWidgetWithText(PButton, '취소'));
        await _go(tester);
        await _go(tester);
        expect(find.byType(PAlertDialogView), findsNothing);
      }
      // 아니어야 할 점 — 오른쪽 밖 · 위아래 5 · 보이는 버튼 왼쪽 밖
      final nots = {
        '오른쪽 밖': Offset(r.right + 1, r.center.dy),
        '위 5': Offset(r.center.dx, r.top - 5),
        '아래 5': Offset(r.center.dx, r.bottom + 5),
        '왼쪽 밖': Offset(r.left - 7, r.center.dy),
      };
      for (final e in nots.entries) {
        await tester.tapAt(e.value);
        await _go(tester);
        expect(
          find.byType(PAlertDialogView),
          findsNothing,
          reason: '${e.key} ${e.value}',
        );
      }
      // 이웃 줄 — 다음 줄 버튼의 위 끝은 그 줄의 기기를 끊는다(침범 없음)
      final next = tester.getRect(
        find.descendant(
          of: find.byType(PListItem).at(2),
          matching: find.byType(PButton),
        ),
      );
      await tester.tapAt(Offset(next.center.dx, next.top - 3.5));
      await _go(tester);
      expect(findPlain('macOS 15 · Firefox에서 로그아웃할까요?'), findsOneWidget);
      await tester.tap(findWidgetWithText(PButton, '취소'));
      await _go(tester);
    });

    testWidgets('[로그아웃] 누르는 동안 눌림 바탕', (tester) async {
      await _pump(
        tester,
        const DevicesScreen(),
        repo: _Repo(devices: _devices()),
      );
      final btn = find.descendant(
        of: find.byType(PListItem).at(1),
        matching: find.byType(PButton),
      );
      final c = GrooTheme.light().extension<PColors>()!;
      final pressed = resolvePButtonColors(
        c,
        variant: PButtonVariant.ghost,
        state: PButtonState.pressed,
      ).background;
      bool hasColor(Color col) => find
          .descendant(
            of: btn,
            matching: find.byWidgetPredicate(
              (w) =>
                  (w is DecoratedBox &&
                      w.decoration is BoxDecoration &&
                      (w.decoration as BoxDecoration).color == col) ||
                  (w is AnimatedContainer &&
                      w.decoration is BoxDecoration &&
                      (w.decoration as BoxDecoration).color == col),
            ),
          )
          .evaluate()
          .isNotEmpty;
      expect(pressed.a, greaterThan(0));
      expect(hasColor(const Color(0x00000000)), isTrue, reason: '누르기 전은 바탕 없음');
      final g = await tester.startGesture(tester.getCenter(btn));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(hasColor(pressed), isTrue);
      await g.up();
      await _go(tester);
    });

    testWidgets('빈 목록 = Result Section empty · 모두 로그아웃 없음', (tester) async {
      await _pump(tester, const DevicesScreen(), repo: _Repo());
      expect(findPlain('로그인된 기기가 없어요'), findsOneWidget);
      expect(find.byType(PResultSection), findsOneWidget);
      expect(findPlain('모든 기기에서 로그아웃'), findsNothing);
    });

    testWidgets('실패 = Result Section failure · 원문 0 · [다시 시도]', (tester) async {
      await _pump(tester, const DevicesScreen(), repo: _Repo(listFails: true));
      expect(findPlain('기기 목록을 불러오지 못했어요'), findsOneWidget);
      expect(findPlain('잠시 뒤 다시 시도해주세요.'), findsOneWidget);
      expect(findPlainContaining('XYZ'), findsNothing);
      expect(findPlain('다시 시도'), findsOneWidget);
      expect(findPlain('모든 기기에서 로그아웃'), findsNothing);
    });

    testWidgets('확인창 — 묻는 말 제목 · criticalSolid · 확인하면 끊고 목록 다시 받음', (
      tester,
    ) async {
      final repo = _Repo(devices: _devices());
      await _pump(tester, const DevicesScreen(), repo: repo);
      await tester.tap(find.bySemanticsLabel('Windows 11 · Chrome 로그아웃'));
      await _go(tester);
      expect(find.byType(PAlertDialogView), findsOneWidget);
      expect(findPlain('Windows 11 · Chrome에서 로그아웃할까요?'), findsOneWidget);
      expect(findPlain('그 기기는 다시 로그인해야 해요.'), findsOneWidget);
      final confirm = tester.widget<PButton>(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findWidgetWithText(PButton, '로그아웃'),
        ),
      );
      expect(confirm.variant, PButtonVariant.criticalSolid);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findWidgetWithText(PButton, '로그아웃'),
        ),
      );
      await _go(tester);
      expect(repo.revoked, ['s2']);
      expect(find.byType(PAlertDialogView), findsNothing);
    });

    testWidgets('끊기 실패 — 확인창은 닫히고 알림은 하나', (tester) async {
      final repo = _Repo(devices: _devices(), fail: true);
      await _pump(tester, const DevicesScreen(), repo: repo);
      await tester.tap(find.bySemanticsLabel('Windows 11 · Chrome 로그아웃'));
      await _go(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findWidgetWithText(PButton, '로그아웃'),
        ),
      );
      await _go(tester);
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(findPlain('로그아웃하지 못했어요.'), findsOneWidget);
      // 확인창 뒤 실패 = 스낵바 + [다시 시도]
      expect(findPlain('다시 시도'), findsOneWidget);
      expect(_Auth.loggedOut, isFalse);
    });

    testWidgets(
      '끊기 응답 없음 — "처리됐는지 확인하지 못했어요." 한 문장 · [다시 시도] 없음 · 목록 다시 받음(판단 ①)',
      (tester) async {
        final repo = _Repo(devices: _devices(), noResponse: true);
        await _pump(tester, const DevicesScreen(), repo: repo);
        final before = repo.listCalls;
        await tester.tap(find.bySemanticsLabel('Windows 11 · Chrome 로그아웃'));
        await _go(tester);
        await tester.tap(
          find.descendant(
            of: find.byType(PAlertDialogView),
            matching: findWidgetWithText(PButton, '로그아웃'),
          ),
        );
        await _go(tester);
        expect(find.byType(PAlertDialogView), findsNothing);
        expect(findPlain('처리됐는지 확인하지 못했어요.'), findsOneWidget);
        expect(findPlain('로그아웃하지 못했어요.'), findsNothing);
        expect(findPlainContaining('저장됐는지'), findsNothing);
        expect(
          findPlain('다시 시도'),
          findsNothing,
          reason: '끊겼을 수 있다 — 다시 누르면 두 번 처리된다',
        );
        expect(repo.listCalls, before + 1, reason: '끊겼는지 서버 목록으로 맞춘다');
      },
    );

    testWidgets('모두 로그아웃 확인창 글 · 확정하면 로그아웃', (tester) async {
      final repo = _Repo(devices: _devices());
      await _pump(tester, const DevicesScreen(), repo: repo);
      await tester.tap(findWidgetWithText(PButton, '모든 기기에서 로그아웃'));
      await _go(tester);
      expect(findPlain('모든 기기에서 로그아웃할까요?'), findsOneWidget);
      expect(findPlain('지금 쓰는 기기도 로그아웃돼요. 다시 로그인해야 해요.'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findWidgetWithText(PButton, '모든 기기에서 로그아웃'),
        ),
      );
      await _go(tester);
      expect(repo.revokeAllCalls, 1);
      expect(_Auth.loggedOut, isTrue);
    });

    testWidgets('글자 200% 에서 넘침 0', (tester) async {
      await _pump(
        tester,
        const DevicesScreen(),
        scale: 2,
        repo: _Repo(devices: _devices()),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
