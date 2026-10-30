import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/presentation/card_format.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/image_frame/p_card_art.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';

/// 카드 그림 — 서버 그림이 있으면 그림, 없으면 카드사 색 면(기관 색 표) · 모르는 카드사는 대체 그림(I-20 E 32).
/// 그림 주소 → 이미지 공급자는 한 자리에서만 만든다(렌더 하네스가 이 자리로 합성 그림을 넣는다).
ImageProvider? cardImageProvider(String? url) =>
    url != null && url.isNotEmpty ? NetworkImage(url) : null;

/// 카드 줄(I-20 E 32) — ds List 누르는 줄 + 앞 카드 그림 56, 위 맞춤. 제목은 카드 이름(줄바꿈, 말줄임 없음), 설명 두 줄은
/// Tag Group t3 로 줄마다 한 줄 말줄임: "{카드사} · {신용|체크} · {혜택 유형}" / "{연회비} · {실적}".
/// 단종은 흐리지 않고 뒤 Badge `weak` `neutral` "단종". 화살표 없음 — 줄은 시트를 연다.
class CardRow extends StatelessWidget {
  const CardRow({super.key, required this.card, required this.onTap});

  final CardCatalogSummary card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PListButtonItem(
      align: PListAlign.top,
      onTap: onTap,
      prefix: PCardArt(
        width: 56,
        issuer: card.company?.name ?? '',
        name: card.cardName,
        image: cardImageProvider(card.imgUrl),
      ),
      title: card.cardName,
      detailChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PTagGroup(
            size: PTagGroupSize.t3,
            overflow: PTagGroupOverflow.truncate,
            items: [for (final x in cardMetaParts(l, card)) PTag(x)],
          ),
          _AmountLine(
            items: [
              annualFeeRowText(l, card.annualFee),
              performanceRowText(l, card.performance),
            ],
          ),
        ],
      ),
      suffix: card.isDiscontinued == 'Y'
          ? PBadge(label: l.assetDiscontinued)
          : null,
    );
  }
}

/// 금액이 든 설명 줄("연회비 1,234,567원 · 실적 300,000원") — 한 줄에 다 들면 Tag Group 한 줄, 안 들면 금액을 말줄임하지 않고
/// 항목을 통째로 다음 줄로 내린다(항목마다 한 줄 · 사이 구분 없음). 한 항목이 한 줄보다 길 때만 그 항목 안에서 말줄임.
class _AmountLine extends StatelessWidget {
  const _AmountLine({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(
            text: items.join(tagGroupSeparator),
            style: PTypography.t3,
          ),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final fits = painter.width <= box.maxWidth;
        painter.dispose();
        if (fits) {
          return PTagGroup(
            size: PTagGroupSize.t3,
            overflow: PTagGroupOverflow.truncate,
            items: [for (final x in items) PTag(x)],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final x in items)
              PTagGroup(
                size: PTagGroupSize.t3,
                overflow: PTagGroupOverflow.truncate,
                items: [PTag(x)],
              ),
          ],
        );
      },
    );
  }
}
