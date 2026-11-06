import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_badge.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import 'package:groo_damda_app/shared/widgets/p_card.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/widgets/p_text_input.dart';

/// 증권사 한 곳의 연결 카드 — 키 등록 / 해제 / 기본 시세 소스 지정.
///
/// **증권사 이름을 코드에 박지 않는다.** 표시명·발급처·입력 라벨은 서버가 주는
/// [BrokerConnection] 에서 온다. 증권사가 늘어도 앱 배포 없이 목록에 나타나고,
/// 같은 자리를 회사마다 다르게 부르는 문제(토스 Client ID / 나무 App Key)도 여기서 풀린다.
class BrokerConnectCard extends ConsumerStatefulWidget {
  const BrokerConnectCard({
    super.key,
    required this.connection,
    required this.showPrimaryAction,
    this.onDirtyChanged,
    this.onBusyChanged,
  });

  final BrokerConnection connection;

  /// 키 · 시크릿 칸에 친 값이 있는가가 바뀌면 — 화면이 나가기 전에 묻는다(I-wrap-b2b 5).
  final ValueChanged<bool>? onDirtyChanged;

  /// 연결 · 해제 · 기본 변경 요청이 나가 있는가가 바뀌면 — 그동안 화면은 나가지 않는다.
  final ValueChanged<bool>? onBusyChanged;

  /// 기본 시세 소스 지정 버튼 노출 여부. 연결이 하나뿐이면 고를 게 없어 감춘다.
  final bool showPrimaryAction;

  @override
  ConsumerState<BrokerConnectCard> createState() => _BrokerConnectCardState();
}

