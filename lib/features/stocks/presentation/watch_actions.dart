/// 관심 그룹 묶음 · 그룹 폼 · 삭제 확인 · 관심 별 토글 · 종목 찾기 시트 — 토스 · 나무가 함께 쓴다(I-13 13-3).
/// toss_stocks_view.dart 에서 옮겼다. 묶음은 줄 짓는 함수를 받는다(증권사마다 시세 얻는 길이 다르다).
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/stock_market_label.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/ds/searchable_list/p_searchable_list.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

// ---- 관심 그룹 -----------------------------------------------------------------

/// 그룹 하나 — 목록 제목("{이름} · {n}" + ⋮) + 줄. 지어지면 보인다고 알리고(시세 부르기) 사라지면 알린다.
class WatchGroupBlock extends ConsumerStatefulWidget {
  const WatchGroupBlock({
    super.key,
    required this.group,
    required this.first,
    required this.onShown,
    required this.onHidden,
    required this.lineBuilder,
  });

  final StockWatchGroup group;
  final bool first;
  final VoidCallback onShown;
  final VoidCallback onHidden;

  /// 줄 하나를 짓는 함수 — 증권사마다 시세를 얻는 길이 달라 호출부가 정한다.
  final Widget Function(WatchItem item) lineBuilder;

  @override
  ConsumerState<WatchGroupBlock> createState() => WatchGroupBlockState();
}

class WatchGroupBlockState extends ConsumerState<WatchGroupBlock> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onShown();
    });
  }

  @override
  void dispose() {
    widget.onHidden();
    super.dispose();
  }

  Future<void> _more() async {
    final l = AppLocalizations.of(context);
    final g = widget.group;
    final rename = PMenuSheetItem(
      label: l.stocksWatchGroupRenameItem,
      icon: LucideIcons.pencil,
    );
    final del = PMenuSheetItem(
      label: l.stocksWatchGroupDelete,
      icon: LucideIcons.trash2,
      tone: PMenuSheetTone.critical,
    );
    final picked = await PMenuSheet.show(
      context,
      semanticLabel: l.stocksWatchGroupMore(g.groupName),
      groups: [
        PMenuSheetGroup([rename, del]),
      ],
    );
    if (!mounted || picked == null) return;
    if (identical(picked, rename)) {
      await showWatchGroupForm(context, ref, group: g);
    } else if (identical(picked, del)) {
      await confirmDeleteWatchGroup(context, ref, g);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final g = widget.group;
    return ColoredBox(
      color: c.bgLayerDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PListHeader(
            title: l.stocksWatchGroupTitle(g.groupName, g.items.length),
            variant: PListHeaderVariant.boldSolid,
            headingLevel: 3,
            topInset: widget.first ? PSpacing.x2 : PSpacing.x4,
            action: PButton.icon(
              icon: LucideIcons.ellipsisVertical,
              semanticLabel: l.stocksWatchGroupMore(g.groupName),
              variant: PButtonVariant.ghost,
              size: PButtonSize.small,
              onPressed: _more,
            ),
          ),
          if (g.items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.x6,
                PSpacing.x1,
                PSpacing.x6,
                PSpacing.x3,
              ),
              child: PText(
                l.stocksWatchGroupEmpty,
                style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
              ),
            )
          else
            PList(
              semanticLabel: g.groupName,
              children: [for (final item in g.items) widget.lineBuilder(item)],
            ),
        ],
      ),
    );
  }
}

/// 그룹 추가 · 이름 바꾸기 폼 — Bottom Sheet. 바깥 누름 · 끌기로 닫히지 않고, 바뀐 값이 있으면 닫기 전에 묻는다.
Future<void> showWatchGroupForm(
  BuildContext context,
  WidgetRef ref, {
  StockWatchGroup? group,
}) {
  final l = AppLocalizations.of(context);
  final probe = _FormProbe();
  // 새 그룹은 이름 칸에 초점(시트가 처음 초점을 컨테이너에 두므로 첫 초점 노드를 넘긴다), 이름 바꾸기는 키보드 없이 표면
  final nameFocus = FocusNode(debugLabel: 'WatchGroup name');
  return PBottomSheet.show<void>(
    context,
    form: true,
    initialFocus: group == null ? nameFocus : null,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) =>
        _GroupForm(group: group, probe: probe, nameFocus: nameFocus),
  );
}

