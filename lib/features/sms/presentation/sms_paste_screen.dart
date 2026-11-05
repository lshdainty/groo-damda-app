import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/sms/data/sms_repository.dart';
import 'package:groo_damda_app/features/sms/domain/sms_draft.dart';
import 'package:groo_damda_app/features/sms/domain/sms_prefilter.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

/// 결제 문자를 붙여넣어 지출로 기록하는 화면. 흰 화면 하나, 버튼은 흐름 안(I-12 7-A).
///
/// iOS 는 문자에 직접 접근할 수 없고(OS 제약) 안드로이드도 권한을 받기 전이라,
/// 두 플랫폼이 공통으로 쓰는 경로는 "복사해서 붙여넣기" 다. 클립보드 배너나
/// 수신 알림에서 들어오는 자동 경로도 결국 이 화면의 해석·확인 흐름을 탄다.
///
/// [initialText] 가 있으면 열자마자 그 문자를 해석한다(배너·알림에서 들어온 경우).
/// [inboxId] 는 안드로이드 수신 보관함에서 온 경우의 항목 id — 저장에 성공하면
/// 그 목록에서 빠진다.
class SmsPasteScreen extends ConsumerStatefulWidget {
  const SmsPasteScreen({super.key, this.initialText, this.inboxId});

  final String? initialText;
  final int? inboxId;

  @override
  ConsumerState<SmsPasteScreen> createState() => _SmsPasteScreenState();
}

/// 직전 해석이 알려 주는 것 — 인식 실패는 칸의 오류, 취소 문자는 오류가 아닌 안내다.
enum _Notice { notRecognized, cancel }

