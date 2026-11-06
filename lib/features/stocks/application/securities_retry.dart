/// 증권 조회의 재시도 정책 — 실패해도 다시 조르지 않는다.
library;

import 'package:flutter_riverpod/misc.dart' show ProviderBase;

/// 실패한 증권 조회를 자동으로 다시 치지 않는다. 다음 조회는 화면이 정한 주기에 맡긴다.
///
/// riverpod 3 은 실패한 provider 를 기본으로 최대 10번(0.2초부터 두 배씩, 6.4초 상한 —
/// 모두 합쳐 약 38초) 다시 만든다. 증권사가 429(유량 초과)로 거절했을 때 그러면 한도를
/// 넘긴 바로 그 순간에 열 번을 더 친다. 웹은 증권 조회를 전부 `retry: false` 로 두고
/// 정해진 주기로만 다시 받는다 — 앱도 같게 한다.
///
/// **주기적으로 다시 받는 조회에만 단다.** 재시도를 끄면 실패한 조회를 되살리는 것은 다음
/// 주기뿐이다. 주기 없이 한 번 읽고 끝나는 조회에 달면 한 번의 실패로 값이 영영 빈다.
///
/// 폴링 표식이기도 하다 — 이 재시도를 단 조회(와 그 값을 받아 만드는 조회)가 받아 둔 값이 있는 채 실패해도 공용 스낵바
/// "새로 고치지 못했어요." 를 띄우지 않는다(`app/query_failure` — 폴링은 그 자리가 알린다, I-wrap-b2b 2-1 · 4). 웹은 같은
/// 뜻을 useQuery meta 로 단다.
Duration? securitiesNoRetry(int retryCount, Object error) => null;

/// 폴링 조회인가 — [securitiesNoRetry] 를 단 provider 또는 그 family 의 한 칸.
bool isPollingProvider(ProviderBase<Object?> provider) =>
    identical(provider.retry, securitiesNoRetry) ||
    identical(provider.from?.retry, securitiesNoRetry);
