// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Expense {

 int get rowId; int? get userRowId; int? get categoryRowId; String? get categoryName; String? get categoryIcon; String? get categoryColor; int? get assetRowId; String? get assetName; String get expenseType;// 'EXPENSE' | 'INCOME'
 int get amount; String? get description; String? get expenseDate;// ISO LocalDateTime ('YYYY-MM-DDTHH:mm:ss')
 String? get merchant; String? get paymentMethod;/// 할부 개월 (null = 일시불). 신용카드 결제에만 의미.
 int? get installmentMonths;/// 환불 처리 시각 (null = 환불 아님). ISO LocalDateTime.
///
/// 환불은 **원거래에 찍는 표식**이다 — 수입 행을 만들지 않는다. 있으면
/// 합계·예산·통계·카드 청구에서 삭제와 똑같이 빠지고, 내역·검색에는 남는다.
 String? get refundedAt;/// 옛 환불 마크가 만든 카드→결제계좌 환급 이체 (null = 없음).
///
/// 이제 환불은 이체를 만들지 않는다(D1). 이 값이 있는 옛 거래만 환불을 취소할 때
/// 그 이체까지 되돌아간다 — 그래서 확인창이 "환급된 금액도 되돌아가요" 를 말한다.
 int? get refundTransferRowId;/// 이 요청이 **방금** 결제계좌로 돌려준 금액 (null = 없음).
///
/// 열린 회차에서 미리 낸 돈이 남을 때만 생긴다(D3). 거래의 속성이 아니라 그 요청의
/// 결과다 — 조회로 받은 거래에는 늘 null 이다. 화면이 "미리 낸 돈 중 N원이 계좌로
/// 돌아왔어요" 를 말할 재료다(D4).
 int? get refundedAmount;/// 이 날짜(회차 말일)까지의 카드 회차분은 계좌 이체 없이 정리된 **기록용** (null = 정상).
///
/// 결제가 끝난(닫힌) 회차에 뒤늦게 적은 카드 지출에 붙는다 — 가계부 합계에는 들어가지만
/// 계좌에서는 빠지지 않았고 이후 청구에도 안 얹힌다(닫힌 회차 규칙 R2). 'YYYY-MM-DD'.
 String? get cardSettledThrough;/// 그 가운데 기록만 남긴 금액 — 할부는 지난 회차분만이라 거래 금액보다 작을 수 있다.
///
/// 금액과 같을 때만 목록 행에 "기록만" 배지를 단다. 작으면 할부 일부라 상세에서
/// "이 중 N원" 으로 말한다(D10).
 int? get recordOnlyAmount;/// 돈 칸 잠금(D12) — 결제일이 된 회차분이 하나라도 있는 신용카드 거래(또는 기록용
/// 표식이 있는 거래)면 서버가 true 로 내린다.
///
/// true 면 금액·날짜·시간·자산·할부·유형·통화 3칸·결제수단을 못 고친다. 카테고리·
/// 가맹점·메모만 고치고, 돈 칸은 [고쳐 쓰기](`POST /expense/{id}/replace`)로 바꾼다.
/// 옛 서버면 false.
 bool get moneyLocked;/// [고쳐 쓰기] 를 쓸 수 있는 거래인가 — 잠겼고(`moneyLocked`) 환불 안 됐고 자동 생성이
/// 아니고 중도 정리하지 않은 할부. 서버가 판정해 내려 준다(QA 26 3).
///
/// 잠겼는데 이게 false 면 사실상 중도 정리한 할부다 — 서버가 교체를 EXP_047 로 거절한다.
/// 옛 서버면 없다(null) — 그때는 잠금으로 본다.
 bool? get replaceable;/// 원 통화 금액 (해외 결제). null 이면 원화 결제 — amount 가 곧 결제액이다.
 double? get originalAmount;/// 원 통화 (ISO 4217, 예: USD).
 String? get originalCurrency;/// 적용 환율 (원 통화 1단위당 원화). amount ≈ originalAmount × exchangeRate.
 double? get exchangeRate;/// 시스템이 만든 거래의 출처 — `TRADE_REALIZED`(매도 실현손익) /
/// `TRANSFER_INTEREST`(이체 이자). null 이면 손으로 쓴 거래다.
///
/// 값이 있으면 금액·날짜·자산은 계산 결과라 고칠 수 없다. 원본 거래를 지우면
/// 함께 사라진다. 카테고리·메모는 분류라서 그대로 고칠 수 있다.
 String? get autoSource;/// 이 기록을 지금 직접 지울 수 있나 — 서버가 판정해 내려 준다. 자동 생성이 아니면 true,
