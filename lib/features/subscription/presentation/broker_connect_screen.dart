import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/features/subscription/presentation/broker_status.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/logo_tile/p_logo_tile.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/toggle/p_toggle.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';

/// 증권사 한 곳 — 둘째 단계(결정 B, I-wrap-b1 β). 별도 라우트 `/settings/securities/:broker`.
///
/// - 미연결: 키 · 시크릿 칸(Field + Input, 눈 Toggle 44) + 안내 + 바닥 [연결하기].
/// - 연결됨: 상태 줄 + 바닥 왼쪽 [연결 해제](ghost critical · 확인창 한 번) · 오른쪽 [기본으로 쓰기].
///
/// **증권사 이름을 코드에 박지 않는다.** 표시명 · 발급처 · 입력 라벨은 서버가 주는 [BrokerConnection] 에서 온다.
///
/// 나가기: 연결 요청이 나가 있는 동안(busy)은 막는다(canPop=false). 키 · 시크릿에 친 값이 있으면 ← · 안드로이드 뒤로 ·
/// 예측형 뒤로 모두 "작성한 내용이 사라져요" 를 묻는다(I-wrap-b2b 5, 금액 가리기와 같은 방식). PopScope 는 셸이 아니라 이
/// 화면에 둔다(예측형 뒤로가기). 첫 단계 화면에는 두지 않는다.
class BrokerConnectScreen extends ConsumerStatefulWidget {
  const BrokerConnectScreen({super.key, required this.broker});

  /// 증권사 코드('TOSS' | 'NAMU' …) — 목록 줄이 라우트에 싣는다.
  final String broker;

  @override
  ConsumerState<BrokerConnectScreen> createState() =>
      _BrokerConnectScreenState();
}

class _BrokerConnectScreenState extends ConsumerState<BrokerConnectScreen> {
  final _keyCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  bool _busy = false;
  // 붙여넣은 키가 맞는지 눈으로 확인할 방법이 없으면 연동이 실패해도 원인을 못 찾는다.
  // 기본은 가린 상태고, 사용자가 잠깐 벗겨 보는 건 본인 의지다.
  bool _revealKey = false;
  bool _revealSecret = false;
  // 연결 실패 — 키 입력 폼이라 폼 위 Callout 한 문장(값 남김). 해제 · 기본 변경은 스낵바 + [다시 시도].
  String? _connectError;
  final _errorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 친 값이 있는지가 PopScope 를 바꾼다 — 칸이 바뀔 때마다 다시 그린다
    _keyCtrl.addListener(_onText);
    _secretCtrl.addListener(_onText);
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  bool get _hasInput => _keyCtrl.text.isNotEmpty || _secretCtrl.text.isNotEmpty;

  /// 저장하지 않고 나가려 할 때 — 친 값이 사라지는 걸 알리고, 확인하면 화면을 닫는다(금액 가리기와 같은 글).
  Future<void> _confirmDiscardAndPop() async {
    final l = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final ok = await PAlertDialog.show(
      context,
      title: l.hideAmountsDiscardTitle,
      description: l.securitiesLeaveBody,
      actionLabel: l.hideAmountsDiscardConfirm,
      destructive: true,
      cancelLabel: l.actionCancel,
    );
    if (ok && mounted) router.pop();
  }

  void _setBusy(bool busy) {
    if (mounted) setState(() => _busy = busy);
  }

