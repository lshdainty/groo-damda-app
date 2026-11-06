import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 바를 화면 위에 놓은 모양 — 위 안전 영역([top])을 흉내 낸다. 가장자리가 보이게 1px 틀을 두른다(틀은 견본 것).
class _Frame extends StatelessWidget {
  const _Frame({required this.child, this.top = 0});

  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.strokeNeutralSubtle),
        borderRadius: BorderRadius.circular(PRounded.r2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PRounded.r2),
        child: MediaQuery(
          data: media.copyWith(padding: EdgeInsets.only(top: top)),
          child: child,
        ),
      ),
    );
  }
}

/// 켜고 끄는 단추를 눌러 보는 견본 — 금액 가리기(eye ↔ eyeOff).
class _HideAmount extends StatefulWidget {
  const _HideAmount();

  @override
  State<_HideAmount> createState() => _HideAmountState();
}

class _HideAmountState extends State<_HideAmount> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    return PTopNavigation(
      type: PTopNavigationType.root,
      title: '자산',
      actions: [
        PTopNavigationIconButton(
          icon: _hidden ? LucideIcons.eyeOff : LucideIcons.eye,
          selectedIcon: LucideIcons.eyeOff500,
          label: '금액 가리기',
          selected: _hidden,
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
        PTopNavigationIconButton(
          icon: LucideIcons.bell,
          label: '알림, 새 알림 있음',
          notification: true,
          onPressed: () {},
        ),
        PTopNavigationIconButton(
          icon: LucideIcons.settings,
          label: '설정',
          onPressed: () {},
        ),
      ],
    );
  }
}

/// 카탈로그(/dev/ds) — Root(큰 제목 + 검색 · 알림 점) · Standard(← + 제목 + 글 버튼 · ✕ · ☰ · 제목 자리 검색칸), 오른쪽 아이콘 0 ~ 3개 · 글 버튼,
/// 켜고 끄는 단추(금액 가리기 — 눌러 본다), 막힘, 안전 영역(위 47), 가장 나쁜 값(아주 긴 제목 + 아이콘 셋 · 글 버튼, 폰 폭).
/// 누름(상자 바탕 + 2px 축소)은 직접 눌러 본다.
class TopNavigationDemo extends StatelessWidget {
  const TopNavigationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '타입',
          children: [
            _Frame(
              child: PTopNavigation(
                type: PTopNavigationType.root,
                title: '홈',
                actions: [
                  PTopNavigationIconButton(
                    icon: LucideIcons.search,
                    label: '검색',
                    onPressed: noop,
                  ),
                  PTopNavigationIconButton(
                    icon: LucideIcons.bell,
                    label: '알림, 새 알림 있음',
                    notification: true,
                    onPressed: noop,
                  ),
                ],
              ),
            ),
            _Frame(
              child: PTopNavigation(
                title: '알림',
                leading: PTopNavigationIconButton.back(
                  label: '뒤로',
                  onPressed: noop,
                ),
                actions: [
                  PTopNavigationTextButton(label: '모두 읽음', onPressed: noop),
                ],
              ),
            ),
            _Frame(
              child: PTopNavigation(
                title: '카드 가져오기',
                leading: PTopNavigationIconButton.close(
                  label: '닫기',
                  onPressed: noop,
                ),
                actions: [
                  PTopNavigationTextButton(label: '완료', onPressed: noop),
                ],
              ),
            ),
            // 거래 검색 — 제목 자리에 검색칸(상자형 medium 40), 화면 이름 "검색" 은 보이지 않는 머리말
            _Frame(
              child: PTopNavigation.search(
                title: '검색',
                leading: PTopNavigationIconButton.back(
                  label: '뒤로',
                  onPressed: noop,
                ),
                search: const PInput(
                  size: PInputSize.medium,
                  semanticLabel: '거래 검색',
                  placeholder: '거래 검색',
                  prefixIcon: LucideIcons.search,
                  clearable: true,
                ),
                actions: [
                  PTopNavigationIconButton(
                    icon: LucideIcons.slidersHorizontal,
                    label: '고급 필터',
                    onPressed: noop,
                  ),
                ],
              ),
            ),
            _Frame(
              child: PTopNavigation(
                title: '휴가 현황',
                leading: PTopNavigationIconButton.menu(
                  label: '주 메뉴',
                  onPressed: noop,
                ),
              ),
            ),
          ],
        ),
        DemoBlock(
          title: '오른쪽 — 0 · 1 · 2 · 3 개',
          children: [
            for (var n = 0; n <= 3; n++)
              _Frame(
                child: PTopNavigation(
                  title: '가계부',
                  leading: PTopNavigationIconButton.back(
                    label: '뒤로',
                    onPressed: noop,
                  ),
                  actions: [
                    for (final icon in [
                      LucideIcons.search,
                      LucideIcons.funnel,
                      LucideIcons.ellipsis,
                    ].take(n))
                      PTopNavigationIconButton(
                        icon: icon,
                        label: '동작',
                        onPressed: noop,
                      ),
                  ],
                ),
              ),
          ],
        ),
        const DemoBlock(
          title: '켜고 끄는 단추 — 눌러 본다(켬 선 2.5 · 끔 선 2, 색은 같다)',
          children: [_Frame(child: _HideAmount())],
        ),
        DemoBlock(
          title: '막힘 — 아이콘 · 글 fg-disabled',
          children: [
            _Frame(
              child: PTopNavigation(
                title: '내보내기',
                leading: PTopNavigationIconButton.back(
                  label: '뒤로',
                  onPressed: noop,
                ),
                actions: [
                  PTopNavigationIconButton(
                    icon: LucideIcons.share,
                    label: '공유',
                    enabled: false,
                    onPressed: noop,
                  ),
                  PTopNavigationIconButton(
                    icon: LucideIcons.ellipsis,
                    label: '내보내기 더보기',
                    onPressed: noop,
                  ),
                ],
              ),
            ),
            _Frame(
              child: PTopNavigation(
                title: '메모',
                leading: PTopNavigationIconButton.close(
                  label: '닫기',
                  onPressed: noop,
                ),
                actions: [
                  PTopNavigationTextButton(
                    label: '완료',
                    enabled: false,
                    onPressed: noop,
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoBlock(
          title: '안전 영역 — 위 47 만큼 높아지고 바탕은 끝까지',
          children: [
            _Frame(
              top: 47,
              child: PTopNavigation(
                type: PTopNavigationType.root,
                title: '캘린더',
                actions: [
                  PTopNavigationIconButton(
                    icon: LucideIcons.search,
                    label: '검색',
                    onPressed: noop,
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoBlock(
          title: '가장 나쁜 값 — 아주 긴 제목 + 아이콘 셋 · 글 버튼(오른쪽 자리 앞 8 에서 말줄임)',
          children: [
            _Frame(
              child: PTopNavigation(
                title: '카드 혜택 · 이번 달 결제 예정 금액과 실적 조건 한눈에 보기',
                leading: PTopNavigationIconButton.back(
                  label: '뒤로',
                  onPressed: noop,
                ),
                actions: [
                  for (final icon in [
                    LucideIcons.search,
                    LucideIcons.bell,
                    LucideIcons.ellipsis,
                  ])
                    PTopNavigationIconButton(
                      icon: icon,
                      label: '동작',
                      notification: icon == LucideIcons.bell,
                      onPressed: noop,
                    ),
                ],
              ),
            ),
            _Frame(
              child: PTopNavigation(
                type: PTopNavigationType.root,
                title: '가계부 · 이번 달 결제 예정 금액',
                actions: [
                  PTopNavigationTextButton(label: '모두 읽음', onPressed: noop),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
