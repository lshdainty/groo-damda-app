import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/storage/prefs_provider.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart'
    show PTouchTargetScope;
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/features/sms/data/clipboard_hint.dart';
import 'package:groo_damda_app/features/sms/data/clipboard_hint_provider.dart';
import 'package:groo_damda_app/features/sms/domain/sms_prefilter.dart';

/// 홈 상단 — 복사한 결제 문자를 기록하도록 권하는 안내 줄(List 강조 줄).
///
/// 문자를 복사해 놓고 앱을 열었을 때 "여기 붙여넣으세요" 를 찾아 헤매지 않게 한다.
/// 이 배너가 없으면 사용자는 더보기 메뉴까지 들어가야 한다.
///
/// **클립보드 내용은 여기서 읽지 않는다.** iOS 는 읽을 때마다 붙여넣기 배너를
/// 띄우므로, 띄울지 말지는 내용 접근이 없는 힌트로 판단하고([readClipboardHint])
/// 실제 읽기는 사용자가 눌렀을 때 한 번만 한다.
///
/// 안드로이드에서는 아무것도 그리지 않는다 — 힌트 API 가 없어 배너를 띄우려면
/// 내용을 읽어야 하고, 문자를 직접 수신할 수 있어 우회로가 필요 없다.
class SmsClipboardBanner extends ConsumerStatefulWidget {
  const SmsClipboardBanner({super.key});

  @override
  ConsumerState<SmsClipboardBanner> createState() => _SmsClipboardBannerState();
}

class _SmsClipboardBannerState extends ConsumerState<SmsClipboardBanner>
    with WidgetsBindingObserver {
  /// 지금 배너를 띄울 근거가 된 클립보드 상태. null 이면 배너를 그리지 않는다.
  int? _changeCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshHint();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 문자 앱에서 복사하고 돌아오는 흐름이 가장 흔하다 — 돌아올 때마다 다시 본다.
    // 내용을 읽는 게 아니라 힌트만 보는 것이라 OS 배너는 뜨지 않는다.
    if (state == AppLifecycleState.resumed) _refreshHint();
  }

  Future<void> _refreshHint() async {
    final hint = await ref.read(clipboardHintReaderProvider)();
    if (!mounted) return;

    if (hint == null || !hint.hasText) {
      if (_changeCount != null) setState(() => _changeCount = null);
      return;
    }
    // 사용자가 이미 닫은 복사본이면 다시 권하지 않는다.
    final prefs = await ref.read(prefsProvider.future);
    if (!mounted) return;
    final dismissed = prefs.getInt(_dismissedKey);
    final next = dismissed == hint.changeCount ? null : hint.changeCount;
    if (next != _changeCount) setState(() => _changeCount = next);
  }

  Future<void> _dismiss() async {
    final current = _changeCount;
    setState(() => _changeCount = null);
    if (current == null) return;
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setInt(_dismissedKey, current);
  }

  /// 배너를 눌렀을 때 — 이때 처음으로 클립보드를 실제로 읽는다.
  Future<void> _open() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final text = data?.text;

    if (text == null || text.trim().isEmpty) {
      PSnackbar.maybeOf(
        context,
      )?.show(message: l.smsClipboardEmpty, tone: PSnackbarTone.critical);
      await _dismiss();
      return;
    }
    // 결제 문자가 아니면 서버로 보내지 않는다 — 붙여넣기 화면에서 사용자가
    // 직접 고칠 수 있도록 원문은 들고 간다.
    if (!looksLikePaymentSms(text)) {
      PSnackbar.maybeOf(
        context,
      )?.show(message: l.smsNotRecognized, tone: PSnackbarTone.critical);
      await _dismiss();
      return;
    }
    await _dismiss();
    if (!mounted) return;
    context.push('/sms-paste', extra: text);
  }

  @override
  Widget build(BuildContext context) {
    if (_changeCount == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);

    // List 강조 줄(list.md Highlight) — 홈 머리 바로 아래 화면 폭 흰 면. 보일 때만 아래에 띠 사이 틈(8)이 이어진다.
    // 누르는 것은 둘 — 줄 전체(가져오기)와 닫기(list.md "줄 안의 누르는 것은 셋 이하").
    final c = context.colors;
    return Column(
      key: const ValueKey('sms-clipboard-banner'),
      mainAxisSize: MainAxisSize.min,
      children: [
        PScreenBandBody(
          child: PTouchTargetScope(
            child: PListButtonItem(
              title: l.smsClipboardBannerTitle,
              detail: l.smsClipboardBannerDesc,
              highlighted: true,
              onTap: _open,
              // 오른쪽 14 블리드 — 닫기 아이콘이 화면 끝 24 에 선다(보이는 36 상자의 오른쪽이 14)
              endInset: PSpacing.x3_5,
              prefix: ExcludeSemantics(
                child: Icon(
                  LucideIcons.clipboard,
                  size: PSpacing.x6,
                  color: c.fgBrand,
                ),
              ),
              suffix: PListSuffix(
                children: [
                  // 화면을 옮기는 줄이라 화살표
                  const ExcludeSemantics(child: Icon(LucideIcons.chevronRight)),
                  PListAction(
                    child: PButton.icon(
                      icon: LucideIcons.x,
                      semanticLabel: l.actionClose,
                      variant: PButtonVariant.ghost,
                      ghostColor: PButtonGhostColor.neutralSubtle,
                      size: PButtonSize.small,
                      onPressed: _dismiss,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: kScreenBandGap),
      ],
    );
  }
}

/// 마지막으로 사용자가 닫은 클립보드 changeCount — 같은 복사본을 또 권하지 않으려고.
const String _dismissedKey = 'pd-sms-clip-dismissed';