class _SmsPasteScreenState extends ConsumerState<SmsPasteScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  bool _parsing = false;

  /// 직전 해석에서 알아낸 것 — 인식 실패·취소 문자.
  _Notice? _notice;

  /// 서버 해석이 실패했다 — 서버 글은 내지 않고 폼 맨 위 Callout 하나로 알린다. 다시 [문자 읽기]를 누르면 걷힌다.
  bool _serverFailed = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialText;
    if (seed != null && seed.trim().isNotEmpty) {
      _textCtrl.text = seed;
      // 해석은 첫 프레임 뒤에 — build 중에 시트를 띄울 수 없다.
      WidgetsBinding.instance.addPostFrameCallback((_) => _parse());
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  /// 클립보드에서 가져오기 — 사용자가 버튼을 눌렀을 때만 읽는다.
  ///
  /// iOS 는 클립보드를 읽을 때마다 "붙여넣기 허용" 배너를 띄운다. 화면에 들어올
  /// 때마다 자동으로 읽으면 그 배너가 계속 떠 사용자를 괴롭힌다.
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    if (text == null || text.trim().isEmpty) {
      PSnackbar.maybeOf(
        context,
      )?.show(message: l.smsClipboardEmpty, tone: PSnackbarTone.critical);
      return;
    }
    setState(() {
      _textCtrl.text = text;
      _notice = null;
      _serverFailed = false;
    });
  }

  Future<void> _parse() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _parsing) return;
    final l = AppLocalizations.of(context);

    // 서버로 보내기 전 로컬 게이트 — 결제 문자가 아닌 텍스트는 아예 올리지 않는다.
    if (!looksLikePaymentSms(text)) {
      setState(() => _notice = _Notice.notRecognized);
      return;
    }

    setState(() {
      _parsing = true;
      _notice = null;
      _serverFailed = false;
    });
    try {
      final repo = await ref.read(smsRepositoryProvider.future);
      final parsed = await repo.parse(text);
      if (!mounted) return;

      if (!parsed.matched) {
        setState(() => _notice = _Notice.notRecognized);
        return;
      }
      // 취소 문자는 원 거래를 특정할 수 없어 자동 기록하지 않는다.
      // 그냥 지출로 넣으면 결제와 취소가 둘 다 지출로 쌓여 두 배가 된다.
      if (parsed.cancel) {
        setState(() => _notice = _Notice.cancel);
        return;
      }

      if (parsed.isLowConfidence) {
        PSnackbar.maybeOf(
          context,
        )?.show(message: l.smsLowConfidence, tone: PSnackbarTone.critical);
      }
      showAddTxSheet(
        context,
        smsDraft: SmsDraft(text: text, parsed: parsed, inboxId: widget.inboxId),
      );
    } on ApiException {
      // 서버 글(e.message)은 화면에 내지 않는다
      if (!mounted) return;
      setState(() => _serverFailed = true);
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final notRecognized = _notice == _Notice.notRecognized;

    return Scaffold(
      // 흰 화면 하나 — 띠 · 회색 바닥이 없다(7-A)
      backgroundColor: c.bgLayerDefault,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.smsPasteTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          key: const ValueKey('sms-paste-body'),
          padding: const EdgeInsets.only(bottom: PSpacing.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 설명 — 위 16 · 좌우 24 · 아래 8
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PSpacing.globalGutter,
                  PSpacing.x4,
                  PSpacing.globalGutter,
                  PSpacing.x2,
                ),
                child: Text(
                  keepAll(l.smsPasteDesc),
                  semanticsLabel: l.smsPasteDesc,
                  style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
                ),
              ),
              // 서버 해석 실패 — 폼 맨 위 Callout critical(설명 아래 · 칸 위)
              if (_serverFailed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PSpacing.globalGutter,
                    PSpacing.x2,
                    PSpacing.globalGutter,
                    0,
                  ),
                  child: PCallout(
                    key: const ValueKey('sms-paste-server-failed'),
                    tone: PCalloutTone.critical,
                    description: l.smsParseFailed,
                    alert: true,
                  ),
                ),
              // 칸 — 위 8(설명 아래). 인식 실패는 칸의 오류(테두리 + 글)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PSpacing.globalGutter,
                  PSpacing.x2,
                  PSpacing.globalGutter,
                  0,
                ),
                child: PField(
                  label: l.smsPasteFieldLabel,
                  invalid: notRecognized,
                  errorMessage: notRecognized ? l.smsNotRecognized : null,
                  child: PTextarea(
                    controller: _textCtrl,
                    placeholder: l.smsPastePlaceholder,
                    // 최대 8줄 — 22 × 8 + 위아래 14
                    maxHeight: 204,
                    disabled: _parsing,
                    // 값을 고치면 오류를 걷는다
                    onChanged: (_) {
                      if (_notice != null) setState(() => _notice = null);
                    },
                  ),
                ),
              ),
              // 취소 문자 — 오류가 아니라 안내. 칸 아래 16
              if (_notice == _Notice.cancel)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PSpacing.globalGutter,
                    PSpacing.x4,
                    PSpacing.globalGutter,
                    0,
                  ),
                  child: PCallout(
                    key: const ValueKey('sms-paste-cancel'),
                    tone: PCalloutTone.informative,
                    description: l.smsCancelNotice,
                  ),
                ),
              // 버튼 둘 — 흐름 안. 칸(과 그 아래 글) 아래 24 · 좌우 24 · 사이 8 · 아래 24
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PSpacing.globalGutter,
                  PSpacing.x6,
                  PSpacing.globalGutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PButton(
                      label: l.smsPasteFromClipboard,
                      variant: PButtonVariant.neutralWeak,
                      size: PButtonSize.large,
                      prefixIcon: LucideIcons.clipboard,
                      onPressed: _parsing ? null : _pasteFromClipboard,
                    ),
                    const SizedBox(height: PSpacing.x2),
                    PButton(
                      label: l.smsPasteAction,
                      variant: PButtonVariant.neutralSolid,
                      size: PButtonSize.large,
                      loading: _parsing,
                      onPressed: _parse,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
