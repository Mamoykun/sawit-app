import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/diagnosa_model.dart';
import '../models/lahan_model.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';

class DiagnosaHistoryScreen extends StatefulWidget {
  final LahanModel lahan;
  const DiagnosaHistoryScreen({super.key, required this.lahan});

  @override
  State<DiagnosaHistoryScreen> createState() => _DiagnosaHistoryScreenState();
}

class _DiagnosaHistoryScreenState extends State<DiagnosaHistoryScreen> {
  List<DiagnosaModel>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService().getDiagnosaHistory(widget.lahan.id, limit: 30);
      if (mounted) setState(() { _data = list; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _data ??= []; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal memuat riwayat diagnosa'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Future<void> _openDetail(DiagnosaModel d) async {
    try {
      final detail = await ApiService().getDiagnosaDetail(widget.lahan.id, d.id);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DiagnosaDetailSheet(
          diagnosa: detail,
          onDelete: () async {
            Navigator.pop(context);
            await _confirmDelete(d);
          },
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal memuat detail diagnosa'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Future<void> _confirmDelete(DiagnosaModel d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Diagnosa'),
        content: const Text('Hapus catatan diagnosa ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService().deleteDiagnosa(widget.lahan.id, d.id);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menghapus diagnosa'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Riwayat Diagnosa',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final data = _data ?? [];
    if (data.isEmpty) {
      return EmptyState.icon(
        iconData: Icons.photo_camera_outlined,
        title: 'Belum Ada Diagnosa',
        message:
            'Foto daun, tandan, atau pohon yang bermasalah untuk dapat diagnosa AI.',
        accent: AppColors.accent,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: data.length,
        itemBuilder: (_, i) => _DiagnosaListItem(
          diagnosa: data[i],
          onTap: () => _openDetail(data[i]),
        ),
      ),
    );
  }
}

class _DiagnosaListItem extends StatelessWidget {
  final DiagnosaModel diagnosa;
  final VoidCallback onTap;

  const _DiagnosaListItem({required this.diagnosa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sevColor = _sevColor(diagnosa.severity);
    final dateStr = diagnosa.createdAt != null
        ? DateFormat('d MMM yyyy', 'id_ID').format(diagnosa.createdAt!)
        : '-';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_iconForJenis(diagnosa.jenis),
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(diagnosa.jenis.label,
                              style: AppTextStyles.body(14,
                                  color: AppColors.text,
                                  weight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: sevColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(diagnosa.severity.label,
                                style: AppTextStyles.body(10,
                                    color: sevColor,
                                    weight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        diagnosa.kondisi ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(dateStr,
                          style: AppTextStyles.body(11, color: AppColors.textLight)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagnosaDetailSheet extends StatelessWidget {
  final DiagnosaModel diagnosa;
  final VoidCallback onDelete;

  const _DiagnosaDetailSheet({required this.diagnosa, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final sevColor = _sevColor(diagnosa.severity);
    final dateStr = diagnosa.createdAt != null
        ? DateFormat('d MMMM yyyy · HH:mm', 'id_ID').format(diagnosa.createdAt!)
        : '-';
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(diagnosa.jenis.label,
                            style: AppTextStyles.display(22)),
                        Text(dateStr,
                            style: AppTextStyles.body(12,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sevColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: sevColor.withOpacity(0.3)),
                    ),
                    child: Text(diagnosa.severity.label,
                        style: AppTextStyles.body(11,
                            color: sevColor, weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (diagnosa.imageBase64 != null && diagnosa.imageBase64!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    base64Decode(diagnosa.imageBase64!),
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 18),
              if (diagnosa.kondisi != null && diagnosa.kondisi!.isNotEmpty)
                _DetailBlock(
                    title: 'KONDISI TERLIHAT',
                    body: diagnosa.kondisi!,
                    color: AppColors.primary),
              if (diagnosa.penyebab != null && diagnosa.penyebab!.isNotEmpty)
                _DetailBlock(
                    title: 'PENYEBAB',
                    body: diagnosa.penyebab!,
                    color: AppColors.gold),
              if (diagnosa.rekomendasi != null && diagnosa.rekomendasi!.isNotEmpty)
                _DetailBlock(
                    title: 'REKOMENDASI',
                    body: diagnosa.rekomendasi!,
                    color: AppColors.accent),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Text('Hapus Diagnosa',
                          style: AppTextStyles.body(13,
                              color: AppColors.danger,
                              weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  const _DetailBlock({required this.title, required this.body, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.body(11,
                      color: color, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(body, style: AppTextStyles.body(13, color: AppColors.text)),
            ],
          ),
        ),
      );
}

Color _sevColor(SeverityDiagnosa s) => switch (s) {
      SeverityDiagnosa.normal => AppColors.success,
      SeverityDiagnosa.perhatian => AppColors.gold,
      SeverityDiagnosa.kritis => AppColors.danger,
    };

IconData _iconForJenis(JenisDiagnosa j) => switch (j) {
      JenisDiagnosa.buah => Icons.eco_rounded,
      JenisDiagnosa.batang => Icons.park_rounded,
      JenisDiagnosa.pelepah => Icons.spa_rounded,
    };
