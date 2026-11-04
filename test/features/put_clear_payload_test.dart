// 칸을 비우고 저장하면 **비워진다** — 수정(PUT) 본문에 명시적 null 이 실린다 (QA #99).
//
// 서버는 2026-09-07 부터 수정 본문의 세 상태를 가른다(desk-back #321, QA #96):
// 키가 없으면 유지, `"key": null` 이면 지움, 값이 오면 교체. 앱은 Dart 의 널 인지 맵
// 엔트리(`'key': ?value`)로 본문을 만들어서 **null 인 칸을 키째 뺐다.** 종전엔 서버가
// "키 없음" 도 null 로 덮어 우연히 지워졌는데, 서버가 셋을 가르기 시작하자 메모 본문을
// 지우고 저장해도 옛 본문이 그대로 남았다.
//
// 여기서 고정하는 것은 둘이다. 둘 다 있어야 이 수정이 안전하다.
//   ① 화면이 **소유한** 칸은 비우면 키가 실리고 값이 null 이다 — 그래야 지워진다
//   ② 화면에 **없는** 칸은 키가 아예 안 실린다 — 안 그러면 다른 화면·웹에서 적어 둔
//      값이 이 화면으로 저장할 때마다 조용히 사라진다. 이게 이 수정의 제일 큰 위험이다
//
// 생성(POST) 경로는 건드리지 않았다 — "안 보냄 = 유지" 는 수정에만 있는 뜻이다.
// 목록·순서 칸(splits · holdings · tagIds · reminderMinutes)도 손대지 않는다. 그 칸들은
// "null=미변경 · 리스트=교체" 라는 뜻이 이미 확정돼 있다(QA #87 · #91).
//
// 서버가 같은 계약을 프리셋과 캘린더로 넓히면서(desk-back #325) 두 도메인이 뒤늦게
// 같은 자리를 밟았다 — 프리셋 거래처·결제 수단·계좌, 일정 설명·장소·라벨이
// 화면에서 비워도 안 지워졌다. 그래서 두 그룹을 여기에 이어 붙인다.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/calendar/data/calendar_repository.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/memo/data/memo_repository.dart';
import 'package:groo_damda_app/features/preset/data/preset_repository.dart';
import 'package:groo_damda_app/features/saving_goal/data/saving_goal_repository.dart';
import 'package:groo_damda_app/features/todo/data/todo_repository.dart';

/// 요청 바디를 잡아 두고 최소 응답을 돌려주는 Dio (holding_sort_order_payload_test 패턴).
(Dio, List<Map<String, dynamic>> captured) _capturingDio(
  Map<String, dynamic> data,
) {
  final captured = <Map<String, dynamic>>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        captured.add((options.data as Map).cast<String, dynamic>());
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'code': 'COMMON_200',
              'message': 'OK',
              'data': data,
            },
          ),
        );
      },
    ),
  );
  return (dio, captured);
}

/// 메서드·경로·본문을 함께 잡는 Dio — 전용 경로(POST/DELETE)를 보는 테스트용.
///
/// [_capturingDio] 는 본문만 잡는다. 환불은 "어느 경로로 갔나" 가 계약의 절반이라
/// (수정 PUT 으로 가면 서버가 400) 메서드와 경로도 함께 본다.
typedef _Call = ({
  String method,
  String path,
  Map<String, dynamic>? body,
  Map<String, dynamic> query,
});

(Dio, List<_Call>) _capturingRequests(Map<String, dynamic> data) {
  final calls = <_Call>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        calls.add((
          method: options.method,
          path: options.path,
          body: (options.data as Map?)?.cast<String, dynamic>(),
          query: options.queryParameters.cast<String, dynamic>(),
        ));
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'code': 'COMMON_200',
              'message': 'OK',
              'data': data,
            },
          ),
        );
      },
    ),
  );
  return (dio, calls);
}

