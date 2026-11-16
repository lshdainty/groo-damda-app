import 'package:groo_damda_app/features/money/presentation/money_bundle_screen.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/sms/data/sms_android.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_content.dart';

class _NavItem {
  const _NavItem({
    required this.label,
    required this.desc,
    required this.onTap,
  });
  final String label;

  /// 검색 필터 전용 — 화면엔 표시하지 않음 (design: 텍스트 링크만).
  final String desc;
  final void Function(BuildContext ctx) onTap;
}

class _NavGroup {
  const _NavGroup({required this.label, required this.items});
  final String label;
  final List<_NavItem> items;
}

List<_NavGroup> _buildGroups(BuildContext ctx, {required bool hasSecurities}) {
  final l = AppLocalizations.of(ctx);
  return [
    _NavGroup(
      label: l.moreGroupMoney,
      items: [
        _NavItem(
          label: l.navExpense,
          desc: l.moreDescExpense,
          onTap: (c) => c.go('/expense'),
        ),
        _NavItem(
          label: l.navAsset,
          desc: l.moreDescAsset,
          onTap: (c) => c.go(MoneyTab.assets.location),
        ),
        // 증권 메뉴는 구독(SECURITIES) 보유 시에만 노출
        if (hasSecurities)
          _NavItem(
            label: l.moreItemStocks,
            desc: l.moreDescStocks,
            onTap: (c) => c.push('/stocks'),
          ),
        _NavItem(
          label: l.navBudget,
          desc: l.moreDescBudget,
          onTap: (c) => c.go(MoneyTab.budget.location),
        ),
        _NavItem(
          label: l.navSavingGoals,
          desc: l.moreDescSavingGoal,
          onTap: (c) => c.push('/saving-goals'),
        ),
        _NavItem(
          label: l.moreItemStats,
          desc: l.moreDescStats,
          onTap: (c) => c.go(MoneyTab.stats.location),
        ),
        _NavItem(
          label: l.moreItemRecurring,
          desc: l.moreDescRecurring,
          onTap: (c) => c.push('/recurring'),
        ),
        _NavItem(
          label: l.moreItemSmsPaste,
          desc: l.moreDescSmsPaste,
          onTap: (c) => c.push('/sms-paste'),
        ),
        // 문자 수신은 안드로이드만 된다 — iOS 는 OS 가 문자 접근을 막아 클립보드로 받는다.
        if (SmsAndroid.isSupported)
          _NavItem(
            label: l.moreItemSmsInbox,
            desc: l.moreDescSmsInbox,
            onTap: (c) => c.push('/sms-inbox'),
          ),
        _NavItem(
          label: l.moreItemAccountCard,
          desc: l.moreDescAccountCard,
          onTap: (c) => c.push('/account-card-manage'),
        ),
      ],
    ),
    _NavGroup(
      label: l.moreGroupDaily,
      items: [
        _NavItem(
          label: l.navCalendar,
          desc: l.moreDescCalendar,
          onTap: (c) => c.go('/calendar'),
        ),
        _NavItem(
          label: l.navTodo,
          desc: l.moreDescTodo,
          onTap: (c) => c.push('/todos'),
        ),
        _NavItem(
          label: l.navMemo,
          desc: l.moreDescMemo,
          onTap: (c) => c.push('/memos'),
        ),
        _NavItem(
          label: l.navDutchPay,
          desc: l.moreDescDutchPay,
          onTap: (c) => c.push('/dutch-pay'),
        ),
        _NavItem(
          label: l.moreItemCardBenefits,
          desc: l.moreDescCardBenefits,
          onTap: (c) => c.push('/card-benefits'),
        ),
      ],
    ),
    _NavGroup(
      label: l.moreGroupPersonal,
      items: [
        _NavItem(
          label: l.navCategories,
          desc: l.moreDescCategories,
          onTap: (c) => c.push('/categories'),
        ),
        _NavItem(
          label: l.navPresets,
          desc: l.moreDescPresets,
          onTap: (c) => c.push('/presets'),
        ),
        _NavItem(
          label: l.moreItemDisplay,
          desc: l.moreDescDisplay,
          onTap: (c) => c.push('/settings/appearance'),
        ),
      ],
    ),
    _NavGroup(
      label: l.moreGroupSystem,
      items: [
        _NavItem(
          label: l.navSettings,
          desc: l.moreDescSettings,
          onTap: (c) => c.push('/settings'),
        ),
        _NavItem(
          label: l.notiSettings,
          desc: l.moreDescNotifications,
          onTap: (c) => c.push('/settings/notifications'),
        ),
        _NavItem(
          label: l.exportTitle,
          desc: l.moreDescExport,
          onTap: (c) => c.push('/settings/export-data'),
        ),
        _NavItem(
          label: l.moreItemAccount,
          desc: l.moreDescAccount,
          onTap: (c) => c.push('/account'),
        ),
      ],
    ),
  ];
}

