import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/export/data/export_repository.dart';
import 'package:groo_damda_app/features/import/presentation/import_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/select_box/p_select_box.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

typedef _TypeMeta = ({String name, String slug, IconData icon});
typedef _FormatMeta = ({String value, String label, String ext, IconData icon});
typedef _PeriodMeta = ({String value});

const List<_TypeMeta> _types = [
  (name: 'EXPENSE', slug: 'expense', icon: LucideIcons.receipt),
  (name: 'ASSET', slug: 'asset', icon: LucideIcons.wallet),
  (name: 'BUDGET', slug: 'budget', icon: LucideIcons.target),
  (name: 'CATEGORY', slug: 'category', icon: LucideIcons.tag),
  (name: 'MEMO', slug: 'memo', icon: LucideIcons.fileText),
  (name: 'CALENDAR', slug: 'calendar', icon: LucideIcons.calendar),
  (name: 'TODO', slug: 'todo', icon: LucideIcons.squareCheckBig),
];

const List<_FormatMeta> _formats = [
  (value: 'CSV', label: 'CSV', ext: '.csv', icon: LucideIcons.fileText),
  (value: 'EXCEL', label: 'Excel', ext: '.xlsx', icon: LucideIcons.sheet),
  (value: 'JSON', label: 'JSON', ext: '.json', icon: LucideIcons.braces),
];

const List<_PeriodMeta> _periods = [
  (value: 'THIS_MONTH'),
  (value: 'LAST_MONTH'),
  (value: 'LAST_3_MONTHS'),
  (value: 'THIS_YEAR'),
  (value: 'CUSTOM'),
];

String _slugOf(String name) => _types.firstWhere((t) => t.name == name).slug;

String _typeLabel(AppLocalizations l, String name) => switch (name) {
  'EXPENSE' => l.exportTypeExpense,
  'ASSET' => l.exportTypeAsset,
  'BUDGET' => l.exportTypeBudget,
  'CATEGORY' => l.exportTypeCategory,
  'MEMO' => l.exportTypeMemo,
  'CALENDAR' => l.exportTypeCalendar,
  _ => l.exportTypeTodo,
};

String _formatDesc(AppLocalizations l, String value) => switch (value) {
  'EXCEL' => l.exportFormatExcelDesc,
  'JSON' => l.exportFormatJsonDesc,
  _ => l.exportFormatCsvDesc,
};

String _periodLabel(AppLocalizations l, String value) => switch (value) {
  'LAST_MONTH' => l.exportPeriodLastMonth,
  'LAST_3_MONTHS' => l.exportPeriodLast3Months,
  'THIS_YEAR' => l.exportPeriodThisYear,
  'CUSTOM' => l.exportPeriodCustom,
  _ => l.exportPeriodThisMonth,
};

String _two(int n) => n.toString().padLeft(2, '0');
String _iso(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
String _krLabel(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length < 3) return isoDate;
  return formatDay(
    DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
  ).md;
}

