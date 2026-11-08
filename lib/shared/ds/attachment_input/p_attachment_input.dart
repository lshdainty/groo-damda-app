import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/core/format/percent.dart';
import 'package:groo_damda_app/l10n/ds_l10n.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/attachment_input/p_attachment_model.dart';
import 'package:groo_damda_app/shared/ds/attachment_input/p_attachment_system_picker.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/image_frame/p_image_frame.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';

export 'package:groo_damda_app/shared/ds/attachment_input/p_attachment_model.dart';

part 'p_attachment_input_parts.dart';

/// 모양 — tile(기본, 첨부 타일 + 항목 줄 — 여럿을 붙이고 사진이 섞이는 자리) · dropzone(파일 하나를 골라 바로 넘기는 자리 —
/// 앱은 끌어 놓기가 없어 드롭존 없이 "파일 선택" 버튼 large · 칸 폭 · 앞 아이콘 upload + 고른 파일 카드).
enum PAttachmentLayout { tile, dropzone }

/// Attachment Input — 사진 · 파일을 골라 붙이는 칸. 구조는 SEED Attachment Input(2026-10-15), 수치 원본은 groo-design
/// `specs/components/attachment-input.yaml`(값은 `test/fixtures/design_spec/attachment-input.json` — 테스트가 위젯이 그 값과
/// 같은지 본다). 웹(desk-front `src/shared/ds/attachment-input`)과 같은 값이다. 사람의 프로필 사진은 Avatar 의 "사진 바꾸기",
/// 붙은 사진을 보이기만 하는 자리는 Image Frame 이다.
///
/// 제어 위젯이다 — 항목 목록([entries])은 쓰는 쪽이 쥐고, 올리기 요청과 상태도 쓰는 쪽이 바꾼다.
///   onFilesAccept(added)   검사를 통과한 새 항목(상태 pending) — 한 번 고른 것을 한 번에
///   onFilesReject(list)    한 번 고른 것 가운데 거절된 것 모두 — Field 오류 글로 이유마다 한 문장(토스트가 아니다). 같은 고르기면
///                          [onFilesAccept] 다음에 부른다
///   onRemove(id)           × · 메뉴의 지우기 — **묻지 않고 지운다**(되돌리기는 다시 고르기)
///   onRetry(id)            실패한 항목의 "다시 시도"
///   onReorder(next)        주면 항목 메뉴의 앞으로 · 뒤로 옮기기 · 대표로 정하기가 열린다. 앱은 끌기를 두지 않는다 —
///                          항목 메뉴가 길이다(끌기는 가로 스크롤과 다투고, 메뉴가 같은 일을 한 번 눌러 한다)
///   onPreview(id)          주면 메뉴 첫 줄 "크게 보기"(파일 카드는 "열기")
///   accept · maxFiles(기본 1, [unlimited] 면 개수를 그리지 않는다) · maxFileSize(바이트) · badgeLabel("대표")
///   disabled · readOnly    Field 안이면 Field 의 값을 받는다. 막힘은 새로 고르지 못하고 × 도 막힌다. 읽기 전용은 타일 · ×
///                          · 순서 바꾸기가 막히고 항목을 누르면 메뉴 없이 바로 [onPreview]
///   pickFiles              고르기 — 기본은 시스템(image_picker · file_picker). 테스트 · 견본은 가짜를 넘긴다
///
/// 고르기 — 앱의 첨부 타일 · 파일 선택은 Menu Sheet 를 연다: "사진 찍기" · "앨범에서 고르기" · "파일 고르기"(받는 형식에 없는
///   줄은 빼고, 남는 줄이 하나면 시트 없이 바로 그 창). 형식 · 크기 · 개수를 다시 검사한다 — 남은 자리보다 많이 고르면 앞에서부터
///   남은 만큼 붙이고 나머지만 거절한다.
/// 항목 — 사진 80 × 80(투명 윤곽 1px) · 파일 카드 160 × 80(썸네일 칸 48 + 이름 폭 70 · 12 / 16 · 500 · 글자 단위 네 줄 · 넘치면
///   셋째 줄 "…" + 넷째 줄 확장자 + 크기 11 / 15). × 는 20 원이 모서리 밖으로 위 4 · 오른쪽 4 걸치고 둘레 24 를 파낸다.
///   올리는 중은 값 있는 원 24(사진 — 딤 위 staticWhite, 파일 — 썸네일 칸에 neutral), 진행이 10초 멈추면 실패, 실패는 덮개 +
///   "다시 시도". 첫 사진에 대표 띠(아래 24 · 검정 65%).
/// 항목 메뉴 — 항목을 누르면 Menu Sheet(머리 = 전체 파일 이름): 크게 보기 · 대표로 정하기 · 앞으로 옮기기 · 뒤로 옮기기 | 지우기.
///   끝에 닿으면 그 방향이 막힌 줄이다. 옮긴 뒤 초점은 새 자리의 항목. 항목에 `customSemanticsActions`(앞으로 · 뒤로 옮기기).
/// 접근성 — 타일 "{칸 이름} 첨부, 3/10"(다 차면 막힌 모습 · 초점은 남는다), 항목은 전체 파일 이름 + 크기 + 상태, × "{파일 이름}
///   지우기", 다시 시도 "{파일 이름} 다시 시도". 붙음 · 올림 · 실패는 한 번씩 읽는다("사진 2장을 붙였어요.").
///
/// 앱의 한계 — × 의 누르는 자리 44 는 위 · 오른쪽으로 보이는 원 밖 12 인데 Flutter 는 부모 밖 누르기를 자식에게 묻지 않는다.
///   항목 자리가 위 16 · (끝 항목은) 오른쪽 16 을 레이아웃에 두고 다른 항목 위로 겹쳐 받으므로 44 가 모두 선다. 이웃 항목과 겹친
///   8 × 28 도 × 가 먼저 받는다(줄이 × 의 44 를 이웃보다 먼저 묻는다). 위 16 은 라벨이 있는 Field 안이면 머리 쪽으로 당겨 받고, 라벨이 없으면
///   (맨 위 칸) 받아 줄 부모 자리가 없어 16 을 레이아웃에 남긴다. 웹의 항목 줄은 부모 여백 밖(좌우 −24)까지 넓어지지만 Flutter 는 부모 밖
///   누르기 · 스크롤을 받지 못하고 OverflowBox 가 접근성 트리와 충돌해 앱은 넓히지 않는다 — 칸 폭 안에서 스크롤하고(기본), 화면 폭
///   전체에 놓는 화면은 칸을 화면 폭에 두고 `PField(edgeInset: 24)` 로 감싼다(머리 · 꼬리만 24 들어오고 줄 안쪽 여백이 24 가 된다) — 또는 [bleed] 에 24.
class PAttachmentInput extends StatefulWidget {
  const PAttachmentInput({
    super.key,
    required this.entries,
    required this.onFilesAccept,
    required this.onRemove,
    this.onRetry,
    this.onFilesReject,
    this.onReorder,
    this.onPreview,
    this.layout = PAttachmentLayout.tile,
    this.accept,
    this.maxFiles = 1,
    this.maxFileSize,
    this.badgeLabel,
    this.disabled,
    this.readOnly,
    this.semanticLabel,
    this.pickFiles = pickSystemAttachments,
    this.bleed,
  });

