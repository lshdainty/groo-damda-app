import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/presentation/card_benefit_detail_sheet.dart';
import 'package:groo_damda_app/features/card/presentation/widgets/card_filter_bar.dart';
import 'package:groo_damda_app/features/card/presentation/widgets/card_row.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/infinite_list/p_infinite_list.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 카드 혜택 라이브러리 — 웹 `CardBenefitPage` 폰 갈래 미러(I-20 E 30 ~ 34).
///
/// 폰은 흰 면 하나다: 머리(← "카드 혜택") → 밑줄 검색칸 → 거르기 칩 줄 → "총 n장" + 단종 카드 포함 → 카드 줄 → 끝 줄.
/// 줄을 누르면 조회 시트가 열린다. 요청 실패는 전역 스낵바가 아니라 이 화면 안 Result Section 으로 알린다(조회는 전역
/// 스낵바를 띄우지 않는다 — error_toast_interceptor).
class CardBenefitsScreen extends ConsumerStatefulWidget {
  const CardBenefitsScreen({super.key});

  @override
  ConsumerState<CardBenefitsScreen> createState() => _CardBenefitsScreenState();
}

class _CardBenefitsScreenState extends ConsumerState<CardBenefitsScreen> {
  final _kwCtrl = TextEditingController();
  final _scroll = ScrollController();
  // null = 전체
  String? _type;
  String? _benefit;
  bool _includeDiscontinued = false;
  Timer? _debounce;
  CardSearchKey _searchKey = defaultCardSearchKey();

  // ─── 누적식 인피니티 스크롤 상태 ──────────────────────────
  final List<CardCatalogSummary> _cards = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _initialLoading = true;
  Object? _error;
  int _totalElements = 0;

