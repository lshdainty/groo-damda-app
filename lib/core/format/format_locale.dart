import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';

import 'package:groo_damda_app/core/settings/user_locale.dart';

/// 숫자·통화·날짜 포맷터가 참조하는 "현재 유효 로케일이 영어인지" 판정.
///
/// 앱이 설정 로케일을 [Intl.defaultLocale] 에 배선(`SettingsNotifier`)하므로 그걸
/// 1순위로 읽고, 아직 배선 전이면 [UserLocale.current](사용자 명시 선택)로 폴백한다.
/// 시스템 로케일을 따를 때도 화면이 실제로 고른 로케일을 [syncIntlLocale] 이 배선한다 — 시스템이 영어인데 글만 영어이고
/// 돈 · 날짜는 한국어("Annual fee 1,234,567원")로 나오던 것을 막는다(DESIGN.md 숫자 · 돈: 영어 = ₩1,234,567).
bool localeIsEn() =>
    (Intl.defaultLocale ?? UserLocale.current?.languageCode) == 'en';

/// 화면이 쓰는 로케일(`Localizations.localeOf`)을 숫자·날짜 포맷터의 전역 로케일에 맞춘다. 앱 위쪽(`MaterialApp.builder`)에서
/// 부른다. 사용자가 고른 로케일이든 시스템을 따르든, 글이 영어면 돈 · 날짜도 영어다. 지원하지 않는 언어는 ko.
void syncIntlLocale(Locale effective) {
  Intl.defaultLocale = effective.languageCode == 'en' ? 'en' : 'ko';
}
