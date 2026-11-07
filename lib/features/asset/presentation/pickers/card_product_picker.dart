import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/picker_sheet.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/presentation/card_fee_text.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/image_frame/p_card_art.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/searchable_list/p_searchable_list.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

/// 카드 상품 고르기(I-17 19) — 칸의 Input Button 이 여는 검색 시트.
///
/// 서버 검색은 마지막 입력 뒤 300ms 에 한 번(Searchable List 의 `onSearch`), 요청은 시트를 열 때 시작한다. [cardType] 은 고른
/// 종류(`CREDIT` · `CHECK`)로 거른다. 검색칸 바로 아래 스위치 줄이 단종 카드를 목록에 넣고 뺀다(누르면 목록이 바로 바뀐다).
/// 돌려주는 값은 고른 상품이다(취소하면 null).
Future<CardCatalogSummary?> showCardProductPicker(
  BuildContext context, {
  required String cardType,
  required int? currentRowId,
}) {
  final focus = FocusNode(debugLabel: 'card search');
  return PBottomSheet.show<CardCatalogSummary>(
    context,
    initialFocus: focus,
    builder: (_) => CardProductSheet(
      cardType: cardType,
      currentRowId: currentRowId,
      searchFocus: focus,
    ),
  ).whenComplete(focus.dispose);
}

class CardProductSheet extends ConsumerStatefulWidget {
  const CardProductSheet({
    super.key,
    required this.cardType,
    required this.currentRowId,
    required this.searchFocus,
  });

  final String cardType;
  final int? currentRowId;
  final FocusNode searchFocus;

  @override
  ConsumerState<CardProductSheet> createState() => _CardProductSheetState();
}

class _CardProductSheetState extends ConsumerState<CardProductSheet> {
  /// 서버로 보낸 검색어 — 마지막 입력 뒤 300ms 에 한 번 바뀐다.
  String _sent = '';
  bool _includeDiscontinued = false;

  /// 받는 동안 보이는 앞 결과 — 처음만 스켈레톤이다.
  List<CardCatalogSummary>? _last;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final key = defaultCardSearchKey(
      keyword: _sent.trim().isEmpty ? null : _sent.trim(),
      cardType: widget.cardType,
      includeDiscontinued: _includeDiscontinued ? true : null,
      page: 0,
      size: 40,
    );
    final async = ref.watch(cardCatalogPageProvider(key));
    final items = async.value?.content;
    if (items != null) _last = items;
    final shown = items ?? _last;

    Widget result;
    if (shown == null && async.hasError) {
      result = PSearchableListError(
        title: l.assetSearchFailed,
        retryLabel: l.actionRetry,
        retrying: async.isLoading,
        onRetry: () => ref.invalidate(cardCatalogPageProvider(key)),
      );
    } else if (shown == null) {
      result = loadingRegion(
        const PSearchableListSkeleton(
          prefix: PSearchableListSkeletonPrefix.cardArt,
        ),
      );
    } else if (shown.isEmpty) {
      result = PSearchableListEmpty(
        titleBuilder: (q) => l.assetSearchEmpty(q),
        description: l.assetCardEmptyHint,
      );
    } else {
      result = PSearchableListResults(
        scrollFog: true,
        semanticLabel: l.assetCardProduct,
        children: [
          for (final c in shown)
            PSearchableListItem(
              value: '${c.rowId}',
              title: c.cardName,
              prefix: PCardArt(
                issuer: c.company?.name ?? '',
                name: c.cardName,
                image: c.imgUrl != null && c.imgUrl!.isNotEmpty
                    ? NetworkImage(c.imgUrl!)
                    : null,
                width: 56,
              ),
              detailChild: _Detail(item: c),
            ),
        ],
      );
    }

    return PBottomSheetContent(
      title: l.assetPickCardTitle,
      closeLabel: l.actionClose,
      flushBody: true,
      // 내용만큼 서고 시트가 낼 수 있는 높이에서 멈춘다(bottom-sheet.md — 0건 · 적은 결과에서 빈 시트가 90% 로 서지 않는다)
      body: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: pickerBodyHeight(context)),
        child: PSearchableList(
          focusNode: widget.searchFocus,
          defaultValue: widget.currentRowId?.toString(),
          onSearch: (q) => setState(() => _sent = q),
          onValueChanged: (v) {
            final picked = shown?.where((c) => '${c.rowId}' == v).firstOrNull;
            if (picked != null) PBottomSheet.of(context).close(picked);
          },
          children: [
            PSearchableListInput(
              placeholder: l.assetCardSearchHint,
              semanticLabel: l.actionSearch,
            ),
            // 단종 카드도 보기 — 누르면 목록이 바로 바뀐다(Switch)
            PListSwitchItem(
              title: l.assetIncludeDiscontinued,
              checked: _includeDiscontinued,
              onChanged: (v) => setState(() => _includeDiscontinued = v),
            ),
            result,
          ],
        ),
      ),
    );
  }
}

/// 설명 줄 — "{발급사} · {신용 | 체크} · 연회비 {금액}원"(정보가 없으면 연회비를 뺀다) + 단종이면 끝에 배지(흐리게 하지 않는다).
class _Detail extends StatelessWidget {
  const _Detail({required this.item});

  final CardCatalogSummary item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 연회비 정보가 아예 없으면(annualFee == null) 목록에서 생략한다 — 정보가 있으면 금액이든 "무료"든 보인다
    final fee = item.annualFee == null
        ? ''
        : ' · ${l.assetAnnualFee} ${cardFeeValue(l, item.annualFee, preferLabel: false)}';
    final kind = item.cardType == 'CREDIT'
        ? l.assetCardShortCredit
        : l.assetCardShortCheck;
    final text = '${item.company?.name ?? '—'} · $kind$fee';
    return Wrap(
      spacing: PSpacing.x1_5,
      runSpacing: PSpacing.x0_5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(keepAll(text)),
        if (item.isDiscontinued == 'Y') PBadge(label: l.assetDiscontinued),
      ],
    );
  }
}
