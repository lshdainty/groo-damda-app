import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/features/settings/data/reauth_repository.dart';
import 'package:groo_damda_app/features/settings/domain/withdrawal_check.dart';

/// desk 이용 해지 — 점검 · 본인 확인 · 해지.
///
/// 본인 확인(재인증)은 **SSO 가 판정하지만 desk-back 이 대신 물어본다.** 앱에는 SSO
/// 액세스 토큰이 없어 SSO 를 직접 못 부른다 — desk-back 이 서비스 토큰으로 대신
/// 부르고(desk-back #340) 그 결과로 받은 **재인증 티켓**을 돌려준다.
///
/// 티켓은 10분·단회다. 저장하지 말고 곧장 [withdraw] 에 실어야 한다. 묻는 길은
/// [ReauthRepository] 가 소셜 연동과 함께 쓴다.
class WithdrawalRepository {
  WithdrawalRepository(this._dio) : _reauth = ReauthRepository(_dio);
  final Dio _dio;

  /// 본인 확인은 소셜 연동과 같은 길이다 — 해지는 목적을 [ReauthPurpose.withdraw] 로 밝힌다.
  final ReauthRepository _reauth;

  /// 해지해도 되는지, 무엇을 잃는지.
  Future<WithdrawalCheck> check() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/users/me/withdrawal-check',
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => (raw as Map<String, dynamic>?) ?? const {},
      );
      if (!body.success) {
        throw ApiException(code: body.code, message: body.message);
      }
      return WithdrawalCheck.fromJson(body.data ?? const {});
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 본인 메일로 6자리 코드 발송 — 소셜 전용 계정의 본인 확인 길.
  Future<void> sendEmailCode() => _reauth.sendEmailCode();

  /// 코드 확인 → 해지용 재인증 티켓.
  Future<String> verifyEmailCode(String code) =>
      _reauth.verifyEmailCode(code, purpose: ReauthPurpose.withdraw);

  /// 비밀번호 확인 → 해지용 재인증 티켓.
  Future<String> verifyPassword(String password) =>
      _reauth.verifyPassword(password, purpose: ReauthPurpose.withdraw);

  /// desk 이용 해지. **되돌릴 수 없다.**
  Future<void> withdraw({required String reauthToken, String? reason}) async {
    try {
      await _dio.delete<dynamic>(
        '/users/me',
        data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
        options: Options(headers: {'X-Reauth-Token': reauthToken}),
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }
}
