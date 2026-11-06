import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 쓰기가 "응답을 읽지 못한" 채 끝났는가([kApiParseErrorCode]) — 2xx 응답을 받은 뒤 풀기에서 난 오류라 서버는 처리했다.
///
/// 이때는 실패라 말하지 않는다(다시 누르면 같은 거래 · 결제가 두 번 생긴다, I-wrap-b2b 검수 M3). 저장 폼은
/// ① 성공 때와 같은 목록을 비우고 ② 맨 위 Callout 을 [saveFailureText] 로 바꾸고 ③ 폼은 닫지 않는다([저장] 은 그대로).
bool isUnconfirmedSave(Object? error) =>
    error is ApiException && error.code == kApiParseErrorCode;

/// 저장 폼 맨 위 Callout 글 — 응답을 읽지 못한 쓰기면 "저장됐는지 확인하지 못했어요. 목록에서 확인해주세요.", 아니면
/// 그 폼의 실패 글([fallback]).
String saveFailureText(AppLocalizations l, Object? error, String fallback) =>
    isUnconfirmedSave(error) ? l.saveUnconfirmed : fallback;
