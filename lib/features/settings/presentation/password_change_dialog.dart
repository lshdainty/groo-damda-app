import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/password_rules.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';

/// desk-back `DeskErrorCode.USER_PASSWORD_CHANGE_FAILED` — 이 폼에서는 현재 비밀번호 불일치 하나다.
/// 판정은 문구가 아니라 코드로 한다(문구는 그루 계정 배포 · 언어마다 바뀐다). 웹 `password-change-error.ts` 와 같다.
const kPasswordChangeFailedCode = 'USER_003';

/// 비밀번호 바꾸기 — ds Bottom Sheet 입력 폼(I-14 14 ~ 16). 위 닫기 원 + 바닥 [저장] 하나.
///
/// 바깥 누름 · 끌어내림으로 닫히지 않고, 값이 있는 채 닫으면 "작성한 내용이 사라져요" 를 묻는다.
/// PATCH /users/me/password (currentPassword, newPassword, confirmPassword).
Future<void> showPasswordChangeDialog(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final probe = _DirtyProbe();
  await PBottomSheet.show<void>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => _PasswordForm(probe: probe),
  );
}

class _DirtyProbe {
  bool Function() dirty = () => false;
}

class _PasswordForm extends ConsumerStatefulWidget {
  const _PasswordForm({required this.probe});
  final _DirtyProbe probe;

  @override
  ConsumerState<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends ConsumerState<_PasswordForm> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _currentFocus = FocusNode();
  bool _submitting = false;

  /// 현재 비밀번호가 맞지 않다고 서버가 답했다 — 그 칸의 오류. 칸을 고치면 사라진다.
  bool _currentInvalid = false;

  /// 그 밖 실패 — 본문 맨 위 Callout. 값은 남는다.
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    widget.probe.dirty = () =>
        _currentCtrl.text.isNotEmpty ||
        _newCtrl.text.isNotEmpty ||
        _confirmCtrl.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _currentFocus.dispose();
    super.dispose();
  }

  /// [저장] 은 네 조건(현재 칸 값 · 조건 충족 · 확인 일치 · 현재와 다름)이 맞을 때만 누를 수 있다.
  bool get _canSubmit {
    if (_submitting) return false;
    final c = _currentCtrl.text;
    final n = _newCtrl.text;
    final f = _confirmCtrl.text;
    // 정책은 kPasswordRules 단일 소스 — 아래 체크리스트가 보여주는 것과 동일
    return c.isNotEmpty && isPasswordValid(n) && n == f && n != c;
  }

  /// 현재 비밀번호와 동일한지 — 서버(그루 계정)도 거부하므로 제출 전에 알린다
  bool get _sameAsCurrent =>
      _currentCtrl.text.isNotEmpty && _newCtrl.text == _currentCtrl.text;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _failed = false;
      _currentInvalid = false;
    });
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
        confirmPassword: _confirmCtrl.text,
      );
      if (!mounted) return;
      PBottomSheet.of(context).close();
      // 시트가 닫힌 뒤 알린다 — 서버가 받았다(성공)
      showGlobalSnack(
        (l) => l.passwordChanged,
        severity: PSnackSeverity.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        // 서버 글은 어디에도 내지 않는다 — 코드로만 가른다
        if (e is ApiException && e.code == kPasswordChangeFailedCode) {
          _currentInvalid = true;
        } else {
          _failed = true;
        }
      });
      // 칸이 다시 켜진 뒤(오류를 반영한 프레임 다음)에 초점 — 제출 중에는 칸이 막혀 초점을 받지 못한다
      if (_currentInvalid) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _currentFocus.requestFocus();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const gutter = EdgeInsets.symmetric(horizontal: PSpacing.globalGutter);
    final newText = _newCtrl.text;
    final confirmText = _confirmCtrl.text;
    final matched = confirmText.isNotEmpty && newText == confirmText;
    final mismatched = confirmText.isNotEmpty && newText != confirmText;

    return PBottomSheetContent(
      title: l.navChangePassword,
      description: l.passwordChangeDescription,
      closeLabel: l.actionClose,
      flushBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failed)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                0,
                PSpacing.globalGutter,
                PSpacing.x5,
              ),
              child: PCallout(
                tone: PCalloutTone.critical,
                alert: true,
                description: l.passwordChangeFailed,
              ),
            ),
          // 필수 표시 · 자리 글(placeholder)은 없다 — 세 칸 모두 필수라 표시하지 않고, 조건은 아래 줄이 말한다
          Padding(
            padding: gutter,
            child: PField(
              label: l.passwordCurrent,
              invalid: _currentInvalid,
              errorMessage: l.passwordCurrentInvalid,
              child: PInput(
                controller: _currentCtrl,
                focusNode: _currentFocus,
                obscureText: true,
                disabled: _submitting,
                autofillHints: const [AutofillHints.password],
                onChanged: (_) => setState(() => _currentInvalid = false),
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x5),
          Padding(
            padding: gutter,
            child: PField(
              label: l.passwordNew,
              invalid: _sameAsCurrent,
              errorMessage: l.passwordSameAsCurrent,
              child: PInput(
                controller: _newCtrl,
                obscureText: true,
                disabled: _submitting,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          // 입력 중 실시간 규칙 표시 — 값이 있을 때만
          if (newText.isNotEmpty)
            Padding(
              padding: gutter.copyWith(top: PSpacing.x2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: PSpacing.x1,
                children: [
                  for (final rule in kPasswordRules)
                    _RuleRow(ok: rule.test(newText), label: rule.label(l)),
                ],
              ),
            ),
          const SizedBox(height: PSpacing.x5),
          Padding(
            padding: gutter,
            child: PField(
              label: l.passwordNewConfirm,
              // 불일치는 Field 오류, 일치는 설명 자리의 체크
              invalid: mismatched,
              errorMessage: l.passwordMismatch,
              child: PInput(
                controller: _confirmCtrl,
                obscureText: true,
                disabled: _submitting,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          if (matched)
            Padding(
              padding: gutter.copyWith(top: PSpacing.x2),
              child: _RuleRow(ok: true, label: l.passwordMatched),
            ),
        ],
      ),
      footer: [
        PButton(
          label: l.passwordChangeAction,
          size: PButtonSize.large,
          loading: _submitting,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

/// 규칙 한 줄 — 충족 `check`(fg-positive) · 미달 `x`(fg-neutral-subtle). 아이콘 16 + t4.
class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.ok, required this.label});

  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = ok ? c.fgPositive : c.fgNeutralSubtle;
    return Row(
      spacing: PSpacing.x1_5,
      children: [
        ExcludeSemantics(
          child: Icon(
            ok ? LucideIcons.check : LucideIcons.x,
            size: 16,
            color: color,
          ),
        ),
        Flexible(
          child: Text(label, style: PTypography.t4.copyWith(color: color)),
        ),
      ],
    );
  }
}
