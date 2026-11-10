import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/accordion/p_accordion.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 카탈로그(/dev/ds) — 글 카드(머리 + 본문) · 목록 카드 · 아코디언 카드 · 누름 셋(none · whole · peers) · 지표(large · small ·
/// 증감 셋 · 가장 나쁜 값) · 순자산(hero) · 기다림 · 실패. 웹 견본과 같은 구성이다. 카드는 늘 회색 바닥 위에 둔다 — 폰은 카드 사이 8.
/// 아코디언 카드는 진짜 [PAccordion] 을 담는다. 눌러 보는 견본은 손가락으로 누른다(멈춘 누름은
/// previewPressed).
class CardDemo extends StatelessWidget {
  const CardDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TextCardDemo(),
        _ListCardDemo(),
        _PressDemo(),
        _StatDemo(),
        _HeroDemo(),
        _WaitFailDemo(),
      ],
    );
  }
}

void _noop() {}

/// 회색 바닥 — 카드는 늘 바닥(bg-layer-basement) 위에 둔다. 폭은 폰 폭 칸 · 더 좁으면 있는 폭만큼.
class _Floor extends StatelessWidget {
  const _Floor({required this.children, this.width = double.infinity});

  final List<Widget> children;
  final double width;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: math.min(width, constraints.maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.bgLayerBasement,
          borderRadius: BorderRadius.circular(PRounded.r3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(PSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: PSpacing.x2,
            children: children,
          ),
        ),
      ),
    ),
  );
}

Widget _body(String text) => Text(text);

Widget _rows(BuildContext context) {
  final c = context.colors;
  Widget amount(String t) => Text(
    t,
    style: TextStyle(fontWeight: FontWeight.w700, color: c.fgNeutral),
  );
  return PList(
    semanticLabel: '오늘 쓴 돈',
    children: [
      PListButtonItem(
        prefix: PListTile(
          background: c.chartBlueWeak,
          color: c.chartBlue,
          child: const Icon(LucideIcons.utensils),
        ),
        title: '점심 — 아주 긴 가게 이름이 두 줄까지 이어질 때 줄이 어떻게 보이는지',
        detail: '식비 · 신한카드',
        suffix: amount('-12,000원'),
        onTap: _noop,
      ),
      PListItem(
        prefix: PListTile(
          background: c.chartOrangeWeak,
          color: c.chartOrange,
          child: const Icon(LucideIcons.coffee),
        ),
        title: '스타벅스 강남점',
        suffix: amount('-5,500원'),
      ),
    ],
  );
}

// ── 글 카드 ──────────────────────────────────────────────────

