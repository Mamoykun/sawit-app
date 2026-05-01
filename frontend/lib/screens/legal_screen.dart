import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/legal_content.dart';

enum LegalTab { privacy, terms }

class LegalScreen extends StatefulWidget {
  final LegalTab initialTab;
  const LegalScreen({super.key, this.initialTab = LegalTab.privacy});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == LegalTab.privacy ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Kebijakan & Ketentuan',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.gold,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.body(13, weight: FontWeight.w700),
          unselectedLabelStyle: AppTextStyles.body(13),
          tabs: const [
            Tab(text: 'Privasi'),
            Tab(text: 'Syarat & Ketentuan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LegalContentList(sections: LegalContent.privacyPolicy),
          _LegalContentList(sections: LegalContent.termsOfService),
        ],
      ),
    );
  }
}

class _LegalContentList extends StatelessWidget {
  final List<LegalSection> sections;
  const _LegalContentList({required this.sections});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // Effective date banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: AppColors.primary3.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Versi ${LegalContent.version} · Berlaku sejak ${LegalContent.effectiveDate}',
                  style: AppTextStyles.body(12,
                      color: AppColors.primary, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...sections.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: AppTextStyles.display(15)),
                  const SizedBox(height: 8),
                  Text(
                    s.body,
                    style: AppTextStyles.body(13.5,
                        color: AppColors.textMid),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
