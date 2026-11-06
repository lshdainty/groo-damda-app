// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Asset _$AssetFromJson(Map<String, dynamic> json) => _Asset(
  rowId: (json['rowId'] as num).toInt(),
  userRowId: (json['userRowId'] as num?)?.toInt(),
  assetName: json['assetName'] as String,
  assetType: json['assetType'] as String,
  balance: (json['balance'] as num?)?.toInt(),
  cashBalance: (json['cashBalance'] as num?)?.toInt(),
  holdingBalance: (json['holdingBalance'] as num?)?.toInt(),
  currency: json['currency'] as String?,
  exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
  balanceInKrw: (json['balanceInKrw'] as num?)?.toInt(),
  color: json['color'] as String?,
  institution: json['institution'] as String?,
  memo: json['memo'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
  isIncludedInTotal: json['isIncludedInTotal'] as String?,
  isAmountHidden: json['isAmountHidden'] as String?,
  creditLimit: (json['creditLimit'] as num?)?.toInt(),
  paymentDay: (json['paymentDay'] as num?)?.toInt(),
  paymentAssetRowId: (json['paymentAssetRowId'] as num?)?.toInt(),
  carryoverAmount: (json['carryoverAmount'] as num?)?.toInt(),
  carryoverLocked: json['carryoverLocked'] as bool? ?? false,
  dueCarryover: json['dueCarryover'] == null
      ? null
      : DueCarryover.fromJson(json['dueCarryover'] as Map<String, dynamic>),
  nextPaymentDate: json['nextPaymentDate'] as String?,
  cardClosedThrough: json['cardClosedThrough'] as String?,
  cardCatalog: json['cardCatalog'] == null
      ? null
      : AssetCardCatalog.fromJson(json['cardCatalog'] as Map<String, dynamic>),
  marketCode: json['marketCode'] as String?,
  tossSymbol: json['tossSymbol'] as String?,
  tossQuantity: (json['tossQuantity'] as num?)?.toInt(),
  holdings:
      (json['holdings'] as List<dynamic>?)
          ?.map((e) => AssetHolding.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AssetHolding>[],
  monthlyUsedAmount: (json['monthlyUsedAmount'] as num?)?.toInt(),
);

Map<String, dynamic> _$AssetToJson(_Asset instance) => <String, dynamic>{
  'rowId': instance.rowId,
  'userRowId': instance.userRowId,
  'assetName': instance.assetName,
  'assetType': instance.assetType,
  'balance': instance.balance,
  'cashBalance': instance.cashBalance,
  'holdingBalance': instance.holdingBalance,
  'currency': instance.currency,
  'exchangeRate': instance.exchangeRate,
  'balanceInKrw': instance.balanceInKrw,
  'color': instance.color,
  'institution': instance.institution,
  'memo': instance.memo,
  'sortOrder': instance.sortOrder,
  'isIncludedInTotal': instance.isIncludedInTotal,
  'isAmountHidden': instance.isAmountHidden,
  'creditLimit': instance.creditLimit,
  'paymentDay': instance.paymentDay,
  'paymentAssetRowId': instance.paymentAssetRowId,
  'carryoverAmount': instance.carryoverAmount,
  'carryoverLocked': instance.carryoverLocked,
  'dueCarryover': instance.dueCarryover,
  'nextPaymentDate': instance.nextPaymentDate,
  'cardClosedThrough': instance.cardClosedThrough,
  'cardCatalog': instance.cardCatalog,
  'marketCode': instance.marketCode,
  'tossSymbol': instance.tossSymbol,
  'tossQuantity': instance.tossQuantity,
  'holdings': instance.holdings,
  'monthlyUsedAmount': instance.monthlyUsedAmount,
};

_DueCarryover _$DueCarryoverFromJson(Map<String, dynamic> json) =>
    _DueCarryover(
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      locked: json['locked'] as bool? ?? false,
      paymentDate: json['paymentDate'] as String?,
    );

Map<String, dynamic> _$DueCarryoverToJson(_DueCarryover instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'locked': instance.locked,
      'paymentDate': instance.paymentDate,
    };

_AssetCardCatalog _$AssetCardCatalogFromJson(Map<String, dynamic> json) =>
    _AssetCardCatalog(
      rowId: (json['rowId'] as num).toInt(),
      cardName: json['cardName'] as String,
      imgUrl: json['imgUrl'] as String?,
      companyName: json['companyName'] as String?,
      companyLogoUrl: json['companyLogoUrl'] as String?,
    );

Map<String, dynamic> _$AssetCardCatalogToJson(_AssetCardCatalog instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'cardName': instance.cardName,
      'imgUrl': instance.imgUrl,
      'companyName': instance.companyName,
      'companyLogoUrl': instance.companyLogoUrl,
    };

_AssetHolding _$AssetHoldingFromJson(Map<String, dynamic> json) =>
    _AssetHolding(
      rowId: (json['rowId'] as num?)?.toInt(),
      holdingType:
          $enumDecodeNullable(
            _$AssetHoldingTypeEnumMap,
            json['holdingType'],
            unknownValue: AssetHoldingType.stock,
          ) ??
          AssetHoldingType.stock,
      linked: json['linked'] as bool? ?? false,
      marketCode: json['marketCode'] as String?,
      tossSymbol: json['tossSymbol'] as String?,
      quantity: decimalStringFromJson(json['quantity']),
      holdingName: json['holdingName'] as String?,
      holdingValue: (json['holdingValue'] as num?)?.toInt(),
      totalCost: (json['totalCost'] as num?)?.toInt(),
      avgPrice: decimalStringFromJson(json['avgPrice']),
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AssetHoldingToJson(_AssetHolding instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'holdingType': _$AssetHoldingTypeEnumMap[instance.holdingType]!,
      'linked': instance.linked,
      'marketCode': instance.marketCode,
      'tossSymbol': instance.tossSymbol,
      'quantity': instance.quantity,
      'holdingName': instance.holdingName,
      'holdingValue': instance.holdingValue,
      'totalCost': instance.totalCost,
      'avgPrice': instance.avgPrice,
      'sortOrder': instance.sortOrder,
    };

const _$AssetHoldingTypeEnumMap = {
  AssetHoldingType.stock: 'STOCK',
  AssetHoldingType.gold: 'GOLD',
  AssetHoldingType.crypto: 'CRYPTO',
};
