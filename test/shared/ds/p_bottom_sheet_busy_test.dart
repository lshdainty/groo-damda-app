// Bottom Sheet 저장 중(busy) — 저장 단추가 로딩인 동안은 닫는 길을 받지 않는다(I-wrap-b2b 1). 실패 Callout 을 그릴 폼이
// 저장 중에 없어지지 않게 한다. 닫기 X 는 흐리게 하지 않고 모양 그대로 둔다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import '../../support/plain_text.dart';

Widget _app(Widget home) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: home,
);

const _leave = PLeaveConfirmCopy(
  title: '작성한 내용이 사라져요',
  description: '나가면 저장되지 않아요.',
  stayLabel: '계속 작성',
  leaveLabel: '나가기',
);

/// 저장 폼 — [저장] 을 누르면 [gate] 가 끝날 때까지 기다린다. 성공이면 close(), 실패면 맨 위 Callout.
class _Form extends StatefulWidget {
  const _Form({required this.gate, required this.useBusy, this.onBack});

  final Completer<bool> Function() gate;
  final bool useBusy;
  final VoidCallback? onBack;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  bool _saving = false;
  bool _failed = false;
  int bodyTaps = 0;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    final sheet = widget.useBusy
        ? (PBottomSheet.maybeOf(context)?..setBusy(true))
        : null;
    try {
      final ok = await widget.gate().future;
      if (!mounted) return;
      if (ok) {
        PBottomSheet.of(context).close();
      } else {
        setState(() => _failed = true);
      }
    } finally {
      sheet?.setBusy(false);
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PBottomSheetContent(
    title: '제목',
    closeLabel: '닫기',
    onBack: widget.onBack,
    backLabel: widget.onBack == null ? null : '뒤로',
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_failed) const Text('저장하지 못했어요'),
        GestureDetector(
          onTap: () => bodyTaps++,
          child: const SizedBox(height: 40, child: Text('본문')),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '저장 중' : '저장'),
        ),
      ],
    ),
  );
}

Future<void> _open(
  WidgetTester tester, {
  required Completer<bool> Function() gate,
  bool useBusy = true,
  bool form = true,
  bool dirty = true,
  bool probeDirty = true,
  VoidCallback? onBack,
  ValueSetter<Object?>? onResult,
}) async {
  await tester.pumpWidget(
    _app(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final r = await PBottomSheet.show<Object?>(
                context,
                form: form,
                isDirty: probeDirty ? () => dirty : null,
                leaveCopy: probeDirty ? _leave : null,
                builder: (_) =>
                    _Form(gate: gate, useBusy: useBusy, onBack: onBack),
              );
              onResult?.call(r);
            },
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('열기'));
  await tester.pumpAndSettle();
  // 끌기는 열린 뒤 0.5초 지나야 받는다
  await tester.pump(kSheetDragDelay);
}

Finder get _close => find.byKey(const ValueKey('p-bottom-sheet-close'));
Finder get _sheet => find.byKey(const ValueKey('p-bottom-sheet-root'));

