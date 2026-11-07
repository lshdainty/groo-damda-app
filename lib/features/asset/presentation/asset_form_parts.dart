import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/amount_input_formatter.dart';
import 'package:groo_damda_app/core/format/amount_limits.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_kind.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';

/// 별칭 길이 상한 — 웹 `ASSET_NAME_MAX` 와 같은 값(QA #16). 100자 별칭은 목록에서 전부 '…' 로 잘려 서로 구분이 안 된다.
const int kAssetNameMax = 30;

/// 메모 길이 상한 — 웹 `maxLength` 와 같다.
const int kAssetMemoMax = 120;

/// 폼 본문이 바뀐 값을 가졌는지 — 입력칸의 주인은 본문 State 라, 닫기 · 뒤로 가기 전에 그쪽에 묻는다("작성한 내용이 사라져요").
class AssetFormProbe {
  bool Function() dirty = () => false;
}

/// 2단계 폼의 틀 — 시트 머리(제목 · 뒤로 · 닫기) · 칸 묶음 · 체크 줄 · 바닥 버튼 하나(I-17 5 · 7). 바닥 버튼은 늘 켜 둔다.
///
/// 칸 묶음은 좌우 24 · 칸 사이 24(`spacing-x6`), 체크 줄은 본문 좌우 0 에 제 24 를 갖는다. 칸 묶음 아래 8 + 체크 줄 위 8 이 마지막
/// 칸 ↔ 체크 줄 16 이다(T14). 넘치면 본문만 스크롤하고 끝 흐림이 선다.
class AssetFormFrame extends StatelessWidget {
  const AssetFormFrame({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.fields,
    required this.checks,
    required this.submitting,
    required this.onSubmit,
    this.onBack,
    this.errorMessage,
    this.errorKey,
  });

  /// 저장 실패 고정 문구 — 있으면 폼 맨 위 Callout 으로 보인다(서버 글 아님, 쓴 값은 그대로).
  final String? errorMessage;
  final Key? errorKey;

  final String title;
  final String submitLabel;
  final List<Widget> fields;
  final Widget checks;
  final bool submitting;
  final VoidCallback onSubmit;

  /// 추가의 2단계에서만 — 1단계로 돌아간다. 수정에는 1단계도 ← 도 없다.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PBottomSheetContent(
      title: title,
      closeLabel: l.actionClose,
      onBack: onBack,
      backLabel: onBack == null ? null : l.actionBack,
      scrollFog: true,
      flushBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpacing.globalGutter,
              ),
              child: FormErrorCallout(key: errorKey, message: errorMessage!),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              0,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PSpacing.x6,
              children: fields,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: PSpacing.x2),
            child: checks,
          ),
        ],
      ),
      footer: [
        PButton(
          label: submitLabel,
          size: PButtonSize.large,
          loading: submitting,
          // 늘 켜 둔다 — 필수가 비었으면 누를 때 칸마다 안내한다(DESIGN.desk "저장 버튼은 켜 두고 누르면 오류")
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

/// 별칭 칸 — 30자(Field 글자 수가 세고 최대에서 멈춘다) · 중복 오류는 Field 꼬리. 카드는 선택(비우면 상품 이름).
class AssetNameField extends StatelessWidget {
  const AssetNameField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.errorMessage,
    this.optional = false,
    this.focusNode,
  });

  final TextEditingController controller;
  final String placeholder;
  final String? errorMessage;
  final bool optional;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PField(
      label: l.assetNickname,
      indicator: optional ? PFieldIndicator.optional : PFieldIndicator.none,
      maxGraphemeCount: kAssetNameMax,
      invalid: errorMessage != null,
      errorMessage: errorMessage,
      child: PInput(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
      ),
    );
  }
}

/// 메모 칸 — 계좌 · 투자 묶음, 추가 · 수정 모두. 120자. 카드 묶음에는 칸이 없다.
class AssetMemoField extends StatelessWidget {
  const AssetMemoField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PField(
      label: l.assetMemo,
      indicator: PFieldIndicator.optional,
      maxGraphemeCount: kAssetMemoMax,
      child: PInput(
        controller: controller,
        placeholder: l.assetMemoPlaceholder,
      ),
    );
  }
}

