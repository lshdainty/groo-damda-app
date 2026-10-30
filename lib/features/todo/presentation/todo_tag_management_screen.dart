import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/forms/tag_settings.dart';

/// 할 일 태그 관리(I-10 5A) — 설정 하위 풀스크린 화면. 본문은 메모 태그와 같은 한 부품([TagSettings])이다(I-15 24).
/// 글과 데이터 길(할 일 태그 저장소)만 이 화면이 넘긴다. 사용 건수는 서버 집계(`usageCount`)다.
class TodoTagManagementScreen extends ConsumerStatefulWidget {
  const TodoTagManagementScreen({super.key});

  @override
  ConsumerState<TodoTagManagementScreen> createState() =>
      _TodoTagManagementScreenState();
}

class _TodoTagManagementScreenState
    extends ConsumerState<TodoTagManagementScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  /// 저장·삭제가 끝나기 전에 화면이 닫혀도 목록을 비울 수 있게 미리 잡아 둔다.
  ///
  /// `ref` 는 unmount 뒤에 쓰면 던지고, `if (mounted)` 로 막으면 무효화 자체가 안 일어난다 —
  /// [todoTagListProvider] 는 keepAlive, [todoListProvider] 는 autoDispose 가 아니라 둘 다 화면보다 오래 산다.
  /// 컨테이너는 `ProviderScope` 의 것이라 화면 수명과 무관하다(#348·#351 과 같은 방식).
  late ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    // 진입 시 갱신 — keepAlive provider 라 다른 클라이언트 변경 반영 위해 무효화.
    Future.microtask(() {
      if (mounted) ref.invalidate(todoTagListProvider);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// 서버에 들어간 뒤 목록을 비우고 **다시 받은 뒤** 끝낸다 — 새 목록이 오기 전에 시트가 닫히면 옛 값이 잠깐 비친다.
  /// 개명 · 삭제는 서버가 그 태그를 쓰던 할 일의 `category` 도 함께 옮기거나 비우므로(`renameCategory` · `clearCategory`) 할 일 목록도 비운다.
  Future<void> _changed() async {
    _container.invalidate(todoTagListProvider);
    _container.invalidate(todoListProvider);
    try {
      await _container.read(todoTagListProvider.future);
    } on Object {
      // 목록을 다시 못 받아도 저장은 끝났다 — 화면은 실패 상자로 알린다.
    }
  }

  TagSettingsCopy _copy(AppLocalizations l) => TagSettingsCopy(
    title: l.ttagTitle,
    desc: l.ttagDesc,
    addCta: l.ttagAddCta,
    emptyTitle: l.ttagEmpty,
    emptyHint: l.ttagEmptyHint,
    loadFailedTitle: l.todoTagLoadError,
    loadFailedDesc: l.tdmLoadFailedDesc,
    usage: l.ttagUsage,
    deleteTitle: l.todoDeleteTagTitle,
    deleteConfirm: l.todoDeleteTagConfirm,
    saveFailed: l.ttagSaveFailed,
    deleteFailed: l.ttagDeleteFailed,
    editTitle: l.ttagEditTitle,
    newPlaceholder: l.todoNewTag,
    namePlaceholder: l.todoTagNamePlaceholder,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(todoTagListProvider);
    final list = async.value;
    return Scaffold(
      // 흰 면 하나 — 띠 · 카드 없이 화면 전체가 흰 층이다
      backgroundColor: context.colors.bgLayerDefault,
      // 머리 = ds 상단 바(← + 제목) — 높이 56, 스크롤해도 선이 없다(I-16 14)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.ttagTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: TagSettings(
        bodyKey: const ValueKey('todo-tags-body'),
        controller: _scrollCtrl,
        copy: _copy(l),
        tags: list == null
            ? null
            : [
                for (final t in list)
                  TagItem(
                    rowId: t.rowId,
                    name: t.tagName,
                    color: t.color,
                    usageCount: t.usageCount,
                  ),
              ],
        failed: list == null && async.hasError,
        onRetry: () => ref.invalidate(todoTagListProvider),
        create: (name, color) async {
          final repo = await _container.read(todoTagRepositoryProvider.future);
          await repo.create(tagName: name, color: color);
          await _changed();
        },
        update: (id, name, color) async {
          final repo = await _container.read(todoTagRepositoryProvider.future);
          await repo.update(id: id, tagName: name, color: color);
          await _changed();
        },
        remove: (id) async {
          final repo = await _container.read(todoTagRepositoryProvider.future);
          await repo.delete(id);
          await _changed();
        },
      ),
    );
  }
}
