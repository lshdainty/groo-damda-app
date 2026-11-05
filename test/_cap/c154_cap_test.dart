// c154 앱 렌더 — 알림 목록 · 알림 설정. 레포에 두지 않는다(test/_cap 에 복사했다가 지운다, 사본은 c154/app/_harness/).
// 실행: TZ=Asia/Seoul flutter test test/_cap/c154_cap_test.dart --dart-define=OUT=<폴더> [--dart-define=SCENES=a,b]
// 데이터 = c154/web/manifest.json(웹 에이전트가 적은 장면 · 알림 · 설정 값).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:groo_damda_app/app/app.dart' show appMessengerKey;
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/format/now_tick.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/notification/data/notification_repository.dart';
import 'package:groo_damda_app/features/notification/data/user_preferences_repository.dart';
import 'package:groo_damda_app/features/notification/domain/notification.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_screen.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_settings_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/switch/p_switch.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/ds/slider/p_slider.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

const outDir = String.fromEnvironment('OUT');
const only = String.fromEnvironment('SCENES');
const manifestPath =
    '/home/lshdainty/qa/design-work/impl-audit/c154/web/manifest.json';

final _now = DateTime(2026, 10, 29, 13);

class _FixedNow extends NowTick {
  @override
  DateTime build() => _now;
}

class _Auth extends AuthNotifier {
  _Auth(this.email);
  final String email;
  @override
  Future<User?> build() async =>
      User(rowId: 1, userId: 'u', userName: '단풍', userEmail: email);
}

class Mock {
  Mock(Map<String, dynamic> m)
    : delayUnread = (m['delayUnread'] ?? 0) as int,
      delayMarkAll = (m['delayMarkAll'] ?? 0) as int,
      delayList = (m['delayList'] ?? 0) as int,
      delayPrefs = (m['delayPrefs'] ?? 0) as int,
      failMarkAll = m['failMarkAll'] == true,
      failDelete = m['failDelete'] == true,
      failList = m['failList'] == true,
      failPatch = m['failPatch'] == true;
  final int delayUnread, delayMarkAll, delayList, delayPrefs;
  final bool failMarkAll, failDelete, failList, failPatch;
}

class FakeNoti extends NotificationRepository {
  FakeNoti(this.items, this.unread, this.mock) : super(Dio());
  List<AppNotification> items;
  int unread;
  final Mock mock;
  @override
  Future<List<AppNotification>> list({bool? unread, int? limit}) async {
    if (mock.delayList > 0)
      await Future<void>.delayed(Duration(milliseconds: mock.delayList));
    if (mock.failList) throw Exception('list');
    return items;
  }

  @override
  Future<int> unreadCount() async {
    if (mock.delayUnread > 0)
      await Future<void>.delayed(Duration(milliseconds: mock.delayUnread));
    return unread;
  }

  @override
  Future<void> markAllRead() async {
    if (mock.delayMarkAll > 0)
      await Future<void>.delayed(Duration(milliseconds: mock.delayMarkAll));
    if (mock.failMarkAll) throw Exception('markAll');
    items = [for (final n in items) n.copyWith(isRead: true)];
    unread = 0;
  }

  @override
  Future<void> markRead(int id) async {}

  @override
  Future<void> delete(int id) async {
    if (mock.failDelete) throw Exception('delete');
    items = [
      for (final n in items)
        if (n.rowId != id) n,
    ];
  }
}

class FakePrefs extends UserPreferencesRepository {
  FakePrefs(this.prefs, this.mock) : super(Dio());
  UserPreferences prefs;
  final Mock mock;
  @override
  Future<UserPreferences> get() async {
    if (mock.delayPrefs > 0)
      await Future<void>.delayed(Duration(milliseconds: mock.delayPrefs));
    return prefs;
  }

  @override
  Future<UserPreferences> update(
    Map<String, dynamic> fields, {
    bool silent = false,
  }) async {
    if (mock.failPatch) throw Exception('patch');
    return prefs;
  }
}

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final l = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await l.load();
}