/// 자동 생성이어도 그 기록을 만든 증권 자산이 이미 삭제됐으면 true. **삭제 버튼 · 스와이프 [삭제] 만**
/// 이 값을 본다(수정 · 환불 · 분할은 [autoSource] 그대로). 옛 서버면 없다(null) — [canDelete] 가 폴백한다.
 bool? get deletable; int? get calendarEventRowId; int? get todoRowId;// 활성 분할 항목들의 카테고리 id (없으면 빈 리스트). 목록 카테고리 필터를 split-aware 하게 매칭.
 List<int> get splitCategoryRowIds;/// 고정 수입·지출 — 월세·월급처럼 매달 정해진 거래. 통계가 전체 · 고정 · 변동으로 나눠 보는
/// **분류 표식**이다(돈·잔액·카드 청구에는 영향 없음). 이체는 대상이 아니다. 옛 서버면 false.
 bool get isFixed; String? get createAt; String? get modifyAt;
/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseCopyWith<Expense> get copyWith => _$ExpenseCopyWithImpl<Expense>(this as Expense, _$identity);

  /// Serializes this Expense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Expense&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryIcon, categoryIcon) || other.categoryIcon == categoryIcon)&&(identical(other.categoryColor, categoryColor) || other.categoryColor == categoryColor)&&(identical(other.assetRowId, assetRowId) || other.assetRowId == assetRowId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.expenseType, expenseType) || other.expenseType == expenseType)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description)&&(identical(other.expenseDate, expenseDate) || other.expenseDate == expenseDate)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.installmentMonths, installmentMonths) || other.installmentMonths == installmentMonths)&&(identical(other.refundedAt, refundedAt) || other.refundedAt == refundedAt)&&(identical(other.refundTransferRowId, refundTransferRowId) || other.refundTransferRowId == refundTransferRowId)&&(identical(other.refundedAmount, refundedAmount) || other.refundedAmount == refundedAmount)&&(identical(other.cardSettledThrough, cardSettledThrough) || other.cardSettledThrough == cardSettledThrough)&&(identical(other.recordOnlyAmount, recordOnlyAmount) || other.recordOnlyAmount == recordOnlyAmount)&&(identical(other.moneyLocked, moneyLocked) || other.moneyLocked == moneyLocked)&&(identical(other.replaceable, replaceable) || other.replaceable == replaceable)&&(identical(other.originalAmount, originalAmount) || other.originalAmount == originalAmount)&&(identical(other.originalCurrency, originalCurrency) || other.originalCurrency == originalCurrency)&&(identical(other.exchangeRate, exchangeRate) || other.exchangeRate == exchangeRate)&&(identical(other.autoSource, autoSource) || other.autoSource == autoSource)&&(identical(other.deletable, deletable) || other.deletable == deletable)&&(identical(other.calendarEventRowId, calendarEventRowId) || other.calendarEventRowId == calendarEventRowId)&&(identical(other.todoRowId, todoRowId) || other.todoRowId == todoRowId)&&const DeepCollectionEquality().equals(other.splitCategoryRowIds, splitCategoryRowIds)&&(identical(other.isFixed, isFixed) || other.isFixed == isFixed)&&(identical(other.createAt, createAt) || other.createAt == createAt)&&(identical(other.modifyAt, modifyAt) || other.modifyAt == modifyAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,rowId,userRowId,categoryRowId,categoryName,categoryIcon,categoryColor,assetRowId,assetName,expenseType,amount,description,expenseDate,merchant,paymentMethod,installmentMonths,refundedAt,refundTransferRowId,refundedAmount,cardSettledThrough,recordOnlyAmount,moneyLocked,replaceable,originalAmount,originalCurrency,exchangeRate,autoSource,deletable,calendarEventRowId,todoRowId,const DeepCollectionEquality().hash(splitCategoryRowIds),isFixed,createAt,modifyAt]);

@override
String toString() {
  return 'Expense(rowId: $rowId, userRowId: $userRowId, categoryRowId: $categoryRowId, categoryName: $categoryName, categoryIcon: $categoryIcon, categoryColor: $categoryColor, assetRowId: $assetRowId, assetName: $assetName, expenseType: $expenseType, amount: $amount, description: $description, expenseDate: $expenseDate, merchant: $merchant, paymentMethod: $paymentMethod, installmentMonths: $installmentMonths, refundedAt: $refundedAt, refundTransferRowId: $refundTransferRowId, refundedAmount: $refundedAmount, cardSettledThrough: $cardSettledThrough, recordOnlyAmount: $recordOnlyAmount, moneyLocked: $moneyLocked, replaceable: $replaceable, originalAmount: $originalAmount, originalCurrency: $originalCurrency, exchangeRate: $exchangeRate, autoSource: $autoSource, deletable: $deletable, calendarEventRowId: $calendarEventRowId, todoRowId: $todoRowId, splitCategoryRowIds: $splitCategoryRowIds, isFixed: $isFixed, createAt: $createAt, modifyAt: $modifyAt)';
}


}