  Future<void> _connect(BrokerConnection c, String key, String secret) async {
    final l = AppLocalizations.of(context);
    // 응답을 못 받은 뒤 다시 받기는 화면이 사라져도 한다 — 컨테이너를 미리 잡는다
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _connectError = null);
    _setBusy(true);
    try {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      await repo.registerBrokerCredential(c.broker, key, secret, silent: true);
      // 연결됐다 — 친 값은 저장된 것이다. 비우지 않으면 연결 해제 뒤 폼에 옛 키가 남는다
      _keyCtrl.clear();
      _secretCtrl.clear();
      ref.invalidate(myFeaturesLoadProvider);
      ref.invalidate(brokerConnectionsProvider);
      if (mounted) {
        PSnackbar.maybeOf(
          context,
        )?.show(message: l.subBrokerConnected(c.displayName));
      }
    } catch (e) {
      // 응답을 못 받았다 — 연결됐을 수 있다. 실패라 하지 않고 연결 상태를 다시 받는다(디자인시스템 판단 ⑤).
      // 키 등록은 같은 증권사를 덮어쓰므로 다시 눌러도 두 번 생기지 않는다 — 단추는 그대로 둔다
      final unconfirmed = isUnconfirmedSave(e);
      if (unconfirmed) {
        container
          ..invalidate(myFeaturesLoadProvider)
          ..invalidate(brokerConnectionsProvider);
      }
      if (!mounted) return;
      // 4xx = 인증정보를 서버가 거절 — 틀림. 그 밖(서버 · 네트워크)은 연결 실패(웹과 같은 갈래).
      final invalid =
          e is ApiException &&
          (e.statusCode ?? 0) >= 400 &&
          (e.statusCode ?? 0) < 500;
      setState(() {
        _connectError = unconfirmed
            ? l.unconfirmedConnect
            : invalid
            ? l.subBrokerInvalidCred
            : l.subBrokerConnectFailed;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _errorKey.currentContext;
        if (ctx != null && ctx.mounted) revealBelowFog(ctx);
      });
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _run(
    Future<void> Function(SubscriptionRepository repo) action,
    String okMsg,
    String errMsg,
  ) async {
    _setBusy(true);
    try {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      await action(repo);
      ref.invalidate(myFeaturesLoadProvider);
      ref.invalidate(brokerConnectionsProvider);
      if (mounted) PSnackbar.maybeOf(context)?.show(message: okMsg);
    } catch (e) {
      // 서버 글은 내지 않는다(요청은 silent) — 고정 글 한 문장 + [다시 시도](같은 일을 다시)
      if (mounted) {
        PSnackbar.maybeOf(context)?.show(
          message: errMsg,
          tone: PSnackbarTone.critical,
          action: PSnackbarAction(
            label: AppLocalizations.of(context).actionRetry,
            onPressed: () => _run(action, okMsg, errMsg),
          ),
        );
      }
    } finally {
      _setBusy(false);
    }
  }

  /// [연결 해제] — 확인창 한 번, 확인하면 요청을 보낸다.
  Future<void> _confirmDisconnect(BrokerConnection c) async {
    final l = AppLocalizations.of(context);
    final ok = await PAlertDialog.show(
      context,
      title: l.subBrokerDisconnectConfirmTitle(c.displayName),
      description: l.subBrokerDisconnectConfirmBody,
      actionLabel: l.assetUnlink,
      cancelLabel: l.actionCancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(
      (repo) => repo.disconnectBrokerCredential(c.broker, silent: true),
      l.subBrokerDisconnected(c.displayName),
      l.subDisconnectFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final connectionsAsync = ref.watch(brokerConnectionsProvider);
    final all = connectionsAsync.value;
    BrokerConnection? c;
    for (final b in all ?? const <BrokerConnection>[]) {
      if (b.broker.toLowerCase() == widget.broker.toLowerCase()) c = b;
    }
    final dirty = c != null && !c.connected && _hasInput;

    return PopScope(
      // 요청이 나가 있는 동안은 막는다 · 친 값이 있으면 묻는다
      canPop: !dirty && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        // 요청이 나가 있는 동안은 묻지 않고 막는다 — 묻는 확인창은 그 뒤에만
        if (didPop || !mounted || _busy) return;
        _confirmDiscardAndPop();
      },
      child: Scaffold(
        backgroundColor: context.colors.bgLayerBasement,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
          child: PTopNavigation(
            title: c?.displayName ?? l.settingsSecuritiesLink,
            leading: PTopNavigationIconButton.back(
              label: l.actionBack,
              // 화면의 PopScope 를 지나게 — 친 값이 있으면 묻는다
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ),
        body: c == null
            ? PScreenBandBody(child: _noBroker(connectionsAsync))
            : _body(c, (all ?? const []).where((b) => b.connected).length),
      ),
    );
  }

  /// 목록에서 이 증권사를 못 찾았다 — 받는 중이거나(딥링크 · 다시 받기) 받지 못했다.
  Widget _noBroker(AsyncValue<List<BrokerConnection>> async) {
    final l = AppLocalizations.of(context);
    if (async.isLoading && !async.hasError) {
      return const Center(
        child: PProgressCircle(key: ValueKey('broker-loading')),
      );
    }
    return PResultSection(
      key: const ValueKey('broker-load-failed'),
      kind: PResultKind.failure,
      title: l.securitiesLoadError,
      description: l.subLoadFailedDesc,
      primaryAction: PResultAction(
        label: l.actionRetry,
        onPressed: () => ref.invalidate(brokerConnectionsProvider),
      ),
    );
  }

  Widget _body(BrokerConnection c, int connectedCount) {
    final colors = context.colors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final connected = c.connected;
    // 연결이 하나뿐이면 기본 소스를 고를 게 없다 — 버튼을 감춘다.
    final showPrimary = connected && connectedCount > 1 && !c.primary;

    return Column(
      children: [
        Expanded(
          child: PScreenBandBody(
            child: AbsorbPointer(
              // 요청이 나가 있는 동안은 칸을 받지 않는다
              absorbing: _busy,
              child: ListView(
                key: const ValueKey('broker-body'),
                padding: const EdgeInsets.only(bottom: PSpacing.x6),
                children: connected
                    ? _connectedChildren(c, showPrimary)
                    : _formChildren(c),
              ),
            ),
          ),
        ),
        // 바닥 — 화면 아래 고정, 위에 끝까지 닿는 선
        DecoratedBox(
          key: const ValueKey('broker-bottom'),
          decoration: BoxDecoration(
            color: colors.bgLayerDefault,
            border: Border(top: BorderSide(color: colors.strokeNeutralSubtle)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x3,
              PSpacing.globalGutter,
              PSpacing.x4 + bottomInset,
            ),
            child: connected
                ? _connectedActions(c, showPrimary)
                : _connectAction(c),
          ),
        ),
      ],
    );
  }

  // ── 미연결: 입력 폼 ─────────────────────────────────────────

  List<Widget> _formChildren(BrokerConnection c) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    const gutter = EdgeInsets.symmetric(horizontal: PSpacing.globalGutter);
    return [
      if (_connectError != null)
        Padding(
          padding: gutter.copyWith(top: PSpacing.x4),
          child: FormErrorCallout(key: _errorKey, message: _connectError!),
        ),
      // 라벨은 서버가 준다 — 회사마다 같은 자리를 다르게 부른다.
      // 키도 시크릿과 같은 자격증명의 반쪽이다 — 어깨너머로 읽히면 안 된다.
      Padding(
        padding: gutter.copyWith(top: PSpacing.x4),
        child: _secretField(
          label: c.keyLabel,
          controller: _keyCtrl,
          revealed: _revealKey,
          onReveal: (v) => setState(() => _revealKey = v),
        ),
      ),
      Padding(
        padding: gutter.copyWith(top: PSpacing.x4),
        child: _secretField(
          label: c.secretLabel,
          controller: _secretCtrl,
          revealed: _revealSecret,
          onReveal: (v) => setState(() => _revealSecret = v),
        ),
      ),
      Padding(
        padding: gutter.copyWith(top: PSpacing.x4),
        child: Text(
          keepAll(l.subBrokerKeyNotice(c.displayName)),
          style: PTypography.t4.copyWith(color: colors.fgNeutralSubtle),
        ),
      ),
    ];
  }

  /// 칸 하나 — Field + Input 에 눈 Toggle(44, 칸 오른쪽). 켠 상태는 eye-off.
  Widget _secretField({
    required String label,
    required TextEditingController controller,
    required bool revealed,
    required ValueChanged<bool> onReveal,
  }) {
    final l = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: PSpacing.x1,
      children: [
        Expanded(
          child: PField(
            label: label,
            child: PInput(
              controller: controller,
              obscureText: !revealed,
              secret: true,
              disabled: _busy,
              autofillHints: const [],
            ),
          ),
        ),
        PToggle(
          semanticLabel: l.subBrokerToggleReveal(label),
          pressed: revealed,
          onChanged: onReveal,
          icon: LucideIcons.eye,
          pressedIcon: LucideIcons.eyeOff500,
        ),
      ],
    );
  }

  Widget _connectAction(BrokerConnection c) {
    final l = AppLocalizations.of(context);
    final key = _keyCtrl.text.trim();
    final secret = _secretCtrl.text.trim();
    return SizedBox(
      width: double.infinity,
      child: PButton(
        label: l.subConnect,
        size: PButtonSize.large,
        loading: _busy,
        onPressed: key.isEmpty || secret.isEmpty || _busy
            ? null
            : () => _connect(c, key, secret),
      ),
    );
  }

  // ── 연결됨: 상태 + 바닥 동작 ────────────────────────────────

  List<Widget> _connectedChildren(BrokerConnection c, bool showPrimary) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    return [
      PList(
        semanticLabel: c.displayName,
        children: [
          PListItem(
            prefix: PLogoTile(name: c.displayName),
            title: c.displayName,
            titleSuffix: [if (c.primary) PBadge(label: l.subBrokerPrimary)],
            detail: brokerStatusText(l, c),
          ),
        ],
      ),
      if (showPrimary)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            PSpacing.x2,
            PSpacing.globalGutter,
            0,
          ),
          child: Text(
            keepAll(l.subBrokerPrimaryNotice),
            style: PTypography.t4.copyWith(color: colors.fgNeutralSubtle),
          ),
        ),
    ];
  }

  Widget _connectedActions(BrokerConnection c, bool showPrimary) {
    final l = AppLocalizations.of(context);
    final disconnect = PButton(
      label: l.assetUnlink,
      variant: PButtonVariant.ghost,
      ghostColor: PButtonGhostColor.critical,
      size: PButtonSize.large,
      onPressed: _busy ? null : () => _confirmDisconnect(c),
    );
    if (!showPrimary) {
      // 기본이거나 연결이 하나뿐이면 [기본으로 쓰기] 가 없다 — [연결 해제] 만 왼쪽에
      return Align(alignment: Alignment.centerLeft, child: disconnect);
    }
    return PResponsivePair(
      secondary: disconnect,
      primary: PButton(
        label: l.subBrokerUseAsPrimary,
        size: PButtonSize.large,
        loading: _busy,
        onPressed: _busy
            ? null
            : () => _run(
                (repo) => repo.setPrimaryBroker(c.broker, silent: true),
                l.subBrokerPrimaryChanged(c.displayName),
                l.subBrokerPrimaryFailed,
              ),
      ),
    );
  }
}
