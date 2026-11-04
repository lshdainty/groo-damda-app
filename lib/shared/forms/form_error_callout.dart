import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';

/// 시트 · 폼 맨 위 저장 실패 알림 — 서버가 낸 글이 아니라 우리 글(고정 문구). 폼은 열려 있고 쓴 값은 그대로다.
///
/// 규칙: **폼 저장 실패 = 맨 위 Callout**(그리고 스크롤해 보이게 — [revealFormError]), **확인창(삭제 · 고정)의 실패 = 확인창을 닫고 critical 스낵바 +
/// [다시 시도]**. 서버 원문을 띄우는 전역 오류 알림은 그 요청에서 끈다. 앱의 스낵바 호스트는 시트 · 확인창 **위**에 뜨지만(길잡이 바깥),
/// 폼 실패는 쓴 값 옆에서 고치는 자리라 Callout 이 맞다.
class FormErrorCallout extends StatelessWidget {
  const FormErrorCallout({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PSpacing.x4),
    child: PCallout(
      tone: PCalloutTone.critical,
      description: message,
      alert: true,
    ),
  );
}

/// 저장 실패 Callout 을 화면 안으로 올린다 — 키보드가 떠 있거나 큰 글자 · 작은 폰에서 본문을 아래로 내린 채 [저장] 을 눌러도 맨 위 Callout 이
/// 화면 밖에 생기지 않게. Callout 을 그린 다음 프레임에 부른다([key] 는 Callout 에 단 키).
void revealFormError(GlobalKey key) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = key.currentContext;
    if (context == null) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 200),
      alignment: 0.1,
    );
  });
}
