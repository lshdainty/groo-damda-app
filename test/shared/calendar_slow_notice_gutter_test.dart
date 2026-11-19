// 캘린더 탭 첫 로딩의 5초 "오래 걸림" 글 — skeleton.md "오래 걸림 글"(groo-design #262): 스켈레톤이 화면 끝까지 그려지는
// 자리(캘린더 달 격자)면 글은 첫 스켈레톤이 아니라 화면 여백(global gutter 24)에 왼쪽을 맞추고, 첫 스켈레톤 위 16 은 그대로다.
// 글자 크기와 상관없는 배치라 100% 로 본다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

import '../support/plain_text.dart';

void main() {
  for (final width in [320.0, 402.0]) {
    testWidgets('${width.round()} · 100% — 글은 화면 여백 24 · 첫 스켈레톤 위 16', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userCalendarListProvider.overrideWith(
              (ref) async => const [
                UserCalendar(rowId: 1, calendarName: '개인', isDefault: true),
              ],
            ),
            monthEventsProvider.overrideWith(
              (ref, key) => Completer<List<CalendarEvent>>().future,
            ),
            holidayListProvider.overrideWith((ref, key) async => const []),
          ],
          child: MaterialApp(
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: child!,
            ),
            home: const Scaffold(body: CalendarScreen()),
          ),
        ),
      );
      // 5초가 지나 글이 붙는다(10초 실패 전)
      await tester.pump(const Duration(seconds: 6));
      expect(tester.takeException(), isNull);
      final slow = findPlainContaining('평소보다 오래 걸리고 있어요');
      expect(slow, findsOneWidget);
      final text = tester.getRect(slow);
      final region = find.ancestor(
        of: slow,
        matching: find.byType(PLoadingRegion),
      );
      // 첫 스켈레톤 = 달 격자(맨 위 칸 선이 격자 위 끝이다 — 날 원은 칸 선 1 · 위 여백 1 아래)
      final grid = tester.getRect(
        find.descendant(
          of: region,
          matching: find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_CalendarGridSkeleton',
          ),
        ),
      );
      expect(text.left, PSpacing.globalGutter, reason: '화면 여백 24 에 선다');
      expect(
        text.right,
        lessThanOrEqualTo(width - PSpacing.globalGutter + 0.01),
        reason: '오른쪽도 화면 여백 안',
      );
      expect(
        grid.top - text.bottom,
        closeTo(PSpacing.x4, 0.01),
        reason: '첫 스켈레톤(달 격자) 위로 16',
      );
      // 격자는 그대로 화면 끝까지(안쪽 2) — 글만 여백에 선다
      expect(tester.getRect(region).left, 0);
    });
  }

  testWidgets('PLoadingRegion.bleed — 끄면 글은 영역 왼쪽 끝(첫 스켈레톤), 켜면 화면 여백 24', (
    tester,
  ) async {
    Future<double> slowLeft({required bool bleed}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: PLoadingRegion(
                key: ValueKey(bleed),
                pending: true,
                bleed: bleed,
                fallback: const PSkeleton(height: 40),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 6));
      return tester.getRect(findPlainContaining('평소보다 오래 걸리고 있어요')).left;
    }

    expect(await slowLeft(bleed: false), 0);
    expect(await slowLeft(bleed: true), PSpacing.globalGutter);
  });
}
