import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/format/now_tick.dart';
import 'package:groo_damda_app/features/sms/data/sms_android.dart';
import 'package:groo_damda_app/features/sms/domain/sms_paste_args.dart';
import 'package:groo_damda_app/features/sms/domain/sms_preview.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart'
    show PTouchTargetScope;
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_content.dart';

/// 아직 기록하지 않은 결제 알림 목록 (안드로이드). 흰 화면 하나(I-12 6-A).
///
/// 알림만 있으면 사용자가 알림을 쓸어 지우는 순간 내용이 사라진다 — 나중에
/// "그거 뭐였지" 하고 찾을 방법이 없다. 받은 것을 여기 쌓아 두고 나중에라도
/// 기록할 수 있게 한다.
///
/// 목록은 기기 안에만 있다. 서버로는 사용자가 확인 화면에서 저장할 때만 올라간다.
///
/// 목록에 보이는 금액·가맹점은 로컬에서 가볍게 훑은 미리보기다([SmsPreview]) —
/// 정확한 파싱은 항목을 눌러 확인 화면으로 갈 때 서버가 한다.
class SmsInboxScreen extends ConsumerStatefulWidget {
  const SmsInboxScreen({super.key});

  @override
  ConsumerState<SmsInboxScreen> createState() => _SmsInboxScreenState();
}

