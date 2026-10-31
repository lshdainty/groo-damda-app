import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 상세 머리의 날짜 · 시각 — "10월 28일 (수) 오후 12:00". 다른 해면 연도가 붙고(`monthDayDow`), 시각이 00:00 이면 날짜만 쓴다
/// (시각 없는 거래가 흔하다). 읽을 수 없으면 null — 줄을 그리지 않는다.
String? txDetailDateTimeLabel(String? iso) {
  if (iso == null || iso.length < 10) return null;
  final day = DateTime.tryParse(iso.substring(0, 10));
  if (day == null) return null;
  final time = iso.length >= 16 ? iso.substring(11, 16) : null;
  if (time == null || time == '00:00') return monthDayDow(day);
  final h = int.tryParse(time.substring(0, 2));
  final m = int.tryParse(time.substring(3, 5));
  if (h == null || m == null) return monthDayDow(day);
  return '${monthDayDow(day)} ${timeOfDay12(DateTime(day.year, day.month, day.day, h, m))}';
}

/// 카테고리 줄의 값 — 하위 거래면 "{상위} · {하위}". 목록에서 못 찾으면(지운 카테고리) 거래가 든 이름을 쓴다.
String txCategoryLabel(
  Expense e,
  List<ExpenseCategory> categories,
  String uncategorized,
) {
  final id = e.categoryRowId;
  final cat = id == null ? null : categories.byRowId(id);
  if (cat == null) return e.categoryName ?? uncategorized;
  final parentId = cat.parentRowId;
  final parent = parentId == null ? null : categories.byRowId(parentId);
  return parent == null
      ? cat.categoryName
      : '${parent.categoryName} · ${cat.categoryName}';
}

/// 결제 수단 줄의 값 — 모르는 값이면 null(줄을 그리지 않는다).
String? txPaymentMethodLabel(AppLocalizations l, String? m) => switch (m) {
  'CASH' => l.expPayCash,
  'CARD' => l.expPayCard,
  'TRANSFER' => l.expPayTransfer,
  'OTHER' => l.expPayOther,
  _ => null,
};

/// 계좌·카드 줄의 값 — "{기관} · {이름}"(기관과 이름이 같으면 한 번만). 못 찾으면 거래가 든 이름.
String? txAssetLabel({
  required String? institution,
  required String? assetName,
  required String? fallbackName,
}) {
  if (assetName == null) return fallbackName;
  return institution != null &&
          institution.isNotEmpty &&
          institution != assetName
      ? '$institution · $assetName'
      : assetName;
}

/// "이 가맹점 이번 달" 묶음의 재료 — 이 거래를 뺀 줄(최대 [kTxHistoryRows])과 머리 숫자(이 거래를 포함한 이 달 전체).
const int kTxHistoryRows = 5;

typedef TxHistory = ({
  List<Expense> rows,
  bool overflow,
  int monthCount,
  int monthTotal,
});

TxHistory txHistoryOf(List<Expense> all, int excludeRowId) {
  final others = [
    for (final x in all)
      if (x.rowId != excludeRowId) x,
  ];
  return (
    rows: others.take(kTxHistoryRows).toList(),
    overflow: others.length > kTxHistoryRows,
    monthCount: all.length,
    // 합계에서 환불된 거래는 뺀다(환불 안내가 "합계에서 빠져요" 라 머리 합계와 어긋나지 않게 — 웹과 같다). 건수는 줄이 보이는 대로 센다
    monthTotal: all
        .where((x) => !x.isRefunded)
        .fold<int>(0, (s, x) => s + x.amount.abs()),
  );
}

/// 날짜(YYYY-MM-DD) 순서를 지키며 묶는다.
List<(String, List<Expense>)> txHistoryByDay(List<Expense> rows) {
  final groups = <String, List<Expense>>{};
  for (final h in rows) {
    groups.putIfAbsent(h.expenseDateOnly ?? '', () => <Expense>[]).add(h);
  }
  return [for (final e in groups.entries) (e.key, e.value)];
}

/// "더 하기" 줄 값 — 이 거래로 만든 반복 수(있으면 "연결됨").
int linkedRecurringCount(List<RecurringTransaction>? list, int expenseRowId) =>
    list?.where((r) => r.sourceExpenseRowId == expenseRowId).length ?? 0;

/// "더 하기" 줄 값 — 이 거래로 만든 더치페이 수.
int linkedDutchPayCount(List<DutchPay>? list, int expenseRowId) =>
    list?.where((d) => d.sourceExpenseRowId == expenseRowId).length ?? 0;

/// 환불 문장 갈래 — 닫힌 회차 · 계좌·카드 없음이면 돌아갈 곳이 없어 표시만 말한다.
bool refundOnlyMark({required bool closedCycle, required String? assetName}) =>
    closedCycle || assetName == null;

/// 금액 문장에 쓰는 글 — "114,200원"(가리면 점).
String txMoney(int amount, bool masked) =>
    krwSigned(amount.abs(), masked, unit: true);

/// 1400.000000 을 1400 으로 — 상세에 소수 6자리를 그대로 보여 주면 지저분하다.
String txTrimRate(double rate) {
  final s = rate.toStringAsFixed(6);
  return s.contains('.')
      ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : s;
}
