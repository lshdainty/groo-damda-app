import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/network/dio_provider.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/silent_error_toast.dart';

/// 금액 가리기 목록 — 기기가 아니라 **계정**에 붙는다.
///
/// 예전에는 SharedPreferences 에만 있어서 폰에서 가려도 웹으로 로그인하면 금액이
/// 그대로 보였다.
class HideCardsRepository {
  HideCardsRepository(this._dio);
  final Dio _dio;

  /// 서버에 저장된 목록.
  ///
  /// `null` 이면 **아직 한 번도 올린 적 없음** — 빈 목록(사용자가 다 풀었음)과 뜻이 다르다.
  /// 이 둘을 뭉개면 이 기능이 나가는 순간 가려 뒀던 금액이 통째로 드러난다.
  Future<List<String>?> fetch() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me/hide-cards');
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => (raw as Map<String, dynamic>?) ?? const {},
      );
      if (!body.success) {
        throw ApiException(code: body.code, message: body.message);
      }
      final cards = body.data?['hideCards'];
      if (cards == null) return null;
      return (cards as List<dynamic>).map((e) => e as String).toList();
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 통째로 교체. 부분 갱신이 아니다.
  ///
  /// [silent] 는 기본이 켜짐 — 실패는 호출한 쪽이 자기 글로 말한다(저장 화면 Callout · 스낵바 + 다시 시도).
  Future<void> put(Set<String> cards, {bool silent = true}) async {
    try {
      await _dio.put<void>(
        '/users/me/hide-cards',
        data: {'hideCards': cards.toList()},
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }
}

/// 테스트에서 갈아 끼울 수 있게 provider 로 뺀다 — 동기화 규칙(null/빈 목록·주인 대조)이
/// 틀리면 가려 뒀던 금액이 드러나므로 눈이 아니라 테스트로 걸어야 한다.
final hideCardsRepositoryProvider = FutureProvider<HideCardsRepository>((
  ref,
) async {
  return HideCardsRepository(await ref.watch(dioProvider.future));
});
