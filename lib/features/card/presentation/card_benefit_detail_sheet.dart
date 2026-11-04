import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/presentation/card_format.dart';
import 'package:groo_damda_app/features/card/presentation/widgets/card_row.dart'
    show cardImageProvider;
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/accordion/p_accordion.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/image_frame/p_card_art.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 카드 혜택 상세 — 조회 시트(I-20 E 34). 바깥 누름 · 끌어내림으로 닫히고 바닥 버튼은 없다(닫기 원 하나). 높이는 내용만큼 ·
/// 최대 90%, 본문만 스크롤 + 끝 흐림.
///
/// 차례: 그림 312 가운데 → 카드 이름 → 설명 "{카드사} · {신용|체크} · {혜택 유형}" → 주요 혜택 태그 한 줄 →
/// 키-값(연회비 · 전월 실적 · 브랜드) → "혜택 n개" + 모두 펼치기 → Accordion separated → 유의사항 Callout.
Future<void> showCardBenefitDetailSheet(BuildContext context, int rowId) {
  final l = AppLocalizations.of(context);
  return PBottomSheet.show<void>(
    context,
    builder: (_) => PBottomSheetContent(
      title: l.assetCardDetail,
      closeLabel: l.actionClose,
      flushBody: true,
      scrollFog: true,
      body: CardDetailContent(rowId: rowId),
    ),
  );
}

/// 시트 안 본문 — 불러오는 중 Skeleton · 실패 Result Section · 내용.
class CardDetailContent extends ConsumerWidget {
  const CardDetailContent({super.key, required this.rowId});
  final int rowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(cardCatalogDetailProvider(rowId));
    return async.when(
      loading: () => const _DetailSkeleton(),
      error: (_, _) => PResultSection(
        kind: PResultKind.failure,
        size: PResultSize.medium,
        title: l.cardDetailLoadError,
        description: l.cardFailDesc,
        primaryAction: PResultAction(
          label: l.dsCommonRetry,
          onPressed: () => ref.invalidate(cardCatalogDetailProvider(rowId)),
        ),
      ),
      data: (d) => _DetailBody(detail: d),
    );
  }
}

/// topBenefits[].tags 를 펴서 중복 없이.
List<String> flattenTopTags(CardCatalogDetail d) {
  final seen = <String>{};
  return [
    for (final g in d.topBenefits)
      for (final tag in g.tags)
        if (decodeHtml(tag).isNotEmpty && seen.add(decodeHtml(tag)))
          decodeHtml(tag),
  ];
}

