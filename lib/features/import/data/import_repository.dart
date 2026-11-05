import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/core/network/silent_error_toast.dart';

// ─── 모델 (백엔드 dataimport 미러) ─────────────────────────────

/// 원본 파일의 열(매핑 select 옵션).
class ImportColumn {
  const ImportColumn({required this.index, required this.name});
  final int index;
  final String name;

  factory ImportColumn.fromJson(Map<String, dynamic> j) => ImportColumn(
    index: (j['index'] as num?)?.toInt() ?? 0,
    name: j['name'] as String? ?? '',
  );
}

/// 미리보기 한 행(매핑·정규화 결과).
class ImportPreviewRow {
  const ImportPreviewRow({
    required this.lineNo,
    this.date,
    this.type,
    this.amount,
    this.category,
    this.asset,
    this.memo,
    required this.duplicate,
    this.error,
  });
  final int lineNo;
  final String? date;
  final String? type;
  final int? amount;
  final String? category;
  final String? asset;
  final String? memo;
  final bool duplicate;
  final String? error;

  factory ImportPreviewRow.fromJson(Map<String, dynamic> j) => ImportPreviewRow(
    lineNo: (j['lineNo'] as num?)?.toInt() ?? 0,
    date: j['date'] as String?,
    type: j['type'] as String?,
    amount: (j['amount'] as num?)?.toInt(),
    category: j['category'] as String?,
    asset: j['asset'] as String?,
    memo: j['memo'] as String?,
    duplicate: j['duplicate'] as bool? ?? false,
    error: j['error'] as String?,
  );
}

/// 파일 분석 결과.
class ImportAnalyzeResult {
  const ImportAnalyzeResult({
    required this.fileName,
    required this.totalRows,
    required this.validRows,
    required this.duplicateCount,
    required this.columns,
    required this.suggestedMapping,
    required this.preview,
    required this.blockedParents,
  });
  final String fileName;
  final int totalRows;
  final int validRows;
  final int duplicateCount;
  final List<ImportColumn> columns;
  final Map<String, int> suggestedMapping; // ImportField.name → 열 인덱스
  final List<ImportPreviewRow> preview;

  /// 거래가 직접 달려 있어 하위를 만들 수 없는 대분류 이름들.
  /// 비어 있지 않으면 그 대분류를 쓰는 행이 전부 실패하므로 실행 전에 알려야 한다.
  final List<String> blockedParents;

  factory ImportAnalyzeResult.fromJson(Map<String, dynamic> j) =>
      ImportAnalyzeResult(
        fileName: j['fileName'] as String? ?? '',
        totalRows: (j['totalRows'] as num?)?.toInt() ?? 0,
        validRows: (j['validRows'] as num?)?.toInt() ?? 0,
        duplicateCount: (j['duplicateCount'] as num?)?.toInt() ?? 0,
        columns: ((j['columns'] as List?) ?? [])
            .map(
              (e) => ImportColumn.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList(),
        suggestedMapping: ((j['suggestedMapping'] as Map?) ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
        preview: ((j['preview'] as List?) ?? [])
            .map(
              (e) =>
                  ImportPreviewRow.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList(),
        blockedParents: ((j['blockedParents'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// 저장 결과.
/// 실행에서 읽지 못해 못 넣은 행 — 줄 번호 + 사유 코드(서버 `FailureRow`).
class ImportFailureRow {
  const ImportFailureRow({required this.lineNo, required this.reason});
  final int lineNo;

  /// 사유 코드 — 화면 글이 아니다. 모르는 코드는 화면이 기본 글로 바꾼다.
  final String reason;

  factory ImportFailureRow.fromJson(Map<String, dynamic> j) => ImportFailureRow(
    lineNo: (j['lineNo'] as num?)?.toInt() ?? 0,
    reason: j['reason']?.toString() ?? '',
  );
}

class ImportExecuteResult {
  const ImportExecuteResult({
    required this.imported,
    required this.skipped,
    required this.failed,
    this.failures = const [],
    this.failuresTruncated = false,
    this.createdCategories = const [],
    this.createdCategoryCount = 0,
  });
  final int imported;
  final int skipped;
  final int failed;

  /// 실패한 행 — 서버가 상한(50)까지만 담는다.
  final List<ImportFailureRow> failures;

  /// [failures] 가 상한에서 잘렸는가.
  final bool failuresTruncated;

  /// 이번에 만든 카테고리 경로(생성 순서, 상한까지만) · 실제 전체 개수.
  final List<String> createdCategories;
  final int createdCategoryCount;

  factory ImportExecuteResult.fromJson(Map<String, dynamic> j) =>
      ImportExecuteResult(
        imported: (j['imported'] as num?)?.toInt() ?? 0,
        skipped: (j['skipped'] as num?)?.toInt() ?? 0,
        failed: (j['failed'] as num?)?.toInt() ?? 0,
        failures: ((j['failures'] as List?) ?? [])
            .map(
              (e) =>
                  ImportFailureRow.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList(),
        failuresTruncated: j['failuresTruncated'] as bool? ?? false,
        createdCategories: ((j['createdCategories'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        createdCategoryCount: (j['createdCategoryCount'] as num?)?.toInt() ?? 0,
      );
}

// ─── Repository ────────────────────────────────────────────────

/// 데이터 가져오기 API. analyze/execute 모두 multipart 업로드(stateless 재업로드).
class ImportRepository {
  ImportRepository(this._dio);
  final Dio _dio;

  Future<ImportAnalyzeResult> analyze(File file, String source) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: _nameOf(file),
        ),
        'source': source,
      });
      final res = await _dio.post<Map<String, dynamic>>(
        '/import/analyze',
        data: form,
        options: Options(extra: {kSilentErrorToast: true}),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data!,
        (o) => (o as Map).cast<String, dynamic>(),
      );
      return ImportAnalyzeResult.fromJson(api.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ImportExecuteResult> execute(
    File file, {
    required String source,
    required Map<String, int> mapping,
    required bool dupSkip,
    required bool autoCat,
  }) async {
    try {
      final request = jsonEncode({
        'source': source,
        'mapping': mapping,
        'dupSkip': dupSkip,
        'autoCat': autoCat,
      });
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: _nameOf(file),
        ),
        'request': MultipartFile.fromString(
          request,
          contentType: DioMediaType.parse('application/json'),
        ),
      });
      final res = await _dio.post<Map<String, dynamic>>(
        '/import/execute',
        data: form,
        options: Options(extra: {kSilentErrorToast: true}),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data!,
        (o) => (o as Map).cast<String, dynamic>(),
      );
      return ImportExecuteResult.fromJson(api.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  String _nameOf(File file) => file.path.split(Platform.pathSeparator).last;
}

final importRepositoryProvider = FutureProvider<ImportRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return ImportRepository(dio);
});
