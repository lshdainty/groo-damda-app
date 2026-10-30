import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';

/// 시트 · 폼 맨 위 저장 실패 알림 — 서버가 낸 글이 아니라 우리 글(고정 문구). 폼은 열려 있고 쓴 값은 그대로다.
/// 서버 원문을 띄우는 전역 오류 알림은 그 요청에서 끈다(스낵바는 시트 뒤 화면에 떠서 가려지고 이 알림과 겹친다).
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
