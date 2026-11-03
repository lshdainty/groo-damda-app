import 'dart:async';

import 'package:flutter/material.dart';
import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/features/sms/data/sms_android.dart';
import 'package:groo_damda_app/features/sms/domain/sms_paste_args.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/session_owner.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/lock/app_lock_gate.dart';
import 'package:groo_damda_app/core/lifecycle/screen_visibility.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/notification/application/notification_stream_service.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/core/auth/oauth_link_listener.dart';
import 'package:groo_damda_app/app/router.dart';
import 'package:groo_damda_app/app/session_scope.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

/// 화면 밖(네트워크 인터셉터 등)에서 토스트를 띄우기 위한 전역 키.
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class GrooDamdaApp extends ConsumerStatefulWidget {
  const GrooDamdaApp({super.key});

  @override
  ConsumerState<GrooDamdaApp> createState() => _GrooDamdaAppState();
}

class _GrooDamdaAppState extends ConsumerState<GrooDamdaApp>
    with WidgetsBindingObserver {
  ProviderSubscription<AsyncValue<User?>>? _authSub;

  /// 다른 사람이 들어와 컨테이너를 새로 만들어 달라고 한 뒤다 — 이 셸은 다음 프레임에
  /// 사라진다. 그때까지 들어오는 신호(인증 변화·포그라운드 복귀)에는 손대지 않는다.
  ///
  /// 다음 프레임이 곧바로 오지 않을 수 있다. 앱이 가려진 채로 로그인이 끝나면 프레임은
  /// 복귀할 때까지 멈춰 있고, 복귀 신호는 **이 셸이 먼저** 받는다. 거기서 대기 중인
  /// 결제 문자를 꺼내면(네이티브는 꺼내는 순간 비운다) 곧 사라질 화면이 들고 없어진다.
  bool _handedOver = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 알림 폴링은 **앞에 있을 때만** 돈다 — 앱이 가려지거나 화면이 꺼지면 멈춘다.
    // 폴링이 바꾸는 건 앱 안 배지뿐이라(폰 알림창은 아직 FCM 이 없다) 안 보이는 동안
    // 받아 온 20건은 아무도 못 보고 사라진다 — 배터리·데이터만 쓴다.
    // 조건이 둘이라 각각 듣고 그때마다 다시 판정한다([_syncNotificationPoller]).
    ref.listenManual(
      appForegroundProvider,
      (_, _) => _syncNotificationPoller(),
    );
    // 인증 성공 시 알림 폴링 시작, 로그아웃 시 정지.
    _authSub = ref.listenManual<AsyncValue<User?>>(authProvider, (prev, next) {
      if (_handedOver) return;
      // 앞사람과 다른 사람이 로그인했다 — 이 컨테이너가 들고 있는 값은 전부 앞사람
      // 몫이다. 비우지 않고 컨테이너째 새로 만든다(이유는 SessionScope 주석).
      //
      // **맨 먼저** 가리고 여기서 끝낸다. 아래 로그인 직후 처리를 이어 하면 곧 버려질
      // 컨테이너에 조회를 걸고, 대기 중인 결제 문자를 여기서 소비해 버린다 — 새
      // 컨테이너가 앱을 새로 켠 것과 같은 길로 처음부터 다시 한다.
      if (ref.read(sessionOwnerProvider).replacedBy(next)) {
        final restart = ref.read(sessionRestartProvider);
        if (restart != null) {
          _handedOver = true;
          // 떠 있던 토스트도 앞사람 것이다. ScaffoldMessenger 는 전역 키라 컨테이너를
          // 갈아도 플러터가 새 트리로 옮겨 붙인다 — 직접 걷어야 한다.
          // `clearSnackBars` 는 줄 선 것만 버리고 지금 것은 사라지는 애니메이션을
          // 태운다. 그 몇 프레임 동안 글자가 읽히므로 `remove` 로 그 자리에서 걷는다.
          appMessengerKey.currentState
            ?..clearSnackBars()
            ..removeCurrentSnackBar();
          restart();
          return;
        }
      }
      final user = next.value;
      _syncNotificationPoller();
      if (user != null) {
        // 앱을 새로 켠 직후에도 세션 캐시를 한 번 비운다.
        //
        // resumed 는 이미 떠 있던 앱이 돌아올 때만 온다. 완전히 종료했다 켜면
        // 그 신호가 없어서, 로그인 검증 직후 화면들이 keepAlive provider 를
        // 채우고 나면 앱을 끌 때까지 그 값이 굳었다 — 그사이 웹에서 고친 카테고리·
        // 자산이 앱에서는 끝내 안 보였다.
        invalidateKeepAliveProviders(ref);
        // 알림을 눌러 앱을 처음 켠 경우도 여기로 온다(콜드 스타트).
        // 로그인 전에 열면 라우터가 로그인 화면으로 되돌리므로 이 시점에 연다.
        _openPendingSms();
        // 금액 가리기를 계정 설정과 맞춘다. 여기서 하는 이유는 로그인 경로가 둘
        // (앱 시작 시 무음 재인증 · 인가코드 교환)인데 둘 다 이 리스너로 모이기 때문이다.
        unawaited(
          ref
              .read(settingsProvider.notifier)
              .syncHideCardsFromServer(user.userId),
        );
      }
    }, fireImmediately: true);
  }

  /// **로그인했고 + 앱이 앞에 있을 때만** 폴링한다 — 인증·포그라운드 어느 쪽이
  /// 바뀌어도 여기로 모인다.
  ///
  /// 다시 부를 때 [NotificationStreamService.start] 를 그대로 쓴다. `start` 는 맨 앞에서
  /// `stop` 을 부르므로 타이머가 겹치지 않고, 이어서 한 번 조회하므로 **돌아온 직후**
  /// 배지가 곧바로 맞는다 — 안 밀면 복귀 후 최대 30초 동안 떠나기 전 값을 본다.
  /// 새 알림 판정 기준(`_lastSeenId`)은 서비스 인스턴스가 들고 있고 `stop`·`start`
  /// 어느 쪽도 건드리지 않는다 — 멈춘 사이 온 알림이 복귀 조회에서 새 것으로 잡힌다.
  void _syncNotificationPoller() {
    if (_handedOver) return;
    final svc = ref.read(notificationStreamServiceProvider);
    final loggedIn = ref.read(authProvider).value != null;
    if (loggedIn && ref.read(appForegroundProvider)) {
      svc.start();
    } else {
      svc.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 포그라운드로 복귀하면 세션 캐시(keepAlive) provider 를 무효화해
    // 백그라운드 동안 다른 클라이언트(웹 등)에서 바뀐 내용을 따라잡는다.
    // 로그인 상태일 때만 — 비로그인 시 불필요한 요청 방지.
    if (_handedOver) return;
    if (state == AppLifecycleState.resumed &&
        ref.read(authProvider).value != null) {
      invalidateKeepAliveProviders(ref);
      _openPendingSms();
    }
  }

  /// 결제 문자 알림을 눌러 들어왔으면 확인 화면을 연다(안드로이드).
  ///
  /// 네이티브가 문자를 들고 있다가 여기서 건네준다 — 가져가면 비우므로
  /// 앱으로 돌아올 때마다 같은 문자가 다시 열리지는 않는다.
  Future<void> _openPendingSms() async {
    final pending = await SmsAndroid.consumePendingSms();
    if (pending == null || !mounted) return;
    // 첫 라우트가 그려지기 전에 밀어 넣으면 스택이 꼬인다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(routerProvider)
          .push(
            '/sms-paste',
            extra: SmsPasteArgs(text: pending.text, inboxId: pending.id),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    // OAuth 콜백 딥링크 리스너 — 앱 수명 내내 켜 둔다(콜드 스타트 복귀 포함).
    ref.watch(oauthLinkListenerProvider);
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    return MaterialApp.router(
      title: '그루 담다',
      // 인터셉터에는 BuildContext 가 없다 — 이 키로 토스트를 띄운다
      // (ErrorToastInterceptor: 아무도 처리하지 않은 API 에러의 마지막 그물).
      scaffoldMessengerKey: appMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: GrooTheme.light(),
      darkTheme: GrooTheme.dark(),
      themeMode: settings.themeMode,
      // i18n: 사용자가 명시적으로 ko/en 선택하지 않았으면 (locale=null)
      // 시스템 로케일을 따르되, 미지원 시 ko 로 폴백.
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // 앱 잠금(생체인증) — 라우터 전체를 덮는 오버레이. 로그인 세션과 별개로,
      // 켜져 있으면 실행·복귀 시 본인 확인 후에만 화면을 보여준다.
      //
      // 스와이프 액션(PSwipeActions)은 "한 번에 한 행만 열림" 을 이 조상에 기댄다.
      // 화면마다 두게 하면 새 리스트를 붙일 때 잊어버리고, 그러면 행이 여러 개
      // 열린 채로 남는다 — 실제로 가계부에서 그렇게 됐다. 여기 한 번만 둔다.
      // 리스트끼리는 groupTag 로 갈라지므로 하나로 충분하다.
      //
      // 주의 — 이 builder 안쪽(라우터 위)의 State 는 **계정이 바뀌어도 살아남는다.**
      // 컨테이너를 새로 만들 때 트리도 새로 그리지만, 위 `scaffoldMessengerKey` 가
      // 전역 키라 플러터가 옛 ScaffoldMessenger 를 그 아래 트리째 새 자리로 옮겨
      // 붙인다(라우터부터는 새 GoRouter 의 키라 새로 만들어진다). 그래서 여기에는
      // 사용자 데이터를 State 로 들지 말고, `ref.listenManual` 도 걸지 않는다 —
      // `ref.watch`·`ref.listen` 은 새 컨테이너로 옮겨 가지만 listenManual 은 버려진
      // 컨테이너에 묶인 채 남는다.
      //
      // 스낵바(ds PSnackbar)의 호스트도 여기 한 번 둔다 — 잠금 화면 아래(AppLockGate 안쪽), 길잡이(Navigator) 바깥이라
      // 시트 · 확인창 위에 뜨고 탭 바(PSnackbarAvoidOverlap) 위 8 에 선다. 호스트 State 는 잠깐 뜨는 띠 하나뿐이다.
      builder: (context, child) {
        // 설정이 "시스템 따름" 이어도 글이 영어면 돈 · 날짜도 영어로 — 전역 포맷 로케일을 화면 로케일에 맞춘다
        syncIntlLocale(Localizations.localeOf(context));
        return _shell(context, child);
      },
      routerConfig: router,
    );
  }

  Widget _shell(
    BuildContext context,
    Widget? child,
  ) => SlidableAutoCloseBehavior(
    child: AppLockGate(
      // 투명 Material — 호스트가 Navigator 바깥이라 Material 조상이 없으면 띠 글에 노란 이중 밑줄(기본 글 스타일 없음)이 간다.
      child: Material(
        type: MaterialType.transparency,
        child: PSnackbarHost(
          closeLabel: AppLocalizations.of(context).actionClose,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
}