class _FormProbe {
  bool Function() dirty = () => false;
}

class _GroupForm extends ConsumerStatefulWidget {
  const _GroupForm({
    required this.group,
    required this.probe,
    required this.nameFocus,
  });
  final StockWatchGroup? group;
  final _FormProbe probe;

  /// 이름 칸 초점 노드 — 호출처가 시트의 첫 초점으로 넘기고 폼 State 가 버린다.
  final FocusNode nameFocus;

  @override
  ConsumerState<_GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends ConsumerState<_GroupForm> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.group?.groupName ?? '',
  );
  late final FocusNode _nameFocus = widget.nameFocus;
  bool _busy = false;
  bool _failed = false;

  /// 실패한 저장의 오류 — 응답을 읽지 못한 쓰기(PARSE)면 실패가 아니라 "저장됐는지 확인하지 못했어요"(검수 M3).
  Object? _failure;
  final _errorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.probe.dirty = () =>
        _ctrl.text.trim() != (widget.group?.groupName ?? '').trim();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() {
      _failed = false;
      _busy = true;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = await container.read(stocksRepositoryProvider.future);
      final g = widget.group;
      if (g == null) {
        await repo.createWatchGroup(name, silent: true);
      } else {
        await repo.renameWatchGroup(g.rowId, name, silent: true);
      }
      container.invalidate(watchGroupsProvider);
      if (mounted) {
        widget.probe.dirty = () => false;
        PBottomSheet.of(context).close();
      }
    } catch (e) {
      // 시트는 열린 채 쓴 이름이 남는다 — 실패는 맨 위 Callout 한 문장(우리 글, 서버 글 아님)이 말한다.
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다(검수 M3)
      if (isUnconfirmedSave(e)) container.invalidate(watchGroupsProvider);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failed = true;
        _failure = e;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _errorKey.currentContext;
        if (ctx != null && ctx.mounted) revealBelowFog(ctx);
      });
    } finally {
      sheet?.setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canSave = _ctrl.text.trim().isNotEmpty && !_busy;
    return PBottomSheetContent(
      title: widget.group == null
          ? l.stocksWatchGroupAdd
          : l.stocksWatchGroupRename,
      closeLabel: l.actionClose,
      flushBody: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_failed) ...[
              FormErrorCallout(
                key: _errorKey,
                message: saveFailureText(
                  l,
                  _failure,
                  l.stocksWatchGroupSaveFail,
                ),
              ),
              const SizedBox(height: PSpacing.x4),
            ],
            PField(
              label: l.stocksWatchGroupNamePlaceholder,
              child: PInput(
                controller: _ctrl,
                focusNode: _nameFocus,
                semanticLabel: l.stocksWatchGroupNamePlaceholder,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _save(),
              ),
            ),
          ],
        ),
      ),
      footer: [
        PButton(
          label: l.actionSave,
          size: PButtonSize.large,
          loading: _busy,
          onPressed: canSave ? _save : null,
        ),
      ],
    );
  }
}

/// 그룹 삭제 확인 — 확인창 뒤 실패는 공용 [askConfirmThenRequest] (critical 스낵바 + [다시 시도]).
Future<void> confirmDeleteWatchGroup(
  BuildContext context,
  WidgetRef ref,
  StockWatchGroup g,
) async {
  final l = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context);
  Future<void> request() async {
    final repo = await container.read(stocksRepositoryProvider.future);
    await repo.deleteWatchGroup(g.rowId, silent: true);
  }

  final ok = await askConfirmThenRequest(
    context,
    title: l.stocksWatchGroupDelete,
    description: g.items.isEmpty
        ? l.stocksWatchGroupDeleteConfirmEmpty(g.groupName)
        : l.stocksWatchGroupDeleteConfirmCount(g.groupName, g.items.length),
    cancelLabel: l.actionCancel,
    actionLabel: l.stocksWatchGroupDelete,
    request: request,
    failedMessage: l.stocksWatchGroupDeleteFail,
    retryLabel: l.actionRetry,
    onRetried: () => container.invalidate(watchGroupsProvider),
    kind: WriteKind.delete,
    onUnconfirmed: () => container.invalidate(watchGroupsProvider),
  );
  if (ok) container.invalidate(watchGroupsProvider);
}