class _BrokerConnectCardState extends ConsumerState<BrokerConnectCard> {
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

  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _keyCtrl.addListener(_reportDirty);
    _secretCtrl.addListener(_reportDirty);
  }

  @override
  void didUpdateWidget(BrokerConnectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 연결되면 칸이 사라진다 — 친 값은 저장된 것이다
    if (oldWidget.connection.connected != widget.connection.connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reportDirty());
    }
  }

  void _reportDirty() {
    final dirty =
        !widget.connection.connected &&
        (_keyCtrl.text.isNotEmpty || _secretCtrl.text.isNotEmpty);
    if (dirty == _dirty) return;
    _dirty = dirty;
    widget.onDirtyChanged?.call(dirty);
  }

  void _setBusy(bool busy) {
    setState(() => _busy = busy);
    widget.onBusyChanged?.call(busy);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect(BrokerConnection c, String key, String secret) async {
    final l = AppLocalizations.of(context);
    setState(() => _connectError = null);
    _setBusy(true);
    try {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      await repo.registerBrokerCredential(c.broker, key, secret, silent: true);
      ref.invalidate(myFeaturesLoadProvider);
      ref.invalidate(brokerConnectionsProvider);
      if (mounted) {
        PSnackbar.maybeOf(
          context,
        )?.show(message: l.subBrokerConnected(c.displayName));
      }
    } catch (e) {
      if (!mounted) return;
      // 4xx = 인증정보를 서버가 거절 — 틀림. 그 밖(서버 · 네트워크)은 연결 실패(웹과 같은 갈래).
      final invalid =
          e is ApiException &&
          (e.statusCode ?? 0) >= 400 &&
          (e.statusCode ?? 0) < 500;
      setState(() {
        _connectError = invalid
            ? l.subBrokerInvalidCred
            : l.subBrokerConnectFailed;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _errorKey.currentContext;
        if (ctx != null && ctx.mounted) revealBelowFog(ctx);
      });
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  Future<void> _run(
    Future<void> Function(SubscriptionRepository repo) action,
    String okMsg,
    String Function(Object error) errMsg,
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
          message: errMsg(e),
          tone: PSnackbarTone.critical,
          action: PSnackbarAction(
            label: AppLocalizations.of(context).actionRetry,
            onPressed: () => _run(action, okMsg, errMsg),
          ),
        );
      }
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = widget.connection;

    return PCard(
      variant: PCardVariant.bordered,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(t, c),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpace.x16,
              0,
              PSpace.x16,
              PSpace.x16,
            ),
            child: c.connected ? _connectedBody(t, c) : _formBody(t, c),
          ),
        ],
      ),
    );
  }

  Widget _header(GrooTokens t, BrokerConnection c) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x16,
        PSpace.x16,
        PSpace.x16,
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.bgBrandSubtle,
              borderRadius: PRadius.brMd,
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.link, size: 18, color: t.fgBrand),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.displayName,
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: 15,
                    fontWeight: PFontWeight.bold,
                    color: t.fgPrimary,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l.subBrokerConnectDesc,
                  style: PTypo.caption.copyWith(
                    color: t.fgSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (c.primary) ...[
            const SizedBox(width: PSpace.x8),
            PBadge(label: l.subBrokerPrimary, variant: PBadgeVariant.softBrand),
          ] else if (c.connected) ...[
            const SizedBox(width: PSpace.x8),
            PBadge(label: l.subConnected, variant: PBadgeVariant.softSuccess),
          ],
        ],
      ),
    );
  }

  Widget _connectedBody(GrooTokens t, BrokerConnection c) {
    final l = AppLocalizations.of(context);
    final verifiedAt = c.verifiedAt;
    // verifiedAt 은 서버 `[UTC]`(UserSecuritiesCredential.verified_at) — 자르면 UTC
    // 날짜가 그대로 나와 KST(+9) 새벽 0~9시 연동이 전날로 보인다. 못 읽는 값만
    // 예전처럼 잘라 쓴다 — 형식이 달라졌다고 라벨을 통째로 잃는 것보단 낫다.
    final sub = verifiedAt != null && verifiedAt.length >= 10
        ? l.subBrokerLastVerified(
            localDateKey(verifiedAt) ?? verifiedAt.substring(0, 10),
          )
        : l.subBrokerCollecting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: t.bgSunken,
            borderRadius: PRadius.brMd,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.circleCheck, size: 18, color: t.statusSuccessFg),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.subBrokerKeyConnected(c.displayName),
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: 13,
                        fontWeight: PFontWeight.semi,
                        color: t.fgPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(sub, style: PTypo.micro.copyWith(color: t.fgTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: PSpace.x8),
              PButton(
                label: l.assetUnlink,
                variant: PButtonVariant.outline,
                size: PButtonSize.sm,
                onPressed: _busy
                    ? null
                    : () => _run(
                        (repo) => repo.disconnectBrokerCredential(
                          c.broker,
                          silent: true,
                        ),
                        l.subBrokerDisconnected(c.displayName),
                        (_) => l.subDisconnectFailed,
                      ),
              ),
            ],
          ),
        ),
        // 연결이 둘 이상일 때만 고를 의미가 있다.
        if (widget.showPrimaryAction && !c.primary) ...[
          const SizedBox(height: PSpace.x12),
          PButton(
            label: l.subBrokerUseAsPrimary,
            variant: PButtonVariant.outline,
            fullWidth: true,
            onPressed: _busy
                ? null
                : () => _run(
                    (repo) => repo.setPrimaryBroker(c.broker, silent: true),
                    l.subBrokerPrimaryChanged(c.displayName),
                    (_) => l.subBrokerPrimaryFailed,
                  ),
          ),
          const SizedBox(height: PSpace.x8),
          Text(
            l.subBrokerPrimaryNotice,
            style: PTypo.micro.copyWith(color: t.fgTertiary, height: 1.5),
          ),
        ],
      ],
    );
  }

  Widget _formBody(GrooTokens t, BrokerConnection c) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_connectError != null)
          FormErrorCallout(key: _errorKey, message: _connectError!),
        // 라벨은 서버가 준다 — 회사마다 같은 자리를 다르게 부른다.
        Text(c.keyLabel, style: _fieldLabel(t)),
        const SizedBox(height: PSpace.x4),
        // 키도 시크릿과 같은 자격증명의 반쪽이다 — 어깨너머로 읽히면 안 된다.
        PTextInput(
          controller: _keyCtrl,
          placeholder: c.keyLabel,
          obscureText: !_revealKey,
          secret: true,
          suffix: _RevealSuffix(
            revealed: _revealKey,
            semanticLabel: l.subBrokerToggleReveal(c.keyLabel),
            onTap: () => setState(() => _revealKey = !_revealKey),
          ),
        ),
        const SizedBox(height: PSpace.x12),
        Text(c.secretLabel, style: _fieldLabel(t)),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _secretCtrl,
          placeholder: c.secretLabel,
          obscureText: !_revealSecret,
          secret: true,
          suffix: _RevealSuffix(
            revealed: _revealSecret,
            semanticLabel: l.subBrokerToggleReveal(c.secretLabel),
            onTap: () => setState(() => _revealSecret = !_revealSecret),
          ),
        ),
        const SizedBox(height: PSpace.x12),
        PButton(
          label: _busy ? l.subConnecting : l.subConnect,
          fullWidth: true,
          onPressed: _busy
              ? null
              : () {
                  final key = _keyCtrl.text.trim();
                  final secret = _secretCtrl.text.trim();
                  if (key.isEmpty || secret.isEmpty) return;
                  _connect(c, key, secret);
                },
        ),
        const SizedBox(height: PSpace.x8),
        Text(
          l.subBrokerKeyNotice(c.displayName),
          style: PTypo.micro.copyWith(color: t.fgTertiary, height: 1.5),
        ),
      ],
    );
  }

  TextStyle _fieldLabel(GrooTokens t) => TextStyle(
    fontFamily: PTypo.sans,
    fontSize: PFontSize.caption,
    fontWeight: PFontWeight.semi,
    color: t.fgSecondary,
  );
}

/// 입력칸 오른쪽 눈 아이콘 — 가린 값을 잠깐 보여 준다.
///
/// `p_date_input.dart` 의 `_PickerSuffix` 와 같은 패턴(GestureDetector + Icon)이다.
/// raw Material `IconButton` 을 쓰지 않는 이유도 같다 — P 위젯 밖에서 Material 위젯을
/// 직접 쓰면 디자인시스템 밖 시각이 섞인다.
class _RevealSuffix extends StatelessWidget {
  const _RevealSuffix({
    required this.revealed,
    required this.onTap,
    required this.semanticLabel,
  });

  final bool revealed;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: semanticLabel,
      // 웹 SecretField 와 같은 치수 — 버튼 32, 글리프 16, 오른쪽 끝에서 4.
      // (날짜·시각 피커는 웹에서도 28/14 로 더 작다.)
      child: PInputSuffixButton(
        size: 32,
        onTap: onTap,
        child: Icon(
          revealed ? LucideIcons.eyeOff : LucideIcons.eye,
          size: 16,
          color: t.fgSecondary,
        ),
      ),
    );
  }
}
