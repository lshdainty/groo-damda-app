// 비밀번호 바꾸기(I-14 14 ~ 16) — 시트 · [저장] 네 조건 · USER_003 → 현재 칸 오류 · 그 밖 → Callout · 서버 글 0.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/auth_repository.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/settings/presentation/password_change_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

class _Repo extends AuthRepository {
  _Repo(this.code) : super(Dio());
  final String? code;
  int calls = 0;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    calls++;
    if (code != null) {
      throw ApiException(code: code!, message: '서버 원문 글입니다');
    }
  }
}

Future<_Repo> _open(WidgetTester tester, {String? code}) async {
  final repo = _Repo(code);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWith((ref) async => repo)],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () => showPasswordChangeDialog(c),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _fill(
  WidgetTester tester,
  String cur,
  String nw,
  String cf,
) async {
  final f = find.byType(EditableText);
  await tester.enterText(f.at(0), cur);
  await tester.enterText(f.at(1), nw);
  await tester.enterText(f.at(2), cf);
  await tester.pump();
}

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<PButton>(find.widgetWithText(PButton, '저장')).onPressed !=
    null;

void main() {
  testWidgets('필수 표시 · 자리 글이 없고 네 조건 전에는 [저장] 이 막힌다', (tester) async {
    await _open(tester);
    expect(find.text('*'), findsNothing);
    expect(_saveEnabled(tester), isFalse);

    await _fill(tester, 'old-one!', 'new-one!!', 'new-one!x');
    expect(find.text('새 비밀번호가 일치하지 않아요'), findsOneWidget);
    expect(_saveEnabled(tester), isFalse);

    await _fill(tester, 'old-one!', 'new-one!!', 'new-one!!');
    expect(find.text('새 비밀번호가 일치해요'), findsOneWidget);
    expect(_saveEnabled(tester), isTrue);
  });

  testWidgets('USER_003 은 현재 칸 오류 · 서버 글은 어디에도 없다', (tester) async {
    await _open(tester, code: 'USER_003');
    await _fill(tester, 'old-one!', 'new-one!!', 'new-one!!');
    await tester.tap(find.widgetWithText(PButton, '저장'));
    await tester.pumpAndSettle();

    expect(find.text('현재 비밀번호가 맞지 않아요'), findsOneWidget);
    expect(find.text('서버 원문 글입니다'), findsNothing);
  });

  testWidgets('그 밖 실패는 본문 맨 위 Callout 이고 값이 남는다', (tester) async {
    await _open(tester, code: 'X_1');
    await _fill(tester, 'old-one!', 'new-one!!', 'new-one!!');
    await tester.tap(find.widgetWithText(PButton, '저장'));
    await tester.pumpAndSettle();

    expect(find.text('비밀번호를 바꾸지 못했어요. 잠시 뒤 다시 시도해주세요.'), findsOneWidget);
    expect(find.text('서버 원문 글입니다'), findsNothing);
  });
}
