// Avatar 의 사진 바꾸기 자리(avatar.json edit=photo · 상태 uploading)가 스펙 값대로인지 — 올리는 중 덮개(딤 50% · 65% +
// 값 있는 원 24 staticWhite) · 버튼 줄(아래 16 · 사이 8 · 가운데 · 좁으면 줄 바꿈) · 두 버튼 막힘 · 읽는 말. 웹은 같은 JSON 을
// 크로미움에서 잰다.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('avatar');
const _combo = {'size': '108', 'edit': 'photo'};

Widget _host(Brightness mode, Widget child, {double width = 360}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: Align(alignment: Alignment.topCenter, child: child),
          ),
        ),
      ),
    );

void _noop() {}

final _photo = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
    0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
    0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

PAvatarPhotoEdit _edit({
  ImageProvider? image,
  double? uploadProgress,
  VoidCallback onChange = _noop,
  VoidCallback onRemove = _noop,
  String uploadLabel = '프로필 사진 올리는 중',
}) => PAvatarPhotoEdit(
  name: '한지우',
  image: image,
  uploadProgress: uploadProgress,
  uploadLabel: uploadLabel,
  changeLabel: '사진 바꾸기',
  removeLabel: '사진 지우기',
  onChange: onChange,
  onRemove: onRemove,
);

Finder get _overlay => find.byKey(const ValueKey('avatar-upload'));
Finder get _circle => find.byType(PProgressCircle);

