import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/import/data/import_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/attachment_input/p_attachment_input.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';
import 'package:groo_damda_app/shared/ds/select_box/p_select_box.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/widgets/p_busy_scrim.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 서버 한도(`application.yml` multipart 10MB) — 고르는 순간 미리 검사한다(서버도 같은 한도로 검사한다).
const int kImportMaxBytes = 10 * 1024 * 1024;

typedef _FieldMeta = ({
  String key,
  String Function(AppLocalizations) label,
  bool required,
});

/// 서버 `ImportSource` enum 이름 그대로 — 화면 문구가 아니라 요청 값이다. 바꾸면 400.
@visibleForTesting
const List<String> importSources = [
  'POREST',
  'EASYBUDGET',
  'BANKSALAD',
  'TOSS',
  'CUSTOM',
];

({String title, String desc}) _sourceText(AppLocalizations l, String v) =>
    switch (v) {
      'POREST' => (title: l.importSourceGroo, desc: l.importSourceGrooDesc),
      'EASYBUDGET' => (
        title: l.importSourceEasybudget,
        desc: l.importSourceEasybudgetDesc,
      ),
      'BANKSALAD' => (
        title: l.importSourceBanksalad,
        desc: l.importSourceBanksaladDesc,
      ),
      'TOSS' => (title: l.importSourceToss, desc: l.importSourceTossDesc),
      _ => (title: l.importSourceCustom, desc: l.importSourceCustomDesc),
    };

const List<_FieldMeta> _fields = [
  (key: 'DATE', label: _fDate, required: true),
  (key: 'AMOUNT', label: _fAmount, required: true),
  (key: 'TYPE', label: _fType, required: false),
  (key: 'CATEGORY', label: _fCategory, required: false),
  (key: 'ASSET', label: _fAsset, required: false),
  (key: 'MEMO', label: _fMemo, required: false),
  // 소스에 따라 있을 수도 없을 수도 있는 열 — 자동매핑이 잡으면 채워지고 없으면 '사용 안 함'.
  (key: 'SUBCATEGORY', label: _fSubcategory, required: false),
  (key: 'TIME', label: _fTime, required: false),
  (key: 'MERCHANT', label: _fMerchant, required: false),
  (key: 'PAYMENT_METHOD', label: _fPaymentMethod, required: false),
];

String _fSubcategory(AppLocalizations l) => l.importFieldSubcategory;
String _fTime(AppLocalizations l) => l.importFieldTime;
String _fMerchant(AppLocalizations l) => l.importFieldMerchant;
String _fPaymentMethod(AppLocalizations l) => l.importFieldPaymentMethod;
String _fDate(AppLocalizations l) => l.importFieldDate;
String _fAmount(AppLocalizations l) => l.importFieldAmount;
String _fType(AppLocalizations l) => l.importFieldType;
String _fCategory(AppLocalizations l) => l.importFieldCategory;
String _fAsset(AppLocalizations l) => l.importFieldAsset;
String _fMemo(AppLocalizations l) => l.importFieldMemo;

/// 서버 사유 코드 → 화면 글. 모르는 코드는 코드를 흘리지 않고 기본 글로(웹 `failReasonKey` 와 같다).
@visibleForTesting
String importFailReasonText(AppLocalizations l, String reason) =>
    switch (reason) {
      'date' => l.importFailReasonDate,
      'amount' => l.importFailReasonAmount,
      'type' => l.importFailReasonType,
      'parentHasTx' => l.importFailReasonParentHasTx,
      'resolve' => l.importFailReasonResolve,
      'save' => l.importFailReasonSave,
      _ => l.importFailReasonUnknown,
    };

enum _Step { upload, mapping, done }

/// 가져오기 고르기 창 — 확장자를 CSV · Excel 로 좁힌다(앱은 카메라 · 갤러리가 없는 파일 하나 고르기).
Future<List<PAttachmentPicked>> _pickImportFiles(
  PAttachmentSource source,
  int limit,
) async {
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['csv', 'xlsx', 'xls'],
  );
  if (picked == null) return const [];
  return [
    for (final f in picked.files)
      PAttachmentPicked(name: f.name, size: f.size, path: f.path),
  ];
}

