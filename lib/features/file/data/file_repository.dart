import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:groo_damda_app/features/file/domain/file_attachment.dart';

/// 파일 첨부 — front `fileApi` 미러.
///
/// `referenceType` 은 백엔드 `ReferenceType` enum: EXPENSE/TODO/MEMO/CALENDAR_EVENT.
/// 업로드는 multipart/form-data.
class FileRepository {
  FileRepository(this._dio);
  final Dio _dio;

  /// 파일 업로드. POST /files/upload (multipart).
  ///
  /// [filePath] 로컬 파일 경로 (image_picker / file_picker 결과).
  /// [fileName] 표시용 파일명 (확장자 포함).
  Future<FileAttachment> upload({
    required String filePath,
    required String fileName,
    required String referenceType,
    int? referenceRowId,
    bool silent = false,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'referenceType': referenceType,
        'referenceRowId': ?referenceRowId,
      });
      final res = await _dio.post<Map<String, dynamic>>(
        '/files/upload',
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          extra: silent ? {kSilentErrorToast: true} : null,
        ),
      );
      return _unwrap(res, FileAttachment.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 특정 reference 의 첨부 파일 목록. GET /files?referenceType&referenceRowId.
  Future<List<FileAttachment>> listByReference({
    required String referenceType,
    required int referenceRowId,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/files',
        queryParameters: {
          'referenceType': referenceType,
          'referenceRowId': referenceRowId,
        },
      );
      return _unwrapList(res, 'files', FileAttachment.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 다운로드 URL 생성 — 토큰 쿠키가 있어야 GET 가능.
  String downloadUrl(int id) => '${_dio.options.baseUrl}/files/$id';

  Future<void> delete(int id, {bool silent = false}) async {
    try {
      await _dio.delete<void>(
        '/files/$id',
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
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
