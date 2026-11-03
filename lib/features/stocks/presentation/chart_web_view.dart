/// 증권 상세 캔들 차트를 desk-front 의 임베드 페이지(/embed/stocks/:symbol)로 띄우는 WebView 위젯.
///
/// 인증: 진입 시 백엔드 POST /api/v1/auth/embed-token 으로 60초 단명 토큰 발급 →
/// 페이지가 ready 를 알리면 `__tokenBridge` 로 밀어넣는다 → desk-front 가 Authorization: Bearer 로
/// candle API 호출. 글로벌 desk_access_token 쿠키 시드 불필요(WebViewCookieManager 의 iOS HttpOnly 제약 회피).
///
/// **토큰은 URL 에 싣지 않는다.** 회전 토큰이 이미 __tokenBridge 로 다니고 있었으므로 첫 토큰도
/// 같은 길로 보낸다 — 전달 규칙과 그 이유는 [chart_bridge.dart] 참고.
///
/// 양방향 통신:
///   - Dart → JS: controller.runJavaScript('window.__tokenBridge|__themeBridge|__rangeBridge(...)')
///   - JS → Dart: JavaScriptChannel 'PorestChart' 메시지({type: 'ready'|'error', ...})
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/stocks/presentation/chart_bridge.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 증권 차트 WebView 높이 — 그래프 168 + 범례(O·H·L·C·VOL) 두 줄 44.
/// 임베드 페이지(height 100%)가 범례 줄을 이 안에서 나눠 쓰므로, 범례가 두 줄이면 그래프는 168 이다.
const double kStockChartWebViewHeight = 212;

/// 차트 임베드 페이지를 띄우는 WebView 위젯.
/// 현재 _StockChart 와 동일한 props(symbol/isUs/range/height) 를 받는다.
class ChartWebView extends ConsumerStatefulWidget {
  const ChartWebView({
    super.key,
    required this.symbol,
    required this.isUs,
    required this.range,
    required this.height,
    this.broker,
  });

  /// 이 탭의 증권사('toss' | 'namu') — 임베드 차트가 그 증권사 캔들을 부르게 할 자리.
  /// 주소에 실리는지는 `kEmbedBrokerQueryEnabled` 가 정한다.
  final String? broker;
  final String symbol;
  final bool isUs;
  final String range;
  final double height;

  @override
  ConsumerState<ChartWebView> createState() => _ChartWebViewState();
}