void main() {
  testWidgets('저장 중에는 X · Esc · 뒤로 · 머리 ← 가 닫지 않고 묻지도 않는다 — 실패하면 Callout', (
    tester,
  ) async {
    final pending = Completer<bool>();
    var backs = 0;
    await _open(tester, gate: () => pending, onBack: () => backs++);
    await tester.tap(findText('저장'));
    await tester.pump();
    expect(findText('저장 중'), findsOneWidget);

    // X — 모양은 그대로(흐리게 하지 않는다), 눌러도 아무 일 없음
    final circle = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('p-bottom-sheet-close-circle')),
    );
    expect(circle.decoration, isA<BoxDecoration>());
    expect(
      find.ancestor(of: _close, matching: find.byType(Opacity)),
      findsNothing,
    );
    await tester.tap(_close, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    // 낭독기 누름(시맨틱 탭)은 누름 막기를 지나 바로 온다 — 그 길도 막는다
    tester.widget<GestureDetector>(_close).onTap!.call();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));
    tester
        .widget<GestureDetector>(
          find.byKey(const ValueKey('p-bottom-sheet-back')),
        )
        .onTap!
        .call();
    await tester.pump(const Duration(milliseconds: 400));
    expect(backs, 0, reason: '머리 ← 는 저장 중에 앞 단계로 가지 않는다');
    expect(find.byType(PAlertDialogView), findsNothing);
    expect(_sheet, findsOneWidget);
    expect(findText('본문'), findsOneWidget);

    // 실패 — 시트는 남고 Callout
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(_sheet, findsOneWidget);
    expect(findText('저장하지 못했어요'), findsOneWidget);

    // 저장이 끝나면 닫는 길이 돌아온다 — 바뀐 값이 있으니 묻는다
    await tester.tap(_close);
    await tester.pumpAndSettle();
    expect(find.byType(PAlertDialogView), findsOneWidget);
  });

  testWidgets('저장 중에는 시트 안 누름을 받지 않는다(입력 막기)', (tester) async {
    final pending = Completer<bool>();
    await _open(tester, gate: () => pending);
    final state = tester.state<_FormState>(find.byType(_Form));
    await tester.tap(findText('본문'));
    expect(state.bodyTaps, 1);
    await tester.tap(findText('저장'));
    await tester.pump();
    await tester.tap(findText('본문'), warnIfMissed: false);
    expect(state.bodyTaps, 1);
    pending.complete(false);
    await tester.pumpAndSettle();
    await tester.tap(findText('본문'));
    expect(state.bodyTaps, 2);
  });

  testWidgets('조회 시트도 저장 중에는 바깥 누르기 · 끌어 내리기로 닫히지 않는다', (tester) async {
    final pending = Completer<bool>();
    await _open(tester, gate: () => pending, form: false, dirty: false);
    await tester.tap(findText('저장'));
    await tester.pump();
    // 딤(시트 위 빈 곳)
    await tester.tapAt(const Offset(20, 20));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_sheet, findsOneWidget);
    // 끌어 내리기 — 머리를 잡고 빠르게
    await tester.fling(
      find.byKey(const ValueKey('p-bottom-sheet-title')),
      const Offset(0, 400),
      2000,
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(_sheet, findsOneWidget);
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(_sheet, findsNothing, reason: '성공하면 폼이 close() 로 닫는다');
  });

  testWidgets(
    '바뀐 값을 살피지 않는 시트(isDirty 없음)도 저장 중에는 시스템 뒤로로 닫히지 않는다 — canPop 이 busy 를 본다(검수 L4)',
    (tester) async {
      final pending = Completer<bool>();
      await _open(
        tester,
        gate: () => pending,
        form: false,
        dirty: false,
        probeDirty: false,
      );
      await tester.tap(findText('저장'));
      await tester.pump();
      final route = ModalRoute.of(tester.element(find.byType(_Form)))!;
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
      // 닫히는 동안에도 표면은 잠깐 남으니 라우트가 살아 있는지로 본다
      expect(route.isActive, isTrue, reason: '저장 중 시스템 뒤로는 시트를 내리지 않는다');
      pending.complete(false);
      await tester.pumpAndSettle();
      // 저장이 끝나면 뒤로가 바로 닫는다
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(route.isActive, isFalse);
    },
  );

  testWidgets('두 저장이 겹치면 둘 다 끝나야 풀린다 — busy 는 짝으로 센다(검수 L3)', (tester) async {
    final pending = Completer<bool>();
    await _open(tester, gate: () => pending);
    final controller = PBottomSheet.maybeOf(
      tester.element(find.byType(_Form)),
    )!;
    controller
      ..setBusy(true)
      ..setBusy(true);
    await tester.pump();
    controller.setBusy(false);
    await tester.pump();
    expect(controller.busy, isTrue, reason: '먼저 끝난 쪽이 풀지 않는다');
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PAlertDialogView), findsNothing);
    controller.setBusy(false);
    await tester.pump();
    expect(controller.busy, isFalse);
  });

  group('확인창이 떠 있는 사이에 저장이 성공하면(조사 a-1 경합)', () {
    testWidgets('busy 없이는 close() 가 시트 대신 확인창을 내린다 — 저장은 됐는데 시트가 남는다', (
      tester,
    ) async {
      final pending = Completer<bool>();
      await _open(tester, gate: () => pending, useBusy: false);
      await tester.tap(findText('저장'));
      await tester.pump();
      await tester.tap(_close);
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
      pending.complete(true);
      await tester.pumpAndSettle();
      // 맨 위 라우트(확인창)가 내려가고 시트가 남는다 — 코드 읽기로만 보던 경합을 실행으로 확인
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(_sheet, findsOneWidget);
    });

    testWidgets('busy 면 저장 중에 확인창이 뜨지 않아 경합이 생기지 않는다 — 성공하면 시트가 닫힌다', (
      tester,
    ) async {
      final pending = Completer<bool>();
      await _open(tester, gate: () => pending);
      await tester.tap(findText('저장'));
      await tester.pump();
      await tester.tap(_close, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PAlertDialogView), findsNothing);
      pending.complete(true);
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
      expect(find.byType(PAlertDialogView), findsNothing);
    });
  });
}
