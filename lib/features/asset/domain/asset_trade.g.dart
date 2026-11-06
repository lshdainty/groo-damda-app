// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_trade.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssetTrade _$AssetTradeFromJson(Map<String, dynamic> json) => _AssetTrade(
  rowId: (json['rowId'] as num).toInt(),
  assetRowId: (json['assetRowId'] as num).toInt(),
  tradeType: json['tradeType'] as String,
  holdingType: json['holdingType'] as String?,
  holdingKey: json['holdingKey'] as String,
  linked: json['linked'] as bool? ?? false,
  quantity: decimalStringFromJson(json['quantity']),
  amount: (json['amount'] as num?)?.toInt(),
  fee: (json['fee'] as num?)?.toInt(),
  realizedPl: (json['realizedPl'] as num?)?.toInt(),
  tradeDate: json['tradeDate'] as String?,
  description: json['description'] as String?,
  settlementAssetRowId: (json['settlementAssetRowId'] as num?)?.toInt(),
);

Map<String, dynamic> _$AssetTradeToJson(_AssetTrade instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'assetRowId': instance.assetRowId,
      'tradeType': instance.tradeType,
      'holdingType': instance.holdingType,
      'holdingKey': instance.holdingKey,
      'linked': instance.linked,
      'quantity': instance.quantity,
      'amount': instance.amount,
      'fee': instance.fee,
      'realizedPl': instance.realizedPl,
      'tradeDate': instance.tradeDate,
      'description': instance.description,
      'settlementAssetRowId': instance.settlementAssetRowId,
    };

_AssetTradePreview _$AssetTradePreviewFromJson(Map<String, dynamic> json) =>
    _AssetTradePreview(
      soldCost: (json['soldCost'] as num?)?.toInt(),
      realizedPl: (json['realizedPl'] as num?)?.toInt(),
      cashDelta: (json['cashDelta'] as num?)?.toInt() ?? 0,
      cashAfter: (json['cashAfter'] as num?)?.toInt() ?? 0,
      fundingAmount: (json['fundingAmount'] as num?)?.toInt() ?? 0,
      cashCurrency: json['cashCurrency'] as String?,
      fundingCurrency: json['fundingCurrency'] as String?,
    );

Map<String, dynamic> _$AssetTradePreviewToJson(_AssetTradePreview instance) =>
    <String, dynamic>{
      'soldCost': instance.soldCost,
      'realizedPl': instance.realizedPl,
      'cashDelta': instance.cashDelta,
      'cashAfter': instance.cashAfter,
      'fundingAmount': instance.fundingAmount,
      'cashCurrency': instance.cashCurrency,
      'fundingCurrency': instance.fundingCurrency,
    };