void main() {
  group('스펙 값', () {
    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 올리는 중 덮개는 원 위 딤 + 값 있는 원 24 staticWhite', (
        tester,
      ) async {
        final want = _spec.resolve(_combo, 'uploading');
        await tester.pumpWidget(
          _host(
            mode,
            PAvatar(name: '한지우', size: PAvatarSize.s108, uploadProgress: 0.4),
          ),
        );
        // 딤 — 라이트 rgba(0,0,0,0.50) · 다크 0.65
        final dim = pickMode(want['uploadOverlay.background'], mode)! as String;
        final alpha = double.parse(
          RegExp(r'([\d.]+)\)$').firstMatch(dim)!.group(1)!,
        );
        final color = tester.widget<ColoredBox>(_overlay).color;
        expect(color.a, closeTo(alpha, 0.01), reason: '$mode 딤');
        expect(color.r + color.g + color.b, 0, reason: '검정 딤');
        // 원 모양 · 아바타를 덮는다
        expect(tester.getSize(_overlay), const Size(108, 108));
        expect(want['uploadOverlay.radius'], 9999);
        expect(want['uploadOverlay.display'], '보임');
        // 값 있는 원 24 · staticWhite · 가운데
        final circle = tester.widget<PProgressCircle>(_circle);
        expect(circle.size, PProgressCircleSize.s24);
        expect(circle.tone, PProgressCircleTone.staticWhite);
        expect(want['uploadOverlay.progress'], contains('Progress Circle 24'));
        expect(want['uploadOverlay.progress'], contains('staticWhite'));
        expect(tester.getSize(_circle), const Size(24, 24));
        expect(tester.getCenter(_circle), tester.getCenter(_overlay));
      });

      testWidgets('${mode.name} — 올리지 않을 때는 덮개가 없다(평소 모양 그대로)', (tester) async {
        final want = _spec.resolve(_combo, 'enabled');
        expect(want['uploadOverlay.display'], 'none');
        await tester.pumpWidget(_host(mode, const PAvatar(name: '한지우')));
        expect(_overlay, findsNothing);
        expect(_circle, findsNothing);
      });
    }

    testWidgets('버튼 줄 — 아바타 아래 16 · 사이 8 · 가운데', (tester) async {
      final want = _spec.resolve(_combo, 'enabled');
      expect(want['editActions.marginTop'], 16);
      expect(want['editActions.gap'], 8);
      await tester.pumpWidget(_host(Brightness.light, _edit(image: _photo)));
      final avatar = tester.getRect(find.byType(PAvatar));
      final buttons = find.byType(PButton);
      final change = tester.getRect(buttons.at(0));
      final remove = tester.getRect(buttons.at(1));
      expect(avatar.size, const Size(108, 108));
      expect(change.top - avatar.bottom, want['editActions.marginTop']);
      expect(remove.left - change.right, want['editActions.gap']);
      // 가운데 정렬 — 아바타와 버튼 줄이 같은 가운데
      final row = Rect.fromLTRB(
        change.left,
        change.top,
        remove.right,
        change.bottom,
      );
      expect(avatar.center.dx, closeTo(row.center.dx, 0.5));
      // 마우스 올림에 기대는 덮개가 없다 — 버튼 줄은 늘 보인다
      expect(find.byKey(const ValueKey('avatar-edit-actions')), findsOneWidget);
    });

    testWidgets('좁으면 줄을 바꾼다 — 줄 사이도 8', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _edit(image: _photo), width: 120),
      );
      final buttons = find.byType(PButton);
      final change = tester.getRect(buttons.at(0));
      final remove = tester.getRect(buttons.at(1));
      expect(remove.top, greaterThan(change.bottom - 0.5));
      expect(remove.top - change.bottom, 8);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '"사진 바꾸기" neutralWeak small · "사진 지우기" ghost small — 사진이 있을 때만 지우기',
      (tester) async {
        await tester.pumpWidget(_host(Brightness.light, _edit(image: _photo)));
        final b = tester.widgetList<PButton>(find.byType(PButton)).toList();
        expect(b.map((e) => e.label), ['사진 바꾸기', '사진 지우기']);
        expect(b[0].variant, PButtonVariant.neutralWeak);
        expect(b[1].variant, PButtonVariant.ghost);
        expect(b.every((e) => e.size == PButtonSize.small), isTrue);
        await tester.pumpWidget(_host(Brightness.light, _edit()));
        expect(
          tester.widgetList<PButton>(find.byType(PButton)).map((e) => e.label),
          ['사진 바꾸기'],
        );
      },
    );
  });

  group('동작', () {
    testWidgets('누르면 각 콜백', (tester) async {
      var change = 0;
      var remove = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _edit(
            image: _photo,
            onChange: () => change++,
            onRemove: () => remove++,
          ),
        ),
      );
      await tester.tap(findText('사진 바꾸기'));
      expect(change, 1);
      await tester.tap(findText('사진 지우기'));
      expect(remove, 1);
    });

    testWidgets('올리는 중에는 두 버튼이 막히고 끝나면 풀린다', (tester) async {
      var change = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _edit(image: _photo, uploadProgress: 0.4, onChange: () => change++),
        ),
      );
      expect(
        tester
            .widgetList<PButton>(find.byType(PButton))
            .every((b) => b.onPressed == null),
        isTrue,
      );
      await tester.tap(findText('사진 바꾸기'), warnIfMissed: false);
      expect(change, 0);
      expect(_overlay, findsOneWidget);
      await tester.pumpWidget(_host(Brightness.light, _edit(image: _photo)));
      expect(
        tester
            .widgetList<PButton>(find.byType(PButton))
            .every((b) => b.onPressed != null),
        isTrue,
      );
      expect(_overlay, findsNothing);
    });

    testWidgets('0 ~ 1 밖의 값은 끝에서 멈추고 유한하지 않으면 덮개가 없다', (tester) async {
      Future<double?> shown(double? v) async {
        await tester.pumpWidget(
          _host(Brightness.light, PAvatar(name: '한지우', uploadProgress: v)),
        );
        return _circle.evaluate().isEmpty
            ? null
            : tester.widget<PProgressCircle>(_circle).value;
      }

      expect(await shown(1.7), 100);
      expect(await shown(-1), 0);
      expect(await shown(0.4), closeTo(40, 1e-9));
      expect(await shown(double.nan), isNull);
      expect(await shown(null), isNull);
    });
  });

  group('읽는 말', () {
    testWidgets('진행 원은 이름 "프로필 사진 올리는 중" · 값 "40%" 로 읽는다 — 이름은 바꿔 넘길 수 있다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, _edit(image: _photo, uploadProgress: 0.4)),
      );
      expect(
        tester.getSemantics(_circle),
        matchesSemantics(label: '프로필 사진 올리는 중', value: '40%'),
      );
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _edit(uploadProgress: 0.4, uploadLabel: 'Uploading photo'),
        ),
      );
      expect(
        tester.getSemantics(_circle),
        matchesSemantics(label: 'Uploading photo', value: '40%'),
      );
      handle.dispose();
    });

    testWidgets('올리는 동안은 숨기지 않는다 — 이름이 있으면 이름을 가진 묶음, 장식이어도 진행 원은 읽힌다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PAvatar(name: '한지우', decorative: false, uploadProgress: 0.2),
        ),
      );
      expect(find.bySemanticsLabel('한지우'), findsOneWidget);
      expect(find.bySemanticsLabel('프로필 사진 올리는 중'), findsOneWidget);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PAvatar(name: '한지우', uploadProgress: 0.2),
        ),
      );
      expect(find.bySemanticsLabel('한지우'), findsNothing);
      expect(find.bySemanticsLabel('프로필 사진 올리는 중'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('올리지 않을 때는 이름만 읽는다(사진 바꾸기 자리의 아바타는 늘 이름을 가진다)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(Brightness.light, _edit()));
      expect(find.bySemanticsLabel('한지우'), findsOneWidget);
      expect(find.bySemanticsLabel('프로필 사진 올리는 중'), findsNothing);
      handle.dispose();
    });
  });
}
