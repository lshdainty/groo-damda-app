// 강제 업데이트 화면(I-05 14 ~ 20 · 76) — 실제 화면을 띄운 채로 잰다.
//
//  - 바닥 = 흰 면(bgLayerDefault), "바뀐 내용" 상자 = bgNeutralWeak 라 라이트에서도 바닥과 다르다
//  - 제목은 머리말 1단계(R1 t6 · 700), 강제 안내는 Callout(warning)
//  - 받는 중 = 값 있는 ds 원 24 · 모르면 값 없는 원
//  - 상자 안이 길면 끝 흐림(PScrollFog box), 바닥 짝 위 영역은 늘 page 흐림(위 20 · 아래 80)
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/update/apk_installer.dart';
import 'package:groo_damda_app/core/update/app_update.dart';
import 'package:groo_damda_app/features/update/presentation/release_notes_view.dart';
import 'package:groo_damda_app/features/update/presentation/update_gate_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';
import '../../support/plain_text.dart';

class _FakeInstaller extends ApkInstaller {
  _FakeInstaller(this.progress);
  final ApkProgress progress;

  @override
  ApkProgress build() => progress;
}

final _longNotes = [
  for (var g = 0; g < 8; g++) ...[
    '새 기능 $g',
    for (var i = 0; i < 4; i++) '- 지어낸 변경 내용 $g-$i 가 두 줄로 넘어갈 만큼 길게 적힌 문장이에요',
  ],
].join('\n');