  /// maxFiles 에 주면 개수를 그리지 않는다(웹 Infinity).
  static const int unlimited = 0x7fffffff;

  final List<PAttachmentEntry> entries;
  final ValueChanged<List<PAttachmentEntry>> onFilesAccept;
  final ValueChanged<String> onRemove;
  final ValueChanged<String>? onRetry;
  final ValueChanged<List<PAttachmentRejection>>? onFilesReject;
  final ValueChanged<List<PAttachmentEntry>>? onReorder;
  final ValueChanged<String>? onPreview;
  final PAttachmentLayout layout;

  /// 받는 형식 — "image/*,application/pdf" · ".csv,.xlsx,.xls". 고르기 길을 가리고 다시 검사에도 쓴다.
  final String? accept;
  final int maxFiles;

  /// 바이트 — 넘으면 거절(fileTooLarge).
  final int? maxFileSize;

  /// 주면 첫 사진에 띠("대표").
  final String? badgeLabel;
  final bool? disabled;
  final bool? readOnly;

  /// 타일 이름의 앞 — 기본은 Field 라벨("영수증" → "영수증 첨부, 3/10").
  final String? semanticLabel;
  final PAttachmentPickFiles pickFiles;

  /// 항목 줄 좌우의 안쪽 여백 — 화면 폭 전체에 놓을 때 화면 여백(24)을 준다(첫 항목이 다른 칸과 같은 자리에서 시작하고 끝 흐림이
  /// 화면 가장자리에 닿는다). 안 주면 Field 의 `edgeInset`(입력은 화면 폭 · 머리 · 꼬리만 24 들이는 길 — Q-016-2)을 따르고, Field 밖이면
  /// 0 — 줄이 칸 폭 안에서 스크롤한다(여백 안에 둔 채 쓰지 않는다 — 끝 흐림 20 이 첫 타일을 깎는다).
  final double? bleed;

