// B5 H-2 — ListView 대신 Column 으로 그리는 불러오는 중 스켈레톤 여섯 화면이 실제 폰 높이(640 · 800)에서 넘치지 않는다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/presentation/account_card_manage_screen.dart';
import 'package:groo_damda_app/features/category/presentation/category_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/notification/data/user_preferences_repository.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_screen.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_settings_screen.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_screen.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

class _NeverPrefs extends UserPreferencesNotifier {
  @override
  Future<UserPreferences> build() => _never();
}

Future<T> _never<T>() => Completer<T>().future;

final _screens = <String, Widget Function()>{
  '알림 설정': () => const NotificationSettingsScreen(),
  '알림': () => const NotificationScreen(),
  '카테고리': () => const CategoryScreen(),
  '프리셋': () => const PresetScreen(),
  '반복 거래': () => const RecurringScreen(),
  '계좌·카드 관리': () => const AccountCardManageScreen(),
};

final _rows = <String>[];

void main() {
  tearDownAll(() => print(_rows.join('\n'))); // ignore: avoid_print
  for (final e in _screens.entries) {
    for (final h in [640.0, 800.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${e.key} 불러오는 중 · 360x${h.toInt()} · ${scale * 100}%', (
          tester,
        ) async {
          tester.view.physicalSize = Size(360, h);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              retry: (_, _) => null,
              overrides: [
                userPreferencesProvider.overrideWith(_NeverPrefs.new),
                notificationListProvider.overrideWith((ref) => _never()),
                unreadCountProvider.overrideWith((ref) => _never()),
                categoriesProvider.overrideWith((ref) => _never()),
                presetListProvider.overrideWith((ref) => _never()),
                recurringListProvider.overrideWith((ref) => _never()),
                assetsProvider.overrideWith((ref) => _never()),
              ],
              child: MaterialApp(
                theme: GrooTheme.light(),
                locale: const Locale('ko'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (c, child) => MediaQuery(
                  data: MediaQuery.of(
                    c,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: e.value(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 1500));
          await tester.pump(const Duration(seconds: 5));
          final ex = tester.takeException();
          _rows.add(
            '${e.key} | 360x${h.toInt()} | ${(scale * 100).toInt()}% | ${ex == null ? '넘침 없음' : '예외: ${ex.toString().split('\n').first}'}',
          );
          expect(ex, isNull);
        });
      }
    }
  }
}