/// 관심 별 토글(Q3-B) — 어느 그룹에든 있으면 전부 해제, 없으면 그룹이 하나면 바로 · 둘 이상이면 시트로 고른 그룹에
/// 담는다(그룹이 없으면 기본 그룹부터 만든다).
Future<void> toggleWatch(
  BuildContext context,
  WidgetRef ref,
  String symbol, {
  String? marketCode,
}) async {
  final l = AppLocalizations.of(context);
  // 그룹 질의가 아직 오는 중이거나 실패면 기본 그룹을 새로 만들지 않는다(같은 이름 그룹이 하나 더 생긴다 — M3).
  final groupsAsync = ref.read(watchGroupsProvider);
  if (!groupsAsync.hasValue) return;
  final groups = groupsAsync.value ?? const <StockWatchGroup>[];
  // 바로 바뀌는 값 — 실패하면 별은 그대로(서버 값이 그대로라 되돌릴 것이 없다) 스낵바 한 문장 + [다시 시도].
  // 서버 글은 띄우지 않는다(silent). 스낵바 길은 시트가 닫히기 전에 쥔다.
  final snack = PSnackbar.maybeOf(context);
  final container = ProviderScope.containerOf(context);
  final repo = await ref.read(stocksRepositoryProvider.future);
  final entries = [
    for (final g in groups) ...g.items.where((i) => i.symbol == symbol),
  ];
  final removing = entries.isNotEmpty;
  Future<void> Function() request;
  if (removing) {
    request = () async {
      for (final e in entries) {
        await repo.removeWatchItem(e.rowId, silent: true);
      }
    };
  } else if (groups.isEmpty) {
    // 기본 그룹은 한 번만 만든다 — 담기만 실패해 다시 시도해도 같은 그룹이 또 생기지 않는다.
    StockWatchGroup? created;
    request = () async {
      created ??= await repo.createWatchGroup(
        l.stocksWatchDefaultGroupName,
        silent: true,
      );
      await repo.addWatchItem(
        created!.rowId,
        symbol,
        marketCode: marketCode,
        silent: true,
      );
    };
  } else if (groups.length == 1) {
    request = () => repo.addWatchItem(
      groups.first.rowId,
      symbol,
      marketCode: marketCode,
      silent: true,
    );
  } else {
    if (!context.mounted) return;
    // 그룹 목록은 사용자 값이라 메뉴(실행)가 아니라 고르기 시트 — 웹 detail-parts.tsx 와 같다.
    final target = await PBottomSheet.show<StockWatchGroup>(
      context,
      builder: (sheetContext) => PBottomSheetContent(
        title: l.stocksWatchPickGroup,
        closeLabel: l.actionClose,
        flushBody: true,
        scrollFog: true,
        body: PList(
          semanticLabel: l.stocksWatchPickGroup,
          children: [
            for (final g in groups)
              PListButtonItem(
                title: g.groupName,
                detail: l.stocksUnitCount(g.items.length),
                onTap: () => PBottomSheet.of(sheetContext).close(g),
              ),
          ],
        ),
      ),
    );
    if (target == null) return;
    request = () => repo.addWatchItem(
      target.rowId,
      symbol,
      marketCode: marketCode,
      silent: true,
    );
  }
  try {
    await request();
    container.invalidate(watchGroupsProvider);
  } catch (e) {
    // 별은 누르는 순간 바뀌는 값이다 — 실패하면 두 문장("… 잠시 뒤 다시 시도해주세요."), [다시 시도] 버튼 없음(다시 누르면 된다).
    // 응답을 못 받았으면 담겼거나 빠졌을 수 있다 — 서버 값을 다시 받아 별을 맞추고 "바뀌었는지" 한 문장(판단 ②)
    final unconfirmed = isUnconfirmedSave(e);
    if (unconfirmed) container.invalidate(watchGroupsProvider);
    snack?.show(
      message: unconfirmed
          ? l.unconfirmedToggle
          : removing
          ? l.stocksWatchRemoveFail
          : l.stocksWatchAddFail,
      tone: PSnackbarTone.critical,
    );
  }
}

// ---- 종목 찾기 (Searchable List · Bottom Sheet) --------------------------------

