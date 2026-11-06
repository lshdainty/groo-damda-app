// 응답 없음 스낵바 다섯 글(저장 · 삭제 · 처리 · 바뀜 · 연결)은 웹과 글자까지 같다 — 기준은 웹
// groo-damda-front i18n/translations.csv 의 query.unconfirmed{Save,Delete,Action,Toggle,Connect}(I-wrap-b2b 판단 ① ② ⑤).
// 앱 키 이름은 앱 규칙(웹 Action = 앱 Process). 한쪽만 고치면 이 시험이 깨진다.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

void main() {
  test('ko — 웹 CSV 와 같은 글 · 한 문장', () async {
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(unconfirmedWriteText(l, WriteKind.save), '저장됐는지 확인하지 못했어요.');
    expect(unconfirmedWriteText(l, WriteKind.delete), '삭제됐는지 확인하지 못했어요.');
    expect(unconfirmedWriteText(l, WriteKind.process), '처리됐는지 확인하지 못했어요.');
    expect(l.unconfirmedToggle, '바뀌었는지 확인하지 못했어요.');
    expect(l.unconfirmedConnect, '연결됐는지 확인하지 못했어요.');
  });

  test('en — 웹 CSV 와 같은 글', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      unconfirmedWriteText(l, WriteKind.save),
      "We couldn't confirm it was saved.",
    );
    expect(
      unconfirmedWriteText(l, WriteKind.delete),
      "We couldn't confirm it was deleted.",
    );
    expect(
      unconfirmedWriteText(l, WriteKind.process),
      "We couldn't confirm it went through.",
    );
    expect(l.unconfirmedToggle, "We couldn't confirm it changed.");
    expect(l.unconfirmedConnect, "We couldn't confirm the connection.");
  });
}
