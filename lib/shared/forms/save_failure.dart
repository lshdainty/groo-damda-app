import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 쓰기가 "응답을 읽지 못한" 채 끝났는가([kApiParseErrorCode] — 2xx 응답을 받은 뒤 풀기에서 난 오류라 서버는 처리했다) ·
/// "응답을 받지 못한" 채 끝났는가([kApiNoResponseCode] — 요청은 나갔는데 응답 전에 끊겨 서버가 처리했을 수 있다).
///
/// 이때는 실패라 말하지 않는다(다시 누르면 같은 거래 · 결제가 두 번 생긴다, I-wrap-b2b 검수 M3). 저장 폼은
/// ① 성공 때와 같은 목록을 비우고 ② 맨 위 Callout 을 [saveFailureText] 로 바꾸고 ③ 폼은 닫지 않는다([저장] 은 그대로).
bool isUnconfirmedSave(Object? error) =>
    error is ApiException &&
    (error.code == kApiParseErrorCode || error.code == kApiNoResponseCode);

/// 저장 폼 맨 위 Callout 글 — 응답을 읽지 못한 쓰기면 "저장됐는지 확인하지 못했어요. 목록에서 확인해주세요.", 아니면
/// 그 폼의 실패 글([fallback]).
String saveFailureText(AppLocalizations l, Object? error, String fallback) =>
    isUnconfirmedSave(error) ? l.saveUnconfirmed : fallback;

/// 쓰기의 종류 — 응답을 못 받았을 때 스낵바 한 문장을 고른다([unconfirmedWriteText]).
///
/// 확인창 뒤 쓰기([askConfirmThenRequest])는 종류를 **반드시** 준다 — 기본 글을 두지 않는다. 기본 글이 "저장" 이던 동안
/// 삭제 · 기기 로그아웃에도 "저장됐는지" 가 나갔다(I-wrap-b2b 디자인시스템 판단 ①). 결제 · 해지는 자기 글이 따로 있다.
enum WriteKind {
  /// 저장 · 추가 · 바꾸기 — "저장됐는지 확인하지 못했어요."
  save,

  /// 삭제 · 빼기 — "삭제됐는지 확인하지 못했어요."
  delete,

  /// 그 밖(기기 로그아웃 · 캘린더 나가기 · 모두 받음 · 구독 해지 …) — "처리됐는지 확인하지 못했어요."
  process,
}

/// 응답을 못 받은 쓰기의 스낵바 글 — 한 문장. 목록은 저절로 다시 받으므로 "목록에서 확인해주세요" 를 붙이지 않는다
/// (스낵바는 한 문장 규칙, 폼 Callout 의 [saveFailureText] 는 두 문장 그대로).
String unconfirmedWriteText(AppLocalizations l, WriteKind kind) =>
    switch (kind) {
      WriteKind.save => l.unconfirmedSave,
      WriteKind.delete => l.unconfirmedDelete,
      WriteKind.process => l.unconfirmedProcess,
    };

/// 쓰기 한 번의 결과 — 누르는 순간 바뀌는 값(토글)이 실패를 가를 때 쓴다.
///
/// - [done] — 서버가 받았다
/// - [failed] — 서버에 닿지 않았거나 거절했다. 되돌리고 실패 글(다시 시도 없음)
/// - [unconfirmed] — 응답을 못 받았다([isUnconfirmedSave]). **되돌리지 않고** 서버 값을 다시 받아 맞춘 뒤
///   "바뀌었는지 확인하지 못했어요." 한 문장(I-wrap-b2b 디자인시스템 판단 ②)
enum WriteOutcome { done, failed, unconfirmed }

/// 던진 오류를 [WriteOutcome] 으로 — 응답을 못 받았으면 [WriteOutcome.unconfirmed], 아니면 [WriteOutcome.failed].
WriteOutcome writeOutcomeOf(Object? error) =>
    isUnconfirmedSave(error) ? WriteOutcome.unconfirmed : WriteOutcome.failed;