/// 모바일 전용 "전체" 탭 — 흰 화면 하나(I-12 2-B · 2-2A).
///
/// 메뉴 검색(Input 밑줄) → 묶음 넷(목록 제목 + 2열 글 칸) → 탭 바 자리. 검색은 화면 전체를 거르는 줄이라 첫 묶음과
/// 한 덩어리다(틈 0). 검색칸은 목록과 함께 흐른다(Q2 B). 칸은 목적지로 가는 버튼이고 눌림은 바탕 + 2px 축소다.
class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  final _ctrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasSecurities = ref.watch(hasSecuritiesProvider);
    final groups = _buildGroups(context, hasSecurities: hasSecurities);
    final q = _query.trim().toLowerCase();
    final isSearching = q.isNotEmpty;
    // design: 검색은 그룹 구조를 유지한 채 라벨/설명 매칭 항목만 남긴다.
    final visible = isSearching
        ? [
            for (final g in groups)
              if (g.items.any(
                (i) =>
                    i.label.toLowerCase().contains(q) ||
                    i.desc.toLowerCase().contains(q),
              ))
                _NavGroup(
                  label: g.label,
                  items: [
                    for (final i in g.items)
                      if (i.label.toLowerCase().contains(q) ||
                          i.desc.toLowerCase().contains(q))
                        i,
                  ],
                ),
          ]
        : groups;

    return ColoredBox(
      key: const ValueKey('more-face'),
      // 흰 화면 하나 — 셸 바닥 위를 남은 높이까지 채운다
      color: context.colors.bgLayerDefault,
      child: PScreenContent(
        child: ListView(
          // 하단 — 플로팅 탭바 자리는 흰 면 안(T7)
          padding: EdgeInsets.only(bottom: bottomNavigationInset(context)),
          children: [
            // 메뉴 검색 — 밑줄 40, 좌우 24, 위 4(T4)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                PSpacing.x1,
                PSpacing.globalGutter,
                0,
              ),
              child: PInput(
                variant: PInputVariant.underline,
                placeholder: l.moreSearchHint,
                semanticLabel: l.moreSearchHint,
                prefixIcon: LucideIcons.search,
                clearable: true,
                controller: _ctrl,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (isSearching && visible.isEmpty)
              PResultSection(
                size: PResultSize.medium,
                icon: LucideIcons.searchX300,
                title: l.moreSearchEmpty,
              )
            else
              for (int gi = 0; gi < visible.length; gi++)
                // 첫 묶음 위 8(검색과 한 덩어리) · 나머지 위 16 (T5 · T6)
                Padding(
                  padding: EdgeInsets.only(
                    top: gi == 0 ? PSpacing.x2 : PSpacing.x4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PListHeader(
                        title: visible[gi].label,
                        variant: PListHeaderVariant.boldSolid,
                      ),
                      Semantics(
                        container: true,
                        explicitChildNodes: true,
                        label: visible[gi].label,
                        child: Padding(
                          // 격자 좌우 12 + 칸 안 12 = 글 시작 24
                          padding: const EdgeInsets.symmetric(
                            horizontal: PSpacing.x3,
                          ),
                          child: Column(
                            children: [
                              for (
                                int r = 0;
                                r < visible[gi].items.length;
                                r += 2
                              )
                                // 같은 행 두 칸은 높은 쪽에 맞춘다
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: _GridCell(
                                          item: visible[gi].items[r],
                                        ),
                                      ),
                                      Expanded(
                                        child: r + 1 < visible[gi].items.length
                                            ? _GridCell(
                                                item: visible[gi].items[r + 1],
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// 2열 격자의 칸 — 글 t5 · 400, 줄바꿈(말줄임 없음). 누르면 칸 전체가 눌림 바탕(모서리 10)이 되고 내용이 2px 줄어든다.
/// 불투명도로 누름을 알리지 않는다.
class _GridCell extends StatefulWidget {
  const _GridCell({required this.item});
  final _NavItem item;

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell> {
  bool _pressed = false;
  double _basis = 24;

  void _set(bool v) {
    if (_pressed == v) return;
    if (v) {
      final size = context.size;
      if (size != null) {
        _basis = math.max(size.height, math.max(size.width / 4, 24));
      }
    }
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      button: true,
      container: true,
      label: widget.item.label,
      onTap: () => widget.item.onTap(context),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: () => widget.item.onTap(context),
          child: AnimatedContainer(
            duration: PDuration.colorTransition,
            curve: PEasing.easing,
            decoration: BoxDecoration(
              color: _pressed
                  ? c.bgLayerDefaultPressed
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(PRounded.r2_5),
            ),
            child: AnimatedScale(
              scale: _pressed && !reduce ? (_basis - 2) / _basis : 1,
              duration: PDuration.pressedScale,
              curve: PEasing.pressedScale,
              child: Padding(
                padding: const EdgeInsets.all(PSpacing.x3),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    keepAll(widget.item.label),
                    style: PTypography.t5.copyWith(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
