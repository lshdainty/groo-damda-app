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
import 'package:groo_damda_app/features/settings/presentation/reauth_form.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/widgets/p_busy_scrim.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

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
  ReauthMethod _method = ReauthMethod.password;
  DateTime? _codeSentAt;
  bool _submitting = false;
  String? _reauthError;

  WithdrawalCheck? _check;
  bool _loading = true;
  bool _retrying = false;
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

  /// [retry] — 실패 화면의 [다시 시도]. 받는 동안 실패를 그대로 두고 단추에 진행 원(skeleton.md:139).
  Future<void> _load({bool retry = false}) async {
    setState(() {
      if (retry) {
        _retrying = true;
      } else {
        _loading = true;
        _loadFailed = false;
      }
    });
    try {
      final repo = await ref.read(withdrawalRepositoryProvider.future);
      final res = await repo.check();
      if (!mounted) return;
      setState(() {
        _check = res;
        _loading = false;
        _loadFailed = false;
        _retrying = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
        _retrying = false;
      });
    }
  }

  bool get _blocked => _check?.isBlocked ?? false;

  /// 코드 방식은 6자리 전에도 [해지하기] 를 켜 두고 누르면 칸 오류로 알린다(input-otp.md).
  bool get _canSubmit {
    if (_submitting) return false;
    if (_step == 1) return true;
    return _method == ReauthMethod.password
        ? _passwordCtrl.text.isNotEmpty
        : true;
  }

  void _back() {
    setState(() {
      _step = 1;
      _reauthError = null;
    });
  }

  void _setMethod(ReauthMethod m) {
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
    if (_method == ReauthMethod.emailCode && _codeCtrl.text.length < 6) {
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
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      final repo = await repoFuture;
      String ticket;
      try {
        ticket = method == ReauthMethod.password
            ? await repo.verifyPassword(password)
            : await repo.verifyEmailCode(code);
      } on ApiException catch (e) {
        if (!mounted) return;
        // 본인 확인 실패는 그 칸의 문제다 — 칸 밑에 붙인다. 코드는 서버 글 대신 화면 글로.
        // 서버 글은 화면에 내지 않는다(Writing 오류). 틀림 · 지남(AUTH_021)만 그 칸의 글이고,
        // 네트워크 · 서버 오류는 해지 실패 글이다.
        setState(() {
          _reauthError = reauthErrorText(
            l,
            e,
            method,
            fallback: l.withdrawFailed,
          );
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
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        // 응답을 읽지 못했거나 받지 못했다 — 해지됐을 수 있다. 실패라 하지 않는다(디자인시스템 판단 6)
        _reauthError = isUnconfirmedSave(e)
            ? l.withdrawUnconfirmed
            : l.withdrawFailed;
        _submitting = false;
      });
    } finally {
      sheet?.setBusy(false);
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
        primaryAction: PResultAction(
          label: l.actionRetry,
          loading: _retrying,
          onPressed: () => _load(retry: true),
        ),
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
      body = _reauthBody();
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
    // 화면 글은 날짜 규칙("10월 31일") — 읽지 못할 때만 서버 값 그대로.
    final endDt = parseServerUtc(check.subscriptionPeriodEnd);
    final until = check.subscriptionPeriodEnd != null
        ? (endDt != null
              ? formatDay(endDt).md
              : check.subscriptionPeriodEnd!.substring(0, 10))
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
          child: PText(
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

  /// 본인 확인 칸 — 소셜 연동 확인 시트와 같은 부품이다(문구 · 간격 한 벌).
  Widget _reauthBody() => ReauthForm(
    method: _method,
    passwordController: _passwordCtrl,
    codeController: _codeCtrl,
    codeFocusNode: _codeFocus,
    error: _reauthError,
    codeSentAt: _codeSentAt,
    busy: _submitting,
    onMethodChanged: _setMethod,
    onSendCode: _sendCode,
    onEdited: () => setState(() => _reauthError = null),
  );
}
