// desk 이용 해지 — 웹과 **한 벌**인지, 그리고 위험한 자리가 잠겨 있는지.
//
// 해지는 되돌릴 수 없어서, 앱과 웹이 서로 다른 말을 하면 그 자체가 사고다
// (한쪽만 "다시 가입할 수 있다" 로 읽히면 사용자가 그걸 믿고 누른다).
// 세 가지를 못 박는다.
//
// - 점검 응답을 우리가 읽는 방식 — 막힘 판정과 개수
// - 되돌릴 수 없다는 두 문장이 ko·en 양쪽에 있다
// - 해지한 계정의 로그인은 "로그인 실패" 가 아니라 **해지** 로 읽힌다
// - 사용자에게 보이는 문구에 예외 원문(`ApiException(...)`)이 새지 않는다
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/auth/presentation/login_screen.dart';
import 'package:groo_damda_app/features/settings/domain/withdrawal_check.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_en.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';

void main() {
  group('WithdrawalCheck', () {
    test('사유가 비어 있어야 해지할 수 있다', () {
      final clear = WithdrawalCheck.fromJson(const {
        'blocked': <String>[],
        'sharedCalendarsOwned': 0,
      });
      expect(clear.isBlocked, isFalse);
      expect(clear.blockedBySubscription, isFalse);
    });

    // 서버가 실제로 보내는 리터럴을 쓴다 — 상수를 여기 넣으면 상수와 입력이 서로를
    // 보고 끄덕이는 닫힌 고리가 되어, 둘 다 틀려도 초록불이 난다.
    test('구독이 막으면 언제부터 가능한지도 함께 온다', () {
      final blocked = WithdrawalCheck.fromJson(const {
        'blocked': ['SUBSCRIPTION_ACTIVE'],
        'subscriptionPeriodEnd': '2026-09-30T15:00:00',
        'dutchPaysOwned': 2,
      });
      expect(blocked.isBlocked, isTrue);
      expect(blocked.blockedBySubscription, isTrue);
      // 이 날짜가 없으면 사용자는 기다릴지 지금 구독을 해지할지 정할 수 없다.
      expect(blocked.subscriptionPeriodEnd, isNotNull);
      expect(blocked.dutchPaysOwned, 2);
    });

    // 이 값은 서버(desk-back WithdrawalServiceImpl)가 짓는다. 한 글자만 달라도
    // 구독으로 막힌 사람에게 날짜를 못 보여 준다 — 2026-09-17 dev 에서 잡은 자리다.
    test('막는 사유 코드가 서버 문자열과 글자 그대로 같다', () {
      expect(WithdrawalCheck.blockSubscription, 'SUBSCRIPTION_ACTIVE');
    });

    test('멤버가 남은 공유 캘린더를 소유하면 막고, 넘겨야 할 수를 함께 읽는다', () {
      final blocked = WithdrawalCheck.fromJson(const {
        'blocked': ['SHARED_CALENDAR_OWNED'],
        'sharedCalendarsToTransfer': 2,
      });
      expect(blocked.isBlocked, isTrue);
      expect(blocked.blockedBySharedCalendar, isTrue);
      expect(blocked.blockedBySubscription, isFalse);
      expect(blocked.sharedCalendarsToTransfer, 2);
      expect(WithdrawalCheck.blockSharedCalendar, 'SHARED_CALENDAR_OWNED');
      expect(WithdrawalCheck.blockedSharedCalendarCode, 'USER_022');
    });

    test('모르는 사유도 막는 것으로 본다 — 서버가 늘려도 앱이 뚫리지 않게', () {
      final unknown = WithdrawalCheck.fromJson(const {
        'blocked': ['SOMETHING_NEW'],
      });
      expect(unknown.isBlocked, isTrue);
      expect(unknown.blockedBySubscription, isFalse);
    });

    test('칸이 통째로 빠져도 0 으로 읽는다 — 옛 서버에서 화면이 깨지지 않게', () {
      final empty = WithdrawalCheck.fromJson(const {});
      expect(empty.isBlocked, isFalse);
      expect(empty.sharedCalendarsOwned, 0);
      expect(empty.calendarMemberships, 0);
      expect(empty.dutchPaysOwned, 0);
      expect(empty.dutchPayParticipations, 0);
      expect(empty.subscriptionPeriodEnd, isNull);
      expect(empty.sharedCalendarsToTransfer, 0);
    });
  });

  group('해지 계정 로그인', () {
    test('USER_021 은 해지로 읽는다', () {
      final e = ApiException(code: 'USER_021', message: '이용을 해지한 계정이에요');
      expect(e.isWithdrawn, isTrue);
    });

    test('다른 코드는 보통의 로그인 실패다 — 해지 안내를 띄우면 안 된다', () {
      final e = ApiException(code: 'AUTH_001', message: '');
      expect(e.isWithdrawn, isFalse);
    });

    // 문구가 아니라 코드로 판정한다 — 문구는 로케일마다 다르고 서버가 고치면 따라 바뀐다.
    test('문구에 해지가 들어 있어도 코드가 아니면 아니다', () {
      final e = ApiException(code: 'COMMON_500', message: '이용을 해지한 계정이에요');
      expect(e.isWithdrawn, isFalse);
    });
  });

  group('문구', () {
    // 해지는 soft delete 다 — 데이터는 남는다. "기록이 사라진다" 로 쓰면 사용자가
    // 실제와 다른 것을 믿고 되돌릴 수 없는 버튼을 누른다(2026-09-17 QA #7).
    test('문구가 "사라진다" 고 말하지 않는다 — 실제로는 접근이 막힐 뿐이다', () {
      final ko = AppLocalizationsKo();
      for (final line in [
        ko.accountWithdrawDesc,
        ko.withdrawIntro,
        ko.withdrawIrreversibleData,
        ko.withdrawnBody,
      ]) {
        expect(line, isNot(contains('사라')));
      }
      // 대신 실제로 벌어지는 일을 말한다.
      expect(ko.withdrawIntro, contains('로그인'));
      expect(ko.withdrawDataRetention, contains('보관'));
      expect(ko.withdrawnBody, contains('보관'));
    });

    test('내보내기 권유는 해지 전에만 할 수 있는 말이라 확인창에 있다', () {
      expect(AppLocalizationsKo().withdrawDataRetention, contains('내보내'));
      expect(AppLocalizationsEn().withdrawDataRetention, contains('Export'));
    });

    test('ko — 되돌릴 수 없는 것 둘을 반드시 말한다', () {
      final l = AppLocalizationsKo();
      // 같은 아이디로 다시 가입할 수 없다는 것은 여기서 말하지 않으면 알 길이 없다.
      expect(l.withdrawIrreversibleRejoin, isNotEmpty);
      expect(l.withdrawIrreversibleData, isNotEmpty);
      // 해지 안내와 로그인 차단 안내가 같은 문장을 쓴다 — 두 자리에서 같은 말을 해야 한다.
      expect(l.withdrawnTitle, isNotEmpty);
    });

    test('en — 같은 자리가 비어 있지 않다', () {
      final l = AppLocalizationsEn();
      expect(l.withdrawIrreversibleRejoin, isNotEmpty);
      expect(l.withdrawIrreversibleData, isNotEmpty);
      expect(l.withdrawnTitle, isNotEmpty);
    });

    test('막는 안내는 언제부터 가능한지 날짜를 끼운다', () {
      final ko = AppLocalizationsKo();
      final en = AppLocalizationsEn();
      expect(
        ko.withdrawBlockedSubscriptionUntil('2026-10-01'),
        contains('2026-10-01'),
      );
      expect(
        en.withdrawBlockedSubscriptionUntil('2026-10-01'),
        contains('2026-10-01'),
      );
    });

    // 버튼이 "회원 탈퇴" 였는데 실제로 하는 일은 desk 이용 해지뿐이다 — 계정은 남고
    // 아이디·이메일은 재가입을 막으려고 계속 보관된다. 이름이 하는 일보다 크면
    // 사용자가 다른 결과를 기대하고 누른다(되돌릴 수 없는 버튼이라 더 그렇다).
    test('설정 행과 시트 제목이 같은 이름을 쓴다', () {
      final ko = AppLocalizationsKo();
      final en = AppLocalizationsEn();
      expect(ko.accountWithdraw, ko.accountWithdrawTitle);
      expect(en.accountWithdraw, en.accountWithdrawTitle);
      // "탈퇴" 가 아니라 "해지" 다 — 계정은 남는다.
      expect(ko.accountWithdraw, contains('해지'));
      expect(ko.accountWithdraw, isNot(contains('탈퇴')));
    });

    test('개수 안내는 숫자를 끼운다 — 0 이면 화면이 줄을 안 만든다', () {
      final ko = AppLocalizationsKo();
      expect(ko.withdrawImpactCalendarsOwned(3), contains('3'));
      expect(ko.withdrawImpactDutchPayParticipations(2), contains('2'));
    });
  });

  // 해지 완료 안내(제목 + 본문 + 재가입 불가)는 이제 토스트가 아니라 화면이다 —
  // test/features/auth/withdrawn_screen_test.dart 가 화면에 셋 다 나오는지 본다.

  // 로그인 실패는 `ApiException.toString()` 을 그대로 띄우고 있었다 —
  // 사용자에게 `ApiException(AUTH_003, ...)` 같은 게 보였다(QA 22차 #7).
  group('로그인 실패 문구', () {
    final ko = AppLocalizationsKo();

    ApiException err(String code, [String message = '']) =>
        ApiException(code: code, message: message, statusCode: 400);

    test('해지 계정은 해지 안내로 말한다', () {
      final msg = loginErrorMessage(err('USER_021'), ko);
      expect(msg, contains(ko.withdrawnTitle));
      expect(msg, contains(ko.withdrawIrreversibleRejoin));
    });

    // 서버 AUTH_003 은 "접근 권한 없음"(AUTH_ACCESS_DENIED) — 담다를 쓸 수 없는 그루 계정이다.
    // 예전엔 "로그인 시간이 지났어요" 로 잘못 말해 같은 계정으로 다시 누르게 했다.
    test('AUTH_003 은 담다를 쓸 수 있는 그루 계정으로 다시 로그인하라고 말한다', () {
      final msg = loginErrorMessage(
        ApiException(code: 'AUTH_003', message: '접근 권한이 없어요', statusCode: 403),
        ko,
      );
      expect(msg, ko.authLoginAccessDenied);
      expect(msg, contains('그루 담다를 쓸 수 있는 그루 계정'));
      expect(msg, isNot(contains('시간이 지났')));
      expect(
        loginErrorMessage(
          ApiException(code: 'AUTH_003', message: '', statusCode: 403),
          AppLocalizationsEn(),
        ),
        contains('that can use 그루 담다'),
      );
    });

    test('교환 실패(AUTH_004)는 이유를 지어내지 않고 로그인하지 못했다고 말한다', () {
      expect(loginErrorMessage(err('AUTH_004'), ko), ko.authLoginFailed);
    });

    test('아는 게 없으면 서버 글을 붙이지 않고 로그인하지 못했다고만 말한다', () {
      final msg = loginErrorMessage(err('AUTH_099', '알 수 없는 오류'), ko);
      expect(msg, ko.authLoginFailed);
      expect(msg, isNot(contains('알 수 없는 오류')));
      expect(msg, isNot(contains('ApiException')));
    });

    test('메시지도 없으면 원문을 흘리지 않는다', () {
      for (final e in <Object?>[err('AUTH_099'), Exception('boom'), null]) {
        final msg = loginErrorMessage(e, ko);
        expect(msg, isNot(contains('ApiException')));
        expect(msg, isNot(contains('Exception')));
        expect(msg, contains(ko.authLoginFailed));
      }
    });
  });
}
