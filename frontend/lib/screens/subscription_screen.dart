import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/payment_model.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import 'payment_webview_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _currentPaket = 'GRATIS';
  int _months = 1;
  bool _processing = false;
  List<PaymentModel>? _history;

  @override
  void initState() {
    super.initState();
    _loadCurrentPaket();
    _loadHistory();
  }

  Future<void> _loadCurrentPaket() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _currentPaket = prefs.getString('user_paket') ?? 'GRATIS');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final list = await ApiService().getMyPayments();
      if (mounted) setState(() => _history = list);
    } catch (_) {}
  }

  Future<void> _upgrade(PricingTier tier) async {
    if (tier.code == 'GRATIS') return;
    if (tier.code == _currentPaket) {
      _showSnack('Anda sudah menggunakan paket ${tier.name}', isError: false);
      return;
    }

    setState(() => _processing = true);
    try {
      final payment = await ApiService().createPayment(
        targetPaket: tier.code,
        durationMonths: _months,
      );

      if (payment.snapUrl == null) {
        throw Exception('SNAP_URL_MISSING');
      }

      if (!mounted) return;
      final result = await Navigator.push<PaymentResult>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            snapUrl: payment.snapUrl!,
            orderId: payment.orderId,
          ),
        ),
      );

      if (!mounted) return;
      _handlePaymentResult(result, tier);
    } catch (e) {
      if (mounted) {
        _showSnack(_parseError(e.toString()), isError: true);
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _handlePaymentResult(PaymentResult? result, PricingTier tier) {
    switch (result) {
      case PaymentResult.success:
        _showSuccessDialog(tier);
        // Update local cache
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('user_paket', tier.code);
        });
        setState(() => _currentPaket = tier.code);
        break;
      case PaymentResult.pending:
        _showSnack(
            'Pembayaran sedang diproses. Cek riwayat untuk update status.',
            isError: false);
        break;
      case PaymentResult.failed:
        _showSnack('Pembayaran gagal. Coba lagi atau pakai metode lain.',
            isError: true);
        break;
      case PaymentResult.cancelled:
      case null:
        _showSnack('Pembayaran dibatalkan', isError: false);
        break;
    }
    _loadHistory();
  }

  void _showSuccessDialog(PricingTier tier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Pembayaran Berhasil!',
                  style: AppTextStyles.display(16,
                      color: AppColors.success)),
            ),
          ],
        ),
        content: Text(
          'Selamat! Paket ${tier.name} aktif selama $_months bulan. '
          'Nikmati semua fitur premium SawitKu.',
          style: AppTextStyles.body(13, color: AppColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }

  String _parseError(String s) {
    final m = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(s);
    if (m != null) return m.group(1)!;
    if (s.contains('PAYMENT_NOT_CONFIGURED')) {
      return 'Gateway pembayaran belum aktif. Hubungi support.';
    }
    return 'Gagal membuat pembayaran. Coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Upgrade Paket',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Riwayat Pembayaran',
            onPressed: () => _showHistorySheet(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current plan card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: AppColors.primary3.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PAKET AKTIF',
                            style: AppTextStyles.label(
                                color: AppColors.primary)),
                        const SizedBox(height: 2),
                        Text(_currentPaket,
                            style: AppTextStyles.display(20,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Duration selector
            Text('DURASI', style: AppTextStyles.label()),
            const SizedBox(height: 8),
            Row(
              children: [1, 3, 6, 12].map((m) {
                final isSel = _months == m;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _months = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$m bulan',
                            style: AppTextStyles.body(13,
                                color: isSel
                                    ? Colors.white
                                    : AppColors.textMid,
                                weight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Pricing tiers
            Text('PILIH PAKET', style: AppTextStyles.label()),
            const SizedBox(height: 12),
            ...PricingTier.all.map((tier) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TierCard(
                    tier: tier,
                    months: _months,
                    isCurrent: tier.code == _currentPaket,
                    processing: _processing,
                    onSelect: () => _upgrade(tier),
                  ),
                )),

            const SizedBox(height: 16),
            // Trust signals
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pembayaran aman via Midtrans. '
                      'Mendukung bank transfer, e-wallet (GoPay, OVO, DANA), kartu kredit.',
                      style: AppTextStyles.body(11,
                          color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
              const SizedBox(height: 14),
              Text('Riwayat Pembayaran',
                  style: AppTextStyles.display(20)),
              const SizedBox(height: 16),
              Expanded(
                child: (_history == null || _history!.isEmpty)
                    ? Center(
                        child: Text('Belum ada riwayat pembayaran',
                            style: AppTextStyles.body(13,
                                color: AppColors.textMuted)),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: _history!.length,
                        itemBuilder: (_, i) =>
                            _PaymentHistoryItem(payment: _history![i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatRp(num n) {
  return NumberFormat.currency(
          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
      .format(n);
}

class _TierCard extends StatelessWidget {
  final PricingTier tier;
  final int months;
  final bool isCurrent;
  final bool processing;
  final VoidCallback onSelect;

  const _TierCard({
    required this.tier,
    required this.months,
    required this.isCurrent,
    required this.processing,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final total = tier.monthlyPriceIDR * months;
    final isFree = tier.code == 'GRATIS';
    final accent = tier.highlight ? AppColors.gold : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: tier.highlight
              ? AppColors.gold
              : isCurrent
                  ? AppColors.primary
                  : AppColors.border,
          width: tier.highlight || isCurrent ? 1.5 : 1,
        ),
        boxShadow: tier.highlight
            ? [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tier.highlight)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
              ),
              child: Center(
                child: Text('PALING POPULER',
                    style: AppTextStyles.label(color: Colors.white)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tier.name,
                        style: AppTextStyles.display(22, color: accent)),
                    const SizedBox(width: 8),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('AKTIF',
                            style: AppTextStyles.body(9,
                                color: Colors.white,
                                weight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (isFree)
                  Text('Gratis selamanya',
                      style: AppTextStyles.body(13,
                          color: AppColors.textMuted))
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatRp(tier.monthlyPriceIDR),
                          style: AppTextStyles.mono(22,
                              color: accent,
                              weight: FontWeight.w700)),
                      Text(' /bulan',
                          style: AppTextStyles.body(12,
                              color: AppColors.textMuted)),
                    ],
                  ),
                if (!isFree && months > 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Total $months bulan: ${_formatRp(total)}',
                    style: AppTextStyles.body(11,
                        color: AppColors.textMuted,
                        weight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 14),
                ...tier.features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 16, color: accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(f,
                                style: AppTextStyles.body(12.5,
                                    color: AppColors.textMid)),
                          ),
                        ],
                      ),
                    )),
                if (!isFree) ...[
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: isCurrent
                        ? 'Paket Anda Saat Ini'
                        : 'Upgrade ke ${tier.name}',
                    icon: isCurrent
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    onTap: (isCurrent || processing) ? null : onSelect,
                    loading: processing,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryItem extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentHistoryItem({required this.payment});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(payment.status);
    final dateStr = payment.createdAt != null
        ? DateFormat('d MMM yyyy · HH:mm', 'id_ID').format(payment.createdAt!)
        : '-';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_statusIcon(payment.status), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${payment.targetPaket} · ${payment.durationMonths} bulan',
                    style: AppTextStyles.body(13,
                        color: AppColors.text, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(dateStr,
                    style:
                        AppTextStyles.body(11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatRp(payment.grossAmount),
                  style: AppTextStyles.mono(13,
                      color: AppColors.text, weight: FontWeight.w700)),
              Text(payment.status.label,
                  style: AppTextStyles.body(10,
                      color: color, weight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(PaymentStatus s) => switch (s) {
        PaymentStatus.paid => AppColors.success,
        PaymentStatus.pending => AppColors.gold,
        PaymentStatus.failed => AppColors.danger,
        PaymentStatus.expired => AppColors.textMuted,
        PaymentStatus.cancelled => AppColors.textMuted,
      };

  IconData _statusIcon(PaymentStatus s) => switch (s) {
        PaymentStatus.paid => Icons.check_circle_rounded,
        PaymentStatus.pending => Icons.hourglass_top_rounded,
        PaymentStatus.failed => Icons.error_rounded,
        PaymentStatus.expired => Icons.schedule_rounded,
        PaymentStatus.cancelled => Icons.cancel_rounded,
      };
}
