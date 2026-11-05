import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/settings/application/withdrawal_providers.dart';
import 'package:groo_damda_app/features/settings/domain/withdrawal_check.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/input_otp/p_input_otp.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/widgets/p_busy_scrim.dart';

/// 그루 담다 이용 해지 — web `WithdrawDialog` 미러.
///
/// **세 번 확인한다.** ① 무엇을 잃는지 개수로 보여 주고 ② 본인 확인을 다시 받고
/// ③ 마지막 버튼이 빨갛다. 되돌릴 수 없는 일이라 한 번의 오조작으로 끝나면 안 된다.
///
/// 표면은 ds Bottom Sheet(입력 폼) — 바깥 누르기 · 끌어내리기로 닫히지 않고, 위 ✕ · 뒤로 가기로 닫으며
/// 사유 · 비밀번호 · 코드가 바뀌어 있으면 "작성한 내용이 사라져요" 를 먼저 묻는다(I-05 31).
/// 바닥 버튼은 1단계 [계속], 2단계 [뒤로][해지하기]. 막힘 · 불러오기 실패는 ✕ 만(바닥 없음).
///
/// 문구는 웹과 한 벌이다 — 한쪽만 고치지 마라.
void showWithdrawalSheet(BuildContext context) {
  final l = AppLocalizations.of(context);
  final probe = _DirtyProbe();
  PBottomSheet.show<void>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => _WithdrawSheet(probe: probe),
  );
}

/// 시트가 바뀐 값을 가졌는지 — 입력칸의 주인은 시트 State 라, 닫을 때 그쪽에 묻는다.
class _DirtyProbe {
  bool Function() dirty = () => false;
}

/// 서버 `REAUTH_FAILED`(AUTH_021) — 비밀번호 · 코드가 틀렸거나 지났다.
const _kReauthFailed = 'AUTH_021';

/// 서버 `REAUTH_LOCKED`(AUTH_022, 429) — 5번 틀려 잠겼다. 코드를 다시 받아야 풀린다.
const _kReauthLocked = 'AUTH_022';

/// 본인 확인 방법. 비밀번호가 없는 소셜 전용 계정은 코드 말고 길이 없다.
enum _Method { password, emailCode }

