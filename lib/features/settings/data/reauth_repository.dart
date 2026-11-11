import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/silent_error_toast.dart';

/// 재인증 티켓을 어디에 쓰는지 — 서버가 티켓에 새겨 두고, 다른 곳에 내밀면 거절한다.
///
/// 빼면 서버는 [withdraw] 로 읽는다. 그래서 연동은 반드시 [oauthLink] 를 실어야 한다.
abstract final class ReauthPurpose {
  /// 이용 해지.
  static const withdraw = 'withdraw';

  /// 소셜 계정 연동 시작.
  static const oauthLink = 'oauth-link';
}

/// 본인 확인(재인증) — 해지와 소셜 연동이 같이 쓴다.
///
/// **SSO 가 판정하지만 desk-back 이 대신 물어본다.** 앱에는 SSO 액세스 토큰이 없어 SSO 를
/// 직접 못 부른다 — desk-back 이 서비스 토큰으로 대신 부르고(desk-back #340) 그 결과로 받은
/// **재인증 티켓**을 돌려준다.
///
/// 티켓은 10분·단회다. 저장하지 말고 곧장 그 요청의 `X-Reauth-Token` 헤더에 실어야 한다.
class ReauthRepository {
  ReauthRepository(this._dio);
  final Dio _dio;

  /// 본인 메일로 6자리 코드 발송.
  ///
  /// 비밀번호가 없는 **소셜 전용 계정**을 위한 경로다 — 그 계정은 비밀번호 칸을
  /// 채울 수 없어 이 길이 막히면 본인 확인을 아예 못 한다.
  Future<void> sendEmailCode() async {
    try {
      await _dio.post<dynamic>(
        '/users/me/reauth/email-code',
        options: Options(extra: {kSilentErrorToast: true}),
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 코드 확인 → 재인증 티켓.
  Future<String> verifyEmailCode(String code, {required String purpose}) =>
      _ticket('/users/me/reauth/email-code/verify', {
        'code': code,
        'purpose': purpose,
      });

  /// 비밀번호 확인 → 재인증 티켓.
  Future<String> verifyPassword(String password, {required String purpose}) =>
      _ticket('/users/me/reauth/password', {
        'password': password,
        'purpose': purpose,
      });

  Future<String> _ticket(String path, Map<String, String> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(extra: {kSilentErrorToast: true}),
      );
      final resp = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => (raw as Map<String, dynamic>?) ?? const {},
      );
      if (!resp.success) {
        throw ApiException(code: resp.code, message: resp.message);
      }
      final token = resp.data?['reauthToken'] as String?;
      // 티켓 없는 성공은 실패로 본다 — 통과시키면 화면이 "확인됐다" 로 읽고 넘어갔다가
      // 다음 호출에서 막히고, 사용자는 방금 맞게 넣은 비밀번호를 의심하게 된다.
      if (token == null || token.isEmpty) {
        throw ApiException(code: resp.code, message: resp.message);
      }
      return token;
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }
}
