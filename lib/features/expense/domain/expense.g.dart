// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Expense _$ExpenseFromJson(Map<String, dynamic> json) => _Expense(
  rowId: (json['rowId'] as num).toInt(),
  userRowId: (json['userRowId'] as num?)?.toInt(),
  categoryRowId: (json['categoryRowId'] as num?)?.toInt(),
  categoryName: json['categoryName'] as String?,
  categoryIcon: json['categoryIcon'] as String?,
  categoryColor: json['categoryColor'] as String?,
  assetRowId: (json['assetRowId'] as num?)?.toInt(),
  assetName: json['assetName'] as String?,
  expenseType: json['expenseType'] as String,
  amount: (json['amount'] as num).toInt(),
  description: json['description'] as String?,
  expenseDate: json['expenseDate'] as String?,
  merchant: json['merchant'] as String?,
  paymentMethod: json['paymentMethod'] as String?,
  installmentMonths: (json['installmentMonths'] as num?)?.toInt(),
  refundedAt: json['refundedAt'] as String?,
  refundTransferRowId: (json['refundTransferRowId'] as num?)?.toInt(),
  refundedAmount: (json['refundedAmount'] as num?)?.toInt(),
  cardSettledThrough: json['cardSettledThrough'] as String?,
  recordOnlyAmount: (json['recordOnlyAmount'] as num?)?.toInt(),
  moneyLocked: json['moneyLocked'] as bool? ?? false,
  replaceable: json['replaceable'] as bool?,
  originalAmount: (json['originalAmount'] as num?)?.toDouble(),
  originalCurrency: json['originalCurrency'] as String?,
  exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
  autoSource: json['autoSource'] as String?,
  deletable: json['deletable'] as bool?,
  calendarEventRowId: (json['calendarEventRowId'] as num?)?.toInt(),
  todoRowId: (json['todoRowId'] as num?)?.toInt(),
  splitCategoryRowIds:
      (json['splitCategoryRowIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  isFixed: json['isFixed'] as bool? ?? false,
  createAt: json['createAt'] as String?,
  modifyAt: json['modifyAt'] as String?,
);

Map<String, dynamic> _$ExpenseToJson(_Expense instance) => <String, dynamic>{
  'rowId': instance.rowId,
  'userRowId': instance.userRowId,
  'categoryRowId': instance.categoryRowId,
  'categoryName': instance.categoryName,
  'categoryIcon': instance.categoryIcon,
  'categoryColor': instance.categoryColor,
  'assetRowId': instance.assetRowId,
  'assetName': instance.assetName,
  'expenseType': instance.expenseType,
  'amount': instance.amount,
  'description': instance.description,
  'expenseDate': instance.expenseDate,
  'merchant': instance.merchant,
  'paymentMethod': instance.paymentMethod,
  'installmentMonths': instance.installmentMonths,
  'refundedAt': instance.refundedAt,
  'refundTransferRowId': instance.refundTransferRowId,
  'refundedAmount': instance.refundedAmount,
  'cardSettledThrough': instance.cardSettledThrough,
  'recordOnlyAmount': instance.recordOnlyAmount,
  'moneyLocked': instance.moneyLocked,
  'replaceable': instance.replaceable,
  'originalAmount': instance.originalAmount,
  'originalCurrency': instance.originalCurrency,
  'exchangeRate': instance.exchangeRate,
  'autoSource': instance.autoSource,
  'deletable': instance.deletable,
  'calendarEventRowId': instance.calendarEventRowId,
  'todoRowId': instance.todoRowId,
  'splitCategoryRowIds': instance.splitCategoryRowIds,
  'isFixed': instance.isFixed,
  'createAt': instance.createAt,
  'modifyAt': instance.modifyAt,
};
