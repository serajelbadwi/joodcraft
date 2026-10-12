/// إدارة الإعلانات المحلية للقرية: قائمة بحالتها الزمنية + إضافة وتعديل
/// وحذف، مع رفع الصورة إلى الدلو العام `village-ads` أثناء الحفظ.
///
/// الصورة تُرفع **عند الحفظ لا عند الاختيار**: إلغاء النافذة بعد اختيار
/// صورة لا يترك ملفاً مُرَفوعاً بلا إعلان يملكه.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/village_admin_repository.dart';
import '../../domain/google_drive_link.dart';
import '../../domain/village.dart';
import '../../domain/village_ad.dart';
import '../../domain/village_admin_text.dart';
import 'village_admin_direction.dart';
import 'village_admin_feedback.dart';

/// امتدادات الصور المقبولة في رفع إعلان.
const List<String> kAdImageExtensions = <String>[
  'png',
  'jpg',
  'jpeg',
  'webp',
  'gif',
];

class VillageAdsAdminScreen extends StatefulWidget {
  const VillageAdsAdminScreen({
    super.key,
    required this.repository,
    required this.village,
  });

  final VillageAdminRepository repository;
  final Village village;

  @override
  State<VillageAdsAdminScreen> createState() => _VillageAdsAdminScreenState();
}

