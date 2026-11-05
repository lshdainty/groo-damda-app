// 데이터 내보내기 · 가져오기 — I-05 39 ~ 53 (앱).
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/export/data/export_repository.dart';
import 'package:groo_damda_app/features/export/presentation/export_screen.dart';
import 'package:groo_damda_app/features/import/data/import_repository.dart';
import 'package:groo_damda_app/features/import/presentation/import_view.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/attachment_input/p_attachment_input.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/select_box/p_select_box.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/widgets/p_busy_scrim.dart';

final _l = lookupAppLocalizations(const Locale('ko'));

/// keepAll 이 끼우는 보이지 않는 글자(U+2060)를 빼고 찾는다.
Finder _t(String part) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').replaceAll('\u2060', '') == part,
);

class _ExportRepo extends ExportRepository {
  _ExportRepo({this.fail = false, this.tables, this.stall = false})
    : super(Dio());
  final bool fail;
  final bool stall;
  final List<ExportPreviewTable>? tables;
  int downloads = 0;
  Completer<void>? gate;

  @override
  Future<List<ExportPreviewTable>> preview(Map<String, dynamic> body) async =>
      tables ?? const [];

  @override
  Future<File> download({
    required Map<String, dynamic> body,
    required String filename,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    downloads++;
    if (stall) throw const ExportStalledException();
    throw ApiException(code: 'X', message: 'server raw');
  }

  @override
  Future<List<ExportTypeCount>> counts(Map<String, dynamic> body) async {
    await gate?.future;
    if (fail) throw ApiException(code: 'X', message: 'x');
    return const [
          ExportTypeCount(type: 'EXPENSE', displayName: '', count: 123456),
          ExportTypeCount(type: 'ASSET', displayName: '', count: 3),
        ]
        .map(
          (c) => ExportTypeCount(
            type: c.type.toLowerCase(),
            displayName: c.displayName,
            count: c.count,
          ),
        )
        .toList();
  }
}

class _ImportRepo extends ImportRepository {
  _ImportRepo() : super(Dio());
  Completer<ImportExecuteResult>? execGate;
  ImportExecuteResult? result;

  @override
  Future<ImportAnalyzeResult> analyze(File file, String source) async =>
      const ImportAnalyzeResult(
        fileName: 'sample.csv',
        totalRows: 12,
        validRows: 10,
        duplicateCount: 2,
        columns: [
          ImportColumn(index: 0, name: '일자'),
          ImportColumn(index: 1, name: '금액'),
        ],
        suggestedMapping: {'DATE': 0, 'AMOUNT': 1},
        preview: [
          ImportPreviewRow(
            lineNo: 1,
            date: '2026-10-01',
            type: 'EXPENSE',
            amount: 12000,
            category: '식비',
            memo: '점심',
            duplicate: true,
          ),
          ImportPreviewRow(lineNo: 2, error: '날짜 형식', duplicate: false),
        ],
        blockedParents: [],
      );