/// @nodoc
abstract mixin class $ExpenseCopyWith<$Res>  {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) _then) = _$ExpenseCopyWithImpl;
@useResult
$Res call({
 int rowId, int? userRowId, int? categoryRowId, String? categoryName, String? categoryIcon, String? categoryColor, int? assetRowId, String? assetName, String expenseType, int amount, String? description, String? expenseDate, String? merchant, String? paymentMethod, int? installmentMonths, String? refundedAt, int? refundTransferRowId, int? refundedAmount, String? cardSettledThrough, int? recordOnlyAmount, bool moneyLocked, bool? replaceable, double? originalAmount, String? originalCurrency, double? exchangeRate, String? autoSource, bool? deletable, int? calendarEventRowId, int? todoRowId, List<int> splitCategoryRowIds, bool isFixed, String? createAt, String? modifyAt
});




}
/// @nodoc
class _$ExpenseCopyWithImpl<$Res>
    implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._self, this._then);

  final Expense _self;
  final $Res Function(Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowId = null,Object? userRowId = freezed,Object? categoryRowId = freezed,Object? categoryName = freezed,Object? categoryIcon = freezed,Object? categoryColor = freezed,Object? assetRowId = freezed,Object? assetName = freezed,Object? expenseType = null,Object? amount = null,Object? description = freezed,Object? expenseDate = freezed,Object? merchant = freezed,Object? paymentMethod = freezed,Object? installmentMonths = freezed,Object? refundedAt = freezed,Object? refundTransferRowId = freezed,Object? refundedAmount = freezed,Object? cardSettledThrough = freezed,Object? recordOnlyAmount = freezed,Object? moneyLocked = null,Object? replaceable = freezed,Object? originalAmount = freezed,Object? originalCurrency = freezed,Object? exchangeRate = freezed,Object? autoSource = freezed,Object? deletable = freezed,Object? calendarEventRowId = freezed,Object? todoRowId = freezed,Object? splitCategoryRowIds = null,Object? isFixed = null,Object? createAt = freezed,Object? modifyAt = freezed,}) {
  return _then(_self.copyWith(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryRowId: freezed == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,categoryIcon: freezed == categoryIcon ? _self.categoryIcon : categoryIcon // ignore: cast_nullable_to_non_nullable
as String?,categoryColor: freezed == categoryColor ? _self.categoryColor : categoryColor // ignore: cast_nullable_to_non_nullable
as String?,assetRowId: freezed == assetRowId ? _self.assetRowId : assetRowId // ignore: cast_nullable_to_non_nullable
as int?,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,expenseType: null == expenseType ? _self.expenseType : expenseType // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,expenseDate: freezed == expenseDate ? _self.expenseDate : expenseDate // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,installmentMonths: freezed == installmentMonths ? _self.installmentMonths : installmentMonths // ignore: cast_nullable_to_non_nullable
as int?,refundedAt: freezed == refundedAt ? _self.refundedAt : refundedAt // ignore: cast_nullable_to_non_nullable
as String?,refundTransferRowId: freezed == refundTransferRowId ? _self.refundTransferRowId : refundTransferRowId // ignore: cast_nullable_to_non_nullable
as int?,refundedAmount: freezed == refundedAmount ? _self.refundedAmount : refundedAmount // ignore: cast_nullable_to_non_nullable
as int?,cardSettledThrough: freezed == cardSettledThrough ? _self.cardSettledThrough : cardSettledThrough // ignore: cast_nullable_to_non_nullable
as String?,recordOnlyAmount: freezed == recordOnlyAmount ? _self.recordOnlyAmount : recordOnlyAmount // ignore: cast_nullable_to_non_nullable
as int?,moneyLocked: null == moneyLocked ? _self.moneyLocked : moneyLocked // ignore: cast_nullable_to_non_nullable
as bool,replaceable: freezed == replaceable ? _self.replaceable : replaceable // ignore: cast_nullable_to_non_nullable
as bool?,originalAmount: freezed == originalAmount ? _self.originalAmount : originalAmount // ignore: cast_nullable_to_non_nullable
as double?,originalCurrency: freezed == originalCurrency ? _self.originalCurrency : originalCurrency // ignore: cast_nullable_to_non_nullable
as String?,exchangeRate: freezed == exchangeRate ? _self.exchangeRate : exchangeRate // ignore: cast_nullable_to_non_nullable
as double?,autoSource: freezed == autoSource ? _self.autoSource : autoSource // ignore: cast_nullable_to_non_nullable
as String?,deletable: freezed == deletable ? _self.deletable : deletable // ignore: cast_nullable_to_non_nullable
as bool?,calendarEventRowId: freezed == calendarEventRowId ? _self.calendarEventRowId : calendarEventRowId // ignore: cast_nullable_to_non_nullable
as int?,todoRowId: freezed == todoRowId ? _self.todoRowId : todoRowId // ignore: cast_nullable_to_non_nullable
as int?,splitCategoryRowIds: null == splitCategoryRowIds ? _self.splitCategoryRowIds : splitCategoryRowIds // ignore: cast_nullable_to_non_nullable
as List<int>,isFixed: null == isFixed ? _self.isFixed : isFixed // ignore: cast_nullable_to_non_nullable
as bool,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,modifyAt: freezed == modifyAt ? _self.modifyAt : modifyAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Expense].
extension ExpensePatterns on Expense {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Expense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Expense value)  $default,){
final _that = this;
switch (_that) {
case _Expense():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Expense value)?  $default,){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  int? categoryRowId,  String? categoryName,  String? categoryIcon,  String? categoryColor,  int? assetRowId,  String? assetName,  String expenseType,  int amount,  String? description,  String? expenseDate,  String? merchant,  String? paymentMethod,  int? installmentMonths,  String? refundedAt,  int? refundTransferRowId,  int? refundedAmount,  String? cardSettledThrough,  int? recordOnlyAmount,  bool moneyLocked,  bool? replaceable,  double? originalAmount,  String? originalCurrency,  double? exchangeRate,  String? autoSource,  bool? deletable,  int? calendarEventRowId,  int? todoRowId,  List<int> splitCategoryRowIds,  bool isFixed,  String? createAt,  String? modifyAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.categoryRowId,_that.categoryName,_that.categoryIcon,_that.categoryColor,_that.assetRowId,_that.assetName,_that.expenseType,_that.amount,_that.description,_that.expenseDate,_that.merchant,_that.paymentMethod,_that.installmentMonths,_that.refundedAt,_that.refundTransferRowId,_that.refundedAmount,_that.cardSettledThrough,_that.recordOnlyAmount,_that.moneyLocked,_that.replaceable,_that.originalAmount,_that.originalCurrency,_that.exchangeRate,_that.autoSource,_that.deletable,_that.calendarEventRowId,_that.todoRowId,_that.splitCategoryRowIds,_that.isFixed,_that.createAt,_that.modifyAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowId,  int? userRowId,  int? categoryRowId,  String? categoryName,  String? categoryIcon,  String? categoryColor,  int? assetRowId,  String? assetName,  String expenseType,  int amount,  String? description,  String? expenseDate,  String? merchant,  String? paymentMethod,  int? installmentMonths,  String? refundedAt,  int? refundTransferRowId,  int? refundedAmount,  String? cardSettledThrough,  int? recordOnlyAmount,  bool moneyLocked,  bool? replaceable,  double? originalAmount,  String? originalCurrency,  double? exchangeRate,  String? autoSource,  bool? deletable,  int? calendarEventRowId,  int? todoRowId,  List<int> splitCategoryRowIds,  bool isFixed,  String? createAt,  String? modifyAt)  $default,) {final _that = this;
switch (_that) {
case _Expense():
return $default(_that.rowId,_that.userRowId,_that.categoryRowId,_that.categoryName,_that.categoryIcon,_that.categoryColor,_that.assetRowId,_that.assetName,_that.expenseType,_that.amount,_that.description,_that.expenseDate,_that.merchant,_that.paymentMethod,_that.installmentMonths,_that.refundedAt,_that.refundTransferRowId,_that.refundedAmount,_that.cardSettledThrough,_that.recordOnlyAmount,_that.moneyLocked,_that.replaceable,_that.originalAmount,_that.originalCurrency,_that.exchangeRate,_that.autoSource,_that.deletable,_that.calendarEventRowId,_that.todoRowId,_that.splitCategoryRowIds,_that.isFixed,_that.createAt,_that.modifyAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowId,  int? userRowId,  int? categoryRowId,  String? categoryName,  String? categoryIcon,  String? categoryColor,  int? assetRowId,  String? assetName,  String expenseType,  int amount,  String? description,  String? expenseDate,  String? merchant,  String? paymentMethod,  int? installmentMonths,  String? refundedAt,  int? refundTransferRowId,  int? refundedAmount,  String? cardSettledThrough,  int? recordOnlyAmount,  bool moneyLocked,  bool? replaceable,  double? originalAmount,  String? originalCurrency,  double? exchangeRate,  String? autoSource,  bool? deletable,  int? calendarEventRowId,  int? todoRowId,  List<int> splitCategoryRowIds,  bool isFixed,  String? createAt,  String? modifyAt)?  $default,) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.rowId,_that.userRowId,_that.categoryRowId,_that.categoryName,_that.categoryIcon,_that.categoryColor,_that.assetRowId,_that.assetName,_that.expenseType,_that.amount,_that.description,_that.expenseDate,_that.merchant,_that.paymentMethod,_that.installmentMonths,_that.refundedAt,_that.refundTransferRowId,_that.refundedAmount,_that.cardSettledThrough,_that.recordOnlyAmount,_that.moneyLocked,_that.replaceable,_that.originalAmount,_that.originalCurrency,_that.exchangeRate,_that.autoSource,_that.deletable,_that.calendarEventRowId,_that.todoRowId,_that.splitCategoryRowIds,_that.isFixed,_that.createAt,_that.modifyAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Expense implements Expense {
  const _Expense({required this.rowId, this.userRowId, this.categoryRowId, this.categoryName, this.categoryIcon, this.categoryColor, this.assetRowId, this.assetName, required this.expenseType, required this.amount, this.description, this.expenseDate, this.merchant, this.paymentMethod, this.installmentMonths, this.refundedAt, this.refundTransferRowId, this.refundedAmount, this.cardSettledThrough, this.recordOnlyAmount, this.moneyLocked = false, this.replaceable, this.originalAmount, this.originalCurrency, this.exchangeRate, this.autoSource, this.deletable, this.calendarEventRowId, this.todoRowId, final  List<int> splitCategoryRowIds = const <int>[], this.isFixed = false, this.createAt, this.modifyAt}): _splitCategoryRowIds = splitCategoryRowIds;
  factory _Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);

@override final  int rowId;
@override final  int? userRowId;
@override final  int? categoryRowId;
@override final  String? categoryName;
@override final  String? categoryIcon;
@override final  String? categoryColor;
@override final  int? assetRowId;
@override final  String? assetName;
@override final  String expenseType;
// 'EXPENSE' | 'INCOME'
@override final  int amount;
@override final  String? description;
@override final  String? expenseDate;
// ISO LocalDateTime ('YYYY-MM-DDTHH:mm:ss')
@override final  String? merchant;
@override final  String? paymentMethod;
/// 할부 개월 (null = 일시불). 신용카드 결제에만 의미.
@override final  int? installmentMonths;
/// 환불 처리 시각 (null = 환불 아님). ISO LocalDateTime.
///
/// 환불은 **원거래에 찍는 표식**이다 — 수입 행을 만들지 않는다. 있으면
/// 합계·예산·통계·카드 청구에서 삭제와 똑같이 빠지고, 내역·검색에는 남는다.
@override final  String? refundedAt;
/// 옛 환불 마크가 만든 카드→결제계좌 환급 이체 (null = 없음).
///
/// 이제 환불은 이체를 만들지 않는다(D1). 이 값이 있는 옛 거래만 환불을 취소할 때
/// 그 이체까지 되돌아간다 — 그래서 확인창이 "환급된 금액도 되돌아가요" 를 말한다.
@override final  int? refundTransferRowId;
/// 이 요청이 **방금** 결제계좌로 돌려준 금액 (null = 없음).
///
/// 열린 회차에서 미리 낸 돈이 남을 때만 생긴다(D3). 거래의 속성이 아니라 그 요청의
/// 결과다 — 조회로 받은 거래에는 늘 null 이다. 화면이 "미리 낸 돈 중 N원이 계좌로
/// 돌아왔어요" 를 말할 재료다(D4).
@override final  int? refundedAmount;
/// 이 날짜(회차 말일)까지의 카드 회차분은 계좌 이체 없이 정리된 **기록용** (null = 정상).
///
/// 결제가 끝난(닫힌) 회차에 뒤늦게 적은 카드 지출에 붙는다 — 가계부 합계에는 들어가지만
/// 계좌에서는 빠지지 않았고 이후 청구에도 안 얹힌다(닫힌 회차 규칙 R2). 'YYYY-MM-DD'.
@override final  String? cardSettledThrough;
/// 그 가운데 기록만 남긴 금액 — 할부는 지난 회차분만이라 거래 금액보다 작을 수 있다.
///
/// 금액과 같을 때만 목록 행에 "기록만" 배지를 단다. 작으면 할부 일부라 상세에서
/// "이 중 N원" 으로 말한다(D10).
@override final  int? recordOnlyAmount;
/// 돈 칸 잠금(D12) — 결제일이 된 회차분이 하나라도 있는 신용카드 거래(또는 기록용
/// 표식이 있는 거래)면 서버가 true 로 내린다.
///
/// true 면 금액·날짜·시간·자산·할부·유형·통화 3칸·결제수단을 못 고친다. 카테고리·
/// 가맹점·메모만 고치고, 돈 칸은 [고쳐 쓰기](`POST /expense/{id}/replace`)로 바꾼다.
/// 옛 서버면 false.
@override@JsonKey() final  bool moneyLocked;
/// [고쳐 쓰기] 를 쓸 수 있는 거래인가 — 잠겼고(`moneyLocked`) 환불 안 됐고 자동 생성이
/// 아니고 중도 정리하지 않은 할부. 서버가 판정해 내려 준다(QA 26 3).
///
/// 잠겼는데 이게 false 면 사실상 중도 정리한 할부다 — 서버가 교체를 EXP_047 로 거절한다.
/// 옛 서버면 없다(null) — 그때는 잠금으로 본다.
@override final  bool? replaceable;
/// 원 통화 금액 (해외 결제). null 이면 원화 결제 — amount 가 곧 결제액이다.
@override final  double? originalAmount;
/// 원 통화 (ISO 4217, 예: USD).
@override final  String? originalCurrency;
/// 적용 환율 (원 통화 1단위당 원화). amount ≈ originalAmount × exchangeRate.
@override final  double? exchangeRate;
/// 시스템이 만든 거래의 출처 — `TRADE_REALIZED`(매도 실현손익) /
/// `TRANSFER_INTEREST`(이체 이자). null 이면 손으로 쓴 거래다.
///
/// 값이 있으면 금액·날짜·자산은 계산 결과라 고칠 수 없다. 원본 거래를 지우면
/// 함께 사라진다. 카테고리·메모는 분류라서 그대로 고칠 수 있다.
@override final  String? autoSource;
/// 이 기록을 지금 직접 지울 수 있나 — 서버가 판정해 내려 준다. 자동 생성이 아니면 true,
/// 자동 생성이어도 그 기록을 만든 증권 자산이 이미 삭제됐으면 true. **삭제 버튼 · 스와이프 [삭제] 만**
/// 이 값을 본다(수정 · 환불 · 분할은 [autoSource] 그대로). 옛 서버면 없다(null) — [canDelete] 가 폴백한다.
@override final  bool? deletable;
@override final  int? calendarEventRowId;
@override final  int? todoRowId;
// 활성 분할 항목들의 카테고리 id (없으면 빈 리스트). 목록 카테고리 필터를 split-aware 하게 매칭.
 final  List<int> _splitCategoryRowIds;
// 활성 분할 항목들의 카테고리 id (없으면 빈 리스트). 목록 카테고리 필터를 split-aware 하게 매칭.
@override@JsonKey() List<int> get splitCategoryRowIds {
  if (_splitCategoryRowIds is EqualUnmodifiableListView) return _splitCategoryRowIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_splitCategoryRowIds);
}