/// 데이터 내보내기 풀스크린 — 설정 > 데이터 내보내기.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String _mode = 'export'; // export | import
  String _format = 'CSV';
  String _period = 'THIS_MONTH';
  DateTime? _customFrom = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime? _customTo = DateTime.now();
  List<String> _selected = ['EXPENSE', 'ASSET', 'BUDGET'];
  bool _mask = false;

  Map<String, int> _counts = {};
  bool _countsLoading = true;
  bool _countsFailed = false;
  final ScrollController _scroll = ScrollController();
  final GlobalKey _previewKey = GlobalKey();
  bool _downloading = false;
  bool _previewing = false;
  bool _previewFailed = false;
  List<ExportPreviewTable>? _preview;
  String? _previewTab;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  bool get _customInvalid =>
      _period == 'CUSTOM' &&
      (_customFrom == null ||
          _customTo == null ||
          _customFrom!.isAfter(_customTo!));

  ({String start, String end}) _resolveRange(String period) {
    final now = DateTime.now();
    DateTime firstOf(int y, int m) => DateTime(y, m, 1);
    DateTime lastOf(int y, int m) => DateTime(y, m + 1, 0);
    switch (period) {
      case 'THIS_MONTH':
        return (
          start: _iso(firstOf(now.year, now.month)),
          end: _iso(lastOf(now.year, now.month)),
        );
      case 'LAST_MONTH':
        final d = DateTime(now.year, now.month - 1, 1);
        return (
          start: _iso(firstOf(d.year, d.month)),
          end: _iso(lastOf(d.year, d.month)),
        );
      case 'LAST_3_MONTHS':
        final d = DateTime(now.year, now.month - 2, 1);
        return (
          start: _iso(firstOf(d.year, d.month)),
          end: _iso(lastOf(now.year, now.month)),
        );
      case 'THIS_YEAR':
        return (
          start: '${now.year}-01-01',
          end: _iso(lastOf(now.year, now.month)),
        );
      default:
        return (
          start: _customFrom != null ? _iso(_customFrom!) : '',
          end: _customTo != null ? _iso(_customTo!) : '',
        );
    }
  }

  Map<String, dynamic> _queryBody(List<String> types) {
    final r = _resolveRange(_period);
    return {
      'period': _period,
      if (_period == 'CUSTOM') 'startDate': r.start,
      if (_period == 'CUSTOM') 'endDate': r.end,
      'types': types,
    };
  }

  String _buildFilename(
    String format,
    List<String> types,
    ({String start, String end}) r,
  ) {
    final ext = format == 'EXCEL'
        ? 'xlsx'
        : format == 'JSON'
        ? 'json'
        : 'csv';
    final rangePart = '${r.start}_${r.end}';
    if (format != 'EXCEL' && types.length > 1) {
      return 'groo-export-$rangePart.zip';
    }
    final namePart = types.length == 1 ? _slugOf(types.first) : 'export';
    return 'porest-$namePart-$rangePart.$ext';
  }

  String _mimeType(String format, List<String> types) {
    if (format != 'EXCEL' && types.length > 1) return 'application/zip';
    switch (format) {
      case 'EXCEL':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'JSON':
        return 'application/json';
      default:
        return 'text/csv';
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    if (_customInvalid) return;
    setState(() {
      _countsLoading = true;
      _countsFailed = false;
    });
    try {
      final repo = await ref.read(exportRepositoryProvider.future);
      final list = await repo.counts(
        _queryBody(_types.map((t) => t.name).toList()),
      );
      if (!mounted) return;
      setState(() {
        _counts = {for (final c in list) c.type: c.count};
        _countsLoading = false;
      });
    } catch (_) {
      // 전역 토스트 대신 자리에서 알린다 — 묶음 아래 오류 글 + [다시 시도](I-05 42)
      if (mounted) {
        setState(() {
          _countsLoading = false;
          _countsFailed = true;
        });
      }
    }
  }

  void _changePeriod(String p) {
    setState(() => _period = p);
    _loadCounts();
  }

  void _toggleType(String name) {
    setState(() {
      _selected = _selected.contains(name)
          ? (_selected.where((x) => x != name).toList())
          : [..._selected, name];
    });
  }

  Future<void> _runPreview() async {
    if (_selected.isEmpty || _customInvalid) return;
    setState(() {
      _previewing = true;
      _previewFailed = false;
    });
    try {
      final repo = await ref.read(exportRepositoryProvider.future);
      final tables = await repo.preview(_queryBody(_orderedSelected()));
      if (!mounted) return;
      setState(() {
        _preview = tables;
        _previewTab = tables.isNotEmpty ? tables.first.type : null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _previewKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: PDuration.d4);
        }
      });
    } on ApiException {
      // 서버 글은 내지 않는다(요청은 silent) — 미리보기 자리에 고정 글 + [다시 시도]
      if (mounted) setState(() => _previewFailed = true);
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _runExport() async {
    if (_selected.isEmpty || _customInvalid) return;
    final l = AppLocalizations.of(context);
    setState(() => _downloading = true);
    try {
      final repo = await ref.read(exportRepositoryProvider.future);
      final r = _resolveRange(_period);
      final types = _orderedSelected();
      final body = {..._queryBody(types), 'format': _format, 'mask': _mask};
      final filename = _buildFilename(_format, types, r);
      final file = await repo.download(body: body, filename: filename);
      try {
        await Share.shareXFiles([
          XFile(file.path, name: filename, mimeType: _mimeType(_format, types)),
        ], text: l.exportShareText(r.start, r.end));
      } finally {
        // 금융 데이터 평문 임시파일 — 공유 완료 후 즉시 삭제(복구 방지).
        if (await file.exists()) await file.delete();
      }
      if (mounted) {
        PSnackbar.maybeOf(context)?.show(message: l.exportSuccess);
      }
    } on ExportStalledException {
      // 받은 바이트가 10초 동안 늘지 않으면 끊는다(I-05 47) — 옛 길의 오류 띠 + [다시 시도]
      if (mounted) _failBar(l.exportStalled);
    } on ApiException {
      // 서버가 준 글은 그대로 내지 않는다(Writing 오류) — 화면 글 + [다시 시도]
      if (mounted) _failBar(l.exportFailed);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _failBar(String message) {
    // 액션 있는 critical 띠 — 시간은 ds 규칙(6초), 8초 · replace 는 쓰지 않는다(D6).
    PSnackbar.maybeOf(context)?.show(
      message: message,
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(
        label: AppLocalizations.of(context).actionRetry,
        onPressed: _runExport,
      ),
    );
  }

  /// 선언 순서 정렬 (백엔드와 일관).
  List<String> _orderedSelected() => _types
      .where((t) => _selected.contains(t.name))
      .map((t) => t.name)
      .toList();

  /// 고른 개수 — 부모 체크의 세 상태(true 모두 · null 일부 · false 없음).
  bool? get _parentChecked => _selected.length == _types.length
      ? true
      : _selected.isEmpty
      ? false
      : null;

  void _toggleAll(bool all) => setState(
    () => _selected = all ? _types.map((t) => t.name).toList() : <String>[],
  );

  Future<void> _pickRange() async {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final picked = await PBottomSheet.show<PDateRange>(
      context,
      builder: (_) {
        PDateRange? draft = PDateRange(start: _customFrom, end: _customTo);
        return StatefulBuilder(
          builder: (context, setSheet) => PBottomSheetContent(
            title: l.exportPeriodTitle,
            closeLabel: l.actionClose,
            flushBody: true,
            body: SizedBox(
              height: PDatePicker.sheetBodyHeight(context),
              child: PDatePicker.range(
                labels: PDatePickerLabels.of(context),
                semanticLabel: l.exportPeriodTitle,
                visibleRange: PDateVisibleRange.continuous,
                presets: const [
                  PDatePreset.thisWeek,
                  PDatePreset.thisMonth,
                  PDatePreset.lastMonth,
                  PDatePreset.last3Months,
                  PDatePreset.thisYear,
                ],
                value: draft,
                today: now,
                onChanged: (v) => setSheet(() => draft = v),
              ),
            ),
            footer: [
              PButton(
                label: l.actionReset,
                size: PButtonSize.large,
                variant: PButtonVariant.neutralWeak,
                onPressed: () => setSheet(() => draft = null),
              ),
              PButton(
                label: l.actionDone,
                size: PButtonSize.large,
                onPressed: draft?.end == null
                    ? null
                    : () => PBottomSheet.of(context).close(draft),
              ),
            ],
          ),
        );
      },
    );
    if (picked?.start == null || picked?.end == null || !mounted) return;
    setState(() {
      _customFrom = picked!.start;
      _customTo = picked.end;
    });
    _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      // 머리 = ds 상단 바(← + 제목) — I-05 39
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.exportTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: PScreenBandBody(
        child: Column(
          children: [
            // 내보내기 · 가져오기 전환 = ds Tabs Line fill(1차) — 상단 바 바로 아래(I-05 40)
            PTabs<String>(
              value: _mode,
              onChanged: (v) => setState(() => _mode = v),
              semanticLabel: l.exportTabsLabel,
              items: [
                PTab(value: 'export', label: l.exportTab),
                PTab(value: 'import', label: l.importTab),
              ],
            ),
            Expanded(
              child: _mode == 'import'
                  ? const ImportView()
                  : Column(
                      children: [
                        Expanded(child: _exportList(l)),
                        _actions(l),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static const _gutter = EdgeInsets.symmetric(
    horizontal: PSpacing.globalGutter,
  );

  Widget _exportList(AppLocalizations l) {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.only(bottom: PSpacing.x6),
      children: [
        // 탭 바로 아래 첫 구역도 구역 제목 + 위 24(웹과 같은 값)
        _section(l.exportPeriodTitle, _periodBody(l)),
        _section(
          l.exportTypesTitle(_selected.length),
          _typesBody(l),
          note: l.exportTypesDesc,
        ),
        _section(l.exportFormatTitle, _formatBody(l)),
        const SizedBox(height: PSpacing.x6),
        Padding(
          padding: _gutter,
          child: PCheckbox(
            label: l.exportMaskLabel,
            checked: _mask,
            onChanged: (v) => setState(() => _mask = v),
          ),
        ),
        if (_previewFailed) ...[
          const SizedBox(height: PSpacing.x6),
          Padding(
            padding: _gutter,
            child: PField(
              invalid: true,
              errorMessage: l.exportPreviewFailed,
              child: const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: _gutter,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: PButton(
                label: l.actionRetry,
                variant: PButtonVariant.ghost,
                size: PButtonSize.small,
                onPressed: _runPreview,
              ),
            ),
          ),
        ] else if (_preview != null) ...[
          const SizedBox(height: PSpacing.x6),
          KeyedSubtree(key: _previewKey, child: _previewBody(l)),
        ],
      ],
    );
  }

  /// 구역 — 구역 제목(List Header boldSolid) + 본문. 구역 사이는 위 24(DESIGN "화면을 나누는 법" ①).
  Widget _section(
    String title,
    Widget body, {
    String? note,
    bool first = false,
  }) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!first) const SizedBox(height: PSpacing.x6),
        PListHeader(title: title, variant: PListHeaderVariant.boldSolid),
        if (note != null)
          Padding(
            padding: _gutter,
            child: Text(
              keepAll(note),
              semanticsLabel: note,
              style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
            ),
          ),
        if (note != null) const SizedBox(height: PSpacing.x2),
        body,
      ],
    );
  }

  // ── 기간 ────────────────────────────────────────────────

  Widget _periodBody(AppLocalizations l) {
    final today = DateTime.now();
    return Padding(
      padding: _gutter,
      child: PRadioSelectBoxGroup<String>(
        semanticLabel: l.exportPeriodTitle,
        value: _period,
        onChanged: _changePeriod,
        // 폰은 1열 가로형(Q5 5B) — 날짜 범위가 한 줄로 읽힌다
        columns: 1,
        children: [
          for (final p in _periods)
            PRadioSelectBox<String>(
              value: p.value,
              label: _periodLabel(l, p.value),
              description: p.value == 'CUSTOM'
                  ? l.expPeriodCustom
                  : _rangeText(_resolveRange(p.value)),
              footer: p.value == 'CUSTOM' ? _customBody(l, today) : null,
            ),
        ],
      ),
    );
  }

  String _rangeText(({String start, String end}) r) =>
      '${_krLabel(r.start)}${rangeSeparator()}${_krLabel(r.end)}';

  Widget _customBody(AppLocalizations l, DateTime today) {
    return PField(
      invalid: _customInvalid,
      errorMessage: _customInvalid ? l.exportDateRangeError : null,
      child: PInputButton(
        semanticLabel: l.exportPeriodTitle,
        placeholder: l.exportRangePlaceholder,
        prefixIcon: LucideIcons.calendar,
        value: formatRangeValue(
          PDateRange(start: _customFrom, end: _customTo),
          today,
        ),
        onPressed: _pickRange,
      ),
    );
  }

  // ── 데이터 종류 ──────────────────────────────────────────

  Widget _typesBody(AppLocalizations l) {
    final group = PListCheckGroup(
      semanticLabel: l.exportTypesTitle(_selected.length),
      children: [
        PListCheckItem(
          title: l.exportSelectAll,
          checked: _parentChecked,
          markPosition: PListMarkPosition.suffix,
          onChanged: _toggleAll,
        ),
        const PListDivider(),
        for (final t in _types)
          PListCheckItem(
            title: _typeLabel(l, t.name),
            // 앞 = 아이콘 22(list.yaml icon) — 줄이 22 · fg-neutral 로 입힌다
            prefix: Icon(t.icon),
            markPosition: PListMarkPosition.suffix,
            checked: _selected.contains(t.name),
            onChanged: (_) => _toggleType(t.name),
            // 뒤 값 = 개수 — 불러오는 중이면 글 자리 Skeleton, 실패하면 비운다
            suffixValue: _countsFailed
                ? null
                : _counts.containsKey(t.slug)
                ? Text(l.exportCount(_counts[t.slug]!))
                : _countsLoading
                ? PSkeleton.text(PTypography.t5, width: PSpacing.x10)
                : null,
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        group,
        if (_countsFailed) ...[
          Padding(
            padding: _gutter,
            child: PField(
              invalid: true,
              errorMessage: l.exportCountsFailed,
              child: const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: _gutter,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: PButton(
                label: l.actionRetry,
                variant: PButtonVariant.ghost,
                size: PButtonSize.small,
                onPressed: _loadCounts,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── 파일 형식 ────────────────────────────────────────────

  Widget _formatBody(AppLocalizations l) {
    return Padding(
      padding: _gutter,
      child: PRadioSelectBoxGroup<String>(
        semanticLabel: l.exportFormatTitle,
        value: _format,
        onChanged: (v) => setState(() => _format = v),
        columns: 1,
        children: [
          for (final f in _formats)
            PRadioSelectBox<String>(
              value: f.value,
              prefix: Icon(f.icon),
              label: '${f.label} (${f.ext})',
              description: _formatDesc(l, f.value),
            ),
        ],
      ),
    );
  }

  // ── 바닥 버튼 ────────────────────────────────────────────

  Widget _actions(AppLocalizations l) {
    final disabled = _selected.isEmpty || _customInvalid;
    return SafeArea(
      top: false,
      // 화면 바닥 짝 — 좌우 24 · 위 12 · 아래 24, 안전 영역(제스처 막대) 위(I-05 27 · 45)
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.globalGutter,
          PSpacing.x3,
          PSpacing.globalGutter,
          PSpacing.x6,
        ),
        child: PResponsivePair(
          secondary: PButton(
            label: l.exportPreview,
            variant: PButtonVariant.neutralWeak,
            size: PButtonSize.large,
            loading: _previewing,
            onPressed: disabled ? null : _runPreview,
          ),
          primary: PButton(
            label: l.exportRun,
            variant: PButtonVariant.neutralSolid,
            size: PButtonSize.large,
            loading: _downloading,
            onPressed: disabled ? null : _runExport,
          ),
        ),
      ),
    );
  }

  // ── 미리보기 — 폰이라 표가 아니라 List 줄(table.md "폰이라 List 줄로") ──

  /// 금액 열 — 머리 이름이 금액인 열(R13 줄 금액으로 뒤에 둔다). 없으면 -1.
  int _amountColumn(List<String> headers) => headers.indexWhere(
    (h) => h.contains('금액') || h.toLowerCase().contains('amount'),
  );

  Widget _previewBody(AppLocalizations l) {
    final c = context.colors;
    final tables = _preview!;
    final active = tables.firstWhere(
      (x) => x.type == _previewTab,
      orElse: () => tables.isNotEmpty
          ? tables.first
          : const ExportPreviewTable(
              type: '',
              displayName: '',
              headers: [],
              rows: [],
              totalCount: 0,
            ),
    );
    final amountAt = _amountColumn(active.headers);
    // 합계 = 고른 종류의 건수 합(빈 종류는 0) — 미리보기 표 건수가 아니다. 웹과 같은 셈
    final total = _selected.fold<int>(
      0,
      (a, name) => a + (_counts[_slugOf(name)] ?? 0),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PListHeader(
          title: l.exportPreview,
          variant: PListHeaderVariant.boldSolid,
        ),
        if (tables.length > 1)
          PTabs<String>(
            value: active.type,
            layout: PTabsLayout.hug,
            semanticLabel: l.exportPreviewTabsLabel,
            onChanged: (v) => setState(() => _previewTab = v),
            items: [
              for (final tb in tables)
                PTab(value: tb.type, label: tb.displayName),
            ],
          ),
        if (active.rows.isEmpty)
          PResultSection(
            kind: PResultKind.empty,
            size: PResultSize.medium,
            icon: LucideIcons.fileText,
            title: l.exportPreviewEmptyTitle,
            description: l.exportEmpty,
          )
        else
          PList(
            semanticLabel: l.exportPreview,
            children: [
              for (final row in active.rows)
                PListItem(
                  title: row.isEmpty ? '' : row.first,
                  detailChild: PTagGroup(
                    items: [
                      for (var i = 1; i < row.length; i++)
                        if (i != amountAt && row[i].isNotEmpty) PTag(row[i]),
                    ],
                  ),
                  // 뒤 금액(R13 줄 금액) — 금액 열이 있을 때
                  suffix:
                      amountAt > 0 &&
                          amountAt < row.length &&
                          row[amountAt].isNotEmpty
                      ? PListValue.amount(row[amountAt])
                      : null,
                ),
            ],
          ),
        Padding(
          padding: _gutter,
          child: PText(
            l.exportPreviewFooter(active.rows.length, _selected.length, total),
            style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
          ),
        ),
      ],
    );
  }
}
