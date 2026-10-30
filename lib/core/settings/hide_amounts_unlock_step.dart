import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 서버가 틀린 비밀번호에 주는 오류 코드 — 이것만 "일치하지 않아요" 로 말하고, 그 밖의 실패는 다시 시도를 부탁한다(서버 글을 내지 않는다).
const kWrongPasswordCode = 'USER_004';

/// 금액 보기 인증 단계(I-17 21 · I-14 6-A) — 시트 안의 한 단계다. 숨김을 푸는 저장에서 생체 인증이 안 될 때 **같은 시트**의
/// 머리 · 본문 · 바닥이 이것으로 바뀐다(위에 확인창을 따로 띄우지 않는다).
///
/// 머리 ←(= 취소)는 저장하지 않고 2단계로 돌아간다. 본문은 설명 + 비밀번호 칸(밑줄 · 자동 완성 password · 열리면 초점 · Enter 로
/// 제출). 틀리면 칸을 비우고 칸 아래 오류를 알린다(서버 글 0). 맞으면 [onVerified] — 부른 쪽이 저장을 이어 간다.
class HideAmountsUnlockStep extends ConsumerStatefulWidget {
  const HideAmountsUnlockStep({
    super.key,
    required this.onBack,
    required this.onVerified,
  });

  final VoidCallback onBack;
  final VoidCallback onVerified;

  @override
  ConsumerState<HideAmountsUnlockStep> createState() =>
      _HideAmountsUnlockStepState();
}

class _HideAmountsUnlockStepState extends ConsumerState<HideAmountsUnlockStep> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    // 본인 확인은 비밀번호 칸이 첫 칸이다. 시트가 이미 열려 있어(컨테이너가 초점을 쥐고 있어) 안쪽 autofocus 는 밀리므로 직접 준다
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pending) return;
    final l = AppLocalizations.of(context);
    // 비어 있어도 단추는 켜 둔다 — 누르면 칸 아래에 알린다(field.md)
    if (_ctrl.text.trim().isEmpty) {
      setState(() => _error = l.unlockPasswordRequired);
      _focus.requestFocus();
      return;
    }
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.verifyPassword(_ctrl.text);
      if (!mounted) return;
      setState(() => _pending = false);
      widget.onVerified();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.code == kWrongPasswordCode
            ? l.unlockMismatch
            : l.unlockVerifyFailed;
        _pending = false;
        _ctrl.clear();
      });
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return PBottomSheetContent(
      title: l.unlockTitle,
      closeLabel: l.actionClose,
      onBack: _pending ? null : widget.onBack,
      backLabel: l.actionBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x4,
        children: [
          Text(
            keepAll(l.unlockBody),
            style: PTypography.t5.copyWith(color: c.fgNeutralMuted),
          ),
          PField(
            label: l.unlockPasswordLabel,
            invalid: _error != null,
            errorMessage: _error,
            child: PInput(
              variant: PInputVariant.underline,
              controller: _ctrl,
              focusNode: _focus,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              readOnly: _pending,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
      footer: [
        PButton(
          label: l.unlockViewAmounts,
          size: PButtonSize.large,
          loading: _pending,
          onPressed: _submit,
        ),
      ],
    );
  }
}
