import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 항목 하나에 할 수 있는 일 — 행(스와이프)과 상세 화면이 <b>같은 것</b>을 부른다.
///
/// 예전엔 삭제가 상세 다이얼로그의 State 안에 있었다. 확인 문구를 고르고, 지우고,
/// 관련 provider 를 무효화하고, 실패를 알리는 일이 전부 거기 묶여 있었다. 스와이프에서
/// 같은 삭제를 부르려면 그걸 복사할 수밖에 없고, 복사한 순간 두 경로가 갈라져 한쪽만
/// 고쳐지는 날이 온다 — 무효화를 한 곳에만 추가하면 다른 경로로 지웠을 때 화면이
/// 안 바뀐다.
///
/// 그래서 항목별로 이 인터페이스를 하나 두고 두 경로가 그걸 부른다.
///
/// [T] 는 도메인 모델. 화면이 이미 들고 있는 값을 그대로 넘기므로 다시 조회하지
/// 않는다 — 행에서 부르든 상세에서 부르든 같은 정보가 들어간다.
abstract interface class ItemActions<T> {
  /// 지울 수 있는 항목인가.
  ///
  /// 시스템이 만든 것(매도 실현손익·이체 이자처럼 원본을 지워야 사라지는 것)은
  /// false. 스와이프는 이게 false 면 삭제 액션을 아예 만들지 않는다 — 눌러서
  /// 거부당하는 것보다 없는 편이 낫다.
  bool canDelete(T item);

  /// 고칠 수 있는 항목인가.
  bool canEdit(T item);

  /// 지우기 전에 물을 제목.
  ///
  /// 스와이프와 상세가 <b>같은 것</b>을 부르므로 제목이 갈리지 않는다 — spec
  /// `alert-dialog` 의 "같은 동작이면 어디서 불렀든 제목·설명이 같다". 예전엔
  /// 스와이프가 액션 라벨(`삭제`)을 제목으로 쓰고 상세는 `메모 삭제` 를 써서,
  /// 같은 삭제가 경로에 따라 다른 말로 떴다.
  String deleteConfirmTitle(BuildContext context, T item);

  /// 지우기 전에 물을 말. 항목마다 달라진다(딸린 게 같이 사라지는 경우 등).
  String deleteConfirmMessage(BuildContext context, T item);

  // 삭제는 이 계약에 두지 않는다 — 확인 · 실패 알림 · 뒷정리가 한 덩어리라 각 actions 의 `confirmAndDelete` 가 맡는다
  // (확인창 뒤 실패는 askConfirmThenRequest: critical 스낵바 + [다시 시도]). 실패를 삼키고 false 만 돌려주는 길을 두지 않는다.

  /// 편집 화면을 연다.
  Future<void> edit(BuildContext context, WidgetRef ref, T item);
}