  @override
  Future<ImportExecuteResult> execute(
    File file, {
    required String source,
    required Map<String, int> mapping,
    required bool dupSkip,
    required bool autoCat,
  }) => result != null ? Future.value(result!) : execGate!.future;
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  List overrides = const [],
  bool dark = false,
  double textScale = 1,
  double height = 2400,
}) async {
  tester.view.physicalSize = Size(360 * 3, height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/expense',
        builder: (_, _) => const Scaffold(body: Text('EXPENSE')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp.router(
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: PSnackbarHost(closeLabel: '닫기', child: child!),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('내보내기', () {
    testWidgets('머리 · 탭 · 기간 1열 · 형식 1열 · 마스크 Checkbox · 바닥 짝', (tester) async {
      await _pump(
        tester,
        const ExportScreen(),
        overrides: [
          exportRepositoryProvider.overrideWith((ref) async => _ExportRepo()),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byType(PTopNavigation), findsOneWidget);
      final tabs = tester.widget<PTabs<String>>(find.byType(PTabs<String>));
      expect(tabs.layout, PTabsLayout.fill);
      expect(tabs.semanticLabel, _l.exportTabsLabel);
      expect(tabs.items.map((e) => e.label), [_l.exportTab, _l.importTab]);

      // 기간 5 · 형식 3 — 모두 1열(Q5 5B)
      final groups = tester
          .widgetList<PRadioSelectBoxGroup<String>>(
            find.byType(PRadioSelectBoxGroup<String>, skipOffstage: false),
          )
          .toList();
      expect(groups, hasLength(2));
      expect(groups.every((g) => g.columns == 1), isTrue);
      expect(groups[0].children, hasLength(5));
      expect(groups[1].children, hasLength(3));

      // 기간 표기 — 스펙 Date Picker "9월 28일~10월 6일"(물결표를 앞뒤에 붙여 쓴다)
      final desc = groups[0].children
          .cast<PRadioSelectBox<String>>()
          .map((b) => b.description!)
          .where((d) => d.contains('~'))
          .toList();
      expect(desc, hasLength(4));
      expect(desc.any((d) => d.contains(' — ')), isFalse);
      // 탭 바로 아래 첫 구역 머리까지 위 24 + 머리 위 8
      final tabsBottom = tester.getRect(find.byType(PTabs<String>)).bottom;
      final headTop = tester.getRect(_t(_l.exportPeriodTitle).first).top;
      expect(headTop - tabsBottom, greaterThanOrEqualTo(PSpacing.x6));

      // 민감 정보 가리기 = ds Checkbox
      expect(find.byType(PCheckbox), findsOneWidget);

      // 바닥: [미리보기] neutralWeak · [내보내기] neutralSolid, 둘 다 large
      final b = tester.widgetList<PButton>(find.byType(PButton)).toList();
      final preview = b.firstWhere((x) => x.label == _l.exportPreview);
      final run = b.firstWhere((x) => x.label == _l.exportRun);
      expect(preview.variant, PButtonVariant.neutralWeak);
      expect(run.variant, PButtonVariant.neutralSolid);
      expect(preview.size, PButtonSize.large);
      expect(run.size, PButtonSize.large);
      expect(tester.takeException(), isNull);
    });

    testWidgets('데이터 종류 — 부모 "모두"의 세 상태 · 개수 값', (tester) async {
      await _pump(
        tester,
        const ExportScreen(),
        overrides: [
          exportRepositoryProvider.overrideWith((ref) async => _ExportRepo()),
        ],
      );
      await tester.pumpAndSettle();
      PListCheckItem parent() =>
          tester.widgetList<PListCheckItem>(find.byType(PListCheckItem)).first;
      // 처음 3개 고름 → 일부(null)
      expect(parent().checked, isNull);
      expect(parent().markPosition, PListMarkPosition.suffix);
      await tester.tap(_t(_l.exportSelectAll));
      await tester.pump();
      expect(parent().checked, isTrue);
      await tester.tap(_t(_l.exportSelectAll));
      await tester.pump();
      expect(parent().checked, isFalse);
      // 개수 6자리
      expect(_t(_l.exportCount(123456)), findsOneWidget);
    });

    testWidgets(
      '종류 줄 — 앞 아이콘 22(타일 아님) · 줄 누르면 체크 · 불러오는 중 Skeleton · 설명 한 번',
      (tester) async {
        final gate = Completer<void>();
        final repo = _ExportRepo()..gate = gate;
        await _pump(
          tester,
          const ExportScreen(),
          overrides: [
            exportRepositoryProvider.overrideWith((ref) async => repo),
          ],
        );
        await tester.pump();
        // 불러오는 중 — 값 자리가 글 자리 Skeleton(t5 줄 높이, 폭 x10)
        final sk = tester
            .widgetList<PSkeleton>(find.byType(PSkeleton))
            .toList();
        expect(sk, hasLength(7));
        expect(sk.first.width, PSpacing.x10);
        expect(
          sk.first.height,
          PTypography.t5.fontSize! * PTypography.t5.height!,
        );
        gate.complete();
        await tester.pumpAndSettle();
        expect(find.byType(PSkeleton), findsNothing);

        final rows = tester
            .widgetList<PListCheckItem>(find.byType(PListCheckItem))
            .toList();
        expect(rows, hasLength(8)); // 모두 + 7종
        for (final r in rows.skip(1)) {
          expect(r.prefix, isA<Icon>(), reason: '앞은 맨 아이콘 — 40 타일이 아니다');
          expect(r.markPosition, PListMarkPosition.suffix);
        }
        expect(find.byType(PListTile), findsNothing);
        // 줄 전체가 누르는 자리 — 제목을 눌러도 체크가 바뀐다(처음 거래 내역은 골라져 있다)
        expect(rows[1].checked, isTrue);
        await tester.tap(_t(_l.exportTypeExpense));
        await tester.pump();
        expect(
          tester
              .widgetList<PListCheckItem>(find.byType(PListCheckItem))
              .toList()[1]
              .checked,
          isFalse,
        );
        // 아무것도 안 골라도 같은 설명 글이 두 번 나오지 않는다
        await tester.tap(_t(_l.exportSelectAll)); // 일부 → 모두
        await tester.tap(_t(_l.exportSelectAll)); // 모두 → 없음
        await tester.pump();
        expect(_t(_l.exportTypesDesc), findsOneWidget);
      },
    );

    testWidgets('바닥 짝 — 안전 영역 위, 아래 24', (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34 * 3);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await _pump(
        tester,
        const ExportScreen(),
        overrides: [
          exportRepositoryProvider.overrideWith((ref) async => _ExportRepo()),
        ],
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.widgetWithText(PButton, _l.exportRun));
      expect(rect.bottom, 2400 - 34 - 24);
    });

    testWidgets('미리보기 — 금액 열은 뒤 값(R13) · 빈 표는 Result Section', (tester) async {
      final repo = _ExportRepo(
        tables: const [
          ExportPreviewTable(
            type: 'EXPENSE',
            displayName: '거래 내역',
            headers: ['날짜', '내용', '금액'],
            rows: [
              ['2026-10-01', '점심', '12,000'],
            ],
            totalCount: 1,
          ),
          ExportPreviewTable(
            type: 'MEMO',
            displayName: '메모',
            headers: ['제목'],
            rows: [],
            totalCount: 0,
          ),
        ],
      );
      await _pump(
        tester,
        const ExportScreen(),
        overrides: [exportRepositoryProvider.overrideWith((ref) async => repo)],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PButton, _l.exportPreview));
      await tester.pumpAndSettle();
      final item = tester
          .widgetList<PListItem>(find.byType(PListItem))
          .firstWhere((i) => i.title == '2026-10-01');
      expect(item.suffix, isA<PListValue>(), reason: '금액은 줄 뒤 값');
      // 메모 탭 — 빈 표
      await tester.tap(
        find.descendant(
          of: find.byType(PTabs<String>).last,
          matching: _t('메모'),
        ),
      );
      await tester.pumpAndSettle();
      // 바닥 글 = 한 키 · 선택한 종류 수(3) · 합계(표 totalCount 합 1)
      expect(
        find.text(_l.exportPreviewFooter(1, 3, 123459)),
        findsNothing,
        reason: '빈 표 탭에서는 그 탭의 행 수(0)',
      );
      // 합계 = 고른 종류(거래 내역 · 자산 · 예산)의 건수 합 — 예산은 건수가 없어 0, 미리보기 표 건수(1)가 아니다
      expect(find.text(_l.exportPreviewFooter(0, 3, 123459)), findsOneWidget);
      final res = tester.widget<PResultSection>(find.byType(PResultSection));
      expect(res.kind, PResultKind.empty);
      expect(res.size, PResultSize.medium);
    });

    testWidgets('바닥 글 합계 — 고른 종류가 비면 0, 미리보기 표 건수가 아니다', (tester) async {
      final repo = _ExportRepo(
        tables: const [
          ExportPreviewTable(
            type: 'BUDGET',
            displayName: '예산 설정',
            headers: ['이름'],
            rows: [
              ['식비'],
            ],
            totalCount: 99,
          ),
        ],
      );
      await _pump(
        tester,
        const ExportScreen(),
        overrides: [exportRepositoryProvider.overrideWith((ref) async => repo)],
      );
      await tester.pumpAndSettle();
      // 거래 내역 · 자산을 풀어 건수가 없는 예산(빈 종류) 하나만 남긴다
      await tester.tap(_t(_l.exportTypeExpense));
      await tester.tap(_t(_l.exportTypeAsset));
      await tester.pump();
      await tester.tap(find.widgetWithText(PButton, _l.exportPreview));
      await tester.pumpAndSettle();
      expect(find.text(_l.exportPreviewFooter(1, 1, 0)), findsOneWidget);
      expect(find.text(_l.exportPreviewFooter(1, 1, 99)), findsNothing);
    });

    for (final stall in [true, false]) {
      testWidgets('내보내기 ${stall ? "멈춤" : "실패"} — 오류 띠 + [다시 시도]', (
        tester,
      ) async {
        final repo = _ExportRepo(stall: stall);
        await _pump(
          tester,
          const ExportScreen(),
          overrides: [
            exportRepositoryProvider.overrideWith((ref) async => repo),
          ],
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(PButton, _l.exportRun));
        await tester.pumpAndSettle();
        expect(repo.downloads, 1);
        expect(_t(stall ? _l.exportStalled : _l.exportFailed), findsOneWidget);
        // 서버 글은 그대로 내지 않는다
        expect(find.text('server raw'), findsNothing);
        await tester.tap(_t(_l.actionRetry));
        await tester.pumpAndSettle();
        expect(repo.downloads, 2);
      });
    }

    testWidgets('개수 실패 — 값 자리 비우고 묶음 아래 오류 글 + 다시 시도', (tester) async {
      await _pump(
        tester,
        const ExportScreen(),
        overrides: [
          exportRepositoryProvider.overrideWith(
            (ref) async => _ExportRepo(fail: true),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text(keepAll(_l.exportCountsFailed)), findsOneWidget);
      expect(find.text(_l.actionRetry), findsOneWidget);
      expect(find.text('…'), findsNothing);
    });

    testWidgets('글자 200% · 다크 — 오류 없이 그려진다', (tester) async {
      await _pump(
        tester,
        const ExportScreen(),
        dark: true,
        textScale: 2,
        overrides: [
          exportRepositoryProvider.overrideWith((ref) async => _ExportRepo()),
        ],
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('받기 10초 멈춤(47)', () {
    Dio dioWith(HttpClientAdapter a) => Dio()..httpClientAdapter = a;

    test('조금씩 오면 끊기지 않는다', () async {
      final repo = ExportRepository(
        dioWith(_SlowAdapter(chunks: 4, gap: const Duration(milliseconds: 80))),
        stallTimeout: const Duration(milliseconds: 1500),
        tempDir: () async => Directory.systemTemp,
      );
      final f = await repo.download(body: {}, filename: 'ok-stall-test.csv');
      expect(await f.length(), 4);
      await f.delete();
    });

    test('바이트가 멈추면 타임아웃 뒤 ExportStalledException', () async {
      final repo = ExportRepository(
        dioWith(_SlowAdapter(chunks: 2, gap: const Duration(seconds: 5))),
        stallTimeout: const Duration(milliseconds: 150),
        tempDir: () async => Directory.systemTemp,
      );
      await expectLater(
        repo.download(body: {}, filename: 'stall-test.csv'),
        throwsA(isA<ExportStalledException>()),
      );
    });

    test('기본 멈춤 한도는 10초', () {
      expect(ExportRepository(Dio()).stallTimeout, const Duration(seconds: 10));
    });
  });

  group('가져오기', () {
    PAttachmentPickFiles pick(int size) =>
        (source, limit) async => [
          PAttachmentPicked(
            name: 'sample.csv',
            size: size,
            path: '${Directory.systemTemp.path}/sample.csv',
            type: 'text/csv',
          ),
        ];

    testWidgets('1단계 — "1 / 3단계" 머리 · 단계 원 없음 · 출처 Select Box 1열 · 드롭존', (
      tester,
    ) async {
      await _pump(
        tester,
        Scaffold(body: ImportView(pickFiles: pick(100))),
        overrides: [
          importRepositoryProvider.overrideWith((ref) async => _ImportRepo()),
        ],
      );
      expect(find.text(_l.importStepMeta(1, 3)), findsOneWidget);
      expect(find.text(_l.importStepUpload), findsWidgets);
      final src = tester.widget<PRadioSelectBoxGroup<String>>(
        find.byType(PRadioSelectBoxGroup<String>),
      );
      expect(src.columns, 1);
      expect(src.children, hasLength(5));
      // 출처 제목 · 설명(Q8 8C)
      expect(_t('그루 담다'), findsOneWidget);
      expect(_t('그루 담다에서 내보낸 파일'), findsOneWidget);
      final att = tester.widget<PAttachmentInput>(
        find.byType(PAttachmentInput),
      );
      expect(att.layout, PAttachmentLayout.dropzone);
      expect(att.maxFileSize, 10 * 1024 * 1024);
      expect(find.text('✓'), findsNothing);
    });

    testWidgets('10MB 넘으면 고르는 순간 칸 아래 오류 글 · 서버로 안 보낸다', (tester) async {
      await _pump(
        tester,
        Scaffold(body: ImportView(pickFiles: pick(10 * 1024 * 1024 + 1))),
        overrides: [
          importRepositoryProvider.overrideWith((ref) async => _ImportRepo()),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('attachment-pick')));
      await tester.pumpAndSettle();
      expect(find.text(keepAll(_l.importFileTooLarge)), findsOneWidget);
      expect(find.text(_l.importStepMeta(2, 3)), findsNothing);
    });

    testWidgets('분석 → 2단계 머리 · 매핑 · 옵션 Checkbox · 확정 덮개 → 완료 CTA', (
      tester,
    ) async {
      final repo = _ImportRepo()..execGate = Completer();
      await _pump(
        tester,
        Scaffold(body: ImportView(pickFiles: pick(2048))),
        overrides: [importRepositoryProvider.overrideWith((ref) async => repo)],
      );
      await tester.tap(find.byKey(const ValueKey('attachment-pick')));
      await tester.pumpAndSettle();
      expect(find.text(_l.importStepMeta(2, 3)), findsOneWidget);
      expect(find.text(_l.importStepMapping), findsWidgets);
      // 오류 · 중복은 상태 Badge 로 가른다
      expect(find.text(_l.importBadgeError), findsOneWidget);
      expect(find.text(_l.importBadgeDup), findsOneWidget);
      // 옵션 둘 = ds Checkbox 줄
      expect(find.byType(PListCheckItem), findsNWidgets(2));

      await tester.tap(find.widgetWithText(PButton, _l.importDoImport(8)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();
      final circle = tester.widget<PProgressCircle>(
        find.byKey(const ValueKey('busy-scrim-circle')),
      );
      expect(circle.semanticsLabel, _l.importBusy);

      repo.execGate!.complete(
        const ImportExecuteResult(imported: 9, skipped: 1, failed: 0),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PBusyScrimLayer), findsNothing);
      final section = tester.widget<PResultSection>(
        find.byType(PResultSection),
      );
      expect(section.kind, PResultKind.done);
      expect(section.size, PResultSize.large);
      final cta = tester.widget<PButton>(
        find.widgetWithText(PButton, _l.importGoExpense),
      );
      expect(cta.size, PButtonSize.large);
      expect(cta.variant, PButtonVariant.neutralSolid);
      final ctaRect = tester.getRect(
        find.widgetWithText(PButton, _l.importGoExpense),
      );
      expect(ctaRect.width, 360 - 48, reason: '바닥 CTA 는 좌우 24 로 폭 가득');
      await tester.tap(find.text(_l.importGoExpense));
      await tester.pumpAndSettle();
      expect(find.text('EXPENSE'), findsOneWidget);
    });

    test('실행 응답 파싱 — 실패 줄 · 잘림 · 만든 카테고리, 옛 응답은 빈 값', () {
      final r = ImportExecuteResult.fromJson({
        'imported': 5,
        'skipped': 1,
        'failed': 120,
        'failures': [
          {'lineNo': 3, 'reason': 'date'},
          {'lineNo': 9, 'reason': 'fxRate'},
        ],
        'failuresTruncated': true,
        'createdCategories': ['식비', '식비 > 커피'],
        'createdCategoryCount': 4,
      });
      expect(r.failures.map((f) => f.lineNo), [3, 9]);
      expect(r.failures.last.reason, 'fxRate');
      expect(r.failuresTruncated, isTrue);
      expect(r.createdCategories, ['식비', '식비 > 커피']);
      expect(r.createdCategoryCount, 4);
      final old = ImportExecuteResult.fromJson({
        'imported': 1,
        'skipped': 0,
        'failed': 0,
      });
      expect(old.failures, isEmpty);
      expect(old.failuresTruncated, isFalse);
      expect(old.createdCategories, isEmpty);
    });

    test('모르는 사유 코드는 코드를 흘리지 않고 기본 글로', () {
      expect(importFailReasonText(_l, 'date'), _l.importFailReasonDate);
      expect(importFailReasonText(_l, 'fxRate'), _l.importFailReasonUnknown);
      expect(importFailReasonText(_l, 'fxRate'), isNot(contains('fxRate')));
    });

    testWidgets('완료 — 만든 카테고리 · 실패 줄 목록 · 잘렸다는 글', (tester) async {
      final repo = _ImportRepo()
        ..result = ImportExecuteResult(
          imported: 70,
          skipped: 0,
          failed: 120,
          failures: [
            const ImportFailureRow(lineNo: 3, reason: 'date'),
            const ImportFailureRow(lineNo: 9, reason: 'fxRate'),
          ],
          failuresTruncated: true,
          createdCategories: const ['식비', '식비 > 커피'],
          createdCategoryCount: 5,
        );
      await _pump(
        tester,
        Scaffold(body: ImportView(pickFiles: pick(2048))),
        overrides: [importRepositoryProvider.overrideWith((ref) async => repo)],
      );
      await tester.tap(find.byKey(const ValueKey('attachment-pick')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PButton, _l.importDoImport(8)));
      await tester.pumpAndSettle();
      expect(_t(_l.importCreatedCatTitle(5)), findsOneWidget);
      // 만든 카테고리 = List 줄(배지 아님) + "외 3개"
      expect(_t('식비 > 커피'), findsOneWidget);
      expect(_t(_l.importNewCatMore(3)), findsOneWidget);
      expect(_t(_l.importFailuresTitle(120)), findsOneWidget);
      expect(_t(_l.importFailureLine(3)), findsOneWidget);
      expect(_t(_l.importFailReasonDate), findsOneWidget);
      expect(_t(_l.importFailReasonUnknown), findsOneWidget);
      expect(find.textContaining('fxRate'), findsNothing);
      expect(_t(_l.importFailuresCapped(120, 2)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// 조금씩(또는 멈췄다가) 바이트를 흘리는 가짜 서버.
class _SlowAdapter implements HttpClientAdapter {
  _SlowAdapter({required this.chunks, required this.gap});
  final int chunks;
  final Duration gap;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final controller = StreamController<Uint8List>();
    () async {
      for (var i = 0; i < chunks; i++) {
        await Future<void>.delayed(gap);
        if (controller.isClosed) return;
        controller.add(Uint8List.fromList([i]));
      }
      await controller.close();
    }();
    cancelFuture?.then((_) {
      if (!controller.isClosed) controller.close();
    });
    return ResponseBody(controller.stream, 200);
  }

  @override
  void close({bool force = false}) {}
}