  @override
  State<PAttachmentInput> createState() => _PAttachmentInputState();
}

class _PAttachmentInputState extends State<PAttachmentInput> {
  // 진행이 10초 멈춘 올리기 — 값(progress)이 있는 것만 잰다. 진행이 바뀌면 다시 센다
  final Map<String, ({double progress, Timer timer})> _watch = {};
  final Set<String> _stalled = {};

  final Map<String, FocusNode> _itemNodes = {};
  final Map<String, FocusNode> _removeNodes = {};
  final FocusNode _triggerNode = FocusNode(debugLabel: 'attachment-trigger');

  // ── 길게 눌러 끌기(앱 — 250ms) ─────────────────────────────
  final ScrollController _scroll = ScrollController();
  final GlobalKey _scrollKey = GlobalKey();
  final Map<String, GlobalKey> _slotKeys = {};
  String? _dragId;

  /// 끄는 항목이 놓일 자리(entries 의 번호) — 손가락이 가장 가까운 항목 자리로 바로 따라 옮겨 보인다.
  int _dragTarget = -1;
  Offset _dragStartFinger = Offset.zero;
  Offset _dragStartTopLeft = Offset.zero;
  Offset _dragFinger = Offset.zero;
  OverlayEntry? _ghost;
  Timer? _edgeScroll;

  String _message = '';
  String? _movedId;
  ({String id, int index})? _removed;
  Map<String, PAttachmentStatus>? _previous;

  @override
  void initState() {
    super.initState();
    _syncStalls();
    _previous = _statusMap();
  }

  @override
  void didUpdateWidget(PAttachmentInput old) {
    super.didUpdateWidget(old);
    _syncStalls();
    _announceChanges();
    _restoreFocus();
    final ids = {for (final e in widget.entries) e.id};
    if (_dragId != null && !ids.contains(_dragId)) _endDrag(commit: false);
    _slotKeys.removeWhere((id, _) => !ids.contains(id));
    for (final map in [_itemNodes, _removeNodes]) {
      map.keys.where((id) => !ids.contains(id)).toList().forEach((id) {
        map.remove(id)?.dispose();
      });
    }
  }

  @override
  void dispose() {
    _edgeScroll?.cancel();
    _ghost?.remove();
    _ghost?.dispose();
    _scroll.dispose();
    for (final w in _watch.values) {
      w.timer.cancel();
    }
    for (final n in [..._itemNodes.values, ..._removeNodes.values]) {
      n.dispose();
    }
    _triggerNode.dispose();
    super.dispose();
  }