/// 고정 수입·지출 — 월세·월급처럼 매달 정해진 거래. 통계가 전체 · 고정 · 변동으로 나눠 보는
/// **분류 표식**이다(돈·잔액·카드 청구에는 영향 없음). 이체는 대상이 아니다. 옛 서버면 false.
@override@JsonKey() final  bool isFixed;
@override final  String? createAt;
@override final  String? modifyAt;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseCopyWith<_Expense> get copyWith => __$ExpenseCopyWithImpl<_Expense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Expense&&(identical(other.rowId, rowId) || other.rowId == rowId)&&(identical(other.userRowId, userRowId) || other.userRowId == userRowId)&&(identical(other.categoryRowId, categoryRowId) || other.categoryRowId == categoryRowId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryIcon, categoryIcon) || other.categoryIcon == categoryIcon)&&(identical(other.categoryColor, categoryColor) || other.categoryColor == categoryColor)&&(identical(other.assetRowId, assetRowId) || other.assetRowId == assetRowId)&&(identical(other.assetName, assetName) || other.assetName == assetName)&&(identical(other.expenseType, expenseType) || other.expenseType == expenseType)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description)&&(identical(other.expenseDate, expenseDate) || other.expenseDate == expenseDate)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.installmentMonths, installmentMonths) || other.installmentMonths == installmentMonths)&&(identical(other.refundedAt, refundedAt) || other.refundedAt == refundedAt)&&(identical(other.refundTransferRowId, refundTransferRowId) || other.refundTransferRowId == refundTransferRowId)&&(identical(other.refundedAmount, refundedAmount) || other.refundedAmount == refundedAmount)&&(identical(other.cardSettledThrough, cardSettledThrough) || other.cardSettledThrough == cardSettledThrough)&&(identical(other.recordOnlyAmount, recordOnlyAmount) || other.recordOnlyAmount == recordOnlyAmount)&&(identical(other.moneyLocked, moneyLocked) || other.moneyLocked == moneyLocked)&&(identical(other.replaceable, replaceable) || other.replaceable == replaceable)&&(identical(other.originalAmount, originalAmount) || other.originalAmount == originalAmount)&&(identical(other.originalCurrency, originalCurrency) || other.originalCurrency == originalCurrency)&&(identical(other.exchangeRate, exchangeRate) || other.exchangeRate == exchangeRate)&&(identical(other.autoSource, autoSource) || other.autoSource == autoSource)&&(identical(other.deletable, deletable) || other.deletable == deletable)&&(identical(other.calendarEventRowId, calendarEventRowId) || other.calendarEventRowId == calendarEventRowId)&&(identical(other.todoRowId, todoRowId) || other.todoRowId == todoRowId)&&const DeepCollectionEquality().equals(other._splitCategoryRowIds, _splitCategoryRowIds)&&(identical(other.isFixed, isFixed) || other.isFixed == isFixed)&&(identical(other.createAt, createAt) || other.createAt == createAt)&&(identical(other.modifyAt, modifyAt) || other.modifyAt == modifyAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,rowId,userRowId,categoryRowId,categoryName,categoryIcon,categoryColor,assetRowId,assetName,expenseType,amount,description,expenseDate,merchant,paymentMethod,installmentMonths,refundedAt,refundTransferRowId,refundedAmount,cardSettledThrough,recordOnlyAmount,moneyLocked,replaceable,originalAmount,originalCurrency,exchangeRate,autoSource,deletable,calendarEventRowId,todoRowId,const DeepCollectionEquality().hash(_splitCategoryRowIds),isFixed,createAt,modifyAt]);