class _TextCardDemo extends StatelessWidget {
  const _TextCardDemo();

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title: '글 카드 — 머리(제목 16 · 700 + 전체 보기, 보이는 32 · 누르는 44) + 본문(여백 24)',
      children: [
        DemoRow(
          label: 'default',
          children: [
            _Floor(
              children: [
                PCard(
                  children: [
                    const PCardHeader(
                      title: '이번 달 예산',
                      actionLabel: '전체 보기',
                      onAction: _noop,
                    ),
                    PCardContent(
                      children: [_body('식비 320,000원 중 184,000원을 썼어요.')],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        DemoRow(
          label: '긴 제목',
          children: [
            _Floor(
              width: 300,
              children: [
                PCard(
                  children: [
                    const PCardHeader(
                      title: '아주 긴 카드 제목이 한 줄을 넘어가는 경우의 모습',
                      actionLabel: '관리',
                      onAction: _noop,
                    ),
                    PCardContent(
                      children: [_body('제목이 길어도 머리 동작은 줄어들지 않고 제목이 줄을 바꾼다.')],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── 목록 · 아코디언 카드 ───────────────────────────────────────

class _ListCardDemo extends StatelessWidget {
  const _ListCardDemo();

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title:
          '목록 카드(body=list) — 줄이 가장자리까지 · 머리 위 24 · 아래 4 · 카드 아래 12 / 아코디언 카드(body=accordion) — 카드 아래 8',
      children: [
        DemoRow(
          label: 'list',
          children: [
            _Floor(
              children: [
                PCard(
                  body: PCardBody.list,
                  children: [
                    const PCardHeader(
                      title: '오늘 쓴 돈',
                      actionLabel: '전체 보기',
                      onAction: _noop,
                    ),
                    _rows(context),
                  ],
                ),
              ],
            ),
            _Floor(
              children: [
                PCard(body: PCardBody.list, children: [_rows(context)]),
              ],
            ),
          ],
        ),
        DemoRow(
          label: 'accordion',
          children: [
            _Floor(
              children: [
                PCard(
                  body: PCardBody.accordion,
                  children: [
                    const PCardHeader(title: '혜택 · 12건'),
                    // 트리거가 카드 가장자리까지 간다 — 제 좌우 24 · 위아래 16 을 가진다
                    PAccordion(
                      children: [
                        PAccordionItem(
                          value: 'fuel',
                          title: '주유 할인',
                          description: '리터당 60원 청구 할인',
                          child: Text(keepAll('주유소 · 충전소에서 월 2회까지 받아요.')),
                        ),
                        PAccordionItem(
                          value: 'coffee',
                          title: '커피 할인',
                          child: Text(keepAll('월 3회 · 건당 최대 3,000원까지 받아요.')),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── 누름 ─────────────────────────────────────────────────────

class _PressDemo extends StatelessWidget {
  const _PressDemo();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget whole(String state, {bool preview = false}) => _Floor(
      width: 220,
      children: [
        PCard(
          onTap: _noop,
          previewPressed: preview,
          children: [
            PCardContent(
              children: [
                Text(
                  '식비 예산',
                  style: PTypography.t5.copyWith(fontWeight: FontWeight.w700),
                ),
                _body(state),
              ],
            ),
          ],
        ),
      ],
    );
    return DemoBlock(
      title: '누름 — whole(카드 전체가 한 곳: 색 + 2px) · peers(대등한 동작이 있어 색만)',
      children: [
        DemoRow(
          label: 'none',
          children: [
            _Floor(
              width: 300,
              children: [
                PCard(
                  children: [
                    PCardContent(children: [_body('보기만 하는 카드')]),
                  ],
                ),
              ],
            ),
          ],
        ),
        DemoRow(
          label: 'whole — enabled · pressed(멈춤)',
          children: [whole('enabled'), whole('pressed', preview: true)],
        ),
        DemoRow(
          label: 'peers — enabled · pressed(멈춤)',
          children: [
            for (final pressed in [false, true])
              _Floor(
                width: 220,
                children: [
                  PCard(
                    press: PCardPress.peers,
                    onTap: _noop,
                    semanticLabel: '장보기 메모',
                    previewPressed: pressed,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '장보기 메모',
                              style: PTypography.t5.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _noop,
                            behavior: HitTestBehavior.opaque,
                            child: Semantics(
                              button: true,
                              label: '장보기 메모 고정',
                              excludeSemantics: true,
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  LucideIcons.star,
                                  size: 20,
                                  color: c.fgNeutralSubtle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _body(pressed ? 'pressed' : 'enabled'),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

// ── 지표 ─────────────────────────────────────────────────────

class _StatDemo extends StatelessWidget {
  const _StatDemo();

  Widget _card(PCardStat stat) => _Floor(
    children: [
      PCard(children: [stat]),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title:
          '지표 카드 — 폰은 한 줄에 하나(large 24 / 32), small 20 / 27 · 증감은 방향(▲ 빨강 · ▼ 파랑 · 변화 없음)',
      children: [
        DemoRow(
          label: 'large — ▲ · ▼ · 변화 없음',
          children: [
            _card(
              const PCardStat(
                label: '이번 달 지출',
                value: '1,240,000원',
                delta: PDelta(
                  direction: PDeltaDirection.up,
                  value: '+12.34%',
                  text: '지난달보다',
                  srText: '지난달보다 12.34% 더 썼어요',
                ),
              ),
            ),
            _card(
              const PCardStat(
                label: '이번 달 수입',
                value: '4,200,000원',
                delta: PDelta(
                  direction: PDeltaDirection.down,
                  value: '−3.00%',
                  text: '지난달보다',
                ),
              ),
            ),
            _card(
              const PCardStat(
                label: '이번 달 저축',
                value: '500,000원',
                delta: PDelta(direction: PDeltaDirection.flat, text: '지난달보다'),
              ),
            ),
          ],
        ),
        DemoRow(
          label: 'small',
          children: [
            _Floor(
              width: 200,
              children: [
                PCard(
                  children: [
                    const PCardStat(
                      size: PCardStatSize.small,
                      label: '이번 달 지출',
                      value: '1,240,000원',
                      delta: PDelta(
                        direction: PDeltaDirection.up,
                        value: '12.34%',
                        text: '지난달보다',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        DemoRow(
          label: '가장 나쁜 값 — 긴 라벨 · −123,456,789,012원 · 부호 겹침',
          children: [
            _Floor(
              width: 300,
              children: [
                PCard(
                  children: [
                    const PCardStat(
                      label: '이번 달 지출 — 이름이 아주 긴 지표 라벨',
                      value: '−123,456,789,012원',
                      delta: PDelta(
                        direction: PDeltaDirection.up,
                        value: '+-12.50%',
                        text: '지난달보다 훨씬 많이',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _Floor(
              width: 300,
              children: [
                PCard(
                  children: [const PCardStat(label: '이번 달 지출', value: '0원')],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── 순자산 ───────────────────────────────────────────────────

class _HeroDemo extends StatelessWidget {
  const _HeroDemo();

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title: '순자산 카드(hero) — 브랜드 채움 · 흰 글자, 다크도 짙은 채움 · 누르면 2px 축소만',
      children: [
        DemoRow(
          label: 'hero',
          children: [
            _Floor(
              children: [
                const PCard(
                  variant: PCardVariant.hero,
                  children: [
                    PCardHeroLabel('순자산'),
                    PCardHeroAmount('42,898,100원'),
                    PCardHeroDetail(text: '자산 80,000,000원 · 부채 37,101,900원'),
                  ],
                ),
              ],
            ),
            // 증감은 흰 글자(순자산 카드의 예외)
            _Floor(
              children: [
                const PCard(
                  variant: PCardVariant.hero,
                  children: [
                    PCardHeroLabel('순자산'),
                    PCardHeroAmount('42,898,100원'),
                    PCardHeroDetail(
                      child: PDelta(
                        direction: PDeltaDirection.up,
                        value: '1.80%',
                        text: '지난달보다',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _Floor(
              children: [
                PCard(
                  variant: PCardVariant.hero,
                  onTap: _noop,
                  previewPressed: true,
                  children: const [
                    PCardHeroLabel('순자산 — pressed'),
                    PCardHeroAmount('−123,456,789,012원'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── 기다림 · 실패 ────────────────────────────────────────────

class _WaitFailDemo extends StatelessWidget {
  const _WaitFailDemo();

  @override
  Widget build(BuildContext context) {
    return DemoBlock(
      title:
          '기다림 · 실패 — 틀은 처음부터, 서버에서 올 자리만 Skeleton · 데이터 하나가 실패하면 그 카드 안 Result Section',
      children: [
        DemoRow(
          label: '기다림',
          children: [
            _Floor(
              children: [
                PCard(
                  children: [
                    const PCardHeader(title: '이번 달 예산'),
                    PCardContent(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 0.75,
                            child: PSkeleton.text(PTypography.t4),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 0.5,
                            child: PSkeleton.text(PTypography.t4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        DemoRow(
          label: '실패 · 비어 있음',
          children: [
            _Floor(
              children: [
                PCard(
                  children: [
                    const PCardHeader(title: '이번 달 예산'),
                    PResultSection(
                      kind: PResultKind.failure,
                      size: PResultSize.medium,
                      placement: PResultPlacement.card,
                      title: '예산을 불러오지 못했어요',
                      description: '잠시 뒤 다시 시도해 주세요.',
                      primaryAction: const PResultAction(
                        label: '다시 시도',
                        onPressed: _noop,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _Floor(
              children: [
                const PCard(
                  body: PCardBody.list,
                  children: [
                    PCardHeader(title: '오늘 쓴 돈'),
                    PResultSection(
                      size: PResultSize.medium,
                      placement: PResultPlacement.listCard,
                      icon: LucideIcons.walletCards,
                      title: '오늘 쓴 돈이 없어요',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
