import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import 'package:groo_damda_app/features/file/application/file_providers.dart';
import 'package:groo_damda_app/features/file/domain/file_attachment.dart';
import 'package:groo_damda_app/shared/widgets/p_progress.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 첨부 파일 섹션 — 거래/할일/메모/이벤트 상세에 embed.
///
/// `referenceType` 은 백엔드 enum: EXPENSE/TODO/MEMO/CALENDAR_EVENT.
/// `referenceRowId` 는 해당 entity 의 rowId. (entity 신규 생성 직후 호출 권장)
class FileAttachmentSection extends ConsumerStatefulWidget {
  const FileAttachmentSection({
    super.key,
    required this.referenceType,
    required this.referenceRowId,
  });

  final String referenceType;
  final int referenceRowId;

  @override
  ConsumerState<FileAttachmentSection> createState() =>
      _FileAttachmentSectionState();
}

class _FileAttachmentSectionState extends ConsumerState<FileAttachmentSection> {
  bool _busy = false;

  FileRefKey get _key => (
    referenceType: widget.referenceType,
    referenceRowId: widget.referenceRowId,
  );

  Future<void> _pickImage() async {
    if (_busy) return;
    final pickr = ImagePicker();
    final picked = await pickr.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _upload(picked.path, picked.name);
  }

  Future<void> _pickCamera() async {
    if (_busy) return;
    final pickr = ImagePicker();
    final picked = await pickr.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    await _upload(picked.path, picked.name);
  }

  Future<void> _pickFile() async {
    if (_busy) return;
    final picked = await FilePicker.platform.pickFiles();
    if (picked == null || picked.files.isEmpty) return;
    final f = picked.files.first;
    if (f.path == null) return;
    await _upload(f.path!, f.name);
  }

  Future<void> _upload(String path, String name) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final repo = await ref.read(fileRepositoryProvider.future);
      await repo.upload(
        filePath: path,
        fileName: name,
        referenceType: widget.referenceType,
        referenceRowId: widget.referenceRowId,
        silent: true,
      );
      ref.invalidate(filesByReferenceProvider(_key));
      if (!mounted) return;
      PSnackbar.maybeOf(context)?.show(message: l.fileUploadComplete(name));
    } on ApiException {
      // 서버 글은 내지 않는다(요청은 silent) — 고정 글 한 문장 + [다시 시도]
      if (!mounted) return;
      PSnackbar.maybeOf(context)?.show(
        message: l.fileUploadFailed,
        tone: PSnackbarTone.critical,
        action: PSnackbarAction(
          label: l.actionRetry,
          onPressed: () => _upload(path, name),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(FileAttachment f) async {
    final l = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    setState(() => _busy = true);
    try {
      // 확인창 뒤 실패는 공용 [askConfirmThenRequest] — critical 스낵바 + [다시 시도].
      final ok = await askConfirmThenRequest(
        context,
        title: l.fileDeleteTitle,
        description: l.fileDeleteConfirm(f.originalName),
        actionLabel: l.actionDelete,
        cancelLabel: l.actionCancel,
        request: () async {
          final repo = await container.read(fileRepositoryProvider.future);
          await repo.delete(f.rowId, silent: true);
        },
        failedMessage: l.fileDeleteFailed,
        retryLabel: l.actionRetry,
        onRetried: () => container.invalidate(filesByReferenceProvider(_key)),
        kind: WriteKind.delete,
        onUnconfirmed: () =>
            container.invalidate(filesByReferenceProvider(_key)),
      );
      if (ok) container.invalidate(filesByReferenceProvider(_key));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _humanSize(int? size) {
    if (size == null) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final async = ref.watch(filesByReferenceProvider(_key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.paperclip, size: 14, color: t.fgSecondary),
            const SizedBox(width: 6),
            Text(
              l.fileAttachTitle,
              style: PTypo.caption.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
            const Spacer(),
            PButton.icon(
              icon: LucideIcons.image,
              size: PButtonSize.sm,
              tooltip: l.fileTooltipGallery,
              onPressed: _busy ? null : _pickImage,
            ),
            PButton.icon(
              icon: LucideIcons.camera,
              size: PButtonSize.sm,
              tooltip: l.fileTooltipCamera,
              onPressed: _busy ? null : _pickCamera,
            ),
            PButton.icon(
              icon: LucideIcons.file,
              size: PButtonSize.sm,
              tooltip: l.fileTooltipFile,
              onPressed: _busy ? null : _pickFile,
            ),
          ],
        ),
        const SizedBox(height: 6),
        async.when(
          // 받아 둔 값이 있으면 다시 받기 실패에도 내용을 그린다 — 실패 화면은 값이 없을 때만(검수 M2, result-section.md:53)
          skipError: true,
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: PCircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            l.fileLoadError,
            style: PTypo.caption.copyWith(color: t.statusDangerFg),
          ),
          data: (files) {
            if (files.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  l.fileEmpty,
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                ),
              );
            }
            return Column(
              children: [
                for (final f in files)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: t.bgSurface,
                      borderRadius: PRadius.brSm,
                      border: Border.all(color: t.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          f.isImage ? LucideIcons.image : LucideIcons.fileText,
                          size: 14,
                          color: t.fgSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.originalName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PTypo.caption.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: PFontWeight.semi,
                                ),
                              ),
                              if ((f.fileSize ?? 0) > 0)
                                Text(
                                  _humanSize(f.fileSize),
                                  style: PTypo.micro.copyWith(
                                    color: t.fgTertiary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        PButton.icon(
                          tooltip: AppLocalizations.of(context).actionClose,
                          icon: LucideIcons.x,
                          size: PButtonSize.sm,
                          iconColor: t.fgTertiary,
                          onPressed: _busy ? null : () => _delete(f),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