class _SmsInboxScreenState extends ConsumerState<SmsInboxScreen>
    with WidgetsBindingObserver {
  List<SmsInboxEntry>? _entries;
  bool _granted = true;
  bool _notiAccess = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 알림 접근은 설정 앱에 다녀와야 켜진다 — 돌아오면 상태를 다시 읽는다.
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final granted = await SmsAndroid.hasPermissions();
    final notiAccess = await SmsAndroid.hasNotificationAccess();
    final entries = await SmsAndroid.inbox();
    if (!mounted) return;
    setState(() {
      _granted = granted;
      _notiAccess = notiAccess;
      _entries = entries;
    });
  }

  /// 한 건 지우기 — × 도 밀기도 같은 확인창을 거친다(6-2A). 기록으로 남기지 않고 목록에서만 치우므로 되돌릴 수 없다.
  Future<void> _confirmRemove(SmsInboxEntry entry) async {
    final l = AppLocalizations.of(context);
    final target = _removeTarget(entry);
    final ok = await PAlertDialog.show(
      context,
      title: l.smsInboxRemoveTitle,
      description: l.smsInboxRemoveConfirm("'$target'"),
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await SmsAndroid.removeFromInbox(entry.id);
    await _load();
  }

  Future<void> _confirmClear(int count) async {
    final l = AppLocalizations.of(context);
    final ok = await PAlertDialog.show(
      context,
      title: l.smsInboxClearTitle,
      description: l.smsInboxClearConfirm(count),
      cancelLabel: l.actionCancel,
      actionLabel: l.smsInboxClear,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await SmsAndroid.clearInbox();
    await _load();
  }

  Future<void> _open(SmsInboxEntry entry) async {
    // 기록에 성공하면 저장 쪽에서 이 항목을 빼 준다. 여기서 미리 지우면
    // 사용자가 시트를 닫고 나왔을 때 문자가 사라져 있다.
    await context.push(
      '/sms-paste',
      extra: SmsPasteArgs(text: entry.text, inboxId: entry.id),
    );
    if (mounted) await _load();
  }

  Future<void> _requestPermission() async {
    await SmsAndroid.requestPermissions();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final now = ref.watch(nowTickProvider);
    final entries = _entries;
    final hasEntries = entries != null && entries.isNotEmpty;
    final bottom = PSpacing.x6 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      // 흰 화면 하나 — 띠 · 회색 바닥이 없다(6-A)
      backgroundColor: c.bgLayerDefault,
      // 머리 = ds 상단 바(← + 제목) + 오른쪽 글 버튼 하나 [비우기](문자가 있을 때만)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.smsInboxTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            if (hasEntries)
              PTopNavigationTextButton(
                label: l.smsInboxClear,
                onPressed: () => _confirmClear(entries.length),
              ),
          ],
        ),
      ),
      body: PScreenContent(
        child: PPullToRefresh(
          onRefresh: _load,
          child: PSwipeActionsProvider(
            child: CustomScrollView(
              key: const ValueKey('sms-inbox-body'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 알림 접근이 이 기능의 유일한 스위치다 — 카드사·은행 앱 푸시도,
                // 결제 문자도 전부 이 경로로 읽는다. 꺼져 있으면 아무것도 안 들어온다.
                // 알림 권한은 없어도 감지는 된다(수신함에 쌓인다) — 알림으로 바로
                // 기록하러 가는 동선만 빠지므로 경고가 아니라 안내로 둔다.
                // 상자 전체가 버튼이다(Callout actionable) — 위 16 · 좌우 24 · 아래 8 (T17 · T18)
                if (!_notiAccess)
                  _notice(
                    PCallout(
                      key: const ValueKey('sms-callout-noti'),
                      tone: PCalloutTone.warning,
                      interaction: PCalloutInteraction.actionable,
                      title: l.smsNotiAccessOffTitle,
                      description: l.smsNotiAccessOffDesc,
                      onPressed: SmsAndroid.openNotificationAccessSettings,
                    ),
                  )
                else if (!_granted)
                  _notice(
                    PCallout(
                      key: const ValueKey('sms-callout-permission'),
                      tone: PCalloutTone.informative,
                      interaction: PCalloutInteraction.actionable,
                      title: l.smsPermissionOffTitle,
                      description: l.smsPermissionOffDesc,
                      onPressed: _requestPermission,
                    ),
                  ),
                if (entries != null && entries.isEmpty)
                  // 안내 상자 아래 남은 자리의 가운데 — 처음 읽는 동안(entries == null)은 비워 둔다
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: PResultSection(
                        icon: LucideIcons.creditCard300,
                        title: l.smsInboxEmpty,
                        description: l.smsInboxEmptyDesc,
                      ),
                    ),
                  )
                else if (entries != null)
                  SliverList(
                    delegate: SliverChildListDelegate(
                      _buildGrouped(context, entries, now),
                    ),
                  ),
                // 끝 여백 24 (T20)
                SliverToBoxAdapter(child: SizedBox(height: bottom)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notice(Widget callout) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x4,
        PSpacing.globalGutter,
        PSpacing.x2,
      ),
      child: callout,
    ),
  );

  /// 날짜별로 묶어 목록 제목 아래 줄을 늘어놓는다. 첫 묶음 위 8 · 나머지 위 16 (T18 · T19).
  List<Widget> _buildGrouped(
    BuildContext context,
    List<SmsInboxEntry> entries,
    DateTime now,
  ) {
    final l = AppLocalizations.of(context);
    final groups = <(DateTime, List<SmsInboxEntry>)>[];
    String? lastKey;
    for (final entry in entries) {
      final key = DateFormat('yyyy-MM-dd').format(entry.receivedAt);
      if (key != lastKey) {
        groups.add((entry.receivedAt, []));
        lastKey = key;
      }
      groups.last.$2.add(entry);
    }
    return [
      for (var i = 0; i < groups.length; i++) ...[
        Builder(
          builder: (context) {
            final label = _dateLabel(context, groups[i].$1, now);
            return PListHeader(
              title: label,
              topInset: i == 0 ? PSpacing.x2 : PSpacing.x4,
            );
          },
        ),
        PList(
          semanticLabel: _dateLabel(context, groups[i].$1, now),
          children: [
            for (final entry in groups[i].$2)
              // 밀면 지우기 — 손가락 지름길이다. 줄 끝 × 가 같은 동작을 맡는다(6-2A). 확인창은 둘 다 같다.
              PSwipeActions(
                key: ValueKey('sms-swipe-${entry.id}'),
                rowLabel: _removeTarget(entry),
                actions: [
                  PSwipeAction(
                    label: l.actionDelete,
                    icon: LucideIcons.trash2,
                    kind: PSwipeActionKind.destructive,
                    onSelect: () => _confirmRemove(entry),
                  ),
                ],
                child: _InboxRow(
                  entry: entry,
                  onOpen: _open,
                  onRemove: _confirmRemove,
                ),
              ),
          ],
        ),
      ],
    ];
  }
}