class _VillageAdsAdminScreenState extends State<VillageAdsAdminScreen> {
  List<VillageAd>? _ads;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _ads = null;
    });
    try {
      final List<VillageAd> ads =
          await widget.repository.fetchAds(villageId: widget.village.id);
      if (!mounted) return;
      setState(() => _ads = ads);
    } catch (failure) {
      if (!mounted) return;
      setState(() => _error = adminErrorText(failure));
    }
  }

  Future<void> _edit({VillageAd? existing}) async {
    final VillageAd? saved = await showDialog<VillageAd>(
      context: context,
      // النافذة تُبنى فوق شجرة الـNavigator الجذرية فلا ترث اتجاه الشاشة.
      builder: (BuildContext dialogContext) => VillageAdminDirection(
        child: _AdDialog(
          repository: widget.repository,
          villageId: widget.village.id,
          existing: existing,
        ),
      ),
    );
    if (saved == null || !mounted) return;
    context.showSuccess(VillageAdminText.adSaved);
    await _load();
  }

  Future<void> _delete(VillageAd ad) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => VillageAdminDirection(
        child: AlertDialog(
          title: const Text(VillageAdminText.deleteAdTitle),
          content: const Text(VillageAdminText.deleteAdBody),
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
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.deleteAd(adId: ad.id);
      if (!mounted) return;
      context.showSuccess(VillageAdminText.adDeleted);
      await _load();
    } catch (failure) {
      if (!mounted) return;
      context.showAdminError(failure);
    }
  }

  @override
  Widget build(BuildContext context) => VillageAdminDirection(
    child: _buildContent(context),
  );

  /// محتوى الشاشة — يُغلَّف بـ[VillageAdminDirection] في [build].
  Widget _buildContent(BuildContext context) {
    final List<VillageAd>? ads = _ads;
    return Scaffold(
      appBar: AppBar(title: const Text(VillageAdminText.adsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey<String>('add-ad'),
        onPressed: ads == null ? null : () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(VillageAdminText.addAd),
      ),
      body: _buildBody(ads),
    );
  }

  Widget _buildBody(List<VillageAd>? ads) {
    if (ads == null) {
      final String? error = _error;
      if (error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline_rounded, size: 40),
                const SizedBox(height: AppTheme.space12),
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: AppTheme.space16),
                FilledButton.tonal(
                  onPressed: _load,
                  child: const Text(VillageAdminText.retry),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    if (ads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Text(
            VillageAdminText.adsEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final DateTime now = DateTime.now();
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
        itemCount: ads.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppTheme.space8),
        itemBuilder: (BuildContext context, int index) {
          final VillageAd ad = ads[index];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              key: ValueKey<String>('ad-${ad.id}'),
              leading: _AdThumb(imageUrl: ad.imageUrl),
              title: Text(ad.title),
              subtitle: Text(
                '${ad.statusLabel(now)}'
                '${ad.contactPhone == null ? '' : ' — ${ad.contactPhone}'}',
                style: const TextStyle(height: 1.5),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    key: ValueKey<String>('edit-ad-${ad.id}'),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: VillageAdminText.editAd,
                    onPressed: () => _edit(existing: ad),
                  ),
                  IconButton(
                    key: ValueKey<String>('delete-ad-${ad.id}'),
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: VillageAdminText.delete,
                    onPressed: () => _delete(ad),
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

/// مصغّرة الصورة في القائمة — أيقونة إن لم تُرفع صورة أو فشل تحميلها.
class _AdThumb extends StatelessWidget {
  const _AdThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl;
    if (url == null || url.isEmpty) {
      return const Icon(Icons.campaign_outlined);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? _) =>
            const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

/// نافذة إضافة/تعديل إعلان: عنوان + صورة + تواصل + نافذة سريان + تفعيل.
class _AdDialog extends StatefulWidget {
  const _AdDialog({
    required this.repository,
    required this.villageId,
    this.existing,
  });

  final VillageAdminRepository repository;
  final String villageId;
  final VillageAd? existing;

  @override
  State<_AdDialog> createState() => _AdDialogState();
}

class _AdDialogState extends State<_AdDialog> {
  late final TextEditingController _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _phoneController =
      TextEditingController(text: widget.existing?.contactPhone ?? '');
  late final TextEditingController _urlController =
      TextEditingController(text: widget.existing?.contactUrl ?? '');

  /// رابط الصورة المُلصوق (من Google Drive أو مباشر) — بديل اختيار ملف.
  late final TextEditingController _imageUrlController =
      TextEditingController(text: widget.existing?.imageUrl ?? '');

  late DateTime? _startsAt = widget.existing?.startsAt;
  late DateTime? _endsAt = widget.existing?.endsAt;
  late bool _isActive = widget.existing?.isActive ?? true;

  Uint8List? _pickedBytes;
  String? _pickedName;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _phoneController.dispose();
    _urlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: kAdImageExtensions,
      );
      if (files.isEmpty || !mounted) return;
      final PlatformFile file = files.first;
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _pickedName = file.name;
      });
    } on Object {
      if (!mounted) return;
      context.showError(VillageAdminText.adUploadFailed);
    }
  }

  Future<DateTime?> _pickDate(DateTime? current) async {
    final DateTime initial = current ?? DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      // المُنتقي يُبنى فوق شجرة الـNavigator الجذرية أيضاً.
      builder: (BuildContext dateContext, Widget? child) =>
          VillageAdminDirection(child: child ?? const SizedBox.shrink()),
    );
  }

  Future<void> _save() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = VillageAdminText.adTitleRequired);
      return;
    }
    // رابط مجلد ليس صورة — نمنع الحفظ برسالة توضيحية بدل تخزين رابط ميت
    // يفشل عرضه في الصفحة (لا يُفحص إلا حين لا صورة مُختارة).
    if (_pickedBytes == null &&
        isGoogleDriveFolderUrl(_imageUrlController.text)) {
      setState(() => _error = VillageAdminText.adImageFolderLink);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // (أ) الصورة: ملف مُختار ⇒ رفعه إلى الدلو العام؛ وإلا فالرابط المُلصوق
      //     (يُطبَّع: روابط Google Drive تتحول إلى صيغة صورة مباشرة).
      String? imageUrl;
      final Uint8List? bytes = _pickedBytes;
      if (bytes != null) {
        imageUrl = await widget.repository.uploadAdImage(
          villageId: widget.villageId,
          bytes: bytes,
          fileName: _pickedName ?? 'ad.png',
        );
      } else {
        imageUrl = normalizeGoogleDriveUrl(_imageUrlController.text);
      }
      final VillageAd saved = await widget.repository.saveAd(
        id: widget.existing?.id,
        villageId: widget.villageId,
        title: title,
        imageUrl: imageUrl,
        contactPhone: _phoneController.text,
        contactUrl: _urlController.text,
        startsAt: _startsAt,
        endsAt: _endsAt,
        isActive: _isActive,
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = adminErrorText(failure);
      });
    }
  }

  String _dateLabel(DateTime? at) {
    final DateTime? date = at;
    if (date == null) return '—';
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = _pickedBytes;
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? VillageAdminText.addAd
            : VillageAdminText.editAd,
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('ad-title'),
                controller: _titleController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: VillageAdminText.adTitleLabel,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              OutlinedButton.icon(
                key: const ValueKey<String>('ad-pick-image'),
                onPressed: _saving ? null : _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(_pickedName ?? VillageAdminText.adPickImage),
              ),
              if (bytes != null) ...<Widget>[
                const SizedBox(height: AppTheme.space12),
                SizedBox(
                  height: 120,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ],
              if (bytes == null) ...<Widget>[
                const SizedBox(height: AppTheme.space12),
                TextField(
                  key: const ValueKey<String>('ad-image-url'),
                  controller: _imageUrlController,
                  enabled: !_saving,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: VillageAdminText.adImageUrlLabel,
                    hintText: 'https://drive.google.com/file/d/…/view',
                    helperText: VillageAdminText.adImageUrlHint,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.space16),
              TextField(
                key: const ValueKey<String>('ad-phone'),
                controller: _phoneController,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: VillageAdminText.adPhoneLabel,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              TextField(
                key: const ValueKey<String>('ad-url'),
                controller: _urlController,
                enabled: !_saving,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: VillageAdminText.adUrlLabel,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${VillageAdminText.adStartLabel}: ${_dateLabel(_startsAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    key: const ValueKey<String>('ad-pick-start'),
                    onPressed: _saving
                        ? null
                        : () async {
                            final DateTime? picked = await _pickDate(_startsAt);
                            if (picked != null && mounted) {
                              setState(() => _startsAt = picked);
                            }
                          },
                    child: const Text('تغيير'),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${VillageAdminText.adEndLabel}: ${_dateLabel(_endsAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    key: const ValueKey<String>('ad-pick-end'),
                    onPressed: _saving
                        ? null
                        : () async {
                            final DateTime? picked = await _pickDate(_endsAt);
                            if (picked == null || !mounted) return;
                            setState(() => _endsAt = picked);
                          },
                    child: const Text('تغيير'),
                  ),
                ],
              ),
              SwitchListTile(
                key: const ValueKey<String>('ad-active'),
                contentPadding: EdgeInsets.zero,
                title: const Text(VillageAdminText.adActiveLabel),
                value: _isActive,
                onChanged: _saving
                    ? null
                    : (bool value) => setState(() => _isActive = value),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppTheme.space8),
                Text(
                  _error!,
                  key: const ValueKey<String>('ad-dialog-error'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text(VillageAdminText.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('ad-submit'),
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