/// 키가 실렸고 그 값이 null 이다 — "지워라".
void expectExplicitNull(Map<String, dynamic> body, String key) {
  expect(body.containsKey(key), isTrue, reason: '$key 키가 빠졌다 — 서버가 옛 값을 지킨다');
  expect(body[key], isNull, reason: '$key 는 null 로 실려야 지워진다');
}

/// 키가 아예 없다 — "건드리지 마라".
void expectAbsent(Map<String, dynamic> body, String key) {
  expect(
    body.containsKey(key),
    isFalse,
    reason: '$key 는 이 화면에 없는 칸이다 — 키를 실으면 남의 값을 지운다. 실린 값=${body[key]}',
  );
}

void main() {
  group('메모', () {
    const memoJson = {'rowId': 1};

    test('본문을 비우면 content 가 명시적 null 로 실린다', () async {
      final (dio, captured) = _capturingDio(memoJson);

      await MemoRepository(dio).update(
        id: 1,
        title: '제목',
        content: const Patch.set(null),
        tag: const Patch.set('개인'),
        color: '#2c70bf',
      );

      expectExplicitNull(captured.single, 'content');
      expect(captured.single['tag'], '개인');
    });

    // 태그도 화면이 비울 수 있는 칸이 됐다 — 서버 마스터 목록에서 "태그 없음" 을
    // 고를 수 있기 때문이다(QA #98). 키를 빼면 서버가 지금 이름으로 태그를 다시
    // 이어 주므로, 비운 것이 다음 저장에서 되살아난다.
    test('태그를 비우면 tag 가 명시적 null 로 실린다', () async {
      final (dio, captured) = _capturingDio(memoJson);

      await MemoRepository(
        dio,
      ).update(id: 1, title: '제목', tag: const Patch.set(null));

      expectExplicitNull(captured.single, 'tag');
    });

    // 태그 아이디는 안 싣는다 — 이름으로만 잇는다. 실으면 목록을 받은 뒤 그 태그가
    // 지워졌을 때 저장 자체가 404 가 된다(desk-back linkByTagId).
    test('태그 아이디는 본문에 없다', () async {
      final (dio, captured) = _capturingDio(memoJson);

      await MemoRepository(
        dio,
      ).update(id: 1, title: '제목', tag: const Patch.set('업무'));

      expectAbsent(captured.single, 'memoTagRowId');
    });

    test('본문에 값이 있으면 그 값이 실린다', () async {
      final (dio, captured) = _capturingDio(memoJson);

      await MemoRepository(
        dio,
      ).update(id: 1, title: '제목', content: const Patch.set('본문'));

      expect(captured.single['content'], '본문');
    });

    test('안 넘긴 칸은 키가 없다 — 서버가 지금 값을 지킨다', () async {
      final (dio, captured) = _capturingDio(memoJson);

      await MemoRepository(dio).update(id: 1, title: '제목');

      expectAbsent(captured.single, 'content');
      expectAbsent(captured.single, 'tag');
      expectAbsent(captured.single, 'color');
    });

    test('생성 경로는 그대로다 — null 인 칸은 키째 빠진다', () async {
      final (dio, captured) = _capturingDio(memoJson);

      await MemoRepository(dio).create(title: '제목');

      expectAbsent(captured.single, 'content');
    });
  });

  group('할 일', () {
    const todoJson = {'rowId': 1, 'title': '제목'};

    test('메모를 비우고 기한을 없애면 둘 다 명시적 null 로 실린다', () async {
      final (dio, captured) = _capturingDio(todoJson);

      await TodoRepository(dio).update(
        id: 1,
        title: '제목',
        content: const Patch.set(null),
        priority: 'MEDIUM',
        category: const Patch.set('업무'),
        dueDate: const Patch.set(null),
      );

      expectExplicitNull(captured.single, 'content');
      expectExplicitNull(captured.single, 'dueDate');
      expect(captured.single['category'], '업무');
    });

    test('"태그 없음" 을 고르면 category 가 명시적 null 로 실린다', () async {
      // 키가 빠지면 서버가 옛 태그를 지킨다 — 앱에서 태그를 뗄 수 없던 원인이다.
      final (dio, captured) = _capturingDio(todoJson);

      await TodoRepository(
        dio,
      ).update(id: 1, title: '제목', category: const Patch.set(null));

      expectExplicitNull(captured.single, 'category');
    });

    test('화면이 태그를 안 넘기면 category 키가 아예 안 실린다', () async {
      final (dio, captured) = _capturingDio(todoJson);

      await TodoRepository(dio).update(id: 1, title: '제목');

      expectAbsent(captured.single, 'category');
    });

    test('태그 칸(tagIds)은 수정 본문에 안 섞인다 — 전용 경로가 따로 있다', () async {
      final (dio, captured) = _capturingDio(todoJson);

      await TodoRepository(dio).update(id: 1, title: '제목');

      expectAbsent(captured.single, 'tagIds');
    });

    test('생성 경로는 그대로다 — null 인 칸은 키째 빠진다', () async {
      final (dio, captured) = _capturingDio(todoJson);

      await TodoRepository(dio).create(title: '제목');

      expectAbsent(captured.single, 'content');
      expectAbsent(captured.single, 'dueDate');
      // 하위 할 일 개념은 걷어냈다(D5) — 부모를 실을 칸이 화면에도 없고 본문에도
      // 안 실린다. 키가 다시 새면 서버가 남의 자식으로 만들어 목록에서 사라진다.
      expectAbsent(captured.single, 'parentRowId');
    });
  });

  group('저축목표', () {
    const goalJson = {'rowId': 1, 'title': '목표', 'targetAmount': 1000};

    test('목표일을 지우면 deadlineDate 가 명시적 null 로 실린다', () async {
      final (dio, captured) = _capturingDio(goalJson);

      await SavingGoalRepository(dio).update(
        id: 1,
        title: '목표',
        targetAmount: 1000,
        deadlineDate: const Patch.set(null),
        icon: 'piggy-bank',
        color: '#2c70bf',
      );

      expectExplicitNull(captured.single, 'deadlineDate');
    });

    test('앱 화면에 없는 설명·연결자산은 키가 없다 — 웹에서 적어 둔 값이 산다', () async {
      final (dio, captured) = _capturingDio(goalJson);

      await SavingGoalRepository(dio).update(
        id: 1,
        title: '목표',
        targetAmount: 1000,
        deadlineDate: const Patch.set(null),
        icon: 'piggy-bank',
        color: '#2c70bf',
      );

      expectAbsent(captured.single, 'description');
      expectAbsent(captured.single, 'linkedAssetRowId');
    });
  });

  group('거래', () {
    const expenseJson = {'rowId': 1, 'expenseType': 'EXPENSE', 'amount': 1000};

    test('시트가 소유한 칸을 비우면 전부 명시적 null 로 실린다', () async {
      final (dio, captured) = _capturingDio(expenseJson);

      await ExpenseRepository(dio).update(
        id: 1,
        categoryRowId: 3,
        assetRowId: const Patch.set(null),
        expenseType: 'EXPENSE',
        amount: 1000,
        expenseDate: '2026-09-08T12:00:00',
        description: const Patch.set(null),
        merchant: const Patch.set(null),
        paymentMethod: const Patch.set(null),
        installmentMonths: const Patch.set(null),
        originalAmount: const Patch.set(null),
        originalCurrency: const Patch.set(null),
        exchangeRate: const Patch.set(null),
      );

      for (final key in [
        'assetRowId',
        'description',
        'merchant',
        'paymentMethod',
        'installmentMonths',
        'originalAmount',
        'originalCurrency',
        'exchangeRate',
      ]) {
        expectExplicitNull(captured.single, key);
      }
    });

    test('환불 표식과 분할은 키가 없다 — 편집 시트에 없는 칸이다', () async {
      final (dio, captured) = _capturingDio(expenseJson);

      await ExpenseRepository(dio).update(
        id: 1,
        categoryRowId: 3,
        expenseType: 'EXPENSE',
        amount: 1000,
        expenseDate: '2026-09-08T12:00:00',
        description: const Patch.set(null),
      );

      // 폐기된 옛 키가 섞이면 서버가 EXP_044 로 400 을 낸다.
      expectAbsent(captured.single, 'refundOfExpenseRowId');
      expectAbsent(captured.single, 'refundedAt');
      expectAbsent(captured.single, 'refundTransferRowId');
      expectAbsent(captured.single, 'splits');
    });

    // 환불은 **전용 경로**다. 수정 PUT 으로 만들 수도 풀 수도 없다 — 원거래를
    // 합계에서 빼는 일이라 "칸 하나 고치기" 와 무게가 다르고, 옛 키를 실으면 서버가
    // 400 을 낸다.
    test('환불은 POST /expense/{id}/refund 로, 환불일만 싣는다', () async {
      final (dio, calls) = _capturingRequests(expenseJson);

      await ExpenseRepository(dio).refund(1, refundedAt: '2026-09-18T12:00:00');

      expect(calls.single.method, 'POST');
      expect(calls.single.path, '/expense/1/refund');
      expect(calls.single.body, {'refundedAt': '2026-09-18T12:00:00'});
    });

    test('환불일을 안 고르면 본문이 빈다 — 서버가 지금으로 찍는다', () async {
      final (dio, calls) = _capturingRequests(expenseJson);

      await ExpenseRepository(dio).refund(1);

      expect(calls.single.body, isEmpty);
    });

    /// 삭제 응답에 선결제 환급액이 실려 온다(D4) — 옛 서버는 본문이 없으므로 그때도
    /// 안 깨진다.
    test('삭제는 환급액을 돌려준다', () async {
      final (dio, _) = _capturingRequests({'refundedAmount': 58600});

      expect(await ExpenseRepository(dio).delete(77), 58600);
    });

    test('본문 없는 옛 응답에서도 null 로 지나간다', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true, 'code': 'COMMON_200', 'message': 'OK'},
            ),
          ),
        ),
      );

      expect(await ExpenseRepository(dio).delete(77), isNull);
    });

    test('환불 취소는 DELETE 다 — 본문이 없다', () async {
      final (dio, calls) = _capturingRequests(expenseJson);

      await ExpenseRepository(dio).cancelRefund(1);

      expect(calls.single.method, 'DELETE');
      expect(calls.single.path, '/expense/1/refund');
      expect(calls.single.body, isNull);
    });

    test('생성 경로는 그대로다 — null 인 칸은 키째 빠진다', () async {
      final (dio, captured) = _capturingDio(expenseJson);

      await ExpenseRepository(dio).create(
        categoryRowId: 3,
        expenseType: 'EXPENSE',
        amount: 1000,
        expenseDate: '2026-09-08T12:00:00',
      );

      expectAbsent(captured.single, 'description');
      expectAbsent(captured.single, 'merchant');
    });
  });

  group('자산', () {
    const assetJson = {
      'rowId': 1,
      'assetName': '주거래',
      'assetType': 'BANK_ACCOUNT',
    };

    test('화면이 넘긴 칸은 비우면 명시적 null 로 실린다', () async {
      final (dio, captured) = _capturingDio(assetJson);

      await AssetRepository(dio).update(
        id: 1,
        assetName: '주거래',
        assetType: 'BANK_ACCOUNT',
        exchangeRate: const Patch.set(null),
        memo: const Patch.set(null),
        creditLimit: const Patch.set(null),
        paymentDay: const Patch.set(null),
        paymentAssetRowId: const Patch.set(null),
      );

      for (final key in [
        'exchangeRate',
        'memo',
        'creditLimit',
        'paymentDay',
        'paymentAssetRowId',
      ]) {
        expectExplicitNull(captured.single, key);
      }
    });

    // 세 화면(계좌·카드·투자)이 이 메서드를 나눠 쓴다. 한 화면이 자기에게 없는 칸까지
    // null 로 실으면 다른 화면에서 적어 둔 값이 지워진다 — 그래서 안 넘긴 칸은 키가 없어야 한다.
    test('안 넘긴 칸은 키가 없다 — 카드 화면 저장이 계좌 메모를 지우지 않는다', () async {
      final (dio, captured) = _capturingDio(assetJson);

      await AssetRepository(dio).update(
        id: 1,
        assetName: '신한카드',
        assetType: 'CHECK_CARD',
        creditLimit: const Patch.set(null),
        paymentDay: const Patch.set(null),
      );

      expectAbsent(captured.single, 'memo');
      expectAbsent(captured.single, 'exchangeRate');
      expectAbsent(captured.single, 'paymentAssetRowId');
      expectAbsent(captured.single, 'color');
      expectAbsent(captured.single, 'institution');
      expectAbsent(captured.single, 'holdings');
    });

    // 투자 자산의 잔액은 "지운다" 가 없는 칸이다 — 보유를 함께 보내면 서버가 평가액을
    // 산정하므로 앱이 계산한 금액을 아예 싣지 않는다. null 을 실으면 그 뜻이 뒤집힌다.
    test('보유를 함께 보낸 투자 자산은 balance 키가 없다', () async {
      final (dio, captured) = _capturingDio(assetJson);

      await AssetRepository(dio).update(
        id: 1,
        assetName: '증권계좌',
        assetType: 'INVESTMENT',
        balance: null,
        memo: const Patch.set(null),
        holdings: const [
          AssetHolding(linked: true, tossSymbol: 'SPY', quantity: '3'),
        ],
      );

      expectAbsent(captured.single, 'balance');
    });

    test('생성 경로는 그대로다 — null 인 칸은 키째 빠진다', () async {
      final (dio, captured) = _capturingDio(assetJson);

      await AssetRepository(
        dio,
      ).create(assetName: '주거래', assetType: 'BANK_ACCOUNT');

      expectAbsent(captured.single, 'memo');
      expectAbsent(captured.single, 'creditLimit');
      expectAbsent(captured.single, 'paymentDay');
    });
  });

  // ─── 프리셋 ────────────────────────────────────
  //
  // 서버가 프리셋 수정 본문도 `Optional` 로 읽기 시작하면서(desk-back #325) 앱이
  // 키를 빼던 칸이 전부 "안 고침" 이 됐다 — 계좌·결제 수단을 '선택 안 함' 으로
  // 되돌리거나 거래처를 지우고 저장해도 옛 값이 그대로 남았다.
  group('프리셋', () {
    const presetJson = {
      'rowId': 1,
      'templateName': '점심',
      'expenseType': 'EXPENSE',
    };

    test('시트가 가진 칸을 비우면 전부 명시적 null 로 실린다', () async {
      final (dio, captured) = _capturingDio(presetJson);

      await PresetRepository(dio).update(
        id: 1,
        templateName: '점심',
        categoryRowId: const Patch.set(3),
        assetRowId: const Patch.set(null),
        expenseType: 'EXPENSE',
        merchant: const Patch.set(null),
        paymentMethod: const Patch.set(null),
      );

      for (final key in ['assetRowId', 'merchant', 'paymentMethod']) {
        expectExplicitNull(captured.single, key);
      }
    });

    test('고른 값은 그대로 실린다', () async {
      final (dio, captured) = _capturingDio(presetJson);

      await PresetRepository(dio).update(
        id: 1,
        templateName: '점심',
        categoryRowId: const Patch.set(3),
        assetRowId: const Patch.set(7),
        expenseType: 'EXPENSE',
        merchant: const Patch.set('김밥천국'),
        paymentMethod: const Patch.set('CARD'),
      );

      expect(captured.single['assetRowId'], 7);
      expect(captured.single['merchant'], '김밥천국');
      expect(captured.single['paymentMethod'], 'CARD');
    });

    // 메모는 편집 시트에 칸이 생겼다(D2). 종전엔 칸이 없어 화면이 읽은 값을 그대로
    // 되돌려 보냈는데(#326), 이제는 다른 칸과 같은 규칙이다 — 비우면 지워져야 한다.
    test('메모를 비우면 description 이 명시적 null 로 실린다', () async {
      final (dio, captured) = _capturingDio(presetJson);

      await PresetRepository(dio).update(
        id: 1,
        templateName: '점심',
        categoryRowId: const Patch.set(3),
        expenseType: 'EXPENSE',
        description: const Patch.set(null),
      );

      expectExplicitNull(captured.single, 'description');
    });

    test('화면이 메모를 안 넘기면 description 키가 아예 안 실린다', () async {
      final (dio, captured) = _capturingDio(presetJson);

      await PresetRepository(dio).update(
        id: 1,
        templateName: '점심',
        categoryRowId: const Patch.set(3),
        expenseType: 'EXPENSE',
        merchant: const Patch.set(null),
      );

      expectAbsent(captured.single, 'description');
      // 순서 칸은 전용 경로가 정한다 — 수정 본문에 섞지 않는다.
      expectAbsent(captured.single, 'sortOrder');
    });

    test('적어 넣은 메모는 그대로 실린다', () async {
      final (dio, captured) = _capturingDio(presetJson);

      await PresetRepository(dio).update(
        id: 1,
        templateName: '점심',
        categoryRowId: const Patch.set(3),
        expenseType: 'EXPENSE',
        description: const Patch.set('회사 근처 김밥천국'),
      );

      expect(captured.single['description'], '회사 근처 김밥천국');
    });

    // 금액은 `lockAmount` 가 정한다 — 서버 `resolveAmount` 가 고정이 꺼져 있으면
    // 실린 금액과 상관없이 null 로 접는다. 그래서 키가 빠져도 금액이 지워진다.
    test('고정 금액을 끄면 lockAmount 가 N 으로 실린다', () async {
      final (dio, captured) = _capturingDio(presetJson);

      await PresetRepository(dio).update(
        id: 1,
        templateName: '점심',
        categoryRowId: const Patch.set(3),
        expenseType: 'EXPENSE',
      );

      expect(captured.single['lockAmount'], 'N');
      expectAbsent(captured.single, 'amount');
    });

    test('생성 경로는 그대로다 — null 인 칸은 키째 빠진다', () async {
      final (dio, captured) = _capturingDio(presetJson);

      await PresetRepository(
        dio,
      ).create(templateName: '점심', expenseType: 'EXPENSE', categoryRowId: 3);

      expectAbsent(captured.single, 'assetRowId');
      expectAbsent(captured.single, 'merchant');
      expectAbsent(captured.single, 'paymentMethod');
      expectAbsent(captured.single, 'description');
    });
  });

  // ─── 캘린더 ────────────────────────────────────
  group('일정', () {
    const eventJson = {
      'rowId': 1,
      'title': '회의',
      'eventType': 'WORK',
      'startDate': '2026-09-10T09:00:00',
      'endDate': '2026-09-10T10:00:00',
      'isAllDay': 'N',
    };

    test('시트가 가진 칸을 비우면 전부 명시적 null 로 실린다', () async {
      final (dio, captured) = _capturingDio(eventJson);

      await CalendarRepository(dio).updateEvent(
        id: 1,
        title: '회의',
        description: const Patch.set(null),
        eventType: 'WORK',
        color: '#2c70bf',
        startDate: '2026-09-10T09:00:00',
        endDate: '2026-09-10T10:00:00',
        labelRowId: const Patch.set(null),
        location: const Patch.set(null),
        rrule: const Patch.set(null),
      );

      for (final key in ['description', 'labelRowId', 'location', 'rrule']) {
        expectExplicitNull(captured.single, key);
      }
    });

    test('고른 값은 그대로 실린다', () async {
      final (dio, captured) = _capturingDio(eventJson);

      await CalendarRepository(dio).updateEvent(
        id: 1,
        title: '회의',
        description: const Patch.set('주간 정례'),
        eventType: 'WORK',
        startDate: '2026-09-10T09:00:00',
        endDate: '2026-09-10T10:00:00',
        labelRowId: const Patch.set(4),
        location: const Patch.set('3층 회의실'),
      );

      expect(captured.single['description'], '주간 정례');
      expect(captured.single['labelRowId'], 4);
      expect(captured.single['location'], '3층 회의실');
    });

    // 소속 캘린더는 "뗀다" 가 없는 칸이다 — 서버 `UpdateRequest.calendarRowId` 는
    // `Optional` 이 아닌 맨 `Long` 이고 서비스가 `if (calendarRowId != null)` 로만
    // 읽는다. 시트 선택기에도 '선택 안 함' 이 없다. null 을 실으면 뜻이 없는 키가 된다.
    test('캘린더를 안 넘기면 키가 아예 없다 — 뗄 수 있는 칸이 아니다', () async {
      final (dio, captured) = _capturingDio(eventJson);

      await CalendarRepository(dio).updateEvent(
        id: 1,
        title: '회의',
        eventType: 'WORK',
        startDate: '2026-09-10T09:00:00',
        endDate: '2026-09-10T10:00:00',
      );

      expectAbsent(captured.single, 'calendarRowId');
    });

    test('안 넘긴 칸은 키가 없다 — 서버가 지금 값을 지킨다', () async {
      final (dio, captured) = _capturingDio(eventJson);

      await CalendarRepository(dio).updateEvent(
        id: 1,
        title: '회의',
        eventType: 'WORK',
        startDate: '2026-09-10T09:00:00',
        endDate: '2026-09-10T10:00:00',
      );

      expectAbsent(captured.single, 'description');
      expectAbsent(captured.single, 'labelRowId');
      expectAbsent(captured.single, 'location');
      expectAbsent(captured.single, 'rrule');
      // 알림은 목록 교체 칸이라 [Patch] 로 안 옮겼다 — 안 넘기면 키가 빠진다(무변경).
      expectAbsent(captured.single, 'reminderMinutes');
    });

    // 종류·색은 화면이 늘 값을 들고 있다 — 비는 상태가 없어 [Patch] 로 안 옮겼다.
    test('종류는 늘 실린다 — 키를 빼면 저장이 깨진다', () async {
      final (dio, captured) = _capturingDio(eventJson);

      await CalendarRepository(dio).updateEvent(
        id: 1,
        title: '회의',
        startDate: '2026-09-10T09:00:00',
        endDate: '2026-09-10T10:00:00',
      );

      expect(captured.single['eventType'], kDefaultCalendarEventType);
    });

    // 반복 일정에서 연 회차 — 서버가 그 회차에서 바뀐 만큼만 반복 전체를 옮긴다(QA 30 2).
    test('연 회차의 원래 시작은 넘기면 실리고, 안 넘기면 키가 없다', () async {
      final (dio, captured) = _capturingDio(eventJson);
      final repo = CalendarRepository(dio);

      await repo.updateEvent(
        id: 1,
        title: '회의',
        startDate: '2026-09-24T09:00:00',
        endDate: '2026-09-24T10:00:00',
        occurrenceStartDate: '2026-09-24T09:00:00',
      );
      await repo.updateEvent(
        id: 1,
        title: '회의',
        startDate: '2026-09-10T09:00:00',
        endDate: '2026-09-10T10:00:00',
      );

      expect(captured.first['occurrenceStartDate'], '2026-09-24T09:00:00');
      expectAbsent(captured.last, 'occurrenceStartDate');
    });

    test('생성 경로는 그대로다 — null 인 칸은 키째 빠진다', () async {
      final (dio, captured) = _capturingDio(eventJson);

      await CalendarRepository(dio).createEvent(
        title: '회의',
        startDate: '2026-09-10T09:00:00',
        endDate: '2026-09-10T10:00:00',
      );

      expectAbsent(captured.single, 'description');
      expectAbsent(captured.single, 'labelRowId');
      expectAbsent(captured.single, 'location');
      expectAbsent(captured.single, 'rrule');
    });
  });
}
