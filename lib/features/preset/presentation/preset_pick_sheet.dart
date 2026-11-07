import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/forms/search_match.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

/// 내역 추가 시트의 "프리셋 고르기"(I-20 C 20) — 칩 줄 끝 "모두 보기" 를 누르면 뜬다. 밑줄 검색칸(이름 · 기본 내역에서 찾는다) +
/// 지금 종류의 프리셋 모두(사용 많은 순). 줄은 프리셋 관리 목록과 같은 부품([PresetListRow])이다. 고르면 그 프리셋이 돌아온다 —
/// 채우고 내역으로 돌아오는 일은 부른 쪽이 한다. "새 프리셋" 줄은 없다(폼 시트 위에 또 입력 폼을 띄울 수 없다).
///
/// 내역 추가 시트가 입력 폼 시트 하나라서 이 단계는 **그 위에 뜨는 고르기 시트**다(같은 시트 안 한 단계로 짜는 것은 거래 시트를 다시
/// 짜는 I-21 21-2 몫 — 그때 이 본문 [PresetPickBody] 를 그대로 옮긴다).
Future<ExpenseTemplate?> showPresetPickSheet(
  BuildContext context, {
  required List<ExpenseTemplate> presets,
}) {
  return PBottomSheet.show<ExpenseTemplate>(
    context,
    builder: (sheetContext) {
      final l = AppLocalizations.of(sheetContext);
      return PBottomSheetContent(
        title: l.presetPickTitle,
        closeLabel: l.actionClose,
        flushBody: true,
        scrollFog: true,
        body: PresetPickBody(presets: presets),
      );
    },
  );
}

/// 본문은 **카테고리 조회를 스스로 지켜본다** — 시트를 연 뒤 [다시 시도] 로 받아 와도 화면이 바뀐다(예전엔 열 때 찍은 값을 들고 있어 실패
/// 화면이 그대로였다). 받는 중에는 Skeleton, 못 받으면 실패 Result Section + 다시 시도, 받으면 줄(회색 "없는 카테고리" 로 읽히지 않는다).
class PresetPickBody extends ConsumerStatefulWidget {
  const PresetPickBody({super.key, required this.presets, this.onPick});

  /// 지금 종류의 프리셋 전부.
  final List<ExpenseTemplate> presets;

  /// 고르면 부른다 — 주면 시트를 닫지 않는다(거래 시트 안 한 단계, I-21 21-2). 안 주면 고르기 시트가 그 프리셋을 들고 닫힌다.
  final ValueChanged<ExpenseTemplate>? onPick;

  @override
  ConsumerState<PresetPickBody> createState() => _PresetPickBodyState();
}

class _PresetPickBodyState extends ConsumerState<PresetPickBody> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final catsAsync = ref.watch(categoriesProvider);
    final masked = ref.watch(hideCardProvider('etc.preset'));
    if (!catsAsync.hasValue) {
      if (catsAsync.loadFailed) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.globalGutter,
          ),
          child: PResultSection(
            kind: PResultKind.failure,
            size: PResultSize.medium,
            title: l.presetCategoryLoadFailed,
            description: l.dashFailDesc,
            primaryAction: PResultAction(
              label: l.actionRetry,
              loading: catsAsync.loadRetrying,
              onPressed: () => ref.invalidate(categoriesProvider),
            ),
          ),
        );
      }
      return loadingRegion(
        Column(
          children: [
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PSpacing.globalGutter,
                  vertical: PSpacing.x3,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: PSpacing.x3,
                  children: [
                    const PSkeleton(
                      width: PListTile.size,
                      height: PListTile.size,
                      radius: PSkeletonRadius.r12,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: PSpacing.x1,
                        children: [
                          PSkeleton.text(PTypography.t5, width: 140),
                          PSkeleton.text(PTypography.t3, width: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    final categories = catsAsync.requireValue;
    final shown = [
      for (final p in widget.presets)
        if (_query.trim().isEmpty ||
            matchesSearch(
              p.templateName,
              _query,
              aliases: [if (p.merchant != null) p.merchant!],
            ))
          p,
    ]..sort((a, b) => (b.useCount ?? 0).compareTo(a.useCount ?? 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            PSpacing.x2,
            PSpacing.globalGutter,
            PSpacing.x2,
          ),
          child: PInput(
            variant: PInputVariant.underline,
            placeholder: l.presetSearch,
            semanticLabel: l.presetSearch,
            prefixIcon: LucideIcons.search,
            clearable: true,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
              vertical: PSpacing.x3,
            ),
            child: PText(
              l.presetNoResult,
              textAlign: TextAlign.center,
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
          )
        else
          PList(
            semanticLabel: l.presetPickTitle,
            children: [
              for (final p in shown)
                PresetListRow(
                  key: ValueKey('preset-pick-${p.rowId}'),
                  preset: p,
                  category: p.categoryRowId == null
                      ? null
                      : categories
                            .where((x) => x.rowId == p.categoryRowId)
                            .firstOrNull,
                  masked: masked,
                  onTap: () => widget.onPick != null
                      ? widget.onPick!(p)
                      : PBottomSheet.of(context).close(p),
                ),
            ],
          ),
      ],
    );
  }
}
