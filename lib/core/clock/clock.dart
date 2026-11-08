import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 화면이 "오늘 · 지금" 을 계산할 때 읽는 시계 하나.
///
/// 화면 안에서 `DateTime.now()` 를 직접 부르면 시험 · 렌더 하네스가 오늘을 고정할 수 없고,
/// 고정한 오늘과 벽시계가 섞이면 다음 날부터 조용히 깨진다. 화면은 `ref.read(clockProvider)()` 로
/// 읽고, 시험은 `clockProvider.overrideWithValue(() => fixed)` 로 고정한다.
///
/// 앱의 기본값은 늘 [DateTime.now] 라 사용자에게 보이는 동작은 같다.
/// 벽시계가 맞는 자리(요청 시작 시각 · 파일 이름 · 인증번호 재전송 대기)는 이것을 쓰지 않는다.
///
/// 이 시계 위에 얹힌 것: `nowTickProvider`(주기 갱신 — 같은 시계를 눈금으로 내림).
/// 따로 남긴 것: `calendarNow`(상태 없는 도메인 함수가 읽는 정적 이음매) ·
/// `stocksNow`(증권 시간대 계산용 정적 이음매) — `ref` 가 없는 자리라 provider 로 못 바꾼다.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