class _ChartWebViewState extends ConsumerState<ChartWebView> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;
  Timer? _tokenTimer; // embed_token 만료 전 in-place 갱신 주기 타이머

  /// embed_token 갱신 주기 — 토큰(60s)이 만료되기 전에 새 토큰을 push.
  static const Duration _tokenRefreshInterval = Duration(seconds: 45);

  /// 토큰·기간·테마를 JS 로 밀어넣는 큐. ready 전 push 는 보관했다가 ready 에 replay.
  late final ChartBridge _bridge = ChartBridge(
    (js) => _controller?.runJavaScript(js),
  );

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// 인증된 사용자(쿠키)로 60초 embed_token 발급. 실패 시 null.
  Future<String?> _fetchEmbedToken() async {
    final dio = await ref.read(dioProvider.future);
    final res = await dio.post<dynamic>('/auth/embed-token');
    final body = res.data;
    final data = (body is Map<String, dynamic>) ? body['data'] : null;
    return (data is Map<String, dynamic>) ? data['token'] as String? : null;
  }

  Future<void> _initialize() async {
    try {
      // 1) embed_token 발급
      final token = await _fetchEmbedToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = AppLocalizations.of(context).stocksChartTokenFailed;
          });
        }
        return;
      }

      // 2) WebView 컨트롤러 구성 — SSO 로그인 화면 패턴 재사용(allowedHost · onNavigationRequest 제한)
      final webOrigin = Uri.tryParse(Env.webBaseUrl);
      if (Env.appEnv != 'local' && webOrigin?.scheme != 'https') {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = AppLocalizations.of(context).stocksChartHttpsError;
          });
        }
        return;
      }
      final allowedHost = webOrigin?.host;

      // 3) 토큰을 브릿지에 보관 — 아직 ready 전이라 나가지 않고, 페이지가 ready 를 알리는 순간
      //    첫 push 로 나간다. **loadRequest 보다 먼저** 넣어야 ready 를 놓치지 않는다.
      _bridge.pushToken(token);

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000)) // 투명 — 부모 PCard 배경이 비치도록
        ..addJavaScriptChannel(
          'PorestChart',
          onMessageReceived: _onChannelMessage,
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) =>
                mounted ? setState(() => _loading = true) : null,
            onPageFinished: (_) =>
                mounted ? setState(() => _loading = false) : null,
            onWebResourceError: (e) {
              if (!mounted) return;
              // 메인 프레임 에러만 사용자에게 노출(서브 리소스 누락은 잡소리 방지)
              if (e.isForMainFrame ?? true) {
                setState(() {
                  _error = '${e.errorCode}: ${e.description}';
                });
              }
            },
            onNavigationRequest: (req) {
              final target = Uri.tryParse(req.url);
              if (target == null) return NavigationDecision.prevent;
              // 외부 origin 차단(attributionLogo 외부 이동 등) — about:blank / data: 제외하고 webOrigin 만 허용
              if (target.scheme == 'about' || target.scheme == 'data') {
                return NavigationDecision.navigate;
              }
              if (target.host != allowedHost) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(_buildEmbedUrl()));

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _error = null;
      });
      _startTokenRefresh(); // reload 없는 토큰 회전 시작
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            '${AppLocalizations.of(context).stocksChartTokenFailed}: ${e.response?.statusCode ?? e.message ?? "error"}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).stocksChartInitFailed;
      });
    }
  }

  String _buildEmbedUrl() => buildEmbedUrl(
    webBaseUrl: Env.webBaseUrl,
    symbol: widget.symbol,
    range: widget.range,
    theme: Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light',
    isUs: widget.isUs,
    broker: widget.broker,
  );

  void _onChannelMessage(JavaScriptMessage msg) {
    try {
      final payload = jsonDecode(msg.message);
      if (payload is! Map) return;
      final type = payload['type'];
      if (type == 'ready') {
        if (!mounted) return;
        // 첫 토큰이 여기서 나간다(URL 대신). 기간·테마도 ready 전 변경분이 있으면 이어서 replay.
        _bridge.onReady();
      } else if (type == 'error') {
        final code = payload['code'];
        // 401: embed_token 만료/위조 → 토큰 재발급 후 reload
        if (code == 401 && _controller != null) {
          unawaited(_reinitialize());
        } else {
          if (kDebugMode) debugPrint('[ChartWebView] embed error: $payload');
        }
      }
    } catch (_) {
      /* 무시 */
    }
  }

  /// embed_token 을 만료 전 주기적으로 재발급해 __tokenBridge 로 push → WebView reload 없이
  /// 헤더만 교체(스피너 없는 토큰 회전). 발급 실패 시 다음 주기 재시도, 만료되면 401 fallback.
  void _startTokenRefresh() {
    _tokenTimer?.cancel();
    _tokenTimer = Timer.periodic(_tokenRefreshInterval, (_) async {
      if (!mounted || _controller == null) return;
      try {
        final token = await _fetchEmbedToken();
        if (token == null || token.isEmpty || !mounted) return;
        // ready 전(로드 중·재초기화 중)이면 브릿지가 보관했다가 ready 에 내보낸다.
        // 예전엔 여기서 바로 쐈고, 페이지가 아직 없으면 그 토큰은 그냥 사라졌다.
        _bridge.pushToken(token);
      } catch (_) {
        /* 다음 주기 재시도; 만료 시 embed 페이지 401 → fallback reload */
      }
    });
  }

  Future<void> _reinitialize() async {
    if (!mounted) return;
    _tokenTimer?.cancel();
    _bridge.reset(); // 새 페이지가 ready 를 알릴 때까지 다시 보관 모드
    setState(() {
      _loading = true;
      _error = null;
    });
    // 기존 컨트롤러는 _controller 교체로 dispose 처리 — _initialize 가 새 컨트롤러 세팅
    await _initialize();
  }

  @override
  void didUpdateWidget(covariant ChartWebView old) {
    super.didUpdateWidget(old);
    if (widget.range != old.range) _bridge.pushRange(widget.range);
    // symbol 이 바뀌면 임베드 URL 자체가 달라지므로 재초기화(토큰도 갱신)
    // isUs 도 주소(가격 축 정밀도)에 들어간다 — 마스터 응답이 뒤늦게 와서 바뀌면 다시 연다(M1)
    if (widget.symbol != old.symbol || widget.isUs != old.isUs) {
      unawaited(_reinitialize());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    // 테마 변경 감지 — settingsProvider 의 themeMode 변경 시 JS 채널로 푸시
    ref.listen<AsyncValue<AppSettings>>(settingsProvider, (_, next) {
      final mode = next.value?.themeMode ?? ThemeMode.system;
      final resolved = _resolveThemeMode(context, mode);
      _bridge.pushTheme(resolved);
    });

    Widget body;
    if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '${l.stocksChartLoadFailed}\n$_error',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: t.fgTertiary),
          ),
        ),
      );
    } else if (_controller == null || _loading) {
      // 스켈레톤 — feedback_skeleton_server_data_only.md 준수(shadow 만, border X)
      body = Container(
        decoration: BoxDecoration(
          color: t.bgSunken,
          borderRadius: PRadius.brMd,
        ),
      );
    } else {
      body = WebViewWidget(
        controller: _controller!,
        // 시트/스크롤 부모 안에서 핀치/팬 제스처를 WebView 가 가져가도록 — 부모와 충돌 방지
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
          Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
        },
      );
    }

    return SizedBox(height: widget.height, child: body);
  }

  @override
  void dispose() {
    _tokenTimer?.cancel();
    // iOS 메모리 회수: about:blank 로 SPA/canvas 해제 후 컨트롤러 폐기(webview_flutter 4.x 는 자동 dispose).
    _controller?.loadRequest(Uri.parse('about:blank'));
    super.dispose();
  }
}

String _resolveThemeMode(BuildContext context, ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark
          ? 'dark'
          : 'light';
  }
}