@override
String toString() {
  return 'Expense(rowId: $rowId, userRowId: $userRowId, categoryRowId: $categoryRowId, categoryName: $categoryName, categoryIcon: $categoryIcon, categoryColor: $categoryColor, assetRowId: $assetRowId, assetName: $assetName, expenseType: $expenseType, amount: $amount, description: $description, expenseDate: $expenseDate, merchant: $merchant, paymentMethod: $paymentMethod, installmentMonths: $installmentMonths, refundedAt: $refundedAt, refundTransferRowId: $refundTransferRowId, refundedAmount: $refundedAmount, cardSettledThrough: $cardSettledThrough, recordOnlyAmount: $recordOnlyAmount, moneyLocked: $moneyLocked, replaceable: $replaceable, originalAmount: $originalAmount, originalCurrency: $originalCurrency, exchangeRate: $exchangeRate, autoSource: $autoSource, deletable: $deletable, calendarEventRowId: $calendarEventRowId, todoRowId: $todoRowId, splitCategoryRowIds: $splitCategoryRowIds, isFixed: $isFixed, createAt: $createAt, modifyAt: $modifyAt)';
}


}

/// @nodoc
abstract mixin class _$ExpenseCopyWith<$Res> implements $ExpenseCopyWith<$Res> {
  factory _$ExpenseCopyWith(_Expense value, $Res Function(_Expense) _then) = __$ExpenseCopyWithImpl;
@override @useResult
$Res call({
 int rowId, int? userRowId, int? categoryRowId, String? categoryName, String? categoryIcon, String? categoryColor, int? assetRowId, String? assetName, String expenseType, int amount, String? description, String? expenseDate, String? merchant, String? paymentMethod, int? installmentMonths, String? refundedAt, int? refundTransferRowId, int? refundedAmount, String? cardSettledThrough, int? recordOnlyAmount, bool moneyLocked, bool? replaceable, double? originalAmount, String? originalCurrency, double? exchangeRate, String? autoSource, bool? deletable, int? calendarEventRowId, int? todoRowId, List<int> splitCategoryRowIds, bool isFixed, String? createAt, String? modifyAt
});




}
/// @nodoc
class __$ExpenseCopyWithImpl<$Res>
    implements _$ExpenseCopyWith<$Res> {
  __$ExpenseCopyWithImpl(this._self, this._then);

  final _Expense _self;
  final $Res Function(_Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowId = null,Object? userRowId = freezed,Object? categoryRowId = freezed,Object? categoryName = freezed,Object? categoryIcon = freezed,Object? categoryColor = freezed,Object? assetRowId = freezed,Object? assetName = freezed,Object? expenseType = null,Object? amount = null,Object? description = freezed,Object? expenseDate = freezed,Object? merchant = freezed,Object? paymentMethod = freezed,Object? installmentMonths = freezed,Object? refundedAt = freezed,Object? refundTransferRowId = freezed,Object? refundedAmount = freezed,Object? cardSettledThrough = freezed,Object? recordOnlyAmount = freezed,Object? moneyLocked = null,Object? replaceable = freezed,Object? originalAmount = freezed,Object? originalCurrency = freezed,Object? exchangeRate = freezed,Object? autoSource = freezed,Object? deletable = freezed,Object? calendarEventRowId = freezed,Object? todoRowId = freezed,Object? splitCategoryRowIds = null,Object? isFixed = null,Object? createAt = freezed,Object? modifyAt = freezed,}) {
  return _then(_Expense(
rowId: null == rowId ? _self.rowId : rowId // ignore: cast_nullable_to_non_nullable
as int,userRowId: freezed == userRowId ? _self.userRowId : userRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryRowId: freezed == categoryRowId ? _self.categoryRowId : categoryRowId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,categoryIcon: freezed == categoryIcon ? _self.categoryIcon : categoryIcon // ignore: cast_nullable_to_non_nullable
as String?,categoryColor: freezed == categoryColor ? _self.categoryColor : categoryColor // ignore: cast_nullable_to_non_nullable
as String?,assetRowId: freezed == assetRowId ? _self.assetRowId : assetRowId // ignore: cast_nullable_to_non_nullable
as int?,assetName: freezed == assetName ? _self.assetName : assetName // ignore: cast_nullable_to_non_nullable
as String?,expenseType: null == expenseType ? _self.expenseType : expenseType // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,expenseDate: freezed == expenseDate ? _self.expenseDate : expenseDate // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,installmentMonths: freezed == installmentMonths ? _self.installmentMonths : installmentMonths // ignore: cast_nullable_to_non_nullable
as int?,refundedAt: freezed == refundedAt ? _self.refundedAt : refundedAt // ignore: cast_nullable_to_non_nullable
as String?,refundTransferRowId: freezed == refundTransferRowId ? _self.refundTransferRowId : refundTransferRowId // ignore: cast_nullable_to_non_nullable
as int?,refundedAmount: freezed == refundedAmount ? _self.refundedAmount : refundedAmount // ignore: cast_nullable_to_non_nullable
as int?,cardSettledThrough: freezed == cardSettledThrough ? _self.cardSettledThrough : cardSettledThrough // ignore: cast_nullable_to_non_nullable
as String?,recordOnlyAmount: freezed == recordOnlyAmount ? _self.recordOnlyAmount : recordOnlyAmount // ignore: cast_nullable_to_non_nullable
as int?,moneyLocked: null == moneyLocked ? _self.moneyLocked : moneyLocked // ignore: cast_nullable_to_non_nullable
as bool,replaceable: freezed == replaceable ? _self.replaceable : replaceable // ignore: cast_nullable_to_non_nullable
as bool?,originalAmount: freezed == originalAmount ? _self.originalAmount : originalAmount // ignore: cast_nullable_to_non_nullable
as double?,originalCurrency: freezed == originalCurrency ? _self.originalCurrency : originalCurrency // ignore: cast_nullable_to_non_nullable
as String?,exchangeRate: freezed == exchangeRate ? _self.exchangeRate : exchangeRate // ignore: cast_nullable_to_non_nullable
as double?,autoSource: freezed == autoSource ? _self.autoSource : autoSource // ignore: cast_nullable_to_non_nullable
as String?,deletable: freezed == deletable ? _self.deletable : deletable // ignore: cast_nullable_to_non_nullable
as bool?,calendarEventRowId: freezed == calendarEventRowId ? _self.calendarEventRowId : calendarEventRowId // ignore: cast_nullable_to_non_nullable
as int?,todoRowId: freezed == todoRowId ? _self.todoRowId : todoRowId // ignore: cast_nullable_to_non_nullable
as int?,splitCategoryRowIds: null == splitCategoryRowIds ? _self._splitCategoryRowIds : splitCategoryRowIds // ignore: cast_nullable_to_non_nullable
as List<int>,isFixed: null == isFixed ? _self.isFixed : isFixed // ignore: cast_nullable_to_non_nullable
as bool,createAt: freezed == createAt ? _self.createAt : createAt // ignore: cast_nullable_to_non_nullable
as String?,modifyAt: freezed == modifyAt ? _self.modifyAt : modifyAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
