import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../models/lahan_photo_model.dart';
import '../services/api_service.dart';

class PhotoProgressScreen extends StatefulWidget {
  final LahanModel lahan;

  const PhotoProgressScreen({super.key, required this.lahan});

  @override
  State<PhotoProgressScreen> createState() => _PhotoProgressScreenState();
}

class _PhotoProgressScreenState extends State<PhotoProgressScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  List<LahanPhotoModel> _photos = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getLahanPhotos(widget.lahan.id);
      setState(() {
        _photos = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat foto: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showPickerSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Tambah Foto',
                  style: AppTextStyles.display(16, color: AppColors.text)),
              const SizedBox(height: 16),
              _PickerOption(
                icon: Icons.camera_alt_rounded,
                label: 'Ambil Foto',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              _PickerOption(
                icon: Icons.photo_library_rounded,
                label: 'Pilih dari Galeri',
                color: AppColors.gold,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      if (mounted) {
        await _showUploadSheet(bytes, xfile.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  Future<void> _showUploadSheet(Uint8List bytes, String filename) async {
    final captionCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Upload Foto Progress',
                  style: AppTextStyles.display(16, color: AppColors.text)),
              const SizedBox(height: 16),
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  bytes,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: captionCtrl,
                decoration: InputDecoration(
                  hintText: 'Keterangan foto (opsional)',
                  hintStyle:
                      AppTextStyles.body(13, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () async {
                          setSheetState(() {});
                          Navigator.pop(ctx);
                          await _upload(
                            bytes,
                            filename,
                            captionCtrl.text.trim(),
                          );
                        },
                  icon: _uploading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_rounded),
                  label:
                      Text(_uploading ? 'Mengupload...' : 'Upload Foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _upload(
      Uint8List bytes, String filename, String caption) async {
    setState(() => _uploading = true);
    try {
      await _api.uploadLahanPhoto(
        widget.lahan.id,
        imageBytes: bytes,
        filename: filename.endsWith('.jpg') ||
                filename.endsWith('.jpeg') ||
                filename.endsWith('.png')
            ? filename
            : '$filename.jpg',
        caption: caption.isNotEmpty ? caption : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto berhasil diupload'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadPhotos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('SocketException') ||
                    e.toString().contains('DioException')
                ? 'Butuh koneksi internet untuk upload foto'
                : 'Upload gagal: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _confirmDelete(LahanPhotoModel photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Foto?',
            style: AppTextStyles.display(16, color: AppColors.text)),
        content: Text(
          'Foto ini akan dihapus secara permanen.',
          style: AppTextStyles.body(13, color: AppColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _api.deleteLahanPhoto(widget.lahan.id, photo.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto berhasil dihapus'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await _loadPhotos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus foto: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  // ── Timeline grouping ────────────────────────────────────────────────────

  Map<String, List<LahanPhotoModel>> _groupByMonth(List<LahanPhotoModel> photos) {
    final map = <String, List<LahanPhotoModel>>{};
    for (final p in photos) {
      final key = p.bulan != null && p.tahun != null
          ? '${p.bulan} ${p.tahun}'
          : '${p.takenAt.month}/${p.takenAt.year}';
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_photos.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            _buildTimeline(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading ? null : _showPickerSheet,
        backgroundColor: const Color(0xFFEC4899),
        child: _uploading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.camera_alt_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: BackButton(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Foto Progress',
              style: AppTextStyles.display(18, color: Colors.white),
            ),
            Text(
              widget.lahan.namaLahan,
              style: AppTextStyles.body(11, color: Colors.white70),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primary2, Color(0xFF1A5C40)],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadPhotos,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.photo_library_rounded,
                  color: Color(0xFFEC4899), size: 40),
            ),
            const SizedBox(height: 20),
            Text('Belum Ada Foto',
                style: AppTextStyles.display(18, color: AppColors.text)),
            const SizedBox(height: 8),
            Text(
              'Mulai dokumentasi kebun Anda\ndengan foto rutin setiap bulan',
              style: AppTextStyles.body(13, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showPickerSheet,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Ambil Foto Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final grouped = _groupByMonth(_photos);

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final keys = grouped.keys.toList();
            if (i >= keys.length) return null;
            final key = keys[i];
            final photos = grouped[key]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month header
                Padding(
                  padding: EdgeInsets.only(bottom: 10, top: i > 0 ? 16 : 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primary2],
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '$key (${photos.length} foto)',
                          style: AppTextStyles.body(12,
                              color: Colors.white, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                // 3-column grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (ctx, j) => _PhotoThumbnail(
                    photo: photos[j],
                    onTap: () => _openViewer(photos, j),
                  ),
                ),
              ],
            );
          },
          childCount: grouped.keys.length,
        ),
      ),
    );
  }

  void _openViewer(List<LahanPhotoModel> photos, int initialIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => _PhotoViewerSheet(
        photos: photos,
        initialIndex: initialIndex,
        onDelete: (photo) async {
          Navigator.pop(context);
          await _confirmDelete(photo);
        },
      ),
    );
  }
}

// ── Thumbnail ─────────────────────────────────────────────────────────────────

class _PhotoThumbnail extends StatelessWidget {
  final LahanPhotoModel photo;
  final VoidCallback onTap;

  const _PhotoThumbnail({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          photo.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  color: AppColors.border,
                  child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.surfaceAlt,
            child: const Icon(Icons.broken_image_rounded,
                color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

// ── Photo viewer sheet ────────────────────────────────────────────────────────

class _PhotoViewerSheet extends StatefulWidget {
  final List<LahanPhotoModel> photos;
  final int initialIndex;
  final ValueChanged<LahanPhotoModel> onDelete;

  const _PhotoViewerSheet({
    required this.photos,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_PhotoViewerSheet> createState() => _PhotoViewerSheetState();
}

class _PhotoViewerSheetState extends State<_PhotoViewerSheet> {
  late PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_current];
    final dateStr =
        '${photo.takenAt.day.toString().padLeft(2, '0')}/${photo.takenAt.month.toString().padLeft(2, '0')}/${photo.takenAt.year}';

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.caption ?? 'Foto Progress',
                        style: AppTextStyles.body(15,
                            color: Colors.white, weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateStr,
                        style: AppTextStyles.body(12,
                            color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                // Page indicator
                Text(
                  '${_current + 1}/${widget.photos.length}',
                  style: AppTextStyles.mono(12, color: Colors.white60),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFFCA5A5)),
                  onPressed: () => widget.onDelete(photo),
                  tooltip: 'Hapus foto',
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Full image
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                final p = widget.photos[i];
                return InteractiveViewer(
                  child: Image.network(
                    p.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) =>
                        progress == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white)),
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.white54, size: 48),
                    ),
                  ),
                );
              },
            ),
          ),
          // Caption if present
          if (photo.caption != null && photo.caption!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  photo.caption!,
                  style: AppTextStyles.body(13, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ] else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Picker option ─────────────────────────────────────────────────────────────

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Text(label,
                  style: AppTextStyles.body(14,
                      color: AppColors.text, weight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      );
}
