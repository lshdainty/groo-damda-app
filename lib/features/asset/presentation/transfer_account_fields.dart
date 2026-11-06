import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/format/amount_limits.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/transfer_rules.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_select.dart';
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart';
import 'package:groo_damda_app/shared/widgets/p_text_input.dart';

/// 이체의 계좌·수수료·이자 칸 — **거래 시트 · 반복 설정 · 프리셋 편집**이 같이 쓴다.
///
/// 규칙은 [transferEligibleAssets]·[isLoanTarget] 한 벌인데 **화면은 세 벌이었다**
/// (2026-09-15). 셀렉트 위젯도 자리마다 달랐다. 그러면 "어떤 계좌를 고를 수 있나 ·
/// 이자 칸이 언제 뜨나" 가 조용히 갈리고, 갈리는 순간 사용자는 시트에서 만든 이체를
/// 반복으로는 못 만들거나, 반복으로 저장해 둔 규칙이 자정에만 거절당한다.
///
/// 여기서 한 번만 정하는 것 — 고를 수 있는 자산 · 받는 쪽에서 보내는 계좌를 빼는 것 ·
/// 이자 칸을 띄우는 조건 · 자산 라벨(`기관 · 이름`) · 수수료 상한.
///
/// **상태는 부르는 쪽이 든다.** 시트는 거래를, 반복은 규칙을, 프리셋은 양식을 저장해
/// 제출 모양이 서로 다르다. 라벨 칠도 화면이 정한다([labelBuilder]) — 시트·드로어는
/// `PSectionLabel`, 프리셋 폼은 자기 `_FieldLabel` 을 쓰고 있어, 여기서 하나로 밀면
/// 그 화면 안에서 이 넷만 다른 글씨가 된다.
class TransferAccountFields extends StatelessWidget {
  const TransferAccountFields({
    super.key,
    required this.assets,
    required this.fromAssetRowId,
    required this.toAssetRowId,
    required this.feeController,
    required this.interestController,
    required this.onFromChanged,
    required this.onToChanged,
    required this.labelBuilder,
    this.onInterestChanged,
    this.amountForHint,
    this.loadErrorText,
    this.interestEnabled = true,
  });

  final AsyncValue<List<Asset>> assets;
  final int? fromAssetRowId;
  final int? toAssetRowId;
  final TextEditingController feeController;
  final TextEditingController interestController;
  final ValueChanged<int?> onFromChanged;
  final ValueChanged<int?> onToChanged;

  /// 화면의 섹션 라벨 — 각 화면이 이미 쓰는 것을 그대로 넘긴다.
  final Widget Function(String text) labelBuilder;

  /// 이자 칸을 고칠 때 알린다(원금·이자 안내를 다시 그리려면 필요하다).
  final VoidCallback? onInterestChanged;

  /// 있으면 이자 안내에 `원금 N · 이자 M` 을 적는다.
  ///
  /// 프리셋은 금액이 없는 게 정상이므로(대출 이자처럼 매달 금액만 다른 이체) null 이고,
  /// 그때는 일반 안내만 띄운다 — 견줄 금액이 없으니 쪼갤 수도 없다. 서버도 같은 이유로
  /// 금액이 있을 때만 금액 규칙을 본다(`AssetTransferRules.validateMoney`).
  final int? amountForHint;

  /// 자산 목록을 못 불러왔을 때 적을 문구. 없으면 아무것도 안 그린다(시트·드로어 기존 동작).
  final String? loadErrorText;

  /// 이자 칸을 쓸 수 있는 화면인가 — **기본은 켜짐**.
  ///
  /// 이자는 받는 자산이 대출일 때만 뜨는데, 그 위에 화면마다 다른 조건이 하나 더 붙는
  /// 자리가 있다. 프리셋 폼은 <b>금액을 고정했을 때만</b> 이자를 받는다 — 금액이 매달
  /// 다르면 이자도 매달 달라서, 박아 둔 이자는 불러올 때마다 틀린 값이 된다
  /// (사용자 결정 2026-09-15).
  ///
  /// 그 조건을 여기 넣으면 안 된다. 이 위젯은 거래 시트·반복 설정·프리셋 폼 셋이 쓰는데
  /// 앞의 둘에는 "금액 고정" 이라는 게 없어서 이자 칸이 통째로 사라진다. 대출 상환
  /// 이체에 이자를 못 적으면 이자 지출이 안 생기고 원금이 과다 상환된 것으로 기록된다.
  /// 그래서 **조건은 호스트가 정한다.**
  final bool interestEnabled;

