import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/input_otp/p_input_otp.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';

/// 본인 확인 방법. 비밀번호가 없는 소셜 전용 계정은 코드 말고 길이 없다.
enum ReauthMethod { password, emailCode }

/// 서버 `REAUTH_FAILED`(AUTH_021) — 비밀번호 · 코드가 틀렸거나 지났다.
const kReauthFailedCode = 'AUTH_021';

/// 서버 `REAUTH_LOCKED`(AUTH_022, 429) — 5번 틀려 잠겼다. 코드를 다시 받아야 풀린다.
const kReauthLockedCode = 'AUTH_022';

/// 본인 확인 실패를 칸 아래 글로 — 해지 · 소셜 연동이 같은 갈래를 쓴다.
///
/// 서버 글은 화면에 내지 않는다(Writing 오류). 틀림 · 지남(AUTH_021) · 잠김(AUTH_022)만 그 칸의
/// 글이고, 네트워크 · 서버 오류는 부르는 쪽의 실패 글([fallback])이다.
String reauthErrorText(
  AppLocalizations l,
  ApiException e,
  ReauthMethod method, {
  required String fallback,
}) => e.code == kReauthLockedCode
    ? l.withdrawLocked
    : e.code == kReauthFailedCode
    ? (method == ReauthMethod.emailCode
          ? l.withdrawCodeWrong
          : l.withdrawPasswordWrong)
    : fallback;

/// 본인 확인 칸 — 비밀번호 한 칸, 또는 메일 코드 칸 + [코드 받기].
///
/// 해지 시트 2단계와 소셜 연동 확인 시트가 같이 그린다(문구 · 간격 · 전환 링크 한 벌). 값과 상태의
/// 주인은 부르는 시트다 — 이 위젯은 그리기만 한다.
class ReauthForm extends StatelessWidget {
  const ReauthForm({
    super.key,
    required this.method,
    required this.passwordController,
    required this.codeController,
    required this.codeFocusNode,
    required this.error,
    required this.codeSentAt,
    required this.busy,
    required this.onMethodChanged,
    required this.onSendCode,
    required this.onEdited,
  });

  final ReauthMethod method;
  final TextEditingController passwordController;
  final TextEditingController codeController;
  final FocusNode codeFocusNode;

  /// 칸 아래 오류 글 — 없으면 설명 줄.
  final String? error;

  /// 코드를 보낸 때 — 다시 받기 60초 · 스팸함 안내가 여기서 갈린다.
  final DateTime? codeSentAt;

  /// 확인 중 — 전환 링크 · 다시 받기를 막는다.
  final bool busy;
  final ValueChanged<ReauthMethod> onMethodChanged;
  final Future<void> Function() onSendCode;

  /// 칸 값이 바뀌었다 — 부르는 쪽이 오류 글을 걷고 바닥 버튼을 다시 살핀다.
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final password = method == ReauthMethod.password;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (password) ...[
          PField(
            label: l.passwordCurrent,
            invalid: error != null,
            errorMessage: error,
            child: PInput(
              controller: passwordController,
              obscureText: true,
              placeholder: l.withdrawPasswordPlaceholder,
              autofillHints: const [AutofillHints.password],
              onChanged: (_) => onEdited(),
            ),
          ),
          const SizedBox(height: PSpacing.x4),
          _linkButton(
            l.withdrawUseEmailCode,
            () => onMethodChanged(ReauthMethod.emailCode),
          ),
        ] else ...[
          PField(
            label: l.withdrawCodeLabel,
            description: l.withdrawCodeDescription,
            invalid: error != null,
            errorMessage: error,
            child: PInputOtp(
              controller: codeController,
              focusNode: codeFocusNode,
              placeholder: l.withdrawCodePlaceholder,
              // 고치기 시작하면 설명 줄로 돌아온다
              onChanged: (_) => onEdited(),
            ),
          ),
          const SizedBox(height: PSpacing.x3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PInputOtpResend(
              sentAt: codeSentAt,
              codeFocusNode: codeFocusNode,
              firstLabel: l.withdrawSendCode,
              readyLabel: l.withdrawResendCode,
              cooldownLabel: l.withdrawResendCooldown,
              onResend: onSendCode,
              disabled: busy,
            ),
          ),
          // 스팸함 안내 — 사용자 결정(10-24) 05-2 Q1 A: 남긴다. 코드를 **보낸 뒤에만** 보인다(보내기 전엔 찾을 메일이 없다).
          // [코드 받기] 아래 12 · t4 fg-neutral-subtle, 오류 때도 남는다.
          if (codeSentAt != null) ...[
            const SizedBox(height: PSpacing.x3),
            PText(
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
            () => onMethodChanged(ReauthMethod.password),
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
      onPressed: busy ? null : onPressed,
    ),
  );
}