  @override
  void initState() {
    super.initState();
    // ref(Provider)·inherited widget 접근은 initState 완료 후로 미룸.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMore(initial: true);
    });
  }

  /// 검색 키를 현재 필터 상태로 갱신. (page/size 제외)
  void _rebuildKey() {
    _searchKey = defaultCardSearchKey(
      keyword: _kwCtrl.text.trim().isEmpty ? null : _kwCtrl.text.trim(),
      cardType: _type,
      benefitType: _benefit,
      includeDiscontinued: _includeDiscontinued ? true : null,
    );
  }

  /// 특정 page 의 검색 키 파생 (record typedef 라 copyWith 대체).
  CardSearchKey _keyForPage(int page) => (
    keyword: _searchKey.keyword,
    cardType: _searchKey.cardType,
    benefitType: _searchKey.benefitType,
    includeDiscontinued: _searchKey.includeDiscontinued,
    page: page,
    size: _searchKey.size,
  );

  /// 필터/검색 변경 → 누적 리셋 후 첫 페이지부터 다시 로드.
  Future<void> _reset() {
    setState(() {
      _cards.clear();
      _page = 0;
      _hasMore = true;
      _initialLoading = true;
      _error = null;
    });
    return _loadMore(initial: true);
  }

  Future<void> _loadMore({bool initial = false}) async {
    if (_loadingMore || (!initial && !_hasMore)) return;
    setState(() => _loadingMore = true);
    final key = _keyForPage(_page);
    try {
      // 새 페이지는 항상 최신 데이터를 받도록 캐시 무효화.
      ref.invalidate(cardCatalogPageProvider(key));
      final p = await ref.read(cardCatalogPageProvider(key).future);
      if (!mounted) return;
      setState(() {
        _cards.addAll(p.content);
        _totalElements = p.totalElements;
        _hasMore = !p.last;
        _page += 1;
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _initialLoading = false;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// 목록 끝 자리의 "다시 시도" — 못 받은 그 쪽을 다시 받는다(이미 받은 줄은 그대로).
  void _retryMore() {
    setState(() => _error = null);
    _loadMore();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _rebuildKey();
      _reset();
    });
  }

  void _setFilters({String? type, String? benefit}) {
    setState(() {
      _type = type;
      _benefit = benefit;
    });
    _rebuildKey();
    _reset();
  }

  void _toggleDiscontinued(bool v) {
    setState(() => _includeDiscontinued = v);
    _rebuildKey();
    _reset();
  }

  @override
  void dispose() {
    _kwCtrl.dispose();
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.cardBenefitsTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: PScreenBandBody(
        child: PPullToRefresh(
          onRefresh: () => _reset(),
          child: ListView(
            controller: _scroll,
            // 목록 끝 자리가 화면 아래 300 안에서 그려져야 다음 쪽을 부른다(Infinite List)
            scrollCacheExtent: const ScrollCacheExtent.pixels(
              kPInfiniteListReach,
            ),
            padding: const EdgeInsets.only(bottom: PSpacing.screenBottom),
            children: [
              // 밑줄 검색칸 — 머리 아래 8
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PSpacing.globalGutter,
                  PSpacing.x2,
                  PSpacing.globalGutter,
                  0,
                ),
                child: PInput(
                  variant: PInputVariant.underline,
                  controller: _kwCtrl,
                  placeholder: l.cardSearchHintFull,
                  semanticLabel: l.cardSearchHintFull,
                  prefixIcon: LucideIcons.search,
                  clearable: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                ),
              ),
              // 거르기 칩 줄 — 검색칸 아래 12, 화면 끝까지
              Padding(
                padding: const EdgeInsets.only(top: PSpacing.x3),
                child: CardFilterBar(
                  type: _type,
                  benefit: _benefit,
                  onType: (v) => _setFilters(type: v, benefit: _benefit),
                  onBenefit: (v) => _setFilters(type: _type, benefit: v),
                ),
              ),
              // 개수 줄 — "총 n장" + 오른쪽 단종 카드 포함
              PListHeader(
                title: _initialLoading
                    ? ''
                    : l.cardTotalCount(krw(_totalElements)),
                trailing: PCheckbox(
                  size: PCheckboxSize.large,
                  checked: _includeDiscontinued,
                  onChanged: _toggleDiscontinued,
                  label: l.cardIncludeDiscontinued,
                ),
              ),
              ..._buildResults(l),
            ],
          ),
        ),
      ),
    );
  }

  /// 결과 영역 — 첫 쪽 Skeleton / 실패 / 0건 / 누적 목록 + 끝 줄.
  List<Widget> _buildResults(AppLocalizations l) {
    if (_initialLoading) {
      return [const _RowsSkeleton(count: 6)];
    }

    // 첫 쪽을 못 불러왔다 — 목록 자리가 Result Section 의 실패다(예외 · 서버 글은 쓰지 않는다)
    if (_error != null && _cards.isEmpty) {
      return [
        PResultSection(
          kind: PResultKind.failure,
          size: PResultSize.large,
          title: l.cardListLoadFailed,
          description: l.cardFailDesc,
          primaryAction: PResultAction(
            label: l.dsCommonRetry,
            onPressed: _reset,
          ),
        ),
      ];
    }

    if (_cards.isEmpty) {
      return [
        PResultSection(
          size: PResultSize.large,
          icon: LucideIcons.searchX,
          title: l.cardNoResults,
          description: l.cardNoResultsHint,
        ),
      ];
    }

    return [
      PList(
        semanticLabel: l.cardBenefitsTitle,
        children: [
          for (final card in _cards)
            CardRow(
              card: card,
              onTap: () => showCardBenefitDetailSheet(context, card.rowId),
            ),
        ],
      ),
      // 목록 끝 자리 — 받는 중(곧 받는다) · 못 불러옴 · 끝. 한 쪽으로 끝나는 짧은 목록에는 끝 글을 두지 않는다
      if (_error != null)
        PInfiniteListEnd(status: PInfiniteListStatus.error, onRetry: _retryMore)
      else if (_hasMore)
        PInfiniteListEnd(
          status: PInfiniteListStatus.loading,
          onReachEnd: _loadMore,
        )
      else if (_page > 1)
        PInfiniteListEnd(
          status: PInfiniteListStatus.end,
          endText: l.cardListEnd,
        ),
    ];
  }
}

/// 불러오는 동안의 줄 — 카드 그림 56 · 세 줄(실제 줄과 같은 차례).
class _RowsSkeleton extends StatelessWidget {
  const _RowsSkeleton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
              vertical: PSpacing.x3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x4,
              children: [
                const PSkeleton(
                  width: 56,
                  height: 56 / 1.586,
                  radius: PSkeletonRadius.r6,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: PSpacing.x0_5,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.75,
                        child: PSkeleton.text(PTypography.t5),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.5,
                        child: PSkeleton.text(PTypography.t3),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.4,
                        child: PSkeleton.text(PTypography.t3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
