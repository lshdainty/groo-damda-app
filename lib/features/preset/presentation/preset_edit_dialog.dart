import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/features/asset/domain/transfer_rules.dart';
import 'package:groo_damda_app/features/asset/presentation/transfer_account_fields.dart';
import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/core/format/amount_limits.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';
import 'package:groo_damda_app/shared/widgets/p_category_tile.dart';
import 'package:groo_damda_app/shared/widgets/p_checkbox.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import 'package:groo_damda_app/shared/widgets/p_select.dart';
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart';
import 'package:groo_damda_app/shared/widgets/p_tabs.dart';
import 'package:groo_damda_app/shared/widgets/p_text_input.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';

/// 웹 `PresetEditDialog` 미러 — 결제 수단 목록.
const _kPaymentMethodValues = <String>['CASH', 'CARD', 'TRANSFER', 'OTHER'];

String _payLabel(AppLocalizations l, String v) => switch (v) {
  'CASH' => l.expPayCash,
  'CARD' => l.expPayCard,
  'TRANSFER' => l.expPayTransfer,
  _ => l.expPayOther,
};

void showPresetEditDialog(BuildContext context, {ExpenseTemplate? edit}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.presetAdd : l.presetEditTitle,
    contentBuilder: (ctx, scrollCtrl) =>
        _Body(edit: edit, scrollController: scrollCtrl, controller: controller),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit == null ? l.presetSubmitAdd : l.actionSave,
    ),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    this.edit,
    required this.scrollController,
    required this.controller,
  });
  final ExpenseTemplate? edit;
  final ScrollController scrollController;
  final PSheetController controller;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _merchantCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late String _type;
  int? _categoryRowId;
  int? _assetRowId;

  /// 이체면 받는 자산. 지출·수입이면 null.
  int? _toAssetRowId;
  late final TextEditingController _feeCtrl;
  late final TextEditingController _interestCtrl;
  late String _paymentMethod;
  late bool _lockAmount;

  /// 고정 수입·지출 기본값 — "고정 금액"(금액을 저장해 둘지)과는 별개다. 통계의 분류 표식이다.
  late bool _isFixed;
  bool _submitting = false;
  bool _touched = false;

  bool get _isEdit => widget.edit != null;

  /// 이름 길이 상한 — 웹 `PRESET_NAME_MAX` · 카테고리와 같은 값(QA #54).
  static const _kNameMax = 12;

  String get _nameTrim => _nameCtrl.text.trim();

  /// 같은 이름 프리셋이 둘이면 불러오기 목록에서 어느 쪽인지 알 수 없다.
  /// 목록 캐시가 비어 있으면 못 잡는다 — 최종 게이트는 서버다.
  bool get _duplicate =>
      _nameTrim.isNotEmpty &&
      (ref.read(presetListProvider).value ?? const <ExpenseTemplate>[]).any(
        (p) =>
            p.templateName.trim() == _nameTrim && p.rowId != widget.edit?.rowId,
      );

  /// 카테고리 다이얼로그와 같은 규칙 — touched 전에는 에러를 안 보여 준다.
  String? get _nameError {
    if (!_touched) return null;
    final l = AppLocalizations.of(context);
    if (_nameTrim.length > _kNameMax) return l.nameTooLong(_kNameMax);
    if (_duplicate) return l.presetNameDuplicate;
    return null;
  }

  @override
  void initState() {
    super.initState();
    final t = widget.edit;
    _type = t?.expenseType ?? 'EXPENSE';
    _nameCtrl = TextEditingController(text: t?.templateName ?? '');
    _categoryRowId = t?.categoryRowId;
    _merchantCtrl = TextEditingController(text: t?.merchant ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _paymentMethod = t?.paymentMethod ?? '';
    _assetRowId = t?.assetRowId;
    _toAssetRowId = t?.toAssetRowId;
    _feeCtrl = TextEditingController(text: t?.fee != null ? '${t!.fee}' : '');
    _interestCtrl = TextEditingController(
      text: t?.interestAmount != null ? '${t!.interestAmount}' : '',
    );
    _lockAmount = (t?.lockAmount ?? 'N') == 'Y';
    _isFixed = t?.isFixed ?? false;
    _amountCtrl = TextEditingController(
      text: t?.amount != null ? '${t!.amount}' : '',
    );
    widget.controller.onSubmit = _submit;
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _merchantCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    _interestCtrl.dispose();
    super.dispose();
  }

  // 웹 canSave: name.trim().length > 0 && categoryRowId != null
  /// 금액은 선택이다 — 프리셋은 금액을 모르는 채로 양식만 저장하려고 만든 것이다.
  /// 고정 금액을 켰을 때만 값이 있어야 한다(불러오는 거래가 그 값을 그대로 받는다).
  bool get _canSubmit =>
      !_submitting &&
      _nameTrim.isNotEmpty &&
      // touched 전엔 막지 않는다 — 기존 장문 이름 프리셋의 다른 필드는 고칠 수 있어야 한다.
      (!_touched || (_nameTrim.length <= _kNameMax && !_duplicate)) &&
      // 이체는 카테고리가 없는 대신 양쪽 계좌가 있어야 성립한다 — 서버도 같은 규칙.
      (_isTransfer
          ? transferPartiesReady(_assetRowId, _toAssetRowId)
          : _effectiveCategoryRowId != null) &&
      (!_lockAmount || _amountValue > 0);

  bool get _isTransfer => _type == 'TRANSFER';

  /// 저장에 쓰는 카테고리 — **받기 전에는 읽어 온 값을 그대로 둔다**, 받았는데 목록에 없으면(지운 카테고리) 없는 것이다. 지운
  /// 카테고리 id 가 저장 본문으로 나가면 서버가 거절한다(저장하려면 다시 골라야 한다).
  int? get _effectiveCategoryRowId {
    final id = _categoryRowId;
    if (id == null) return null;
    final cats = ref.read(categoriesProvider).value;
    if (cats == null) return id;
    return cats.any((c) => c.rowId == id) ? id : null;
  }

  /// 이자 칸을 보이는가 — 규칙은 거래 시트와 한 벌이다(`transfer_rules.dart`).
  /// 이자는 **금액을 고정했을 때만** 받는다(사용자 결정 2026-09-15). 금액이 매달
  /// 다르면 이자도 매달 다르니, 박아 둔 이자는 불러올 때마다 틀린 값이 된다.
  /// 수수료는 그대로 둔다 — 계좌 짝의 성질이라 매번 같을 수 있다.
  ///
  /// 자산을 아직 못 받았으면 "받는 계좌가 대출인가" 를 모른다 — 읽어 온 이자가 있는 한 있는 것으로 본다. 모르는 채로 false 면 저장 본문이
  /// 이자를 null 로 실어 서버에 저장된 이자가 지워진다(자산이 오기 전에 저장을 누르면).
  bool get _showInterest {
    if (!_lockAmount || !_isTransfer) return false;
    final assets = ref.read(assetsProvider).value;
    if (assets == null) return _interestCtrl.text.isNotEmpty;
    return isLoanTarget(assets, _toAssetRowId);
  }

  int? _numOrNull(TextEditingController c) {
    final v = int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return v > 0 ? v : null;
  }

  int get _amountValue =>
      int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  /// 타입 변경 시 현재 카테고리가 새 타입과 안 맞으면 리셋 (웹 effect 정합).
  void _onTypeChanged(String next, List<ExpenseCategory> categories) {
    setState(() {
      _type = next;
      // 이체에는 카테고리가 없고, 지출·수입에는 이체 칸이 없다. 안 맞는 값이 남으면
      // 저장할 때 서버가 400 으로 거절한다.
      if (next == 'TRANSFER') {
        _categoryRowId = null;
      } else {
        _toAssetRowId = null;
        _feeCtrl.clear();
        _interestCtrl.clear();
        final id = _categoryRowId;
        if (id != null) {
          final cat = categories.byRowId(id);
          if (cat == null || cat.expenseType != next) {
            _categoryRowId = null;
          }
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(presetRepositoryProvider.future);
      final name = _nameTrim;
      final merchant = _merchantCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      // 웹: amount = lockAmount ? Number(amount||0) : undefined
      final amount = _lockAmount
          ? (int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                0)
          : null;
      if (_isEdit) {
        // 이 화면이 가진 칸(거래처·메모·결제 수단·계좌)은 **비운 상태 그대로** 실어야
        // 지워진다 — 서버가 프리셋 수정도 "키 없으면 유지" 로 읽으므로(desk-back #325)
        // 키를 빼면 '선택 안 함' 을 고르고 저장해도 옛 값이 그대로 남는다.
        //
        // 메모(description)는 종전엔 칸이 없어 **읽은 값을 그대로 되돌려 보냈다**(#326).
        // 이제 칸이 생겼으므로(D2) 지운 메모는 실제로 지워져야 한다.
        await repo.update(
          id: widget.edit!.rowId,
          templateName: name,
          categoryRowId: Patch.set(
            _isTransfer ? null : _effectiveCategoryRowId,
          ),
          assetRowId: Patch.set(_assetRowId),
          // 이체 칸도 이 시트의 칸이다 — 지출·수입으로 바꿔 저장하면 null 로 지워진다.
          toAssetRowId: Patch.set(_isTransfer ? _toAssetRowId : null),
          fee: Patch.set(_isTransfer ? _numOrNull(_feeCtrl) : null),
          interestAmount: Patch.set(
            _isTransfer && _showInterest ? _numOrNull(_interestCtrl) : null,
          ),
          expenseType: _type,
          amount: amount,
          description: Patch.set(desc.isEmpty ? null : desc),
          merchant: Patch.set(
            _isTransfer || merchant.isEmpty ? null : merchant,
          ),
          paymentMethod: Patch.set(
            _isTransfer || _paymentMethod.isEmpty ? null : _paymentMethod,
          ),
          lockAmount: _lockAmount,
          // 이체는 고정이 없다 — 켜 둔 채 이체로 바꿔도 싣지 않는다(서버도 꺼 버린다).
          isFixed: !_isTransfer && _isFixed,
        );
      } else {
        await repo.create(
          templateName: name,
          categoryRowId: _isTransfer ? null : _effectiveCategoryRowId,
          assetRowId: _assetRowId,
          toAssetRowId: _isTransfer ? _toAssetRowId : null,
          fee: _isTransfer ? _numOrNull(_feeCtrl) : null,
          interestAmount: _isTransfer && _showInterest
              ? _numOrNull(_interestCtrl)
              : null,
          expenseType: _type,
          amount: amount,
          description: desc.isEmpty ? null : desc,
          merchant: _isTransfer || merchant.isEmpty ? null : merchant,
          paymentMethod: _isTransfer || _paymentMethod.isEmpty
              ? null
              : _paymentMethod,
          lockAmount: _lockAmount,
          isFixed: !_isTransfer && _isFixed,
        );
      }
      ref.invalidate(presetListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException {
      if (!mounted) return;
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final assetsAsync = ref.watch(assetsProvider);
    final categories = categoriesAsync.value ?? const <ExpenseCategory>[];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return ListView(
      controller: widget.scrollController,
      // 시트 좌우 여백은 xl(24) — groo-design drawer.md 정합.
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.lg),
      children: [
        // ① 지출/수입 세그먼트
        PTabs<String>(
          value: _type,
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          items: [
            PTabItem(value: 'EXPENSE', label: l.expTypeExpense),
            PTabItem(value: 'INCOME', label: l.expTypeIncome),
            PTabItem(value: 'TRANSFER', label: l.expTypeTransfer),
          ],
          onChanged: (v) => _onTypeChanged(v, categories),
        ),
        const SizedBox(height: PSpace.lg),

        // ② 프리셋 이름
        _FieldLabel(l.presetName),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _nameCtrl,
          placeholder: l.expPresetNamePlaceholder,
          autofocus: true,
          onChanged: (_) => setState(() => _touched = true),
        ),
        const SizedBox(height: PSpace.x4),
        // 카운터 N/12 또는 에러 — 카테고리 다이얼로그와 같은 모양.
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _nameError ?? '${_nameTrim.length}/$_kNameMax',
            style: PTypo.micro.copyWith(
              color: _nameError != null ? t.statusDangerFg : t.fgTertiary,
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (_isTransfer) ...[
          // ③ 이체 — 규칙과 화면 모두 거래 시트·반복 설정과 한 벌이다.
          // 금액은 넘기지 않는다: 프리셋은 금액을 비워 두는 것이 정상 용도라
          // 견줄 금액이 없고, 그래서 이자 안내도 쪼개지 않는다.
          TransferAccountFields(
            assets: assetsAsync,
            fromAssetRowId: _assetRowId,
            toAssetRowId: _toAssetRowId,
            feeController: _feeCtrl,
            interestController: _interestCtrl,
            onFromChanged: (v) => setState(() => _assetRowId = v),
            onToChanged: (v) => setState(() => _toAssetRowId = v),
            labelBuilder: (text) => _FieldLabel(text),
            loadErrorText: l.presetAssetLoadError,
            interestEnabled: _lockAmount,
          ),
        ] else ...[
          // ③ 카테고리 (5열 그룹 타일 grid)
          _FieldLabel(l.expCategory),
          const SizedBox(height: PSpace.x8),
          categoriesAsync.when(
            loading: () => _categoryGridSkeleton(),
            error: (e, _) => Text(
              l.categoryLoadError,
              style: PTypo.caption.copyWith(color: t.statusDangerFg),
            ),
            data: (cats) => _CategoryGrid(
              categories: cats,
              type: _type,
              categoryRowId: _categoryRowId,
              onSelect: (id) => setState(() => _categoryRowId = id),
            ),
          ),
          // 세부 카테고리 — 반복거래와 동일 패턴: 자식이 있으면 상위/세부 선택으로 변경 가능
          categoriesAsync.maybeWhen(
            data: (cats) => _buildSubcategorySelect(l, cats),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),

          // ④ 기본 내역
          _FieldLabel(l.presetMerchant),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _merchantCtrl,
            placeholder: l.presetMerchantPlaceholder,
          ),
          const SizedBox(height: 14),
        ],

        // ⑤ 메모 — 불러올 때 거래의 메모로 들어간다.
        _FieldLabel(l.expDescription),
        const SizedBox(height: PSpace.x4),
        PTextInput(controller: _descCtrl, placeholder: l.expMemoPlaceholder),
        const SizedBox(height: 14),

        if (!_isTransfer) ...[
          // ⑥ 결제 수단
          _FieldLabel(l.expPaymentMethod),
          const SizedBox(height: PSpace.x4),
          PSelect<String>(
            value: _paymentMethod.isEmpty ? null : _paymentMethod,
            placeholder: l.presetSelectNone,
            title: l.expPaymentMethod,
            items: [
              PSelectItem(value: '', label: l.presetSelectNone),
              for (final v in _kPaymentMethodValues)
                PSelectItem(value: v, label: _payLabel(l, v)),
            ],
            onChanged: (v) => setState(() => _paymentMethod = v ?? ''),
          ),
          const SizedBox(height: 14),

          // ⑦ 계좌·카드
          _FieldLabel(l.presetAssetCard),
          const SizedBox(height: PSpace.x4),
          assetsAsync.when(
            loading: () => const PSkeleton(width: double.infinity, height: 40),
            error: (e, _) => Text(
              l.presetAssetLoadError,
              style: PTypo.caption.copyWith(color: t.statusDangerFg),
            ),
            data: (assets) => PSelect<int>(
              value: _assetRowId,
              placeholder: l.presetSelectNone,
              title: l.presetAssetCard,
              items: [
                PSelectItem(value: -1, label: l.presetSelectNone),
                for (final a in assets)
                  PSelectItem(
                    value: a.rowId,
                    label: a.institution != null && a.institution!.isNotEmpty
                        ? '${a.institution} · ${a.assetName}'
                        : a.assetName,
                  ),
              ],
              onChanged: (v) => setState(
                () => _assetRowId = (v == null || v == -1) ? null : v,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ⑧ '고정 금액 사용' 체크 카드
        _LockAmountCard(
          lockAmount: _lockAmount,
          amountCtrl: _amountCtrl,
          onToggle: (v) => setState(() {
            _lockAmount = v;
            // 고정을 끄면 이자도 비운다 — 이자는 금액을 따라간다(2026-09-15 결정).
            // 안 비우면 칸만 감춰졌다가 다시 켤 때 옛 이자가 되살아난다. 저장 결과는
            // 어차피 맞지만(payload 가 null), 화면에 지난달 이자가 떠 있으면 사용자는
            // 그 값이 저장된 줄 안다. 웹도 같은 자리에서 비운다.
            if (!v) _interestCtrl.clear();
          }),
        ),
        if (!_isTransfer) ...[
          const SizedBox(height: 10),
          _FixedCard(
            title: _type == 'INCOME'
                ? l.presetFixedTitleIncome
                : l.presetFixedTitleExpense,
            isFixed: _isFixed,
            onToggle: (v) => setState(() => _isFixed = v),
          ),
        ],
      ],
    );
  }

  /// 세부 카테고리 선택 — 반복거래(recurring_settings_drawer)와 동일 패턴.
  /// 선택된 상위에 자식이 있으면 [상위 (상위), ...자식들] PSelect 로 변경 가능하게.
  Widget _buildSubcategorySelect(
    AppLocalizations l,
    List<ExpenseCategory> cats,
  ) {
    bool isTop(ExpenseCategory c) =>
        c.parentRowId == null || c.parentRowId == 0;

    final childrenByParent = <int, List<ExpenseCategory>>{};
    for (final c in cats) {
      if (isTop(c) || c.expenseType != _type) continue;
      childrenByParent.putIfAbsent(c.parentRowId!, () => []).add(c);
    }
    for (final list in childrenByParent.values) {
      list.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    }

    final selectedCat = _categoryRowId == null
        ? null
        : cats.byRowId(_categoryRowId!);
    final selectedParentId = selectedCat == null
        ? null
        : (isTop(selectedCat) ? selectedCat.rowId : selectedCat.parentRowId);
    final children = selectedParentId == null
        ? const <ExpenseCategory>[]
        : (childrenByParent[selectedParentId] ?? const []);
    if (selectedParentId == null || children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: PSelect<int>(
        value: _categoryRowId,
        placeholder: l.expSubcategory,
        title: l.expSubcategory,
        // 상위 자신은 고를 수 없다 — 하위가 있는 상위는 프리셋도 거래도 안 받는다
        // (EXPENSE_CATEGORY_NOT_LEAF). 거래 추가와 같다(QA 30 13).
        items: [
          for (final child in children)
            PSelectItem(value: child.rowId, label: child.categoryName),
        ],
        onChanged: (v) {
          if (v != null) setState(() => _categoryRowId = v);
        },
      ),
    );
  }

  Widget _categoryGridSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        const columns = 5;
        final cell = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (int i = 0; i < 10; i++)
              SizedBox(
                width: cell,
                height: 64,
                child: const PSkeleton(
                  width: double.infinity,
                  height: 64,
                  borderRadius: PRadius.brLg,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 웹 `FieldLabel` 미러 — text-label-sm(13) / fg-secondary / 600.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(
      text,
      style: TextStyle(
        fontFamily: PTypo.sans,
        fontSize: PFontSize.bodySm, // --text-label-sm = 13
        fontWeight: PFontWeight.semi,
        color: t.fgSecondary,
      ),
    );
  }
}

/// 5열 그룹 타일 grid + 첫 자식 매핑 (웹 `topCategories`/`childrenByParent` 정합).
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.type,
    required this.categoryRowId,
    required this.onSelect,
  });

  final List<ExpenseCategory> categories;
  final String type;
  final int? categoryRowId;
  final ValueChanged<int> onSelect;

  bool _isTop(ExpenseCategory c) => c.parentRowId == null || c.parentRowId == 0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    final topCategories =
        categories.where((c) => c.expenseType == type && _isTop(c)).toList()
          ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));

    if (topCategories.isEmpty) {
      return Text(
        l.expNoCategoryForType,
        style: PTypo.caption.copyWith(color: t.fgTertiary),
      );
    }

    final childrenByParent = <int, List<ExpenseCategory>>{};
    for (final c in categories) {
      if (_isTop(c) || c.expenseType != type) continue;
      childrenByParent.putIfAbsent(c.parentRowId!, () => []).add(c);
    }
    for (final list in childrenByParent.values) {
      list.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    }

    // 선택된 카테고리를 부모로 환원해 active 타일 판정.
    final selectedCat = categoryRowId == null
        ? null
        : categories.byRowId(categoryRowId!);
    final selectedParentId = selectedCat == null
        ? null
        : (_isTop(selectedCat) ? selectedCat.rowId : selectedCat.parentRowId);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        const columns = 5;
        final cell = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in topCategories)
              SizedBox(
                width: cell,
                child: PCategoryTile(
                  name: c.categoryName,
                  color: resolveChartColor(
                    context,
                    c.color,
                    fallback: t.fgBrand,
                  ),
                  icon: lucideByName(c.icon),
                  active: selectedParentId == c.rowId,
                  onTap: () {
                    final firstChild = childrenByParent[c.rowId]?.first;
                    onSelect(firstChild != null ? firstChild.rowId : c.rowId);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// '고정 지출/수입으로 기록' 체크 카드 — 이 프리셋으로 만든 거래가 통계의 고정 항목으로 잡힌다.
class _FixedCard extends StatelessWidget {
  const _FixedCard({
    required this.title,
    required this.isFixed,
    required this.onToggle,
  });
  final String title;
  final bool isFixed;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(PSpace.md),
      decoration: BoxDecoration(
        color: t.bgSunken,
        borderRadius: PRadius.brLg, // --radius-tile = 12
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PCheckbox(
            size: PCheckboxSize.sm,
            value: isFixed,
            semanticLabel: title,
            onChanged: (v) => onToggle(v == true),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onToggle(!isFixed),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: PFontSize.bodySm, // --text-label-sm
                      fontWeight: PFontWeight.bold,
                      color: t.fgPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.presetFixedDesc,
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// '고정 금액 사용' 체크 카드 + 조건부 금액 입력.
class _LockAmountCard extends StatelessWidget {
  const _LockAmountCard({
    required this.lockAmount,
    required this.amountCtrl,
    required this.onToggle,
  });
  final bool lockAmount;
  final TextEditingController amountCtrl;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(PSpace.md),
      decoration: BoxDecoration(
        color: t.bgSunken,
        borderRadius: PRadius.brLg, // --radius-tile = 12
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PCheckbox(
                size: PCheckboxSize.sm,
                value: lockAmount,
                semanticLabel: l.presetLockToggle,
                onChanged: (v) => onToggle(v == true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onToggle(!lockAmount),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.presetLockToggle,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.bodySm, // --text-label-sm
                          fontWeight: PFontWeight.bold,
                          color: t.fgPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.presetLockDesc,
                        style: PTypo.caption.copyWith(color: t.fgTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (lockAmount) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.borderSubtle)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(l.presetLockAmountLabel),
                  const SizedBox(height: PSpace.x4),
                  PTextInput(
                    controller: amountCtrl,
                    numbersOnly: true,
                    amountMax: kAmountMax,
                    placeholder: '0',
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: PFontSize.bodyLg, // --text-body-lg
                      fontWeight: PFontWeight.bold,
                      color: t.fgPrimary,
                    ),
                    // 우측 '원' 접미사 (웹 absolute 접미사 정합).
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 12, left: 4),
                      child: Text(
                        wonUnit(),
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.bodySm, // --text-label-sm
                          fontWeight: PFontWeight.bold,
                          color: t.fgTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