/// 금액 칸 하나(I-17 12 · 13) — 쓰는 동안 쉼표가 찍히고 뒤에 단위 글자(고른 통화)가 붙는다. 부호 키는 안 먹고 상한은 잔액 ·
/// 한도 상한(`kBalanceMax`)이다. 도움말 · 안내는 Field 설명이다(여러 줄이면 줄바꿈으로 잇는다).
///
/// [descriptionIcon] 은 설명 앞 아이콘(한도 초과 안내의 경고) — 칸을 오류로 칠하지 않는다(저장을 막지 않는 안내).
class AssetAmountField extends StatefulWidget {
  const AssetAmountField({
    super.key,
    required this.label,
    required this.controller,
    required this.unit,
    this.optional = false,
    this.readOnly = false,
    this.description,
    this.descriptionIcon,
    this.inputKey,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String unit;
  final bool optional;
  final bool readOnly;
  final String? description;
  final IconData? descriptionIcon;
  final Key? inputKey;
  final ValueChanged<String>? onChanged;

  @override
  State<AssetAmountField> createState() => _AssetAmountFieldState();
}

class _AssetAmountFieldState extends State<AssetAmountField> {
  /// 1,000억을 넘겨 입력을 막았나 — 칸 아래 오류를 띄우고 다음 유효한 입력에서 걷는다.
  bool _over = false;
  late final List<TextInputFormatter> _formatters = [
    AmountInputFormatter(
      max: kBalanceMax,
      onLimit: (over) {
        if (over != _over && mounted) setState(() => _over = over);
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PField(
      label: widget.label,
      indicator: widget.optional
          ? PFieldIndicator.optional
          : PFieldIndicator.none,
      readOnly: widget.readOnly,
      description: widget.description,
      descriptionIcon: widget.descriptionIcon,
      invalid: _over,
      errorMessage: _over ? l.amountTooLargeAt(l.amountLimitBalance) : null,
      child: PInput(
        key: widget.inputKey,
        controller: widget.controller,
        placeholder: '0',
        suffixText: widget.unit,
        tabularFigures: true,
        readOnly: widget.readOnly,
        keyboardType: TextInputType.number,
        inputFormatters: _formatters,
        onChanged: widget.onChanged,
      ),
    );
  }
}

/// 입력칸의 쉼표를 떼고 정수로 읽는다 — 비었거나 숫자가 아니면 null. 저장 본문은 이 값만 쓴다(칸 모양과 상관없다).
int? parseAmountField(TextEditingController c) => parseAmountInput(c.text);

/// 처음 값에 쉼표를 찍어 넣는다 — 새 자산은 빈 칸이다.
String initialAmountText(int? value) =>
    value == null ? '' : formatAmountInput(value);

/// 수정의 "종류" 칸(I-17 9) — 같은 묶음의 종류만 고른다. 계좌 여섯은 Select, 카드 둘(신용 · 체크)은 Chip 하나 고르기, 투자는 하나뿐이라
/// 그리지 않는다. 바꾸면 그 종류의 칸으로 바뀐다(카드 종류를 바꿔도 고른 상품은 남는다). 추가 2단계에는 없다(1단계가 정했다).
class AssetKindField extends StatelessWidget {
  const AssetKindField({
    super.key,
    required this.kind,
    required this.onChanged,
  });

  final AssetKind kind;
  final ValueChanged<AssetKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final kinds = kind.siblings;
    if (kinds.length < 2) return const SizedBox.shrink();
    return PField(
      label: l.assetFormKindLabel,
      child: kind.group == AssetKindGroup.account
          ? PSelect<AssetKind>(
              groups: [
                PSelectGroup(
                  items: [
                    for (final k in kinds)
                      PSelectItem(value: k, label: k.label(l)),
                  ],
                ),
              ],
              value: kind,
              placeholder: l.assetFormKindLabel,
              onChanged: onChanged,
            )
          : PChipRadioGroup<AssetKind>(
              value: kind,
              onChanged: onChanged,
              semanticLabel: l.assetFormKindLabel,
              children: [
                for (final k in kinds)
                  PChipRadio<AssetKind>(
                    value: k,
                    label: k.label(l),
                    // 갈래를 바꾸는 고르기라 테두리가 또렷한 칩이다
                    variant: PChipVariant.outlineStrong,
                  ),
              ],
            ),
    );
  }
}

/// "전체 자산 합계에 포함" · "금액 가리기" — 저장해야 적용되는 값이라 체크 줄 둘(DESIGN.desk "합계에 포함은 Checkbox", I-17 17).
/// 줄은 본문 좌우 0 에 제 24 를 갖는다. 둘 다 이 자산 하나에 붙는 표시 규칙이라 나란히 둔다.
class AssetCheckRows extends StatelessWidget {
  const AssetCheckRows({
    super.key,
    required this.includeInTotal,
    required this.onIncludeInTotal,
    required this.hideAmount,
    required this.onHideAmount,
  });

  final bool includeInTotal;
  final ValueChanged<bool> onIncludeInTotal;
  final bool hideAmount;
  final ValueChanged<bool> onHideAmount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PListCheckGroup(
      semanticLabel: l.assetFormRulesGroup,
      children: [
        PListCheckItem(
          markPosition: PListMarkPosition.suffix,
          title: l.assetIncludeInTotal,
          detail: l.assetIncludeInTotalDesc,
          checked: includeInTotal,
          onChanged: onIncludeInTotal,
        ),
        PListCheckItem(
          markPosition: PListMarkPosition.suffix,
          title: l.assetHideThisAmount,
          detail: l.assetHideThisAmountDesc,
          checked: hideAmount,
          onChanged: onHideAmount,
        ),
      ],
    );
  }
}