class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.detail});
  final CardCatalogDetail detail;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  List<String> _values = const [];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final d = widget.detail;
    final s = d.summary;
    final tags = flattenTopTags(d);
    final brands = d.brands
        .map(decodeHtml)
        .where((b) => b.trim().isNotEmpty)
        .toList();
    final benefits = d.benefits;
    final ids = [for (var i = 0; i < benefits.length; i++) 'b$i'];
    final expandable = [
      for (var i = 0; i < benefits.length; i++)
        if ((benefits[i].detail ?? '').trim().isNotEmpty) ids[i],
    ];
    final cautions = [
      for (final x in d.cautions)
        (x.detail ?? x.summary ?? x.title ?? x.category ?? '').trim(),
    ].where((x) => x.isNotEmpty).toList();
    const gutter = EdgeInsets.symmetric(horizontal: PSpacing.globalGutter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: gutter.copyWith(bottom: PSpacing.x3),
          child: LayoutBuilder(
            builder: (context, box) => Center(
              child: PCardArt(
                width: math.min(312, box.maxWidth),
                issuer: decodeHtml(s.company?.name),
                name: decodeHtml(s.cardName),
                image: cardImageProvider(s.imgUrl),
              ),
            ),
          ),
        ),
        Padding(
          padding: gutter.copyWith(bottom: PSpacing.x2),
          child: Text(
            keepAll(decodeHtml(s.cardName)),
            semanticsLabel: decodeHtml(s.cardName),
            style: PTypography.t6.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: gutter.copyWith(bottom: PSpacing.x2),
          child: Text(
            keepAll(cardMetaParts(l, s).join(' · ')),
            semanticsLabel: cardMetaParts(l, s).join(' · '),
            style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
          ),
        ),
        if (tags.isNotEmpty)
          Padding(
            padding: gutter.copyWith(bottom: PSpacing.x2),
            child: Semantics(
              label: l.cardKeyBenefitTags,
              child: PTagGroup(
                size: PTagGroupSize.t3,
                items: [for (final t in tags) PTag(t)],
              ),
            ),
          ),
        PList(
          semanticLabel: l.assetCardDetail,
          children: [
            PListItem(
              title: l.assetAnnualFee,
              suffix: Text(annualFeeDetailText(l, s.annualFee)),
            ),
            PListItem(
              title: l.cardLastMonthPerf,
              suffix: Text(performanceDetailText(l, s.performance)),
            ),
            if (brands.isNotEmpty)
              PListItem(title: l.cardBrands, suffix: Text(brands.join(' · '))),
          ],
        ),
        Padding(
          padding: gutter.copyWith(top: PSpacing.x2),
          child: PAccordionHeader(
            title: l.cardBenefitDetailCount(benefits.length),
            trailing: expandable.isEmpty
                ? null
                : PAccordionExpandAll(
                    values: _values,
                    expandable: expandable,
                    onValuesChange: (v) => setState(() => _values = v),
                    expandLabel: l.cardExpandAll,
                    collapseLabel: l.cardCollapseAll,
                  ),
          ),
        ),
        if (benefits.isEmpty)
          Padding(
            padding: gutter.copyWith(top: PSpacing.x6, bottom: PSpacing.x6),
            child: Text(
              keepAll(l.cardNoBenefits),
              semanticsLabel: l.cardNoBenefits,
              textAlign: TextAlign.center,
              style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
            ),
          )
        else
          Padding(
            padding: gutter,
            child: PAccordion(
              variant: PAccordionVariant.separated,
              values: _values,
              onValuesChange: (v) => setState(() => _values = v),
              children: [
                for (var i = 0; i < benefits.length; i++)
                  _benefitItem(ids[i], benefits[i]),
              ],
            ),
          ),
        if (cautions.isNotEmpty) ...[
          Padding(
            padding: gutter.copyWith(top: PSpacing.x6, bottom: PSpacing.x2),
            child: Text(
              l.cardCautions,
              style: PTypography.t4.copyWith(
                color: c.fgNeutral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: gutter,
            child: PCallout(
              tone: PCalloutTone.informative,
              description: cautions.first,
              moreDescriptions: cautions.skip(1).toList(),
            ),
          ),
        ],
        const SizedBox(height: PSpacing.x6),
      ],
    );
  }

  Widget _benefitItem(String id, CardBenefit b) {
    final title = (b.category ?? '').trim();
    final description = (b.summary ?? b.title ?? '').trim();
    final body = (b.detail ?? '').trim();
    return body.isNotEmpty
        ? PAccordionItem(
            value: id,
            title: title,
            description: description.isEmpty ? null : description,
            child: Text(keepAll(body), semanticsLabel: body),
          )
        : PAccordionPlainItem(
            title: title,
            description: description.isEmpty ? null : description,
          );
  }
}

/// 불러오는 동안 — 그림 312 · 이름 · 설명 · 키-값 셋 · 혜택 머리 + 항목 셋(실제 차례와 같다).
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    const gutter = EdgeInsets.symmetric(horizontal: PSpacing.globalGutter);
    return Padding(
      padding: gutter.copyWith(bottom: PSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: LayoutBuilder(
              builder: (context, box) => PSkeleton(
                width: math.min(312, box.maxWidth),
                height: math.min(312, box.maxWidth) / 1.586,
                radius: PSkeletonRadius.r8,
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x3),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 2 / 3,
              child: PSkeleton.text(PTypography.t6),
            ),
          ),
          const SizedBox(height: PSpacing.x2),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: PSkeleton.text(PTypography.t4),
            ),
          ),
          const SizedBox(height: PSpacing.x4),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpacing.x3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PSkeleton.text(PTypography.t5, width: 64),
                  PSkeleton.text(PTypography.t5, width: 96),
                ],
              ),
            ),
          const SizedBox(height: PSpacing.x4),
          PSkeleton.text(PTypography.t4, width: 96),
          const SizedBox(height: PSpacing.x4),
          for (var i = 0; i < 3; i++) ...[
            const PSkeleton(height: 74, radius: PSkeletonRadius.r16),
            const SizedBox(height: PSpacing.x2),
          ],
        ],
      ),
    );
  }
}