/// 날짜 묶음 제목 — "10월 23일 (금) · 오늘". 다른 해면 연도를 붙인다. 영어는 지금 그대로.
String _dateLabel(BuildContext context, DateTime date, DateTime now) {
  final l = AppLocalizations.of(context);
  final en = Localizations.localeOf(context).languageCode == 'en';
  final today =
      date.year == now.year && date.month == now.month && date.day == now.day;
  final base = en
      ? DateFormat('EEE, MMM d', 'en').format(date)
      : DateFormat(
          date.year == now.year ? 'M월 d일 (E)' : 'yyyy년 M월 d일 (E)',
          'ko',
        ).format(date);
  return today ? '$base · ${l.dateToday}' : base;
}

/// 확인창이 부르는 이름 — 가맹점(못 읽으면 받은 시각)에 금액이 있으면 " 12,000원".
String _removeTarget(SmsInboxEntry entry) {
  final preview = SmsPreview.of(entry.text);
  final name = preview.merchant ?? timeOfDay12(entry.receivedAt);
  final amount = preview.amount;
  if (amount == null) return name;
  return '$name ${krwSigned(amount.abs(), false, unit: true)}';
}

/// 결제 알림 한 건 — 회색 타일 + 가맹점 + (발신기관·시각) + 금액 + [×].
///
/// 아직 카테고리가 없어 타일은 결제 수단(카드)·회색으로 고정한다(색에 뜻이 없다). 금액·가맹점은 로컬 미리보기라
/// 못 읽을 수 있고, 그때는 원문 첫 줄로 대신한다. 줄을 누르면 붙여넣기 화면으로 간다.
class _InboxRow extends StatelessWidget {
  const _InboxRow({
    required this.entry,
    required this.onOpen,
    required this.onRemove,
  });

  final SmsInboxEntry entry;
  final Future<void> Function(SmsInboxEntry) onOpen;
  final Future<void> Function(SmsInboxEntry) onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final preview = SmsPreview.of(entry.text);

    // 제목 = 가맹점. 못 읽으면 원문 첫 줄로 대신한다(빈 자리보다 낫다).
    final title = preview.merchant ?? _firstLine(entry.text);
    final sub = [
      preview.issuer,
      timeOfDay12(entry.receivedAt),
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    return PTouchTargetScope(
      child: PListButtonItem(
        title: title,
        detail: sub.isEmpty ? null : sub,
        onTap: () => onOpen(entry),
        // 오른쪽 14 블리드 — [×] 아이콘이 화면 끝 24 에 선다(보이는 36 상자의 오른쪽이 14)
        endInset: PSpacing.x3_5,
        prefix: PListTile(
          background: c.chartGrayWeak,
          color: c.chartGray,
          child: const Icon(LucideIcons.creditCard),
        ),
        suffix: PListSuffix(
          children: [
            if (preview.amount != null)
              PListValue.amount(
                krwSigned(
                  preview.amount!.abs(),
                  false,
                  sign: minusOf(preview.amount!),
                  unit: true,
                ),
                style: TextStyle(
                  color: c.fgNeutral,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            // 삭제 — 기록하지 않고 목록에서만 치운다. 이름은 어느 줄인지 안다.
            PListAction(
              child: PButton.icon(
                icon: LucideIcons.x,
                semanticLabel: l.smsInboxRemoveLabel(_removeTarget(entry)),
                variant: PButtonVariant.ghost,
                ghostColor: PButtonGhostColor.neutralSubtle,
                size: PButtonSize.small,
                onPressed: () => onRemove(entry),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _firstLine(String text) {
    final line = text
        .replaceAll('[Web발신]', '')
        .split(RegExp(r'\r\n|\r|\n'))
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => text.trim());
    return line.length > 40 ? '${line.substring(0, 40)}…' : line;
  }
}