/// 종목 찾기 시트 — 서버 검색은 마지막 입력 뒤 300ms 에 한 번. 줄은 상세로 가는 줄(라디오 없음).
Future<void> showStockSearchSheet(
  BuildContext context, {
  required void Function(String symbol) onPick,
}) {
  final focus = FocusNode(debugLabel: 'stock search');
  return PBottomSheet.show<String>(
    context,
    initialFocus: focus,
    builder: (_) => _StockSearchSheet(searchFocus: focus),
  ).then((symbol) {
    focus.dispose();
    if (symbol != null) onPick(symbol);
  });
}

class _StockSearchSheet extends ConsumerStatefulWidget {
  const _StockSearchSheet({required this.searchFocus});
  final FocusNode searchFocus;

  @override
  ConsumerState<_StockSearchSheet> createState() => _StockSearchSheetState();
}

class _StockSearchSheetState extends ConsumerState<_StockSearchSheet> {
  String _typed = '';
  String _sent = '';

  /// 마지막으로 받은 결과 — 새 검색어를 기다리는 동안 이것을 보인다(첫 글자 뒤 "결과 없음" 깜빡임 방지, M2).
  List<StockMasterItem> _prev = const [];
  Timer? _slowTimer;
  bool _slow = false;

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final query = _typed.trim();
    // 친 글자와 서버로 보낸 글자가 다르면 300ms 를 기다리는 중이다 — 질의가 아직 안 나갔으니 "없음" 이 아니다.
    final pending = query != _sent.trim();
    final async = ref.watch(stockSearchResultProvider(_sent));
    final fresh = (!pending && async.hasValue) ? async.value! : null;
    if (fresh != null) _prev = fresh;
    final results = fresh ?? _prev;
    final failed = !pending && async.hasError && !async.hasValue;
    final busy = pending || (async.isLoading && !async.hasValue);
    // 옛 결과를 두고, 1초 넘게 걸리면 그때 Skeleton
    if (busy && query.isNotEmpty) {
      _slowTimer ??= Timer(const Duration(seconds: 1), () {
        if (mounted) setState(() => _slow = true);
      });
    } else {
      _slowTimer?.cancel();
      _slowTimer = null;
      _slow = false;
    }
    final fetching = busy && _slow;
    Widget? body;
    if (query.isNotEmpty && !failed) {
      body = fetching
          ? loadingRegion(const PSearchableListSkeleton())
          : PSearchableListResults(
              scrollFog: true,
              semanticLabel: l.stocksSearch,
              children: [
                for (final s in results)
                  PSearchableListItem(
                    value: s.symbol,
                    title: s.nameKr.isNotEmpty ? s.nameKr : s.symbol,
                    detail:
                        '${s.symbol} · ${stockMarketLabel(l, s.marketCode)}'
                        ' · ${stockSecurityTypeLabel(l, s.securityType)}',
                  ),
              ],
            );
    }
    return PBottomSheetContent(
      title: l.stocksSearch,
      closeLabel: l.actionClose,
      flushBody: true,
      body: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: PSearchableList(
          selectionMark: PSearchableListSelectionMark.off,
          focusNode: widget.searchFocus,
          query: _typed,
          onQueryChanged: (q) => setState(() => _typed = q),
          onSearch: (q) => setState(() => _sent = q),
          onValueChanged: (v) => PBottomSheet.of(context).close(v),
          children: [
            PSearchableListInput(
              placeholder: l.stocksSearchPlaceholder,
              semanticLabel: l.actionSearch,
            ),
            if (query.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PSpacing.x6,
                  PSpacing.x4,
                  PSpacing.x6,
                  PSpacing.x6,
                ),
                child: PText(
                  l.stocksSearchHint,
                  style: PTypography.t4.copyWith(
                    color: context.colors.fgNeutralSubtle,
                  ),
                ),
              )
            else if (failed)
              PSearchableListError(
                title: l.stocksFailSearch,
                retryLabel: l.actionRetry,
                retrying: async.isLoading,
                onRetry: () => ref.invalidate(stockSearchResultProvider(_sent)),
              )
            else if (results.isEmpty && !busy)
              PSearchableListEmpty(
                titleBuilder: (q) => l.stocksSearchNoResults(q),
              ),
            ?body,
          ],
        ),
      ),
    );
  }
}
