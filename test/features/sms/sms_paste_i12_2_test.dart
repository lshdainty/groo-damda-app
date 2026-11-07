// I-12 12-2 H — 문자 붙여넣기를 실제 화면으로 잰다.
//
//  - 흰 화면 하나 · 머리 = Top Navigation · 설명 t4 subtle
//  - 칸 = Field(라벨 "결제 문자") + Textarea · 인식 실패는 칸의 오류(경고 상자 아님) · 값을 고치면 걷힘
//  - 취소 문자 = Callout informative display(칸은 오류가 아니다)
//  - 서버 해석 실패 = 폼 맨 위 Callout critical · 서버 글은 안 낸다 · 다시 읽으면 걷힘
//  - 버튼 둘 = 흐름 안(neutralWeak · neutralSolid, large)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/plain_text.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/sms/data/sms_repository.dart';
import 'package:groo_damda_app/features/sms/presentation/sms_paste_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

const _pay = '[Web발신]\n숲빛카드 승인\n5,500원 일시불\n골목찻집';

class _Repo implements SmsRepository {
  _Repo(this.script);

  /// 부를 때마다 하나씩 쓴다 — 'cancel' · 'server' · 'hang'.
  final List<String> script;
  int calls = 0;

  @override
  Future<SmsParseResult> parse(String text, {bool silent = false}) async {
    final mode = script[calls < script.length ? calls : script.length - 1];
    calls++;
    if (mode == 'hang') return Completer<SmsParseResult>().future;
    if (mode == 'server') {
      throw ApiException(code: 'X', message: 'upstream timeout 서버 원문');
    }
    return SmsParseResult(
      matched: true,
      confidence: mode == 'low' ? 'LOW' : 'HIGH',
      cancel: mode == 'cancel',
      amount: 5500,
      assetRemembered: false,
      assetCandidates: const [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_Repo> _pump(
  WidgetTester tester, {
  List<String> script = const ['cancel'],
  bool dark = false,
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(360 * 2, 800 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final repo = _Repo(script);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [smsRepositoryProvider.overrideWith((ref) async => repo)],
      child: MaterialApp(
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: PSnackbarHost(closeLabel: '닫기', child: child!),
        ),
        home: const SmsPasteScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
}

Future<void> _read(WidgetTester tester) async {
  await tester.tap(findText('문자 읽기'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

PField _field(WidgetTester tester) =>
    tester.widget<PField>(find.byType(PField));

void main() {
  testWidgets('문구(M 52 · 55) — 설명은 "채워드려요" · 빈 클립보드 알림은 마침표로 끝난다', (
    tester,
  ) async {
    await _pump(tester);
    expect(findRichPlain('지출 폼을 채워드려요. 저장 전에'), findsOneWidget);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData' ? {'text': ''} : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.tap(findText('클립보드에서 붙여넣기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(findPlain('클립보드에 텍스트가 없어요.'), findsOneWidget);
  });

  testWidgets('B5-5 — "일부 항목" 안내를 스낵바로 또 띄우지 않는다(시트 맨 위 Callout 이 한다)', (
    tester,
  ) async {
    await _pump(tester, script: ['low']);
    await _type(tester, _pay);
    await tester.tap(findText('문자 읽기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // 안내는 시트 Callout 하나뿐이다 — 스낵바 글까지 두 번이 아니다.
    expect(findPlain('일부 항목을 읽지 못했어요. 확인하고 채워주세요.'), findsOneWidget);
    expect(find.byKey(const ValueKey('callout-text')), findsOneWidget);
    expect(find.byType(PSnackbarHost), findsOneWidget);
  });

  testWidgets('흰 화면 하나 · 머리는 Top Navigation · 옛 띠 · 경고 상자가 없다', (tester) async {
    await _pump(tester);
    final c = Theme.of(
      tester.element(find.byType(SmsPasteScreen)),
    ).extension<PColors>()!;
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      c.bgLayerDefault,
    );
    expect(find.byType(PScreenBandBody), findsNothing);
    expect(find.byType(PTopNavigation), findsOneWidget);
    expect(findText('결제 문자로 기록'), findsOneWidget);
  });

  testWidgets('칸 = Field "결제 문자" + Textarea(자리 글은 지어낸 예시, 실제 카드사 · 상호 0)', (
    tester,
  ) async {
    await _pump(tester);
    expect(_field(tester).label, '결제 문자');
    expect(_field(tester).invalid, isFalse);
    final ta = tester.widget<PTextarea>(find.byType(PTextarea));
    expect(ta.autoSize, isTrue);
    expect(ta.maxHeight, 204);
    expect(ta.placeholder, contains('숲빛카드'));
    // 빈 칸은 3줄(94)만 보인다 — 예시는 3줄 안, 가맹점 줄을 남긴다
    expect(ta.placeholder!.split('\n').length, lessThanOrEqualTo(3));
    expect(ta.placeholder, contains('골목찻집'));
    for (final real in ['KB국민', '스타벅스']) {
      expect(ta.placeholder, isNot(contains(real)));
    }
  });

  testWidgets('버튼 둘은 흐름 안 — neutralWeak · neutralSolid, 둘 다 large', (
    tester,
  ) async {
    await _pump(tester);
    final buttons = tester.widgetList<PButton>(find.byType(PButton)).toList();
    expect(buttons, hasLength(2));
    expect(buttons[0].label, '클립보드에서 붙여넣기');
    expect(buttons[0].variant, PButtonVariant.neutralWeak);
    expect(buttons[0].size, PButtonSize.large);
    expect(buttons[1].label, '문자 읽기');
    expect(buttons[1].variant, PButtonVariant.neutralSolid);
    expect(buttons[1].size, PButtonSize.large);
    // 칸 바로 아래 — 바닥에 붙지 않는다
    final fieldBottom = tester.getBottomLeft(find.byType(PField)).dy;
    final buttonTop = tester.getTopLeft(find.byType(PButton).first).dy;
    expect(buttonTop - fieldBottom, 24);
    final buttonGap =
        tester.getTopLeft(find.byType(PButton).last).dy -
        tester.getBottomLeft(find.byType(PButton).first).dy;
    expect(buttonGap, 8);
  });

  testWidgets('인식 실패는 칸의 오류 — 글은 칸 아래, 값을 고치면 걷힌다', (tester) async {
    await _pump(tester);
    await _type(tester, '점심 뭐 먹지 오늘은 국밥');
    await _read(tester);
    expect(_field(tester).invalid, isTrue);
    expect(
      _field(tester).errorMessage,
      '결제 문자로 보이지 않아요. 문자 전체를 붙여넣었는지 확인해주세요.',
    );
    expect(find.byType(PCallout), findsNothing);
    // 값을 고치면 오류를 걷는다 — × 로 닫을 길이 없다
    await _type(tester, '점심 뭐 먹지 오늘은 국밥!');
    expect(_field(tester).invalid, isFalse);
    expect(_field(tester).errorMessage, isNull);
  });

  testWidgets('취소 문자는 오류가 아니라 Callout informative 안내 — 칸은 그대로', (tester) async {
    await _pump(tester, script: ['cancel']);
    await _type(tester, _pay);
    await _read(tester);
    final callout = tester.widget<PCallout>(find.byType(PCallout));
    expect(callout.tone, PCalloutTone.informative);
    expect(callout.interaction, PCalloutInteraction.display);
    expect(callout.description, startsWith('취소 문자예요.'));
    expect(_field(tester).invalid, isFalse);
    // 칸 아래 16
    final gap =
        tester.getTopLeft(find.byType(PCallout)).dy -
        tester.getBottomLeft(find.byType(PField)).dy;
    expect(gap, 16);
  });

  testWidgets('서버 해석 실패는 폼 맨 위 Callout critical — 서버 글은 안 내고 다시 읽으면 걷힌다', (
    tester,
  ) async {
    await _pump(tester, script: ['server', 'cancel']);
    await _type(tester, _pay);
    await _read(tester);
    final callout = tester.widget<PCallout>(find.byType(PCallout));
    expect(callout.tone, PCalloutTone.critical);
    expect(callout.description, '문자를 읽지 못했어요. 잠시 뒤 다시 시도해주세요.');
    expect(findTextContaining('upstream'), findsNothing);
    expect(findTextContaining('서버 원문'), findsNothing);
    // 설명 아래 · 칸 위
    expect(
      tester.getTopLeft(find.byType(PCallout)).dy,
      lessThan(tester.getTopLeft(find.byType(PField)).dy),
    );
    await _read(tester);
    // 두 번째는 취소 문자로 답한다 — 실패 상자는 걷히고 취소 안내가 선다
    expect(
      tester.widget<PCallout>(find.byType(PCallout)).tone,
      PCalloutTone.informative,
    );
  });

  testWidgets('읽는 동안 [문자 읽기] 는 로딩이고 칸은 막힌다', (tester) async {
    await _pump(tester, script: ['hang']);
    await _type(tester, _pay);
    await _read(tester);
    final read = tester
        .widgetList<PButton>(find.byType(PButton))
        .firstWhere((b) => b.label == '문자 읽기');
    expect(read.loading, isTrue);
    final clip = tester
        .widgetList<PButton>(find.byType(PButton))
        .firstWhere((b) => b.label == '클립보드에서 붙여넣기');
    expect(clip.onPressed, isNull);
  });

  testWidgets('다크 · 글자 200% 에서도 넘침 없이 그려진다', (tester) async {
    await _pump(tester, dark: true, scale: 2);
    await _type(tester, '점심 뭐 먹지');
    await _read(tester);
    expect(tester.takeException(), isNull);
  });
}
