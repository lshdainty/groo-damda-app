import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/core/format/date.dart';

/// 서버 `[UTC]` 시각을 로컬로 옮기는 규칙.
///
/// 이게 틀리면 "마지막 사용 3분 전" 이 "9시간 전" 으로 보인다 — 화면이 멀쩡해 보여서
/// 눈으로는 못 잡는 종류의 오차라 테스트로 못 박는다.
void main() {
  test('시간대 표시가 없는 값은 UTC 로 읽는다', () {
    final dt = parseServerUtc('2026-08-24T10:30:00');
    // toLocal() 결과는 기기 시간대에 따라 다르므로, UTC 로 되돌려 비교한다.
    expect(dt!.toUtc(), DateTime.utc(2026, 8, 24, 10, 30));
  });

  test('Z 가 붙어 오면 그대로 존중한다 — 두 번 보정하지 않는다', () {
    expect(
      parseServerUtc('2026-08-24T10:30:00Z')!.toUtc(),
      DateTime.utc(2026, 8, 24, 10, 30),
    );
  });

  test('오프셋이 붙어 오면 그대로 존중한다', () {
    expect(
      parseServerUtc('2026-08-24T19:30:00+09:00')!.toUtc(),
      DateTime.utc(2026, 8, 24, 10, 30),
    );
  });

  test('밀리초가 붙어도 읽는다', () {
    expect(
      parseServerUtc('2026-08-24T10:30:00.123')!.toUtc(),
      DateTime.utc(2026, 8, 24, 10, 30, 0, 123),
    );
  });

  test('없거나 못 읽는 값은 null — 화면이 시각을 빼고 그린다', () {
    expect(parseServerUtc(null), isNull);
    expect(parseServerUtc(''), isNull);
    expect(parseServerUtc('알 수 없음'), isNull);
  });

  group('날짜만 있는 값(LocalDate)은 대상이 아니다', () {
    // 리뷰에서 앱↔웹이 갈린 자리다. 입력 '2026-08-24' 에 대해 Dart 는 '2026-08-24Z' 를
    // 거부해 null 을 내고, V8 은 받아들여 자정 UTC 로 읽는다. 값이 갈리는 것도 문제지만
    // 웹 쪽 결과가 더 위험하다 — KST(+9)에서는 09:00 이 되어 날짜가 그대로라 개발
    // 기기에서는 멀쩡해 보이고, UTC 뒤쪽 시간대(-05:00)에서만 하루 앞으로 밀린다.
    //
    // 그래서 **거부(null)** 로 계약을 닫았다. 벽시계 날짜(expenseDate·transferDate·
    // 캘린더 startDate)는 시간대가 없는 값이라 애초에 변환 대상이 아니고, null 은
    // 호출부가 이미 갖고 있는 폴백 경로로 눈에 띄게 떨어진다.

    test('YYYY-MM-DD 는 null — 자정 UTC 로 읽어 하루 밀리는 걸 막는다', () {
      expect(parseServerUtc('2026-08-24'), isNull);
    });

    test('구분자 없는 YYYYMMDD 도 null', () {
      expect(parseServerUtc('20260824'), isNull);
    });

    test('파생 함수도 같이 닫힌다 — 조용히 다른 날짜를 내지 않는다', () {
      expect(localDateKey('2026-08-24'), isNull);
      expect(localDateTime('2026-08-24'), isNull);
      expect(formatMemoStamp('2026-08-24'), '');
    });

    test('시각이 붙으면 그대로 받는다 — 자정도 날짜만 있는 값이 아니다', () {
      expect(
        parseServerUtc('2026-08-24T00:00:00')!.toUtc(),
        DateTime.utc(2026, 8, 24),
      );
      // 공백 구분자(Dart `DateTime.parse` 허용 형태)도 시각이 있으면 통과한다.
      expect(
        parseServerUtc('2026-08-24 10:30:00')!.toUtc(),
        DateTime.utc(2026, 8, 24, 10, 30),
      );
    });
  });

  group('localDateKey — 로컬 yyyy-MM-dd 집계 키', () {
    // TZ=Asia/Seoul 로 돌 때만 의미가 있는 케이스는 따로 표시한다. 그 외 기기에서도
    // 깨지지 않도록 "UTC 로 읽었다면 나와야 할 로컬 날짜" 와 맞춘다.
    String expected(DateTime utc) {
      final d = utc.toLocal();
      String p2(int n) => n.toString().padLeft(2, '0');
      return '${d.year.toString().padLeft(4, '0')}-${p2(d.month)}-${p2(d.day)}';
    }

    test('시간대 표시가 없는 값은 UTC 로 읽어 로컬 날짜로 조립한다', () {
      expect(
        localDateKey('2026-08-24T10:30:00'),
        expected(DateTime.utc(2026, 8, 24, 10, 30)),
      );
    });

    test('UTC 오후 늦은 시각은 로컬에서 다음 날 — 잘라 쓰면 하루 앞이 나온다', () {
      // KST(+9) 기준 2026-08-25 00:30. substring(0, 10) 은 '2026-08-24' 를 준다.
      expect(
        localDateKey('2026-08-24T15:30:00'),
        expected(DateTime.utc(2026, 8, 24, 15, 30)),
      );
      // 기기가 KST 면 실제로 하루 넘어간 값이어야 한다.
      if (DateTime.utc(2026, 8, 24, 15, 30).toLocal().day == 25) {
        expect(localDateKey('2026-08-24T15:30:00'), '2026-08-25');
      }
    });

    test('UTC 새벽은 로컬에서 같은 날 — 두 값이 갈리지 않는다', () {
      expect(
        localDateKey('2026-08-24T00:30:00'),
        expected(DateTime.utc(2026, 8, 24, 0, 30)),
      );
    });

    test('연말 자정 근처는 해까지 넘어간다', () {
      expect(
        localDateKey('2026-12-31T15:30:00'),
        expected(DateTime.utc(2026, 12, 31, 15, 30)),
      );
    });

    test('Z 가 붙은 값과 안 붙은 값이 같은 키로 나온다 — 낙관적 갱신과 재조회가 안 갈린다', () {
      expect(
        localDateKey('2026-08-24T15:30:00'),
        localDateKey('2026-08-24T15:30:00Z'),
      );
    });

    test('오프셋이 붙어 오면 그대로 존중한다', () {
      expect(
        localDateKey('2026-08-25T00:30:00+09:00'),
        expected(DateTime.utc(2026, 8, 24, 15, 30)),
      );
    });

    test('없거나 못 읽는 값은 null — 호출부가 폴백을 고른다', () {
      expect(localDateKey(null), isNull);
      expect(localDateKey(''), isNull);
      expect(localDateKey('알 수 없음'), isNull);
    });
  });

  group('localDateTime — 로컬 yyyy-MM-dd HH:mm', () {
    String expected(DateTime utc) {
      final d = utc.toLocal();
      String p2(int n) => n.toString().padLeft(2, '0');
      return '${d.year.toString().padLeft(4, '0')}-${p2(d.month)}-${p2(d.day)}'
          ' ${p2(d.hour)}:${p2(d.minute)}';
    }

    test('UTC 를 로컬 날짜·시각으로 찍는다', () {
      expect(
        localDateTime('2026-08-24T15:30:00'),
        expected(DateTime.utc(2026, 8, 24, 15, 30)),
      );
    });

    test('날짜 부분은 localDateKey 와 같다', () {
      expect(
        localDateTime('2026-08-24T15:30:00')!.substring(0, 10),
        localDateKey('2026-08-24T15:30:00'),
      );
    });

    test('없거나 못 읽는 값은 null', () {
      expect(localDateTime(null), isNull);
      expect(localDateTime('알 수 없음'), isNull);
    });
  });

  group('toServerUtc — parseServerUtc 의 역변환', () {
    test('왕복해도 같은 시각 — 오프셋 없는 문자열로 나가 +9 씩 밀리던 버그', () {
      const raw = '2026-08-24T15:30:00';
      final once = toServerUtc(parseServerUtc(raw));
      final twice = toServerUtc(parseServerUtc(once));
      expect(parseServerUtc(once)!.toUtc(), DateTime.utc(2026, 8, 24, 15, 30));
      expect(twice, once);
    });

    test('UTC 표시가 붙어 나간다 — 받는 쪽이 로컬로 오해할 수 없다', () {
      expect(toServerUtc(parseServerUtc('2026-08-24T15:30:00')), endsWith('Z'));
    });

    test('null 은 null', () {
      expect(toServerUtc(null), isNull);
    });
  });

  group(
    'formatMemoStamp — 메모 수정 시각 (올해 "10월 22일 오후 5:10" · 다른 해 "2025년 12월 3일")',
    () {
      // 테스트가 도는 기기 시간대를 모르므로(로컬 CI 는 KST, GitHub 러너는 UTC)
      // 기대값을 문자열로 못 박지 않고 "UTC 로 읽었다면 나와야 할 로컬 시각" 과 맞춘다.
      String sameYear(DateTime utc) {
        final d = utc.toLocal();
        final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
        final ap = d.hour < 12 ? '오전' : '오후';
        final mm = d.minute.toString().padLeft(2, '0');
        return '${d.month}월 ${d.day}일 $ap $h12:$mm';
      }

      test('올해는 줄임 날짜 + 시각 — UTC 로 읽어 로컬로 찍는다', () {
        final utc = DateTime.utc(2026, 8, 24, 10, 30);
        expect(
          formatMemoStamp('2026-08-24T10:30:00', now: utc.toLocal()),
          sameYear(utc),
        );
      });

      test('다른 해는 시각 없이 표준 날짜', () {
        final d = DateTime.utc(2025, 12, 3, 3, 0).toLocal();
        expect(
          formatMemoStamp('2025-12-03T03:00:00', now: DateTime(2026, 6, 1)),
          '${d.year}년 ${d.month}월 ${d.day}일',
        );
      });

      test('자정 근처는 날짜까지 넘어간다 — 잘라 쓰던 시절의 하루 오차', () {
        // KST 라면 09-01 06:00 — 잘라 쓰던 시절엔 08/31 21:00 으로 하루 앞이 찍혔다.
        final utc = DateTime.utc(2026, 8, 31, 21, 0);
        expect(
          formatMemoStamp('2026-08-31T21:00:00', now: utc.toLocal()),
          sameYear(utc),
        );
      });

      test('Z 가 붙은 값과 안 붙은 값이 같은 시각으로 나온다', () {
        final now = DateTime.utc(2026, 8, 24).toLocal();
        expect(
          formatMemoStamp('2026-08-24T10:30:00', now: now),
          formatMemoStamp('2026-08-24T10:30:00Z', now: now),
        );
      });

      test('없거나 못 읽는 값은 빈 문자열 — 메타 줄이 빈 조각을 뺀다', () {
        expect(formatMemoStamp(null), '');
        expect(formatMemoStamp(''), '');
        expect(formatMemoStamp('알 수 없음'), '');
        expect(formatMemoStamp('2026-08-24'), '');
      });
    },
  );
}
