import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/settings/application/oauth_link_providers.dart';
import 'package:groo_damda_app/features/settings/application/reauth_providers.dart';
import 'package:groo_damda_app/features/settings/data/reauth_repository.dart';
import 'package:groo_damda_app/features/settings/presentation/reauth_form.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

/// 소셜 계정 연결 전 본인 확인 — 보안 점검 S-2.
///
/// 로그인 쿠키만 훔친 사람이 자기 소셜 계정을 붙이면 계정을 영구히 가져간다. 그래서 연결을
/// 시작하기 전에 비밀번호(소셜 전용 계정은 메일 코드)를 다시 받고, 그 티켓을 실어 연결을 시작한다.
///
/// **시트가 확인과 연결 시작을 둘 다 한다** — 티켓은 10분 · 단회라 들고 다니지 않는다. 연결 시작까지
/// 되면 브라우저로 열 주소(`startUrl`)를 돌려주며 닫히고, 닫기만 하면 null 이다. 연결 시작이
/// 실패하면 시트가 그대로 남아 오류를 말하고, 다시 누르면 본인 확인부터 다시 한다.
///
/// 모양은 이용 해지 시트의 본인 확인 단계 그대로다([ReauthForm]) — ds Bottom Sheet 입력 폼이라 바깥
/// 누르기 · 끌어내리기로 닫히지 않고, 칸에 값이 있으면 ✕ · 뒤로 가기가 "작성한 내용이 사라져요" 를 먼저 묻는다.
Future<String?> showOAuthLinkReauthSheet(
  BuildContext context, {
  required String provider,
  required String providerName,
  required String returnUrl,
}) {
  final l = AppLocalizations.of(context);
  final probe = _DirtyProbe();
  return PBottomSheet.show<String>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => _LinkReauthSheet(
      probe: probe,
      provider: provider,
      providerName: providerName,
      returnUrl: returnUrl,
    ),
  );
}

/// 시트가 바뀐 값을 가졌는지 — 입력칸의 주인은 시트 State 라, 닫을 때 그쪽에 묻는다.
class _DirtyProbe {
  bool Function() dirty = () => false;
}

class _LinkReauthSheet extends ConsumerStatefulWidget {
  const _LinkReauthSheet({
    required this.probe,
    required this.provider,
    required this.providerName,
    required this.returnUrl,
  });
  final _DirtyProbe probe;

  /// 서버 경로의 소문자 provider — "google".
  final String provider;

  /// 화면 글에 끼우는 이름 — "Google".
  final String providerName;
  final String returnUrl;

  @override
  ConsumerState<_LinkReauthSheet> createState() => _LinkReauthSheetState();
}

class _LinkReauthSheetState extends ConsumerState<_LinkReauthSheet> {
  final _passwordCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();

  ReauthMethod _method = ReauthMethod.password;
  DateTime? _codeSentAt;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.probe.dirty = () =>
        _passwordCtrl.text.isNotEmpty || _codeCtrl.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  /// 코드 방식은 6자리 전에도 [확인] 을 켜 두고 누르면 칸 오류로 알린다(input-otp.md) — 해지와 같다.
  bool get _canSubmit {
    if (_submitting) return false;
    return _method == ReauthMethod.password
        ? _passwordCtrl.text.isNotEmpty
        : true;
  }

  void _setMethod(ReauthMethod m) {
    setState(() {
      _method = m;
      _error = null;
    });
  }

  Future<void> _sendCode() async {
    final l = AppLocalizations.of(context);
    try {
      final repo = await ref.read(reauthRepositoryProvider.future);
      await repo.sendEmailCode();
      if (!mounted) return;
      setState(() {
        _codeSentAt = DateTime.now();
        _error = null;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _error = l.linkReauthFailed);
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (_method == ReauthMethod.emailCode && _codeCtrl.text.length < 6) {
      setState(() => _error = l.withdrawCodeIncomplete);
      _codeFocus.requestFocus();
      return;
    }
    // 기다리기 전에 손에 쥔다 — 시트를 닫는 길(컨트롤러)은 caller 의 context 가 아니라 이 시트의 것이다.
    final sheet = PBottomSheet.maybeOf(context);
    final reauthFuture = ref.read(reauthRepositoryProvider.future);
    final linkFuture = ref.read(oauthLinkRepositoryProvider.future);
    final method = _method;
    final password = _passwordCtrl.text;
    final code = _codeCtrl.text;

    setState(() {
      _submitting = true;
      _error = null;
    });
    // 확인 · 연결 시작 동안은 닫히지 않는다 — 실패 글을 그릴 시트가 남아 있어야 한다.
    sheet?.setBusy(true);
    var busy = true;
    try {
      final reauth = await reauthFuture;
      // 매번 새 티켓을 받는다 — 단회라 앞서 실패한 연결 시작의 티켓은 다시 못 쓴다.
      final String ticket;
      try {
        ticket = method == ReauthMethod.password
            ? await reauth.verifyPassword(
                password,
                purpose: ReauthPurpose.oauthLink,
              )
            : await reauth.verifyEmailCode(
                code,
                purpose: ReauthPurpose.oauthLink,
              );
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() {
          _error = reauthErrorText(l, e, method, fallback: l.linkReauthFailed);
          _submitting = false;
        });
        return;
      }
      final String startUrl;
      try {
        final repo = await linkFuture;
        startUrl = await repo.startLink(
          widget.provider,
          widget.returnUrl,
          reauthToken: ticket,
        );
      } on ApiException {
        // 티켓 거절(400) · 네트워크 — 티켓은 이미 썼다. 다시 누르면 본인 확인부터 다시 한다.
        if (!mounted) return;
        setState(() {
          _error = l.linkReauthFailed;
          _submitting = false;
        });
        return;
      }
      sheet?.setBusy(false);
      busy = false;
      sheet?.close(startUrl);
    } finally {
      if (busy) sheet?.setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PBottomSheetContent(
      title: l.linkReauthTitle,
      description: l.linkReauthIntro(widget.providerName),
      closeLabel: l.actionClose,
      scrollFog: false,
      body: ReauthForm(
        method: _method,
        passwordController: _passwordCtrl,
        codeController: _codeCtrl,
        codeFocusNode: _codeFocus,
        error: _error,
        codeSentAt: _codeSentAt,
        busy: _submitting,
        onMethodChanged: _setMethod,
        onSendCode: _sendCode,
        onEdited: () => setState(() => _error = null),
      ),
      footer: [
        PButton(
          label: l.actionConfirm,
          variant: PButtonVariant.neutralSolid,
          size: PButtonSize.large,
          loading: _submitting,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}
