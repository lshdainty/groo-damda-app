import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/silent_error_toast.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/memo/domain/memo.dart';

class MemoRepository {
  MemoRepository(this._dio);
  final Dio _dio;

  /// 서버 원문을 띄우는 전역 오류 알림을 끈다 — 화면이 고정 글로 알린다(I-15 12 · 13 · 21: 저장 실패는 시트 안 Callout, 삭제 · 고정 실패는 스낵바 + 다시 시도).
  static final Options _silent = Options(extra: {kSilentErrorToast: true});

  Future<List<Memo>> list({String? search}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/memos',
        options: _silent,
        queryParameters: {'search': ?search},
      );
      return _unwrapList(res, 'memos', Memo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Memo> create({
    String? title,
    String? content,
    String? tag,
    String? color,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/memo',
        options: _silent,
        data: {
          'title': ?title,
          'content': ?content,
          'tag': ?tag,
          'color': ?color,
        },
      );
      return _unwrap(res, Memo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 수정 — 편집 화면이 소유한 칸만 키를 싣는다(QA #99).
  ///
  /// [content] 와 [tag] 가 [Patch] 다. 둘 다 화면에서 지울 수 있는 칸이라
  /// "비웠다" 를 명시적 null 로 실어야 서버가 지운다. 제목·색은 화면이 늘 값을
  /// 들고 있어(색은 기본값이 있고 제목은 빈 값을 막는다) 비워질 일이 없다.
  ///
  /// **태그는 이름 문자열로만 싣는다** — 태그 아이디(`memoTagRowId`)는 안 보낸다.
  /// 서버가 이름으로 활성 마스터를 찾고 없으면 만들어 FK 를 잇고(desk-back #323),
  /// 한 사용자의 활성 태그 이름은 UNIQUE 라 이름 → 마스터가 일대일이다. 아이디를
  /// 실으면 화면이 목록을 받은 뒤 그 태그가 지워졌을 때 저장 자체가 404 로 깨지는데,
  /// 이름으로 가면 그때도 저장은 되고 태그만 다시 확보된다. 할 일 편집 시트도
  /// 같은 이유로 이름(`category`)만 싣는다.
  ///
  /// `"tag": null` 은 서버에서 문자열과 마스터 연결을 **함께** 끊는다 — 문자열만
  /// 남기면 다음 저장에서 그 이름의 태그가 되살아난다(QA #88).
  Future<Memo> update({
    required int id,
    String? title,
    Patch<String> content = const Patch.keep(),
    Patch<String> tag = const Patch.keep(),
    String? color,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/memo/$id',
        options: _silent,
        data: {
          'title': ?title,
          if (content.present) 'content': content.value,
          if (tag.present) 'tag': tag.value,
          'color': ?color,
        },
      );
      return _unwrap(res, Memo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/memo/$id', options: _silent);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> pin(int id) async {
    try {
      await _dio.patch<dynamic>('/memo/$id/pin', options: _silent);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  T _unwrap<T>(
    Response<Map<String, dynamic>> res,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = ApiResponse<T>.fromJson(
      res.data ?? const {},
      (raw) => fromJson(raw! as Map<String, dynamic>),
    );
    if (!body.success || body.data == null) {
      throw ApiException(code: body.code, message: body.message);
    }
    return body.data!;
  }

  List<T> _unwrapList<T>(
    Response<Map<String, dynamic>> res,
    String listKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = ApiResponse<Map<String, dynamic>>.fromJson(
      res.data ?? const {},
      (raw) => raw! as Map<String, dynamic>,
    );
    if (!body.success || body.data == null) {
      throw ApiException(code: body.code, message: body.message);
    }
    final list = (body.data![listKey] as List<dynamic>?) ?? const [];
    return list
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
