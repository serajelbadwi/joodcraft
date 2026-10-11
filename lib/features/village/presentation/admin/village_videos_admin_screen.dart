/// إدارة فيديوهات القرية: قائمة كاملة (بما فيها المجدولة) + إضافة وتعديل
/// وحذف — الرابط يُحلَّج إلى `youtube_id` في اللحظة نفسها قبل الحفظ.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/village_admin_repository.dart';
import '../../data/village_repository.dart';
import '../../domain/village.dart';
import '../../domain/village_admin_text.dart';
import '../../domain/village_video.dart';
import 'village_admin_feedback.dart';

class VillageVideosAdminScreen extends StatefulWidget {
  const VillageVideosAdminScreen({
    super.key,
    required this.repository,
    required this.village,
  });

  final VillageAdminRepository repository;
  final Village village;

  @override
  State<VillageVideosAdminScreen> createState() =>
      _VillageVideosAdminScreenState();
}

class _VillageVideosAdminScreenState extends State<VillageVideosAdminScreen> {
  List<VillageVideo>? _videos;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _videos = null;
    });
    try {
      final List<VillageVideo> videos = await widget.repository.fetchVideos(
        villageId: widget.village.id,
      );
      if (!mounted) return;
      setState(() => _videos = videos);
    } catch (failure) {
      if (!mounted) return;
      setState(() => _error = adminErrorText(failure));
    }
  }

  Future<void> _edit({VillageVideo? existing}) async {
    final VillageVideo? saved = await showDialog<VillageVideo>(
      context: context,
      builder: (BuildContext dialogContext) => _VideoDialog(
        repository: widget.repository,
        villageId: widget.village.id,
        existing: existing,
      ),
    );
    if (saved == null || !mounted) return;
    context.showSuccess(VillageAdminText.videoSaved);
    await _load();
  }

  Future<void> _delete(VillageVideo video) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text(VillageAdminText.deleteVideoTitle),
        content: const Text(VillageAdminText.deleteVideoBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(VillageAdminText.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(VillageAdminText.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.deleteVideo(videoId: video.id);
      if (!mounted) return;
      context.showSuccess(VillageAdminText.videoDeleted);
      await _load();
    } catch (failure) {
      if (!mounted) return;
      context.showAdminError(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<VillageVideo>? videos = _videos;
    return Scaffold(
      appBar: AppBar(title: const Text(VillageAdminText.videosTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey<String>('add-video'),
        onPressed: videos == null ? null : () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(VillageAdminText.addVideo),
      ),
      body: _buildBody(videos),
    );
  }

  Widget _buildBody(List<VillageVideo>? videos) {
    if (videos == null) {
      final String? error = _error;
      if (error != null) {
        return _LoadError(message: error, onRetry: _load);
      }
      return const Center(child: CircularProgressIndicator());
    }
    if (videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Text(
            VillageAdminText.videosEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space16,
          AppTheme.space16,
          AppTheme.space16,
          AppTheme.space48,
        ),
        itemCount: videos.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppTheme.space8),
        itemBuilder: (BuildContext context, int index) {
          final VillageVideo video = videos[index];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              key: ValueKey<String>('video-${video.id}'),
              leading: Icon(
                video.isPublished
                    ? Icons.play_circle_outline_rounded
                    : Icons.schedule_rounded,
              ),
              title: Text(video.title),
              subtitle: Text(
                video.isPublished
                    ? video.youtubeId
                    : '${video.youtubeId} — ${VillageAdminText.videoScheduled}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(height: 1.5),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    key: ValueKey<String>('edit-video-${video.id}'),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: VillageAdminText.editVideo,
                    onPressed: () => _edit(existing: video),
                  ),
                  IconButton(
                    key: ValueKey<String>('delete-video-${video.id}'),
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: VillageAdminText.delete,
                    onPressed: () => _delete(video),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// حالة خطأ التحميل مع إعادة المحاولة.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, size: 40),
            const SizedBox(height: AppTheme.space12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.space16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text(VillageAdminText.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// نافذة إضافة/تعديل فيديو: عنوان + رابط (مع معاينة المعرّف) + وصف.
class _VideoDialog extends StatefulWidget {
  const _VideoDialog({
    required this.repository,
    required this.villageId,
    this.existing,
  });

  final VillageAdminRepository repository;
  final String villageId;
  final VillageVideo? existing;

  @override
  State<_VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<_VideoDialog> {
  late final TextEditingController _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _urlController =
      TextEditingController(text: widget.existing?.youtubeUrl ?? '');
  late final TextEditingController _descController =
      TextEditingController(text: widget.existing?.description ?? '');

  String? _extractedId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _extractedId = VillageYoutube.idFromUrl(_urlController.text);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String title = _titleController.text.trim();
    final String url = _urlController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = VillageAdminText.videoTitleRequired);
      return;
    }
    final String? extracted = VillageYoutube.idFromUrl(url);
    if (extracted == null) {
      setState(() => _error = VillageAdminText.videoIdMissing);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final VillageVideo saved = await widget.repository.saveVideo(
        id: widget.existing?.id,
        villageId: widget.villageId,
        title: title,
        youtubeUrl: url,
        description: _descController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on VillageException catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? extracted = _extractedId;
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? VillageAdminText.addVideo
            : VillageAdminText.editVideo,
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>('video-title'),
              controller: _titleController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: VillageAdminText.videoTitleLabel,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            TextField(
              key: const ValueKey<String>('video-url'),
              controller: _urlController,
              enabled: !_saving,
              textDirection: TextDirection.ltr,
              onChanged: (String value) => setState(
                () => _extractedId = VillageYoutube.idFromUrl(value),
              ),
              decoration: const InputDecoration(
                labelText: VillageAdminText.videoUrlLabel,
                hintText: 'https://youtu.be/…',
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              extracted == null
                  ? VillageAdminText.videoUrlHint
                  : VillageAdminText.videoIdDetected(extracted),
              key: const ValueKey<String>('video-id-preview'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: extracted == null
                        ? null
                        : Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: AppTheme.space16),
            TextField(
              key: const ValueKey<String>('video-description'),
              controller: _descController,
              enabled: !_saving,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: VillageAdminText.videoDescLabel,
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppTheme.space12),
              Text(
                _error!,
                key: const ValueKey<String>('video-dialog-error'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text(VillageAdminText.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('video-submit'),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(VillageAdminText.save),
        ),
      ],
    );
  }
}
