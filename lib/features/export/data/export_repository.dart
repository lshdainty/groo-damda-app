import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';

/// 종별 건수 (체크박스 배지).
class ExportTypeCount {
  const ExportTypeCount({
    required this.type,
    required this.displayName,
    required this.count,
  });
  final String type;
  final String displayName;
  final int count;

  factory ExportTypeCount.fromJson(Map<String, dynamic> json) =>
      ExportTypeCount(
        type: json['type'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

/// 종별 미리보기 표 (상위 N행).
class ExportPreviewTable {
  const ExportPreviewTable({
    required this.type,
    required this.displayName,
    required this.headers,
    required this.rows,
    required this.totalCount,
  });
  final String type;
  final String displayName;
  final List<String> headers;
  final List<List<String>> rows;
  final int totalCount;

  factory ExportPreviewTable.fromJson(Map<String, dynamic> json) =>
      ExportPreviewTable(
        type: json['type'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        headers: ((json['headers'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        rows: ((json['rows'] as List?) ?? [])
            .map((r) => ((r as List?) ?? []).map((e) => e.toString()).toList())
            .toList(),
        totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      );
}

/// 데이터 내보내기 API. 다운로드는 dio stream → 임시파일로 점진 기록(대용량 대응).
class ExportRepository {
  ExportRepository(
    this._dio, {
    this.stallTimeout = const Duration(seconds: 10),
    this.tempDir,
  });
  final Dio _dio;

  /// 받은 바이트가 이만큼 늘지 않으면 실패로 본다.
  final Duration stallTimeout;

  /// 임시 폴더 — 시험에서 바꾼다.
  final Future<Directory> Function()? tempDir;

  Future<List<ExportTypeCount>> counts(Map<String, dynamic> body) async {
    try {
      // 화면 진입 시 건수 미리보기 — best-effort 라 실패해도 조용히 넘긴다.
      final res = await _dio.post<Map<String, dynamic>>(
        '/export/counts',
        data: body,
        options: Options(extra: {kSilentErrorToast: true}),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data!,
        (o) => (o as Map).cast<String, dynamic>(),
      );
      final list = (api.data?['counts'] as List?) ?? [];
      return list
          .map(
            (e) => ExportTypeCount.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ExportPreviewTable>> preview(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/export/preview',
        data: body,
        options: Options(extra: {kSilentErrorToast: true}),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data!,
        (o) => (o as Map).cast<String, dynamic>(),
      );
      final list = (api.data?['tables'] as List?) ?? [];
      return list
          .map(
            (e) =>
                ExportPreviewTable.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 파일 생성 → 임시파일에 스트림 기록. 생성된 File 반환(호출처가 Share).
  ///
  /// **받은 바이트가 [stallTimeout](10초) 동안 늘지 않으면 끊고 [ExportStalledException] 을 던진다**
  /// (I-05 47 — 서버가 파일을 만드는 동안도 센다. 조금씩이라도 오면 끊기지 않는다).
  Future<File> download({
    required Map<String, dynamic> body,
    required String filename,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final cancel = CancelToken();
    var stalled = false;
    Timer? watch;
    void kick() {
      watch?.cancel();
      watch = Timer(stallTimeout, () {
        stalled = true;
        cancel.cancel('stalled');
      });
    }

    kick();
    try {
      final res = await _dio.post<ResponseBody>(
        '/export',
        data: body,
        cancelToken: cancel,
        // 이 길의 실패는 화면이 [다시 시도] 가 달린 띠로 알린다 — 전역 토스트와 겹치지 않게
        options: Options(
          responseType: ResponseType.stream,
          extra: {kSilentErrorToast: true},
        ),
        onReceiveProgress: (received, total) {
          kick();
          onReceiveProgress?.call(received, total);
        },
      );
      final dir = await (tempDir ?? getTemporaryDirectory)();
      final file = File('${dir.path}/$filename');
      final sink = file.openWrite();
      try {
        await for (final chunk in res.data!.stream) {
          kick();
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }
      return file;
    } on DioException catch (e) {
      if (stalled) throw const ExportStalledException();
      throw ApiException.fromDio(e);
    } finally {
      watch?.cancel();
    }
  }
}

/// 받기가 [ExportRepository.stallTimeout] 동안 멈췄다.
class ExportStalledException implements Exception {
  const ExportStalledException();

  @override
  String toString() => 'ExportStalledException';
}

final exportRepositoryProvider = FutureProvider<ExportRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return ExportRepository(dio);
});
