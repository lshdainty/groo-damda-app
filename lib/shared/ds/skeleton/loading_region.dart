import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

/// 화면의 loading 분기에서 스켈레톤을 [PLoadingRegion] 으로 감싸는 한 줄 — 호출처는
/// `loading: () => loadingRegion(const _Skeleton())` 처럼 바꾼다.
///
/// 0 ~ 1초는 스켈레톤을 보이지 않게 그려 높이만 지키고(틀만), 1초부터 스켈레톤, 5초부터 오래 걸림 글이 스켈레톤 위에
/// 붙는다. 앱 맨 위의 [PLoadingAnnouncer] 가 1초 "불러오는 중…" · 5초 "평소보다 오래 걸리고 있어요." 를 보조 기술에
/// 한 번씩 읽는다. 내용이 오면 이 위젯이 트리에서 빠지므로 기다림이 끝난 것으로 알려진다(announcer 가 처음부터 다시 센다).
///
/// 한 화면에 기다리는 영역(쿼리)이 여럿이면 영역마다 한 번씩 감싼다 — 읽는 글은 announcer 가 한 번만 읽는다.
///
/// 폭이 정해진 자리(Column · ListView 안)에서 쓴다 — 기다리는 영역은 폭을 채우고 스켈레톤은 왼쪽 맞춤으로 제 폭을 지킨다.
Widget loadingRegion(Widget skeleton, {bool slowText = false}) =>
    PLoadingRegion(
      pending: true,
      showSlowText: slowText,
      // 영역의 틀은 폭을 채우되 스켈레톤은 제 폭 그대로(고정 폭 조각이 늘어나지 않게) 왼쪽에 놓는다
      fallback: Align(
        alignment: AlignmentDirectional.topStart,
        child: skeleton,
      ),
      child: const SizedBox.shrink(),
    );

/// 구조를 미리 그릴 수 없는 화면 · 시트 · 카드 전체 — 스켈레톤 대신 가운데 Progress Circle(40).
Widget loadingRegionCircle() =>
    const PLoadingRegion.circle(pending: true, child: SizedBox.shrink());

/// 주요 화면(홈 · 가계부 · 자산 · 통계 · 예산 · 캘린더)의 기다리는 영역 — 5초에 화면에도 "평소보다 오래 걸리고 있어요." 를
/// 더한다. 나머지 화면은 [loadingRegion](보조 기술 알림만, 화면 글은 B6 에서 정한다).
Widget loadingRegionWithText(Widget skeleton) =>
    loadingRegion(skeleton, slowText: true);

/// 값 조각(줄 끝 · 달력 칸 안 · 글 옆 숫자 자리) — 폭이 정해지지 않은 Row 에서도 선다. 0~1초 보이지 않고, 알림 · 5초 글은 없다.
Widget loadingInline(Widget skeleton) =>
    PLoadingRegion.inline(fallback: skeleton);