  FocusNode _itemNode(String id) =>
      _itemNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'item-$id'));
  FocusNode _removeNode(String id) =>
      _removeNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'remove-$id'));

  // ── 길게 눌러 끌기 ───────────────────────────────────────────
  // 250ms 누른 채 움직이면 끌기다 — 그 전에 움직이면 줄이 가로로 스크롤하고(제스처 경쟁에서 스크롤이 이긴다), 그냥 떼면 누르기(메뉴).
  // 끄는 항목은 2px 줄어든 채 손가락을 따라가고(사진 불투명도 0.5 · 파일 글 fg-disabled · × 와 구멍 없음 — 13B), 원래 자리는 놓을
  // 곳으로 비어 이웃이 비켜선다. 놓으면 onReorder, 그 자리의 항목에 초점이 간다.
  GlobalKey _slotKey(String id) => _slotKeys.putIfAbsent(id, GlobalKey.new);

  /// 지금 그리는 차례 — 끄는 중이면 끄는 항목을 놓일 자리에 두어 이웃이 비켜선 모습으로.
  List<PAttachmentEntry> get _displayEntries {
    final list = widget.entries;
    final id = _dragId;
    if (id == null) return list;
    final from = list.indexWhere((e) => e.id == id);
    if (from < 0) return list;
    final next = [...list];
    final moved = next.removeAt(from);
    next.insert(_dragTarget.clamp(0, next.length), moved);
    return next;
  }

  void _startDrag(PAttachmentEntry entry, Offset finger) {
    if (_dragId != null) return;
    final box = _slotKeys[entry.id]?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    HapticFeedback.selectionClick();
    _dragStartFinger = finger;
    _dragFinger = finger;
    // 항목 몸의 왼쪽 위 — 자리 상자의 위 16(× 의 누르는 자리)을 뺀다
    _dragStartTopLeft = box.localToGlobal(
      Offset(0, _Dims.of(context).touchBleed),
    );
    _dragTarget = widget.entries.indexWhere((e) => e.id == entry.id);
    _say(
      dsL(context)?.dsAttachLifted(_dragTarget + 1) ??
          '${_dragTarget + 1}번째 항목을 들었어요.',
    );
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject()! as RenderBox;
    final badge =
        entry.isImage &&
        widget.badgeLabel != null &&
        widget.entries.where((e) => e.isImage).firstOrNull?.id == entry.id;
    _ghost = OverlayEntry(
      builder: (_) {
        final at = overlayBox.globalToLocal(
          _dragStartTopLeft + Offset(_dragFinger.dx - _dragStartFinger.dx, 0),
        );
        return Positioned(
          left: at.dx,
          top: at.dy,
          child: IgnorePointer(
            child: _DragGhost(
              entry: entry,
              status: _statusOf(entry),
              badgeLabel: badge ? widget.badgeLabel : null,
            ),
          ),
        );
      },
    );
    overlay.insert(_ghost!);
    setState(() => _dragId = entry.id);
    _edgeScroll = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _scrollAtEdge();
    });
  }

  void _moveDrag(Offset finger) {
    if (_dragId == null) return;
    _dragFinger = finger;
    _ghost?.markNeedsBuild();
    _retarget();
  }

  /// 손가락과 가장 가까운 항목 자리로 놓일 곳을 옮긴다(가운데 가로 거리).
  void _retarget() {
    final id = _dragId;
    if (id == null) return;
    final shown = _displayEntries;
    var best = _dragTarget;
    var bestDistance = double.infinity;
    for (var i = 0; i < shown.length; i++) {
      final box = _slotKeys[shown[i].id]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final center = box.localToGlobal(box.size.center(Offset.zero)).dx;
      final distance = (center - _dragFinger.dx).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    if (best != _dragTarget) setState(() => _dragTarget = best);
  }

  /// 손가락이 줄의 왼쪽 · 오른쪽 가장자리 가까이면 줄을 스크롤한다.
  void _scrollAtEdge() {
    if (_dragId == null || !_scroll.hasClients) return;
    final box = _scrollKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final left = box.localToGlobal(Offset.zero).dx;
    final right = left + box.size.width;
    const zone = 48.0;
    const step = 6.0;
    var delta = 0.0;
    if (_dragFinger.dx < left + zone) {
      delta = -step;
    } else if (_dragFinger.dx > right - zone) {
      delta = step;
    }
    if (delta == 0) return;
    final next = (_scroll.offset + delta).clamp(
      _scroll.position.minScrollExtent,
      _scroll.position.maxScrollExtent,
    );
    if (next == _scroll.offset) return;
    _scroll.jumpTo(next);
    // 줄이 밀리면 항목 자리가 바뀐다 — 다음 프레임에 다시 잰다
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _retarget();
    });
  }

  void _endDrag({required bool commit}) {
    final id = _dragId;
    if (id == null) return;
    final target = _dragTarget;
    _edgeScroll?.cancel();
    _edgeScroll = null;
    _ghost?.remove();
    _ghost?.dispose();
    _ghost = null;
    final from = widget.entries.indexWhere((e) => e.id == id);
    if (mounted) {
      setState(() {
        _dragId = null;
        _dragTarget = -1;
      });
    } else {
      _dragId = null;
    }
    if (commit && from >= 0 && target != from) _moveTo(id, target);
  }

  // ── 올리기가 멈췄나 ──────────────────────────────────────────
  void _syncStalls() {
    final live = <String>{};
    for (final e in widget.entries) {
      final p = e.progress;
      if (e.status != PAttachmentStatus.uploading || p == null || p >= 1) {
        continue;
      }
      live.add(e.id);
      final prev = _watch[e.id];
      if (prev != null && prev.progress == p) continue;
      prev?.timer.cancel();
      _stalled.remove(e.id);
      _watch[e.id] = (
        progress: p,
        timer: Timer(kAttachmentStall, () {
          if (!mounted) return;
          setState(() => _stalled.add(e.id));
        }),
      );
    }
    for (final id in _watch.keys.toList()) {
      if (live.contains(id)) continue;
      _watch.remove(id)?.timer.cancel();
      _stalled.remove(id);
    }
  }

  PAttachmentStatus _statusOf(PAttachmentEntry e) =>
      e.status == PAttachmentStatus.uploading && _stalled.contains(e.id)
      ? PAttachmentStatus.error
      : e.status;

  Map<String, PAttachmentStatus> _statusMap() => {
    for (final e in widget.entries) e.id: _statusOf(e),
  };

  // ── 읽기 글 — 붙음 · 올림 · 실패를 한 번씩 ───────────────────
  void _announceChanges() {
    final before = _previous;
    final now = _statusMap();
    _previous = now;
    if (before == null) return;
    final added = widget.entries.where((e) => !before.containsKey(e.id));
    final succeeded = widget.entries
        .where(
          (e) =>
              before.containsKey(e.id) &&
              before[e.id] != PAttachmentStatus.success &&
              now[e.id] == PAttachmentStatus.success,
        )
        .length;
    final failed = widget.entries
        .where(
          (e) =>
              before.containsKey(e.id) &&
              before[e.id] != PAttachmentStatus.error &&
              now[e.id] == PAttachmentStatus.error,
        )
        .length;
    final parts = <String>[];
    if (added.isNotEmpty) {
      final images = added.where((e) => e.isImage).length;
      if (images == added.length) {
        parts.add(
          dsL(context)?.dsAttachAddedPhotos(images) ?? '사진 $images장을 붙였어요.',
        );
      } else if (images == 0) {
        parts.add(
          dsL(context)?.dsAttachAddedFiles(added.length) ??
              '파일 ${added.length}개를 붙였어요.',
        );
      } else {
        parts.add(
          dsL(context)?.dsAttachAddedItems(added.length) ??
              '${added.length}개를 붙였어요.',
        );
      }
    }
    if (succeeded > 0) {
      parts.add(
        dsL(context)?.dsAttachUploaded(succeeded) ?? '$succeeded개를 올렸어요.',
      );
    }
    if (failed > 0) {
      parts.add(
        dsL(context)?.dsAttachFailedCount(failed) ?? '$failed개는 올리지 못했어요.',
      );
    }
    if (parts.isNotEmpty) _say(parts.join(' '));
  }

  /// 같은 글이 이어지면 다시 읽히게 끝에 빈칸을 번갈아 붙인다.
  void _say(String text) {
    _message = _message.endsWith(' ') ? text : '$text ';
  }

  // ── 초점 ────────────────────────────────────────────────────
  // 옮긴 뒤는 새 자리의 항목, 지운 뒤는 다음 항목의 × → 앞 항목의 × → 첨부 타일
  void _restoreFocus() {
    final moved = _movedId;
    final removed = _removed;
    if (moved != null) {
      _movedId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _itemNodes[moved]?.requestFocus();
      });
    } else if (removed != null &&
        !widget.entries.any((e) => e.id == removed.id)) {
      _removed = null;
      final list = widget.entries;
      final target = removed.index < list.length
          ? _removeNode(list[removed.index].id)
          : removed.index - 1 >= 0 && removed.index - 1 < list.length
          ? _removeNode(list[removed.index - 1].id)
          : _triggerNode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) target.requestFocus();
      });
    }
  }

  // ── 고르기 ──────────────────────────────────────────────────
  bool get _disabled =>
      widget.disabled ?? PFieldScope.maybeOf(context)?.data.disabled ?? false;
  bool get _readOnly =>
      widget.readOnly ?? PFieldScope.maybeOf(context)?.data.readOnly ?? false;
  bool get _full => widget.entries.length >= widget.maxFiles;
  bool get _blocked => _disabled || _readOnly || _full;

  Future<void> _openPicker() async {
    if (_blocked) return;
    final sources = attachmentSources(widget.accept);
    if (sources.isEmpty) return;
    if (sources.length == 1) {
      await _pick(sources.single);
      return;
    }
    PAttachmentSource? chosen;
    PMenuSheetItem line(String label, PAttachmentSource source) =>
        PMenuSheetItem(label: label, onSelect: () => chosen = source);
    await PMenuSheet.show(
      context,
      title: dsL(context)?.dsAttachTitle ?? '첨부',
      layout: PMenuSheetLayout.textOnly,
      groups: [
        PMenuSheetGroup([
          if (sources.contains(PAttachmentSource.camera))
            line(
              dsL(context)?.dsAttachCamera ?? '사진 찍기',
              PAttachmentSource.camera,
            ),
          if (sources.contains(PAttachmentSource.gallery))
            line(
              dsL(context)?.dsAttachGallery ?? '앨범에서 고르기',
              PAttachmentSource.gallery,
            ),
          if (sources.contains(PAttachmentSource.files))
            line(
              dsL(context)?.dsAttachFiles ?? '파일 고르기',
              PAttachmentSource.files,
            ),
        ]),
      ],
    );
    final source = chosen;
    if (source != null && mounted) await _pick(source);
  }

  Future<void> _pick(PAttachmentSource source) async {
    final room = widget.maxFiles - widget.entries.length;
    final files = await widget.pickFiles(source, room < 1 ? 1 : room);
    if (!mounted || files.isEmpty) return;
    take(files);
  }

  /// 고른 파일을 검사해 붙인다 — 형식 · 크기 · 개수. 통과한 것을 먼저, 거절을 뒤에 알린다.
  @visibleForTesting
  void take(List<PAttachmentPicked> files) {
    if (_blocked) return;
    final result = attachmentValidate(
      files,
      room: (widget.maxFiles - widget.entries.length).clamp(0, 1 << 30),
      accept: widget.accept,
      maxFileSize: widget.maxFileSize,
    );
    if (result.accepted.isNotEmpty) {
      widget.onFilesAccept([
        for (final f in result.accepted)
          PAttachmentEntry(
            id: newAttachmentId(),
            name: f.name,
            size: f.size,
            type: f.type,
            preview: f.preview,
            path: f.path,
          ),
      ]);
    }
    if (result.rejections.isNotEmpty) {
      widget.onFilesReject?.call(result.rejections);
    }
  }

  // ── 순서 · 메뉴 ──────────────────────────────────────────────
  void _moveTo(String id, int to) {
    final list = widget.entries;
    final from = list.indexWhere((e) => e.id == id);
    if (widget.onReorder == null ||
        from < 0 ||
        to < 0 ||
        to >= list.length ||
        from == to) {
      return;
    }
    final next = [...list];
    next.insert(to, next.removeAt(from));
    _movedId = id;
    _say(dsL(context)?.dsAttachMoved(to + 1) ?? '${to + 1}번째 자리로 옮겼어요.');
    widget.onReorder!(next);
  }

  void _remove(String id) {
    _removed = (id: id, index: widget.entries.indexWhere((e) => e.id == id));
    widget.onRemove(id);
  }

  bool get _menuAvailable =>
      !_disabled &&
      !_readOnly &&
      (widget.onReorder != null || widget.onPreview != null);

  Future<void> _openMenu(PAttachmentEntry entry, int index) async {
    final last = widget.entries.length - 1;
    final image = entry.isImage;
    final reorder = widget.onReorder != null;
    PMenuSheetItem line(
      String label,
      VoidCallback run, {
      bool enabled = true,
      PMenuSheetTone tone = PMenuSheetTone.neutral,
    }) => PMenuSheetItem(
      label: label,
      tone: tone,
      enabled: enabled,
      onSelect: run,
    );
    final top = [
      if (widget.onPreview != null)
        line(
          image
              ? (dsL(context)?.dsAttachPreviewImage ?? '크게 보기')
              : (dsL(context)?.dsAttachOpen ?? '열기'),
          () => widget.onPreview!(entry.id),
        ),
      if (reorder && image && widget.badgeLabel != null)
        line(
          dsL(context)?.dsAttachMakeCover ?? '대표로 정하기',
          () => _moveTo(entry.id, 0),
          enabled: index != 0,
        ),
      if (reorder) ...[
        line(
          dsL(context)?.dsAttachMoveForward ?? '앞으로 옮기기',
          () => _moveTo(entry.id, index - 1),
          enabled: index != 0,
        ),
        line(
          dsL(context)?.dsAttachMoveBack ?? '뒤로 옮기기',
          () => _moveTo(entry.id, index + 1),
          enabled: index != last,
        ),
      ],
    ];
    await PMenuSheet.show(
      context,
      title: entry.name,
      layout: PMenuSheetLayout.textOnly,
      groups: [
        if (top.isNotEmpty) PMenuSheetGroup(top),
        PMenuSheetGroup([
          line(
            dsL(context)?.dsInputClear ?? '지우기',
            () => _remove(entry.id),
            tone: PMenuSheetTone.critical,
          ),
        ]),
      ],
    );
  }

  /// 항목의 접근성 동작 — 앞으로 · 뒤로 옮기기(끌기 대신 — 순서를 바꿀 때) · 지우기. 끝에서는 그 방향이 없다.
  Map<CustomSemanticsAction, VoidCallback>? _itemActions(
    PAttachmentEntry entry,
    int index, {
    required bool menu,
  }) {
    if (!menu) return null;
    final last = widget.entries.length - 1;
    final reorder = widget.onReorder != null;
    return {
      if (reorder && index > 0)
        CustomSemanticsAction(
          label: dsL(context)?.dsAttachMoveForward ?? '앞으로 옮기기',
        ): () =>
            _moveTo(entry.id, index - 1),
      if (reorder && index < last)
        CustomSemanticsAction(
          label: dsL(context)?.dsAttachMoveBack ?? '뒤로 옮기기',
        ): () =>
            _moveTo(entry.id, index + 1),
      CustomSemanticsAction(label: dsL(context)?.dsInputClear ?? '지우기'): () =>
          _remove(entry.id),
    };
  }

  String _describe(
    BuildContext context,
    PAttachmentEntry e,
    PAttachmentStatus status,
    String? badge,
  ) {
    final parts = [e.name, formatFileSize(e.size)];
    if (badge != null) parts.add(badge);
    if (status == PAttachmentStatus.uploading) {
      final pct = formatProgress(
        e.progress == null ? 0 : e.progress!.clamp(0.0, 1.0) * 100,
      );
      parts.add(
        e.progress == null
            ? (dsL(context)?.dsAttachUploading ?? '올리는 중')
            : (dsL(context)?.dsAttachUploadingPercent(pct) ?? '올리는 중 $pct'),
      );
    }
    if (status == PAttachmentStatus.error) {
      parts.add(dsL(context)?.dsAttachUploadFailed ?? '올리지 못했어요');
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final field = PFieldScope.maybeOf(context)?.data;
    // × 의 누르는 자리가 들어갈 위 · 오른쪽 여백 16 — 글자 배율을 따른다(03-B 결정 3 A)
    final bleedPx = _Dims.of(context).touchBleed;
    final disabled = _disabled;
    final readOnly = _readOnly;
    final limited = widget.maxFiles < PAttachmentInput.unlimited;
    final entries = widget.entries;
    final failures = entries
        .where((e) => _statusOf(e) == PAttachmentStatus.error)
        .length;
    final firstImageId = widget.badgeLabel == null
        ? null
        : entries.where((e) => e.isImage).firstOrNull?.id;

    final slots = <Widget>[];
    final shown = _displayEntries;
    for (var position = 0; position < shown.length; position++) {
      final entry = shown[position];
      final i = entries.indexWhere((e) => e.id == entry.id);
      final status = _statusOf(entry);
      final badge = entry.id == firstImageId ? widget.badgeLabel : null;
      final menu = _menuAvailable && status != PAttachmentStatus.error;
      final VoidCallback? press = menu
          ? () => _openMenu(entry, i)
          : readOnly && !disabled && widget.onPreview != null
          ? () => widget.onPreview!(entry.id)
          : null;
      final last = position == shown.length - 1;
      final index = i;
      final canDrag =
          widget.onReorder != null &&
          !disabled &&
          !readOnly &&
          status != PAttachmentStatus.error &&
          widget.layout == PAttachmentLayout.tile;
      slots.add(
        KeyedSubtree(
          key: _slotKey(entry.id),
          child: _ItemSlot(
            key: ValueKey('attachment-item-${entry.id}'),
            entry: entry,
            status: status,
            description: _describe(context, entry, status, badge),
            readOnly: readOnly,
            disabled: disabled,
            badgeLabel: entry.isImage ? badge : null,
            rightBleed: last ? bleedPx : 0,
            onRemove: () => _remove(entry.id),
            onRetry: widget.onRetry == null
                ? null
                : () => widget.onRetry!(entry.id),
            onPress: press,
            itemNode: _itemNode(entry.id),
            removeNode: _removeNode(entry.id),
            canDrag: canDrag,
            dragging: _dragId == entry.id,
            onDragStart: (finger) => _startDrag(entry, finger),
            onDragMove: _moveDrag,
            onDragEnd: () => _endDrag(commit: true),
            onDragCancel: () => _endDrag(commit: false),
            customActions: _itemActions(entry, index, menu: menu),
          ),
        ),
      );
    }

    final label =
        widget.semanticLabel ??
        field?.label ??
        (dsL(context)?.dsAttachDefaultLabel ?? '파일');
    final count = limited ? '${entries.length}/${widget.maxFiles}' : null;
    final suffix = count == null
        ? (dsL(context)?.dsAttachSuffix ?? '첨부')
        : (dsL(context)?.dsAttachSuffixCount(count) ?? '첨부, $count');

    Widget body;
    if (widget.layout == PAttachmentLayout.dropzone) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: PSpacing.x2,
        children: [
          PButton(
            key: const ValueKey('attachment-pick'),
            label: dsL(context)?.dsAttachPickFiles ?? '파일 선택',
            variant: PButtonVariant.neutralWeak,
            size: PButtonSize.large,
            prefixIcon: LucideIcons.upload,
            onPressed: _blocked ? null : _openPicker,
          ),
          if (slots.isNotEmpty)
            _PullUp(
              pull: bleedPx,
              child: Padding(
                padding: const EdgeInsets.only(top: 0),
                child: _RemoveFirstScope(
                  child: Wrap(
                    spacing: PSpacing.x2,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: slots,
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      final trigger = Padding(
        padding: EdgeInsets.only(top: bleedPx),
        child: _TriggerTile(
          key: const ValueKey('attachment-trigger'),
          focusNode: _triggerNode,
          icon: attachmentAcceptsImages(widget.accept)
              ? LucideIcons.image
              : LucideIcons.paperclip,
          label: '$label $suffix',
          count: entries.length,
          max: limited ? widget.maxFiles : null,
          blocked: readOnly || _full,
          disabled: disabled,
          onTap: _openPicker,
        ),
      );
      final bleed = widget.bleed ?? field?.edgeInset ?? 0;
      Widget row = PScrollFogMask(
        axis: Axis.horizontal,
        child: SingleChildScrollView(
          key: _scrollKey,
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(
            left: bleed,
            right: (bleed - bleedPx).clamp(0, bleed),
          ),
          child: _RemoveFirstScope(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x2,
              children: [trigger, ...slots],
            ),
          ),
        ),
      );
      body = row;
    }

    final root = Semantics(
      container: true,
      label: widget.semanticLabel ?? field?.label,
      hint: [
        if (field?.message != null) field!.message!,
        if (failures > 0)
          (dsL(context)?.dsAttachFailedCount(failures) ??
              '$failures개는 올리지 못했어요'),
      ].join(' ').nullIfEmpty,
      enabled: !disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          body,
          // 붙음 · 올림 · 실패를 한 번씩 읽는다(polite)
          Semantics(
            container: true,
            liveRegion: true,
            label: _message,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
    // 항목 줄 위 16 은 × 의 누르는 자리 — 위에 라벨(머리)이 있으면 레이아웃에서 빼고(웹 -mt-x4) 그 자리의 누르기는 이 칸이 받는다.
    // 라벨이 없으면(라벨 없는 Field · 칸이 맨 위) 그 위에는 받아 줄 부모 자리가 없어 누르기가 잘린다 — 16 을 레이아웃에 남겨 둔다
    final pull = field?.label != null ? bleedPx : 0.0;
    return widget.layout == PAttachmentLayout.tile
        ? _PullUp(pull: pull, child: root)
        : root;
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