/// 데이터 가져오기 마법사 — 소스선택 → 파일업로드(analyze) → 열매핑·미리보기·옵션(execute) → 완료.
/// ExportScreen 탭의 '가져오기' 모드 본문.
class ImportView extends ConsumerStatefulWidget {
  const ImportView({super.key, this.pickFiles = _pickImportFiles});

  /// 고르기 창 — 시험에서 바꾼다.
  @visibleForTesting
  final PAttachmentPickFiles pickFiles;

  @override
  ConsumerState<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends ConsumerState<ImportView> {
  _Step _step = _Step.upload;
  String _source = 'POREST';
  File? _file;
  List<PAttachmentEntry> _entries = const [];
  String? _fileError;
  ImportAnalyzeResult? _analysis;
  Map<String, int> _mapping = {};
  bool _dupSkip = true;
  bool _autoCat = true;
  bool _executing = false;
  ImportExecuteResult? _result;

  bool get _canExecute =>
      _mapping.containsKey('DATE') &&
      (_mapping.containsKey('AMOUNT') ||
          _mapping.containsKey('AMOUNT_OUT') ||
          _mapping.containsKey('AMOUNT_IN'));

  void _onAccept(List<PAttachmentEntry> added) {
    final entry = added.first;
    if (entry.path == null) return;
    setState(() {
      _file = File(entry.path!);
      _fileError = null;
      _entries = [entry.copyWith(status: PAttachmentStatus.uploading)];
    });
    _analyze();
  }

  void _onReject(List<PAttachmentRejection> rejected) {
    final l = AppLocalizations.of(context);
    final tooLarge = rejected.any(
      (r) => r.codes.contains(PAttachmentRejectionCode.fileTooLarge),
    );
    // 거절은 칸 아래 오류 글 — 전역 토스트가 아니다
    setState(
      () => _fileError = tooLarge ? l.importFileTooLarge : l.importFileInvalid,
    );
  }

  Future<void> _analyze() async {
    try {
      final repo = await ref.read(importRepositoryProvider.future);
      final res = await repo.analyze(_file!, _source);
      if (!mounted) return;
      setState(() {
        _analysis = res;
        _mapping = Map<String, int>.from(res.suggestedMapping);
        _step = _Step.mapping;
        _entries = const [];
      });
    } on ApiException {
      if (mounted) {
        setState(() {
          _entries = [
            for (final e in _entries)
              e.copyWith(status: PAttachmentStatus.error),
          ];
        });
      }
    }
  }

  Future<void> _runImport() async {
    if (_file == null || !_canExecute) return;
    final l = AppLocalizations.of(context);
    setState(() => _executing = true);
    // 확정하는 동안 화면 전체 딤 + 흰 원 40 (I-05 49) — 37 과 같은 덮개
    final scrim = PBusyScrim.show(context, label: l.importBusy);
    try {
      final repo = await ref.read(importRepositoryProvider.future);
      final res = await repo.execute(
        _file!,
        source: _source,
        mapping: _mapping,
        dupSkip: _dupSkip,
        autoCat: _autoCat,
      );
      // 한 번에 수십 건이 들어온다 — 가계부·홈·통계가 전부 달라진다.
      // 어느 달로 들어갔는지는 파일을 열기 전엔 알 수 없다 — 월 목록은 base 로 민다.
      ref.invalidate(monthExpensesProvider);
      invalidateAfterExpenseChange(ref);
      if (!mounted) return;
      setState(() {
        _result = res;
        _step = _Step.done;
      });
    } on ApiException catch (e) {
      // 응답을 못 받았다 — 가져왔을 수 있다(거래 수십 건). [다시 시도] 를 주면 두 번 들어간다 — 다시 받고 확인을
      // 부탁한다(검수 M3)
      if (isUnconfirmedSave(e)) {
        ref.invalidate(monthExpensesProvider);
        invalidateAfterExpenseChange(ref);
        if (mounted) {
          PSnackbar.maybeOf(
            context,
          )?.show(message: l.saveUnconfirmed, tone: PSnackbarTone.critical);
        }
        return;
      }
      // 서버 글은 내지 않는다(요청은 silent) — 흐름은 멈추고 고정 글 한 문장 + [다시 시도].
      if (mounted) {
        PSnackbar.maybeOf(context)?.show(
          message: l.importExecuteFailed,
          tone: PSnackbarTone.critical,
          action: PSnackbarAction(label: l.actionRetry, onPressed: _runImport),
        );
      }
    } finally {
      scrim.hide();
      if (mounted) setState(() => _executing = false);
    }
  }

  void _reset() {
    setState(() {
      _step = _Step.upload;
      _file = null;
      _entries = const [];
      _fileError = null;
      _analysis = null;
      _mapping = {};
      _result = null;
    });
  }

  static const _gutter = EdgeInsets.symmetric(
    horizontal: PSpacing.globalGutter,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final Widget content = switch (_step) {
      _Step.upload => _uploadStep(l),
      _Step.mapping when _analysis != null => _mappingStep(l, _analysis!),
      _Step.done when _result != null => _doneStep(l, _result!),
      _ => const SizedBox.shrink(),
    };
    return content;
  }

  // ── 단계 머리 — "2 / 3단계" + 단계 이름 + 한 줄 설명 (Q6 6B) ──

  Widget _stepHead(AppLocalizations l, int n, String name, String desc) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x6,
        PSpacing.globalGutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.importStepMeta(n, 3),
            style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
          ),
          const SizedBox(height: PSpacing.x1),
          Text(
            name,
            style: PTypography.t5.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: PSpacing.x1),
          Text(
            keepAll(desc),
            semanticsLabel: desc,
            style: PTypography.t5.copyWith(color: c.fgNeutralMuted),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    Widget body, {
    bool first = false,
    PListHeaderVariant variant = PListHeaderVariant.boldSolid,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: first ? PSpacing.x2 : PSpacing.x6),
      PListHeader(title: title, variant: variant),
      body,
    ],
  );

  // ── 1. 업로드 ────────────────────────────────────────────

  Widget _uploadStep(AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.only(bottom: PSpacing.x6),
      children: [
        _stepHead(l, 1, l.importStepUpload, l.importStepUploadDesc),
        _section(
          l.importSourceTitle,
          Padding(
            padding: _gutter,
            child: PRadioSelectBoxGroup<String>(
              semanticLabel: l.importSourceTitle,
              value: _source,
              onChanged: (v) => setState(() => _source = v),
              columns: 1,
              children: [
                for (final s in importSources)
                  PRadioSelectBox<String>(
                    value: s,
                    label: _sourceText(l, s).title,
                    description: _sourceText(l, s).desc,
                  ),
              ],
            ),
          ),
          first: true,
        ),
        _section(
          l.importUploadTitle,
          Padding(
            padding: _gutter,
            child: PField(
              description: l.importUploadDesc,
              invalid: _fileError != null,
              errorMessage: _fileError,
              child: PAttachmentInput(
                layout: PAttachmentLayout.dropzone,
                semanticLabel: l.importUploadTitle,
                accept: '.csv,.xlsx,.xls',
                maxFiles: 1,
                maxFileSize: kImportMaxBytes,
                entries: _entries,
                pickFiles: widget.pickFiles,
                onFilesAccept: _onAccept,
                onFilesReject: _onReject,
                onRetry: (_) => _analyze(),
                onRemove: (_) => setState(() {
                  _entries = const [];
                  _file = null;
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: PSpacing.x6),
        Padding(
          padding: _gutter,
          child: PCallout(description: l.importNotice),
        ),
      ],
    );
  }

  // ── 2. 매핑 ──────────────────────────────────────────────

  Widget _mappingStep(AppLocalizations l, ImportAnalyzeResult a) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: PSpacing.x6),
            children: [
              _stepHead(l, 2, l.importStepMapping, l.importStepMappingDesc),
              // 실행하면 반드시 실패할 행을 미리 알린다 — 넣고 나서 실패 숫자만 보면 원인을 알 수 없다.
              if (a.blockedParents.isNotEmpty) ...[
                const SizedBox(height: PSpacing.x4),
                Padding(
                  padding: _gutter,
                  child: PCallout(
                    tone: PCalloutTone.critical,
                    title: l.importBlockedTitle(a.blockedParents.join(', ')),
                    description: l.importBlockedDesc,
                  ),
                ),
              ],
              _section(
                l.importFileTitle,
                PList(
                  semanticLabel: l.importFileTitle,
                  children: [
                    PListItem(
                      // 앞 = 아이콘 22(list.yaml icon) — 회색 타일이 아니다
                      prefix: const Icon(LucideIcons.fileSpreadsheet),
                      title: a.fileName,
                      detail: l.importRowsDetected(a.totalRows, a.validRows),
                      suffix: PListAction(
                        child: PButton(
                          label: l.importChange,
                          variant: PButtonVariant.ghost,
                          size: PButtonSize.small,
                          onPressed: _reset,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _section(
                l.importMapTitle,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: _gutter,
                      child: Text(
                        keepAll(l.importMapDesc),
                        semanticsLabel: l.importMapDesc,
                        style: PTypography.t4.copyWith(
                          color: context.colors.fgNeutralSubtle,
                        ),
                      ),
                    ),
                    const SizedBox(height: PSpacing.x3),
                    _mapFields(l, a),
                  ],
                ),
              ),
              _section(l.exportPreview, _previewList(l, a)),
              _section(
                l.importOptionsTitle,
                PListCheckGroup(
                  semanticLabel: l.importOptionsTitle,
                  children: [
                    PListCheckItem(
                      title: l.importOptDupSkip,
                      detail: l.importOptDupSkipDesc(a.duplicateCount),
                      checked: _dupSkip,
                      onChanged: (v) => setState(() => _dupSkip = v),
                    ),
                    PListCheckItem(
                      title: l.importOptAutoCat,
                      detail: l.importOptAutoCatDesc,
                      checked: _autoCat,
                      onChanged: (v) => setState(() => _autoCat = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _bottomBar(
          PResponsivePair(
            secondary: PButton(
              label: l.importPrev,
              variant: PButtonVariant.neutralWeak,
              size: PButtonSize.large,
              onPressed: _executing ? null : _reset,
            ),
            primary: PButton(
              label: l.importDoImport(
                _dupSkip ? a.validRows - a.duplicateCount : a.validRows,
              ),
              variant: PButtonVariant.neutralSolid,
              size: PButtonSize.large,
              onPressed: _canExecute && !_executing ? _runImport : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapFields(AppLocalizations l, ImportAnalyzeResult a) {
    const none = -1;
    final items = [
      PSelectGroup<int>(
        items: [
          PSelectItem<int>(value: none, label: l.importNotMapped),
          for (final col in a.columns)
            PSelectItem<int>(
              value: col.index,
              label: col.name.isEmpty ? '#${col.index + 1}' : col.name,
            ),
        ],
      ),
    ];
    return Padding(
      padding: _gutter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x4,
        children: [
          for (final f in _fields)
            PField(
              label: f.label(l),
              // 필수가 둘뿐이라 필수 칸에만 점(field.md 2/3 규칙)
              required: f.required,
              indicator: f.required
                  ? PFieldIndicator.required
                  : PFieldIndicator.none,
              child: PSelect<int>(
                groups: items,
                value: _mapping[f.key] ?? none,
                placeholder: l.importNotMapped,
                onChanged: (v) => setState(() {
                  if (v == none) {
                    _mapping.remove(f.key);
                  } else {
                    _mapping[f.key] = v;
                  }
                }),
              ),
            ),
        ],
      ),
    );
  }

  /// 미리보기 — 폰이라 표가 아니라 List 줄: 제목(메모) + 설명 Tag Group(나머지 열) + 뒤 금액. 오류 · 중복은 상태 Badge.
  Widget _previewList(AppLocalizations l, ImportAnalyzeResult a) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: _gutter,
          child: Text(
            l.importPreviewDesc(a.duplicateCount),
            style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
          ),
        ),
        PList(
          semanticLabel: l.exportPreview,
          children: [
            for (final r in a.preview)
              PListItem(
                title: (r.memo != null && r.memo!.isNotEmpty)
                    ? r.memo!
                    : (r.category ?? '—'),
                detailChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: PSpacing.x1,
                  children: [
                    if (r.error != null || r.duplicate)
                      PBadgeGroup(
                        children: [
                          if (r.error != null)
                            PBadge(
                              label: l.importBadgeError,
                              tone: PBadgeTone.critical,
                            ),
                          if (r.duplicate) PBadge(label: l.importBadgeDup),
                        ],
                      ),
                    PTagGroup(
                      items: [
                        PTag(
                          r.date != null && r.date!.length >= 10
                              ? r.date!.substring(0, 10)
                              : '—',
                        ),
                        if (r.type != null)
                          PTag(
                            r.type == 'INCOME'
                                ? l.importIncome
                                : l.importExpense,
                          ),
                        if (r.category != null && r.memo != null)
                          PTag(r.category!),
                        if (r.asset != null) PTag(r.asset!),
                      ],
                    ),
                  ],
                ),
                suffix: r.amount != null
                    ? PListValue.amount(_fmt(r.amount!))
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  // ── 3. 완료 ──────────────────────────────────────────────

  Widget _doneStep(AppLocalizations l, ImportExecuteResult r) {
    final c = context.colors;
    final capped = r.failuresTruncated || r.failed > r.failures.length;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: PSpacing.x6),
                // 제목 = "N건을 가져왔어요"(result-section.md 예), 설명 = 건너뜀 · 못 가져옴, 둘째 = 글 버튼(R16)
                PResultSection(
                  kind: PResultKind.done,
                  size: PResultSize.large,
                  title: l.importDoneCount(r.imported),
                  description: l.importDoneDetail(r.skipped, r.failed),
                  secondaryAction: PResultAction(
                    label: l.importAnother,
                    onPressed: _reset,
                  ),
                ),
                // 만든 카테고리 — 미리보기에서 본 것과 실제가 같은지 확인시킨다(목록 제목 R5 + 줄)
                if (r.createdCategories.isNotEmpty)
                  _section(
                    l.importCreatedCatTitle(r.createdCategoryCount),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PList(
                          semanticLabel: l.importCreatedCatTitle(
                            r.createdCategoryCount,
                          ),
                          children: [
                            for (final n in r.createdCategories)
                              PListItem(title: n),
                          ],
                        ),
                        if (r.createdCategoryCount > r.createdCategories.length)
                          Padding(
                            padding: _gutter,
                            child: Text(
                              l.importNewCatMore(
                                r.createdCategoryCount -
                                    r.createdCategories.length,
                              ),
                              style: PTypography.t4.copyWith(
                                color: c.fgNeutralSubtle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    variant: PListHeaderVariant.mediumWeak,
                  ),
                // 못 넣은 행 — 줄 번호 + 사유, 잘렸으면 그 사실을 말한다
                if (r.failures.isNotEmpty)
                  _section(
                    l.importFailuresTitle(r.failed),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PList(
                          semanticLabel: l.importFailuresTitle(r.failed),
                          children: [
                            for (final f in r.failures)
                              PListItem(
                                title: l.importFailureLine(f.lineNo),
                                detail: importFailReasonText(l, f.reason),
                              ),
                          ],
                        ),
                        if (capped)
                          Padding(
                            padding: _gutter,
                            child: Text(
                              l.importFailuresCapped(
                                r.failed,
                                r.failures.length,
                              ),
                              style: PTypography.t4.copyWith(
                                color: c.fgNeutralSubtle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    variant: PListHeaderVariant.mediumWeak,
                  ),
                const SizedBox(height: PSpacing.x6),
              ],
            ),
          ),
        ),
        // 바닥 CTA 하나 — 좌우 24 · 위 12 · 아래 24, 안전 영역 위
        _bottomBar(
          SizedBox(
            width: double.infinity,
            child: PButton(
              label: l.importGoExpense,
              variant: PButtonVariant.neutralSolid,
              size: PButtonSize.large,
              onPressed: () => context.go('/expense?tab=expense'),
            ),
          ),
        ),
      ],
    );
  }

  /// 화면 바닥 줄 — 좌우 24 · 위 12 · 아래 24, 안전 영역 위(I-05 27 · 45).
  Widget _bottomBar(Widget child) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x3,
        PSpacing.globalGutter,
        PSpacing.x6,
      ),
      child: child,
    ),
  );

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
