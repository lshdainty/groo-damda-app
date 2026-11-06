import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';

/// 통화·환율 칸 — 계좌·카드·투자 편집 폼이 함께 쓴다.
///
/// 웹 `AssetForm` 이 통화 select + 환율 입력의 단일 구현이고, 앱에서는 이 위젯이
/// 그 자리다. 세 폼이 각자 베껴 두면 한쪽만 고쳐졌을 때 "카드에서만 환율이 안 뜬다"
/// 같은 차이가 조용히 생긴다.
///
/// **환율은 통화가 KRW 가 아닐 때만 뜬다.** 원화에 1 을 적게 하는 칸은 의미가 없고,
/// 서버도 KRW 의 환산율은 1 로 정규화한다(`Asset.normalizeRate`).
///
/// **외화면 환율이 필수다**(서버 AST_036, I-13) — 비운 채 저장을 누르면([showErrors]) 칸 오류 "환율을 입력해주세요.".
/// 카드는 원화만이라 이 칸을 쓰지 않는다(서버 AST_037).
///
/// 두 칸을 16 간격으로 나란히 둔다(라벨과 값이 짧을 때만 — field.yaml). 환율 안내는 환율 칸의 설명이다. 글자가 커지면(150% 넘게)
/// 환율 칸은 아래 줄로 내려 값이 가려지지 않게 한다.
class AssetCurrencyFields extends StatelessWidget {
  const AssetCurrencyFields({
    super.key,
    required this.currency,
    required this.rateController,
    required this.onCurrencyChanged,
    this.showErrors = false,
  });

  /// 저장을 한 번이라도 눌렀나 — 환율이 비면 이때부터 칸 오류를 보인다.
  final bool showErrors;

  /// 지금 고른 통화 코드(ISO). 비어 있을 수 없다 — 기본은 [kDefaultCurrency].
  final String currency;

  /// 환율 입력 컨트롤러. 외화가 아닐 때는 칸이 안 그려질 뿐 값은 유지된다 —
  /// 통화를 잘못 눌렀다 되돌렸을 때 적어 둔 환율이 사라지면 곤란하다.
  final TextEditingController rateController;

  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final foreign = isForeignCurrency(currency);
    final currencyField = PField(
      label: l.assetCurrency,
      child: PSelect<String>(
        groups: [
          PSelectGroup(
            items: [
              for (final o in kCurrencies)
                PSelectItem(value: o.code, label: '${o.symbol} ${o.code}'),
            ],
          ),
        ],
        value: currency,
        placeholder: l.assetCurrency,
        onChanged: onCurrencyChanged,
      ),
    );
    // 환율 안내는 칸의 설명이다(Field 설명 — 칸 폭 안에서 줄이 바뀐다)
    final rateInvalid =
        showErrors && exchangeRateMissing(currency, rateController);
    final rateField = PField(
      label: l.assetExchangeRate,
      description: l.assetExchangeRateDesc,
      invalid: rateInvalid,
      errorMessage: rateInvalid ? l.assetExchangeRateRequired : null,
      child: PInput(
        controller: rateController,
        invalid: rateInvalid,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        placeholder: l.assetExchangeRateHint(currency),
        tabularFigures: true,
      ),
    );
    final wide = MediaQuery.textScalerOf(context).scale(16) <= 24;
    if (!foreign) return currencyField;
    // 두 칸은 16 간격으로 나란히(field.yaml form.gapX — 라벨과 값이 짧을 때만). 글자가 커지면 위아래로 쌓는다(Field ↔ Field 24)
    return wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x4,
            children: [
              Expanded(child: currencyField),
              Expanded(child: rateField),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PSpacing.x6,
            children: [currencyField, rateField],
          );
  }
}

/// 외화인데 환율이 비었거나 0 이하인가 — 저장을 막는다(서버 AST_036 과 같은 규칙, I-13). 원화는 칸이 없으니 늘 false.
bool exchangeRateMissing(String currency, TextEditingController rate) {
  if (!isForeignCurrency(currency)) return false;
  final v = double.tryParse(rate.text.replaceAll(',', ''));
  return !(v != null && v > 0);
}

/// 저장 실패 Callout 의 고정 글 — 서버 원문은 내지 않는다(28-5). 고쳐 다시 할 수 있는 두 코드만 가려 다른 고정 글:
/// AST_037 카드는 원화만 · AST_036 외화 자산 환율 필수(I-13, 웹 FormStep `saveFailedText` 와 같다). 그 밖은 "자산을 저장하지 못했어요."
String assetSaveFailedText(AppLocalizations l, String? code) => switch (code) {
  // 응답만 못 읽었다(서버는 저장했다) — 실패라 하지 않는다(검수 M3)
  kApiParseErrorCode || kApiNoResponseCode => l.saveUnconfirmed,
  'AST_037' => l.assetSaveCardForeign,
  'AST_036' => l.assetSaveRateRequired,
  _ => l.assetSaveFailed,
};

/// 1400.000000 을 1400 으로 — 서버가 소수 6자리로 주는 값을 그대로 채워 두면
/// 편집 폼이 지저분하고, 사용자가 고치려고 지웠다 다시 적게 된다.
String trimExchangeRate(double rate) {
  final s = rate.toStringAsFixed(6);
  return s.contains('.')
      ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : s;
}