class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet({required this.probe});
  final _DirtyProbe probe;

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  final _reasonCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();

  /// 1 = 무엇을 잃는지, 2 = 본인 확인.
  int _step = 1;
  _Method _method = _Method.password;
  DateTime? _codeSentAt;
  bool _submitting = false;
  String? _reauthError;

  WithdrawalCheck? _check;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    widget.probe.dirty = () =>
        _reasonCtrl.text.isNotEmpty ||
        _passwordCtrl.text.isNotEmpty ||
        _codeCtrl.text.isNotEmpty;
    _load();
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    _reasonCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final repo = await ref.read(withdrawalRepositoryProvider.future);
      final res = await repo.check();
      if (!mounted) return;
      setState(() {
        _check = res;
        _loading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  bool get _blocked => _check?.isBlocked ?? false;

  /// 코드 방식은 6자리 전에도 [해지하기] 를 켜 두고 누르면 칸 오류로 알린다(input-otp.md).
  bool get _canSubmit {
    if (_submitting) return false;
    if (_step == 1) return true;
    return _method == _Method.password ? _passwordCtrl.text.isNotEmpty : true;
  }

  void _back() {
    setState(() {
      _step = 1;
      _reauthError = null;
    });
  }

  void _setMethod(_Method m) {
    setState(() {
      _method = m;
      _reauthError = null;
    });
  }

  Future<void> _onPrimary() async {
    if (_step == 1) {
      setState(() => _step = 2);
      return;
    }
    if (_method == _Method.emailCode && _codeCtrl.text.length < 6) {
      setState(
        () =>
            _reauthError = AppLocalizations.of(context).withdrawCodeIncomplete,
      );
      _codeFocus.requestFocus();
      return;
    }
    await _withdraw();
  }

  Future<void> _withdraw() async {
    final l = AppLocalizations.of(context);
    // **기다리기 전에** 뒷정리에 필요한 것을 손에 쥔다.
    //
    // 제출 중에 시트를 내리면(뒤로가기) 이 State 가 사라진다. 그런데 해지는
    // 서버에서 이미 진행 중이라 그대로 끝난다 — 예전엔 거기서 `mounted` 검사에 걸려
    // **로그아웃도 안내도 없이** 이미 없는 계정으로 앱이 계속 돌았다(2026-09-17 QA).
    //
    // navigator 의 context 는 시트보다 위에 있어 시트가 사라져도 살아 있다. 라우터도
    // 같은 이유로 미리 쥔다 — 해지가 끝나면 완료 화면으로 보낸다.
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final auth = ref.read(authProvider.notifier);
    final repoFuture = ref.read(withdrawalRepositoryProvider.future);
    final method = _method;
    final reason = _reasonCtrl.text.trim();
    final password = _passwordCtrl.text;
    final code = _codeCtrl.text;

    setState(() {
      _submitting = true;
      _reauthError = null;
    });
    // 화면 전체 딤 + 흰 원 40 — 시트까지 덮는다. 시트를 내려도 해지는 끝까지 가고,
    // 덮개는 완료 화면으로 간 뒤에 걷는다(I-05 37).
    final scrim = PBusyScrim.show(context, label: l.withdrawBusy);
    try {
      final repo = await repoFuture;
      String ticket;
      try {
        ticket = method == _Method.password
            ? await repo.verifyPassword(password)
            : await repo.verifyEmailCode(code);
      } on ApiException catch (e) {
        if (!mounted) return;
        // 본인 확인 실패는 그 칸의 문제다 — 칸 밑에 붙인다. 코드는 서버 글 대신 화면 글로.
        // 서버 글은 화면에 내지 않는다(Writing 오류). 틀림 · 지남(AUTH_021)만 그 칸의 글이고,
        // 네트워크 · 서버 오류는 해지 실패 글이다.
        setState(() {
          _reauthError = e.code == _kReauthLocked
              ? l.withdrawLocked
              : e.code == _kReauthFailed
              ? (method == _Method.emailCode
                    ? l.withdrawCodeWrong
                    : l.withdrawPasswordWrong)
              : l.withdrawFailed;
          _submitting = false;
        });
        return;
      }
      await repo.withdraw(reauthToken: ticket, reason: reason);

      // 여기서부터는 이 State 의 `mounted` 를 보지 않는다 — 해지는 이미 끝났고,
      // 시트가 사라졌다고 로그아웃을 건너뛰면 안 된다.
      if (navigator.mounted) navigator.pop();
      // 해지 완료 화면(웹 /withdrawn 과 같은 화면)으로 보낸 **뒤** 로그아웃한다. 먼저
      // 로그아웃하면 라우터가 로그인 화면으로 보내 한 번 번쩍인다. 완료 화면은 로그아웃
      // 상태에서도 열려 있는 화면이라 로그아웃이 끝나도 그대로 남는다.
      router.go('/withdrawn');
      // 화면이 통째로 사라졌어도 로그아웃은 한다 — 이게 빠지면 이미 없는 계정으로
      // 앱이 계속 돈다.
      auth.logout();
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _reauthError = l.withdrawFailed;
        _submitting = false;
      });
    } finally {
      scrim.hide();
    }
  }

  Future<void> _sendCode() async {
    final l = AppLocalizations.of(context);
    try {
      final repo = await ref.read(withdrawalRepositoryProvider.future);
      await repo.sendEmailCode();
      if (!mounted) return;
      setState(() {
        _codeSentAt = DateTime.now();
        _reauthError = null;
      });
      // 시트가 열린 채라 스낵바가 아니라 코드 칸 아래 안내 글이 말한다(아래 _codeSentAt 블록).
    } on ApiException {
      if (!mounted) return;
      setState(() => _reauthError = l.withdrawFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loadingOrFailed = _loading || _loadFailed;
    final blocked = !loadingOrFailed && _blocked;

    final String? description = loadingOrFailed || blocked
        ? null
        : (_step == 1 ? l.withdrawIntro : l.withdrawReauthIntro);

    final Widget body;
    List<PButton> footer = const [];
    var flush = false;
    if (_loading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: PSpacing.x8),
        child: Center(child: PProgressCircle()),
      );
    } else if (_loadFailed) {
      body = PResultSection(
        kind: PResultKind.failure,
        size: PResultSize.medium,
        title: l.withdrawLoadFailedTitle,
        description: l.withdrawLoadFailedDescription,
        primaryAction: PResultAction(label: l.actionRetry, onPressed: _load),
      );
    } else if (blocked) {
      body = _blockedBody(l);
    } else if (_step == 1) {
      flush = true;
      body = _impactBody(l);
      footer = [
        PButton(
          label: l.withdrawNext,
          variant: PButtonVariant.criticalSolid,
          size: PButtonSize.large,
          onPressed: _onPrimary,
        ),
      ];
    } else {
      body = _reauthBody(l);
      footer = [
        PButton(
          label: l.actionBack,
          variant: PButtonVariant.neutralWeak,
          size: PButtonSize.large,
          onPressed: _submitting ? null : _back,
        ),
        PButton(
          label: l.withdrawConfirm,
          variant: PButtonVariant.criticalSolid,
          size: PButtonSize.large,
          loading: _submitting,
          onPressed: _canSubmit ? _onPrimary : null,
        ),
      ];
    }

    return PBottomSheetContent(
      title: l.accountWithdrawTitle,
      description: description,
      closeLabel: l.actionClose,
      flushBody: flush,
      scrollFog: false,
      body: body,
      footer: footer,
    );
  }

  Widget _blockedBody(AppLocalizations l) {
    final check = _check!;
    // 서버가 시간대 없이 주는 `[UTC]` — 그냥 자르면 KST 에서 하루 이르게 보인다.
    // 구독 시트와 같은 값이라 같은 방식으로 읽어야 두 화면이 다른 날짜를 말하지 않는다.
    final until = check.subscriptionPeriodEnd != null
        ? (localDateKey(check.subscriptionPeriodEnd) ??
              check.subscriptionPeriodEnd!.substring(0, 10))
        : null;
    final headline = check.blockedBySubscription
        ? (until != null
              ? l.withdrawBlockedSubscriptionUntil(until)
              : l.withdrawBlockedSubscription)
        : l.withdrawBlockedOther;
    return PCallout(
      tone: PCalloutTone.warning,
      title: headline,
      description: l.withdrawBlockedHint,
    );
  }

  Widget _impactBody(AppLocalizations l) {
    final c = _check!;
    final c2 = context.colors;
    // 0 인 항목은 줄을 안 만든다 — 없는 손실을 세어 겁줄 이유가 없다.
    final impacts = <String>[
      if (c.sharedCalendarsOwned > 0)
        l.withdrawImpactCalendarsOwned(c.sharedCalendarsOwned),
      if (c.calendarMemberships > 0)
        l.withdrawImpactCalendarMemberships(c.calendarMemberships),
      if (c.dutchPaysOwned > 0)
        l.withdrawImpactDutchPaysOwned(c.dutchPaysOwned),
      if (c.dutchPayParticipations > 0)
        l.withdrawImpactDutchPayParticipations(c.dutchPayParticipations),
    ];
    const gutter = EdgeInsets.symmetric(horizontal: PSpacing.globalGutter);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 잃는 것 — 누르지 않는 List 줄(설명 · 앞 없음)
        if (impacts.isNotEmpty) ...[
          PList(
            semanticLabel: l.withdrawIrreversibleTitle,
            children: [for (final line in impacts) PListItem(title: line)],
          ),
          const SizedBox(height: PSpacing.x4),
        ],
        // 되돌릴 수 없는 것 둘 — 여기서 말하지 않으면 사용자가 알 길이 없다.
        Padding(
          padding: gutter,
          child: PCallout(
            tone: PCalloutTone.warning,
            title: l.withdrawIrreversibleTitle,
            description:
                '${l.withdrawIrreversibleRejoin}\n${l.withdrawIrreversibleData}',
          ),
        ),
        const SizedBox(height: PSpacing.x4),
        // 데이터가 어떻게 되는지 — "사라진다" 가 아니라 보관 뒤 파기다. 내보내기
        // 권유는 해지 전에만 할 수 있는 말이라 여기 둔다(설계서 결정 12). R9 칸 설명.
        Padding(
          padding: gutter,
          child: Text(
            l.withdrawDataRetention,
            style: PTypography.t4.copyWith(color: c2.fgNeutralSubtle),
          ),
        ),
        const SizedBox(height: PSpacing.x4),
        Padding(
          padding: gutter,
          child: PField(
            label: l.withdrawReasonLabel,
            indicator: PFieldIndicator.optional,
            child: PInput(
              controller: _reasonCtrl,
              placeholder: l.withdrawReasonPlaceholder,
              inputFormatters: [LengthLimitingTextInputFormatter(200)],
            ),
          ),
        ),
        const SizedBox(height: PSpacing.x4),
      ],
    );
  }

  Widget _reauthBody(AppLocalizations l) {
    final password = _method == _Method.password;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (password) ...[
          PField(
            label: l.passwordCurrent,
            invalid: _reauthError != null,
            errorMessage: _reauthError,
            child: PInput(
              controller: _passwordCtrl,
              obscureText: true,
              placeholder: l.withdrawPasswordPlaceholder,
              autofillHints: const [AutofillHints.password],
              onChanged: (_) => setState(() => _reauthError = null),
            ),
          ),
          const SizedBox(height: PSpacing.x4),
          _linkButton(
            l.withdrawUseEmailCode,
            () => _setMethod(_Method.emailCode),
          ),
        ] else ...[
          PField(
            label: l.withdrawCodeLabel,
            description: l.withdrawCodeDescription,
            invalid: _reauthError != null,
            errorMessage: _reauthError,
            child: PInputOtp(
              controller: _codeCtrl,
              focusNode: _codeFocus,
              placeholder: l.withdrawCodePlaceholder,
              // 고치기 시작하면 설명 줄로 돌아온다
              onChanged: (_) => setState(() => _reauthError = null),
            ),
          ),
          const SizedBox(height: PSpacing.x3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PInputOtpResend(
              sentAt: _codeSentAt,
              codeFocusNode: _codeFocus,
              firstLabel: l.withdrawSendCode,
              readyLabel: l.withdrawResendCode,
              cooldownLabel: l.withdrawResendCooldown,
              onResend: _sendCode,
              disabled: _submitting,
            ),
          ),
          // 스팸함 안내 — 사용자 결정(10-24) 05-2 Q1 A: 남긴다. 코드를 **보낸 뒤에만** 보인다(보내기 전엔 찾을 메일이 없다).
          // [코드 받기] 아래 12 · t4 fg-neutral-subtle, 오류 때도 남는다.
          if (_codeSentAt != null) ...[
            const SizedBox(height: PSpacing.x3),
            Text(
              '${l.withdrawCodeSent} ${l.withdrawCodeHint}',
              style: PTypography.t4.copyWith(
                color: context.colors.fgNeutralSubtle,
              ),
            ),
          ],
          // [비밀번호로 확인하기] 위 16(웹 gap-x4 와 같은 값 — migration/i05-2-q 그림)
          const SizedBox(height: PSpacing.x4),
          _linkButton(
            l.withdrawUsePassword,
            () => _setMethod(_Method.password),
          ),
        ],
      ],
    );
  }

  /// 칸 아래 줄 끝의 글 버튼(R16, ghost small).
  Widget _linkButton(String label, VoidCallback onPressed) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: PButton(
      label: label,
      variant: PButtonVariant.ghost,
      size: PButtonSize.small,
      onPressed: _submitting ? null : onPressed,
    ),
  );
}
