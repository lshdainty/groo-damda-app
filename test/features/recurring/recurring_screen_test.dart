// 반복 거래 관리(I-20 D 21 ~ 25) — 목록 · 상세 · 일시정지 · 삭제.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/data/recurring_repository.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_screen.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

import 'recurring_test_support.dart';

class _Repo extends RecurringRepository {
  _Repo(this.items, {this.fail = false}) : super(Dio());
  List<RecurringTransaction> items;
  final bool fail;
  final calls = <String>[];

  @override
  Future<List<RecurringTransaction>> list({
    bool? upcoming,
    int? limit,
    bool silent = false,
  }) async => [...items];

  @override
  Future<void> toggle(int id, {bool silent = false}) async {
    calls.add('toggle $id silent=$silent');
    if (fail) throw ApiException(code: 'X', message: '이자는 금액보다 클 수 없습니다.');
    items = [
      for (final r in items)
        r.rowId == id ? r.copyWith(isActive: r.isActive == 'Y' ? 'N' : 'Y') : r,
    ];
  }

  @override
  Future<void> delete(int id, {bool silent = false}) async {
    calls.add('delete $id silent=$silent');
    if (fail) throw ApiException(code: 'X', message: '이자는 금액보다 클 수 없습니다.');
    items = [
      for (final r in items)
        if (r.rowId != id) r,
    ];
  }
}

Future<_Repo> _pump(
  WidgetTester tester,
  List<RecurringTransaction> items, {
  bool fail = false,
}) async {
  final repo = _Repo(items, fail: fail);
  await pumpApp(tester, const RecurringScreen(), [
    recurringRepositoryProvider.overrideWith((ref) async => repo),
    categoriesProvider.overrideWith((ref) async => const []),
  ]);
  return repo;
}

void main() {
  final items = [
    rec(1, '관리비', 234560),
    rec(2, '급여', 990000, type: 'INCOME', dom: 21),
    rec(3, '적금 이체', 100000, type: 'TRANSFER', dom: 10, active: 'N'),
  ];

  testWidgets('종류별 묶음 — 지출 → 수입 → 이체 · 빈 묶음은 없다', (tester) async {
    await _pump(tester, [items[2], items[1], items[0]]);
    expect(plain('지출 1개'), findsOneWidget);
    expect(plain('수입 1개'), findsOneWidget);
    expect(plain('이체 1개'), findsOneWidget);
    double y(String s) => tester.getTopLeft(plain(s)).dy;
    expect(y('지출 1개') < y('수입 1개'), isTrue);
    expect(y('수입 1개') < y('이체 1개'), isTrue);
  });

  testWidgets('줄 설명 — 켜짐 "다음 …" · 쉬는 중 "쉬는 중 · …" + Badge', (tester) async {
    await _pump(tester, items);
    expect(plainStarts('다음 11월 25일'), findsOneWidget);
    expect(plainStarts('쉬는 중 · 매월 10일'), findsOneWidget);
    expect(plain('일시정지'), findsOneWidget); // 쉬는 줄 Badge
  });

  testWidgets('줄 끝 ⋮ 가 없다 — 줄 누름 = 상세', (tester) async {
    await _pump(tester, items);
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
    expect(find.byType(PListButtonItem), findsNWidgets(3));
  });

  testWidgets('상세 — 바닥은 [일시정지][수정], 삭제는 바닥에 없고 머리 ⋮ 안', (tester) async {
    await _pump(tester, items);
    await tester.tap(plainStarts('관리비').first);
    await tester.pumpAndSettle();
    expect(plain('반복 거래 상세'), findsOneWidget);
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsOneWidget);
    expect(plain('수정'), findsOneWidget);
    expect(plain('삭제'), findsNothing);
    expect(plainStarts('매월 25일, 끝나는 날 없이 반복해요.'), findsOneWidget);
  });

  testWidgets('일시정지 — 요청은 silent, 상세는 열린 채 문장이 바뀐다', (tester) async {
    final repo = await _pump(tester, items);
    await tester.tap(plainStarts('관리비').first);
    await tester.pumpAndSettle();
    await tester.tap(plain('일시정지').last);
    await tester.pumpAndSettle();
    expect(repo.calls, ['toggle 1 silent=true']);
    expect(plain('다시 켜기'), findsWidgets);
    expect(plainStarts('지금은 쉬고 있어요.'), findsOneWidget);
  });

  testWidgets('삭제 — 머리 ⋮ 메뉴 → 확인창 글 → 지운 뒤 닫힌다(silent)', (tester) async {
    final repo = await _pump(tester, items);
    await tester.tap(plainStarts('관리비').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();
    await tester.tap(plain('삭제').last);
    await tester.pumpAndSettle();
    expect(plain('반복 거래 삭제'), findsOneWidget);
    expect(
      plain('"관리비" 반복 설정을 삭제할까요? 이미 기록된 거래는 그대로 남아요. 삭제한 반복 설정은 되돌릴 수 없어요.'),
      findsOneWidget,
    );
    await tester.tap(plain('삭제').last);
    await tester.pumpAndSettle();
    expect(repo.calls, ['delete 1 silent=true']);
    expect(plain('관리비 반복 설정을 삭제했어요'), findsOneWidget); // 스낵바
  });

  testWidgets('삭제 실패 — 스낵바 고정 글 + 다시 시도, 서버 원문은 없다', (tester) async {
    await _pump(tester, items, fail: true);
    await tester.tap(plainStarts('관리비').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();
    await tester.tap(plain('삭제').last);
    await tester.pumpAndSettle();
    await tester.tap(plain('삭제').last);
    await tester.pumpAndSettle();
    expect(plain('반복 설정을 삭제하지 못했어요'), findsOneWidget);
    expect(plain('다시 시도'), findsOneWidget);
    expect(find.text('이자는 금액보다 클 수 없습니다.'), findsNothing);
  });

  testWidgets('비면 Result Section — 머리 "추가" 는 없고 본문 버튼이 하나', (tester) async {
    await _pump(tester, const []);
    expect(plain('반복 거래가 없어요'), findsOneWidget);
    expect(plain('반복 거래 추가'), findsOneWidget);
    expect(plain('추가'), findsNothing);
  });
}