Future<void> _pump(
  WidgetTester tester, {
  bool dark = false,
  bool forced = false,
  double scale = 1,
  Size size = const Size(360, 780),
  EdgeInsets safeArea = EdgeInsets.zero,
  ApkProgress progress = const ApkProgress(),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3.0;
  final inset = FakeViewPadding(
    top: safeArea.top * 3,
    bottom: safeArea.bottom * 3,
  );
  tester.view.padding = inset;
  tester.view.viewPadding = inset;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final status = UpdateStatus(
    currentBuild: 100,
    latest: AppRelease(
      version: '9.9.9',
      buildNumber: 101,
      androidFile: 'a.apk',
      iosFile: 'a.ipa',
      notes: _longNotes,
      minBuildNumber: forced ? 101 : 0,
    ),
  );
  final container = ProviderContainer(
    overrides: [
      updateStatusProvider.overrideWith((ref) async => status),
      apkInstallerProvider.overrideWith(() => _FakeInstaller(progress)),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: '/gate',
    routes: [
      GoRoute(path: '/gate', builder: (_, _) => const UpdateGateScreen()),
      GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  if (progress.isBusy) {
    // 값 없는 원은 끝없이 돈다 — settle 하지 않는다
    await tester.pump(const Duration(milliseconds: 300));
  } else {
    await tester.pumpAndSettle();
  }
}

/// "바뀐 내용" 회색 상자 — 노트를 담은 가장 가까운 Container.
/// 아주 큰 글자에서는 처음에 화면 밖(스크롤 아래)일 수 있어 화면 밖도 찾는다.
Finder _box() => find
    .ancestor(
      of: find.byType(PReleaseNotes, skipOffstage: false),
      matching: find.byType(Container, skipOffstage: false),
    )
    .first;

/// 흐림 — 바닥 짝 위 영역(page) · "바뀐 내용" 상자 안(box).
Finder _fog(PScrollFogUse use) => find.byWidgetPredicate(
  (w) => w is PScrollFog && w.use == use,
  skipOffstage: false,
);

void main() {
  for (final dark in [false, true]) {
    testWidgets('${dark ? "다크" : "라이트"} — 바닥은 흰 면이고 상자 바탕은 바닥과 다르다', (
      tester,
    ) async {
      await _pump(tester, dark: dark, forced: true);
      final c = (dark ? GrooTheme.dark() : GrooTheme.light())
          .extension<PColors>()!;
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, c.bgLayerDefault);
      final box = tester.widget<Container>(
        find
            .ancestor(
              of: _fog(PScrollFogUse.box),
              matching: find.byType(Container),
            )
            .first,
      );
      final fill = (box.decoration! as BoxDecoration).color;
      expect(fill, c.bgNeutralWeak);
      expect(fill, isNot(scaffold.backgroundColor));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('제목은 머리말 1단계 · 강제 안내는 Callout(warning) · 상자는 끝 흐림', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, forced: true);
    final title = findText('새 버전 9.9.9이 나왔어요');
    expect(title, findsOneWidget);
    expect(tester.getSemantics(title).hasFlag(SemanticsFlag.isHeader), isTrue);
    final style = tester.widget<Text>(title).style!;
    expect(style.fontSize, 18);
    expect(style.fontWeight, FontWeight.w700);
    expect(
      tester.widget<PCallout>(find.byType(PCallout)).tone,
      PCalloutTone.warning,
    );
    expect(_fog(PScrollFogUse.box), findsOneWidget);
    expect(_fog(PScrollFogUse.page), findsOneWidget);
    handle.dispose();
  });

  testWidgets('글자 200% · 폭 360 — 넘치지 않는다', (tester) async {
    await _pump(tester, forced: true, scale: 2);
    expect(tester.takeException(), isNull);
  });

  // 바닥 짝 위는 늘 page 흐림 — 넘치지 않으면 흐림이 위 20 · 아래 80 빈 여백 위에 놓이고, 상자는 그 여백을 뺀
  // 남은 높이를 다 쓴다(scroll-fog.md "넘쳤는지 재서 켜고 끄지 않는다").
  testWidgets('100% — page 흐림 여백을 뺀 남은 높이를 상자가 다 쓰고 안에서 스크롤한다', (tester) async {
    await _pump(tester, forced: true);
    final box = tester.getRect(_box());
    final region = tester.getRect(_fog(PScrollFogUse.page));
    final actionsTop = tester.getRect(find.byType(PButton).first).top;
    expect(_fog(PScrollFogUse.box), findsOneWidget);
    expect(
      actionsTop - box.bottom,
      closeTo(80, 0.01),
      reason: '상자 끝 → 바닥 짝 80',
    );
    expect(
      actionsTop - region.bottom,
      closeTo(0, 0.01),
      reason: '영역은 바닥 짝 바로 위에서 끝난다(여백 80 이 간격을 대신)',
    );
    expect(
      tester
              .getRect(
                find
                    .ancestor(
                      of: find.byIcon(LucideIcons.download),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .top -
          region.top,
      closeTo(20, 0.01),
      reason: '위 여백 20',
    );
    // 화면(바깥)은 스크롤되지 않는다 — 넘친 노트는 상자 안에서 넘긴다
    final outer = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(outer.position.maxScrollExtent, 0);
  });

  // QA 2026-11-20(iOS 3048 AX5): 제목 · 안내 · 쌓인 바닥 짝만으로 공간이 차 "이번에 달라진 점" 아래 상자가
  // 0 으로 눌렸다(Expanded 가 남은 0 을 받음). 읽는 내용은 커진다(#260) — 상자가 내용 높이를 갖고 화면이 스크롤된다.
  for (final c in [
    (
      name: 'iOS AX5(310%) · 393×852',
      scale: 3.1,
      size: const Size(393, 852),
      safe: const EdgeInsets.only(top: 59, bottom: 34),
      platform: TargetPlatform.iOS,
    ),
    (
      name: '안드 200% · 412×915',
      scale: 2.0,
      size: const Size(412, 915),
      safe: const EdgeInsets.only(top: 24, bottom: 24),
      platform: TargetPlatform.android,
    ),
    (
      name: '안드 200% · 360×780',
      scale: 2.0,
      size: const Size(360, 780),
      safe: EdgeInsets.zero,
      platform: TargetPlatform.android,
    ),
  ]) {
    for (final forced in [false, true]) {
      testWidgets(
        '${c.name}${forced ? ' · 강제' : ''} — 바뀐 내용 글이 보이고 높이가 있다',
        (tester) async {
          await _pump(
            tester,
            forced: forced,
            scale: c.scale,
            size: c.size,
            safeArea: c.safe,
          );
          expect(tester.takeException(), isNull, reason: '넘침 없음');
          // 두 모양 모두 바닥 짝 위 영역은 page 흐림이다
          expect(_fog(PScrollFogUse.page), findsOneWidget);
          final region = tester.getRect(_fog(PScrollFogUse.page));

          // 상자가 눌리지 않았다 — 위아래 안쪽 여백(20 · 20) 말고도 글 자리가 있다
          final box = tester.getRect(_box());
          final first = findTextContaining(
            '지어낸 변경 내용 0-0',
            skipOffstage: false,
          );
          final last = findTextContaining('지어낸 변경 내용 7-3', skipOffstage: false);
          expect(tester.getSize(first).height, greaterThan(0));
          expect(box.height, greaterThan(40));
          expect(tester.getRect(first).top, greaterThanOrEqualTo(box.top));

          // 첫 줄 · 마지막 줄 모두 스크롤해서 영역 안에 보인다.
          // AX5 는 항목 하나가 영역보다 길 수 있어 걸친 자리를 본다.
          for (final line in [first, last]) {
            await tester.ensureVisible(line);
            await tester.pumpAndSettle();
            final r = tester.getRect(line);
            expect(r.bottom, greaterThan(region.top));
            expect(r.top, lessThan(region.bottom));
          }
          // 끝까지 스크롤하면 마지막 줄이 흐림 밖에 보인다 — 상자 안 여백 20 위, 상자는 page 아래 여백 80 위.
          // 큰 글자면 영역 전체(스크롤 하나), 보통이면 상자 안 스크롤 — 둘 중 안쪽이 마지막이다
          await tester.drag(
            find.byType(Scrollable).last,
            const Offset(0, -100000),
          );
          await tester.pumpAndSettle();
          final endBox = tester.getRect(_box());
          expect(
            tester.getRect(last).bottom,
            lessThanOrEqualTo(endBox.bottom - 20 + 0.01),
          );
          expect(endBox.bottom, lessThanOrEqualTo(region.bottom - 80 + 0.01));
          // 영역은 바닥 짝 바로 위에서 끝난다 — 끝까지 내린 상자 끝은 바닥 짝 위 80
          final actionsTop = tester.getRect(find.byType(PButton).first).top;
          expect(region.bottom, closeTo(actionsTop, 0.01));
        },
        variant: TargetPlatformVariant.only(c.platform),
      );
    }
  }

  testWidgets('바닥 짝 [취소][설치] — 100% 는 한 줄 3 : 7, 200% 는 쌓인다', (tester) async {
    await _pump(tester, forced: true);
    expect(find.byKey(const ValueKey('pair-row')), findsOneWidget);
    final cancel = tester.getSize(find.byType(PButton).first);
    final install = tester.getSize(find.byType(PButton).last);
    expect(cancel.width, closeTo(304 * 0.3, 0.01));
    expect(install.width, closeTo(304 * 0.7, 0.01));
    expect(cancel.height, 48);
    expect(
      tester.widget<PButton>(find.byType(PButton).first).variant,
      PButtonVariant.neutralWeak,
    );
    expect(
      tester.widget<PButton>(find.byType(PButton).last).variant,
      PButtonVariant.neutralSolid,
    );
  });

  testWidgets('바닥 짝 200% — 쌓이고 오류가 없다', (tester) async {
    await _pump(tester, forced: true, scale: 2);
    expect(find.byKey(const ValueKey('pair-column')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('받는 중 37% — 값 있는 원 24', (tester) async {
    await _pump(
      tester,
      progress: const ApkProgress(
        stage: ApkStage.downloading,
        received: 37,
        total: 100,
      ),
    );
    final circle = tester.widget<PProgressCircle>(find.byType(PProgressCircle));
    expect(circle.size, PProgressCircleSize.s24);
    expect(circle.value, closeTo(37, 0.001));
    expect(findText('받는 중이에요'), findsOneWidget);
  });

  testWidgets('길이를 모르면 값 없는 원', (tester) async {
    await _pump(tester, progress: const ApkProgress(stage: ApkStage.opening));
    final circle = tester.widget<PProgressCircle>(find.byType(PProgressCircle));
    expect(circle.value, isNull);
  });
}