void main() {
  testWidgets('cap', (t) async {
    debugDisableShadows = false;
    await _font('Pretendard', 'assets/fonts/PretendardVariable.ttf');
    await _font('FlutterTest', 'assets/fonts/PretendardVariable.ttf');
    await _font('Roboto', 'assets/fonts/PretendardVariable.ttf');
    final home = Platform.environment['HOME'];
    final cache = Platform.environment['PUB_CACHE'] ?? '$home/.pub-cache';
    final d = Directory('$cache/hosted/pub.dev')
        .listSync()
        .firstWhere((e) => e.path.contains('lucide_icons_flutter'))
        .path;
    await _font('packages/lucide_icons_flutter/Lucide', '$d/assets/lucide.ttf');
    for (final w in [100, 200, 300, 400, 500, 600]) {
      await _font(
        'packages/lucide_icons_flutter/Lucide$w',
        '$d/assets/build_font/LucideVariable-w$w.ttf',
      );
    }
    Directory(outDir).createSync(recursive: true);
    final mf =
        jsonDecode(File(manifestPath).readAsStringSync())
            as Map<String, dynamic>;
    final scenes = {
      for (final s in mf['scenes'] as List)
        (s as Map<String, dynamic>)['id'] as String: s,
    };
    final meas = <String, Object?>{};
    final status = <String, Object?>{};
    final errs = <String>[];
    FlutterError.onError = (d) {
      final m = d.toString().split('\n').take(8).join(' | ');
      errs.add(m);
      stdout.writeln('FLUTTERERR ' + m);
    };

    Future<void> settle(int ms) async {
      for (var k = 0; k < ms ~/ 50; k++) {
        await t.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> shot(String k, GlobalKey key) async {
      await t.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 2);
        final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
        File('$outDir/$k.png').writeAsBytesSync(bytes.buffer.asUint8List());
      });
    }

    Finder tx(String x) => find.byWidgetPredicate(
      (w) =>
          w is RichText && w.text.toPlainText().replaceAll('\u2060', '') == x,
    );

    Finder delFinder() => find.byWidgetPredicate(
      (w) =>
          w is RichText &&
          w.text.toPlainText().replaceAll('\u2060', '') == '삭제',
    );

    Future<void> scrollTo(Finder f) async {
      if (f.evaluate().isEmpty) {
        await t.dragUntilVisible(
          f,
          find.byType(Scrollable).first,
          const Offset(0, -120),
          maxIteration: 60,
        );
      }
      await Scrollable.ensureVisible(t.element(f.first), alignment: 0.3);
      await settle(300);
    }

    Future<void> run(
      String id, {
      required bool settings,
      String? dataId,
      Future<void> Function(Mock)? act,
      int wait = 1200,
      Map<String, Object?> Function()? measure,
    }) async {
      if (only.isNotEmpty && !only.split(',').contains(id)) return;
      final s = scenes[dataId ?? id];
      if (s == null) {
        status[id] = 'manifest 에 없음';
        return;
      }
      final mock = Mock(Map<String, dynamic>.from(s['mock'] as Map));
      final dark = s['scheme'] == 'dark';
      final scale = (s['fontScale'] as num).toDouble();
      final items = [
        for (final n in (s['notifications'] as List))
          AppNotification.fromJson(Map<String, dynamic>.from(n as Map)),
      ];
      final noti = FakeNoti(items, (s['serverUnreadCount'] ?? 0) as int, mock);
      final prefs = s['preferences'] == null
          ? null
          : FakePrefs(
              UserPreferences.fromJson(
                Map<String, dynamic>.from(s['preferences'] as Map),
              ),
              mock,
            );
      t.view.physicalSize = const Size(390 * 2, 844 * 2);
      t.view.devicePixelRatio = 2;
      final key = GlobalKey();
      final router = GoRouter(
        initialLocation: settings ? '/settings' : '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const NotificationSettingsScreen(),
          ),
        ],
      );
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ProviderScope(
            retry: (_, _) => null,
            overrides: [
              nowTickProvider.overrideWith(_FixedNow.new),
              notificationRepositoryProvider.overrideWith((ref) async => noti),
              userPreferencesRepositoryProvider.overrideWith(
                (ref) async =>
                    prefs ??
                    FakePrefs(
                      UserPreferences.fromJson(
                        Map<String, dynamic>.from(
                          mf['defaultPreferences'] as Map,
                        ),
                      ),
                      mock,
                    ),
              ),
              authProvider.overrideWith(() => _Auth(s['email'] as String)),
            ],
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: appMessengerKey,
              routerConfig: router,
              theme: dark ? GrooTheme.dark() : GrooTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ko'),
              builder: (c, ch) => PSnackbarHost(
                closeLabel: '닫기',
                child: MediaQuery(
                  data: MediaQuery.of(
                    c,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: ch!,
                ),
              ),
            ),
          ),
        ),
      );
      await settle(wait);
      if (act != null) await act(mock);
      final err = t.takeException();
      stdout.writeln('PRE-MEASURE $id');
      if (measure != null) meas[id] = measure();
      stdout.writeln('PRE-SHOT $id');
      await shot(id, key);
      status[id] = err == null
          ? 'ok'
          : 'ERR ${err.toString().split('\n').first}';
      router.dispose();
      await t.pumpWidget(const SizedBox());
      await settle(100);
    }

    Map<String, Object?> switchMeasure() {
      final sw = t.widgetList<PSwitchmark>(find.byType(PSwitchmark)).first;
      final r = t.getSize(find.byType(PSwitchmark).first);
      final rects = [
        for (final e in find.byType(PSwitchmark).evaluate())
          (e.renderObject as RenderBox).localToGlobal(Offset.zero) &
              (e.renderObject as RenderBox).size,
      ];
      final icons = [
        for (final e in find.byType(Icon).evaluate())
          (e.renderObject as RenderBox).localToGlobal(Offset.zero) &
              (e.renderObject as RenderBox).size,
      ];
      return {
        'switchMarkSize': '${r.width}x${r.height}',
        'size': sw.size.toString(),
        'switchRightMax': rects
            .map((e) => e.right)
            .reduce((a, b) => a > b ? a : b),
        'switchLeftMin': rects
            .map((e) => e.left)
            .reduce((a, b) => a < b ? a : b),
        'iconLeftMin': icons.map((e) => e.left).reduce((a, b) => a < b ? a : b),
        'switchRects': rects.take(3).map((e) => e.toString()).toList(),
      };
    }

    // 목록
    await run('notif-list', settings: false);
    await run('notif-list-dark', settings: false);
    await run('notif-late-count', settings: false, wait: 1000);
    await run(
      'mark-all-pressed',
      settings: false,
      act: (_) async {
        await t.tap(tx('모두 읽음'));
        await settle(500);
      },
    );
    await run(
      'mark-all-done',
      settings: false,
      act: (_) async {
        await t.tap(tx('모두 읽음'));
        await settle(1500);
      },
    );
    await run(
      'fail-mark-all',
      settings: false,
      act: (_) async {
        await t.tap(tx('모두 읽음'));
        await settle(800);
      },
    );
    await run(
      'fail-delete',
      settings: false,
      act: (_) async {
        stdout.writeln(
          'KEY ${find.byKey(const ValueKey('noti-more-6')).evaluate().length} rect ${t.getRect(find.byKey(const ValueKey('noti-more-6')))}',
        );
        final more = find.byKey(const ValueKey('noti-more-6'));
        final box = t.getRect(
          find.descendant(of: more, matching: find.byType(DecoratedBox)).first,
        );
        await t.tapAt(box.topCenter - const Offset(0, 5));
        await settle(1500);
        var f = delFinder();
        stdout.writeln(
          'STEP1 ${f.evaluate().length} ' +
              t
                  .widgetList<RichText>(find.byType(RichText))
                  .map((e) => e.text.toPlainText().replaceAll('\u2060', '~'))
                  .join('|'),
        );
        await t.tap(f.first);
        await settle(800);
        f = delFinder();
        stdout.writeln('STEP2 ${f.evaluate().length}');
        await t.tap(f.last);
        await settle(900);
      },
    );
    await run('empty', settings: false);
    await run('fail', settings: false);
    await run('loading', settings: false, wait: 600);
    // 설정
    await run('settings-default', settings: true, measure: switchMeasure);
    await run('settings-default-dark', settings: true);
    await run(
      'settings-push-off',
      settings: true,
      act: (_) async {
        await scrollTo(tx('시작'));
      },
    );
    await run(
      'settings-dnd-off',
      settings: true,
      act: (_) async {
        await scrollTo(tx('시작'));
      },
    );
    await run(
      'time-sheet',
      settings: true,
      act: (_) async {
        stdout.writeln(
          'TXT ' +
              t
                  .widgetList<RichText>(find.byType(RichText))
                  .map((e) => e.text.toPlainText().replaceAll('\u2060', '~'))
                  .join('|'),
        );
        await scrollTo(tx('시작'));
        await t.tap(tx('시작').first);
        stdout.writeln('TS2');
        await settle(900);
        stdout.writeln('TS3');
      },
      measure: () {
        final p = t.widgetList<PTimePicker>(find.byType(PTimePicker)).toList();
        return {'minuteStep': p.isEmpty ? null : p.first.minuteStep};
      },
    );
    await run(
      'slider-ends',
      settings: true,
      act: (_) async {
        await scrollTo(tx('50%'));
      },
      measure: () {
        final sl = t.getRect(find.byType(PSlider).first);
        return {
          'sliderRect': sl.toString(),
          'sliderTexts': t
              .widgetList<RichText>(find.byType(RichText))
              .map((e) => e.text.toPlainText().replaceAll('\u2060', ''))
              .where((x) => x.contains('%') || x.contains('알림'))
              .toList(),
        };
      },
    );
    await run(
      'settings-scroll-end',
      settings: true,
      dataId: 'settings-default',
      act: (_) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -5000));
        await settle(500);
        await t.drag(find.byType(Scrollable).first, const Offset(0, -5000));
        await settle(500);
      },
    );
    await run(
      'fail-switch',
      settings: true,
      act: (_) async {
        await t.tap(tx('결제 알림'));
        await settle(900);
      },
    );
    await run(
      'fail-slider',
      settings: true,
      act: (_) async {
        await scrollTo(tx('50%'));
        await t.drag(find.byType(PSlider), const Offset(-60, 0));
        await settle(900);
      },
    );
    await run(
      'email-52',
      settings: true,
      act: (_) async {
        await scrollTo(tx('이메일 받기'));
      },
    );
    await run('settings-loading', settings: true, wait: 600);
    await run('settings-loaded', settings: true, wait: 2500);
    await run('x200-list', settings: false);
    await run(
      'x200-settings-value',
      settings: true,
      act: (_) async {
        await scrollTo(tx('시작'));
      },
    );
    await run(
      'x200-settings-indent',
      settings: true,
      act: (_) async {
        await scrollTo(tx('발송 주기'));
      },
    );

    final mp = File('$outDir/measure.json');
    final prev = mp.existsSync()
        ? jsonDecode(mp.readAsStringSync()) as Map<String, dynamic>
        : <String, dynamic>{};
    final pm = Map<String, dynamic>.from(prev['measure'] ?? {})..addAll(meas);
    final ps = Map<String, dynamic>.from(prev['status'] ?? {})..addAll(status);
    final pe = [...((prev['errors'] ?? []) as List), ...errs];
    mp.writeAsStringSync(
      const JsonEncoder.withIndent(
        ' ',
      ).convert({'measure': pm, 'status': ps, 'errors': pe}),
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
