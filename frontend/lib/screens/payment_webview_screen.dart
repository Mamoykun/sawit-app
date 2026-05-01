import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/payment_model.dart';

/// Loads Midtrans Snap URL in a WebView.
/// Detects redirect to result URLs (`status_code=200/201` = success, `transaction_status=*`)
/// and pops with a [PaymentResult] enum.
class PaymentWebViewScreen extends StatefulWidget {
  final String snapUrl;
  final String orderId;
  const PaymentWebViewScreen({
    super.key,
    required this.snapUrl,
    required this.orderId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

enum PaymentResult { success, pending, failed, cancelled }

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (req) {
          // Midtrans Snap may redirect to success/error URLs with query params.
          final url = req.url.toLowerCase();
          if (url.contains('transaction_status=settlement') ||
              url.contains('transaction_status=capture')) {
            _checkAndPop();
            return NavigationDecision.prevent;
          }
          if (url.contains('transaction_status=pending')) {
            Navigator.pop(context, PaymentResult.pending);
            return NavigationDecision.prevent;
          }
          if (url.contains('transaction_status=deny') ||
              url.contains('transaction_status=cancel') ||
              url.contains('transaction_status=expire') ||
              url.contains('transaction_status=failure')) {
            Navigator.pop(context, PaymentResult.failed);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.snapUrl));
  }

  /// After Snap reports success, double-check via our backend before popping.
  Future<void> _checkAndPop() async {
    try {
      final p = await ApiService().getPaymentByOrderId(widget.orderId);
      if (!mounted) return;
      Navigator.pop(
        context,
        p.status == PaymentStatus.paid
            ? PaymentResult.success
            : PaymentResult.pending,
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context, PaymentResult.pending);
    }
  }

  Future<bool> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pembayaran?'),
        content: const Text(
            'Pembayaran belum selesai. Yakin keluar? Anda dapat melanjutkan dari menu Riwayat Pembayaran.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Lanjut Bayar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Keluar',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _confirmExit();
        if (shouldExit && mounted) {
          Navigator.pop(context, PaymentResult.cancelled);
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pembayaran',
              style: AppTextStyles.display(18, color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () async {
              if (await _confirmExit() && mounted) {
                Navigator.pop(context, PaymentResult.cancelled);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.primaryTint,
              ),
          ],
        ),
      ),
    );
  }
}
