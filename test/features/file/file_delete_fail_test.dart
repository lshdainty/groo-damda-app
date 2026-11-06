// 파일 첨부 삭제 실패 — 확인창 뒤 critical 스낵바 + [다시 시도], 서버 글 없음, silent.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/file/application/file_providers.dart';
import 'package:groo_damda_app/features/file/data/file_repository.dart';
import 'package:groo_damda_app/features/file/domain/file_attachment.dart';
import 'package:groo_damda_app/features/file/presentation/file_attachment_section.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

import '../../support/plain_text.dart';

const _file = FileAttachment(rowId: 5, originalName: '영수증.pdf');

class _Repo extends FileRepository {
  _Repo() : super(Dio());
  int deletes = 0;
  final silent = <bool>[];

  @override
  Future<List<FileAttachment>> listByReference({
    required String referenceType,
    required int referenceRowId,
  }) async => const [_file];

  @override
  Future<void> delete(int id, {bool silent = false}) async {
    deletes++;
    this.silent.add(silent);
    throw ApiException(code: 'X', message: '서버 원문');
  }
}

void main() {
  testWidgets('삭제 실패 — 스낵바 + 다시 시도 · silent · 서버 글 없음', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    final repo = _Repo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fileRepositoryProvider.overrideWith((ref) async => repo)],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          builder: (c, child) => PSnackbarHost(closeLabel: '닫기', child: child!),
          home: const Scaffold(
            body: FileAttachmentSection(
              referenceType: 'EXPENSE',
              referenceRowId: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();
    await tester.tap(findPlain(l.actionDelete).last);
    await tester.pumpAndSettle();
    expect(repo.deletes, 1);
    expect(repo.silent, [true]);
    expect(l.fileDeleteFailed, '파일을 삭제하지 못했어요.');
    expect(findPlain(l.fileDeleteFailed), findsOneWidget);
    expect(findTextContaining('서버 원문'), findsNothing);
    await tester.tap(findPlain(l.actionRetry));
    await tester.pumpAndSettle();
    expect(repo.deletes, 2);
  });
}