  static String _label(Asset a) =>
      a.institution != null && a.institution!.isNotEmpty
      ? '${a.institution} · ${a.assetName}'
      : a.assetName;

  Widget _accountSelect({
    required BuildContext context,
    required String title,
    required int? value,
    required bool excludeFrom,
    required ValueChanged<int?> onChanged,
  }) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return assets.when(
      // 받아 둔 값이 있으면 다시 받기 실패에도 내용을 그린다 — 실패 화면은 값이 없을 때만(검수 M2, result-section.md:53)
      skipError: true,
      loading: () => const PSkeleton(width: double.infinity, height: 40),
      error: (e, _) => loadErrorText == null
          ? const SizedBox.shrink()
          : Text(
              loadErrorText!,
              style: PTypo.caption.copyWith(color: t.statusDangerFg),
            ),
      data: (list) {
        final candidates = excludeFrom
            ? transferEligibleAssets(
                list,
              ).where((a) => a.rowId != fromAssetRowId)
            : transferEligibleAssets(list);
        return PSelect<int>(
          value: value,
          placeholder: l.expSelect,
          title: title,
          items: [
            for (final a in candidates)
              PSelectItem(value: a.rowId, label: _label(a)),
          ],
          onChanged: onChanged,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final showInterest =
        interestEnabled && isLoanTarget(assets.value, toAssetRowId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        labelBuilder(l.expWithdrawAccount),
        const SizedBox(height: PSpace.x4),
        _accountSelect(
          context: context,
          title: l.expWithdrawAccount,
          value: fromAssetRowId,
          excludeFrom: false,
          onChanged: onFromChanged,
        ),
        const SizedBox(height: PSpace.x12),

        labelBuilder(l.expDepositAccount),
        const SizedBox(height: PSpace.x4),
        _accountSelect(
          context: context,
          title: l.expDepositAccount,
          value: toAssetRowId,
          excludeFrom: true,
          onChanged: (v) {
            // 받는 자산이 대출이 아니게 되면 이자 칸이 사라진다 — 값도 같이 버린다.
            // 안 버리면 다시 대출로 바꿨을 때 옛 이자가 되살아나고, 화면이 "이 이자가
            // 저장돼 있다" 고 말한다. 저장값은 호스트가 걸러 맞지만 화면이 틀린다.
            //
            // 규칙이 하나이므로 자리도 하나다 — 이 위젯을 쓰는 세 화면(거래 시트 ·
            // 반복 설정 · 프리셋 폼)이 각자 비우면 한쪽만 고쳐져 갈라진다. 웹은
            // 렌더 중에 비우는 훅이 세 화면에 다 있지만, Dart 에는 그 자리가 없다.
            if (!isLoanTarget(assets.value, v)) interestController.clear();
            onToChanged(v);
          },
        ),
        // 받는 목록에서 보내는 계좌를 빼므로 손으로는 같아질 수 없지만, 기존 이체를
        // 편집으로 열면 저장된 값이 같을 수 있다 — 그때 왜 저장이 안 되는지 알려 준다.
        if (fromAssetRowId != null && fromAssetRowId == toAssetRowId)
          Padding(
            padding: const EdgeInsets.only(top: PSpace.x4),
            child: Text(
              l.expTransferSameAsset,
              style: PTypo.caption.copyWith(color: t.statusDangerFg),
            ),
          ),
        const SizedBox(height: PSpace.x12),

        labelBuilder(l.expFeeOptional),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: feeController,
          numbersOnly: true,
          amountMax: kAmountMax,
          placeholder: '0',
        ),
        const SizedBox(height: PSpace.x12),

        // 이자 — 대출 상환에만. 상환액 중 이자는 부채를 줄이지 않고 지출로 잡힌다.
        if (showInterest) ...[
          labelBuilder(l.expInterest),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: interestController,
            numbersOnly: true,
            amountMax: kAmountMax,
            placeholder: '0',
            onChanged: onInterestChanged == null
                ? null
                : (_) => onInterestChanged!(),
          ),
          const SizedBox(height: PSpace.x4),
          Builder(
            builder: (_) {
              final amount = amountForHint;
              final interest =
                  int.tryParse(interestController.text.replaceAll(',', '')) ??
                  0;
              final canSplit = amount != null && amount > 0 && interest > 0;
              return Text(
                canSplit
                    ? l.expInterestSplit(
                        krw(amount - interest < 0 ? 0 : amount - interest),
                        krw(interest),
                      )
                    : l.expInterestHint,
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              );
            },
          ),
          const SizedBox(height: PSpace.x12),
        ],
      ],
    );
  }
}
