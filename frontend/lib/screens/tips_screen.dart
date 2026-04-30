import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/tips_data.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TipsData.kategori.length,
      vsync: this,
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
        title: Text('Info & Tips Sawit',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFFD97706),
          indicatorWeight: 3,
          labelStyle: AppTextStyles.body(13, weight: FontWeight.w700),
          unselectedLabelStyle: AppTextStyles.body(13),
          tabs: TipsData.kategori
              .map((k) => Tab(text: k.nama))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: TipsData.kategori
            .map((k) => _TipsListView(items: k.items))
            .toList(),
      ),
    );
  }
}

class _TipsListView extends StatelessWidget {
  final List<TipItem> items;
  const _TipsListView({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: items.length,
      itemBuilder: (_, i) => _TipCard(item: items[i], index: i + 1),
    );
  }
}

class _TipCard extends StatefulWidget {
  final TipItem item;
  final int index;
  const _TipCard({required this.item, required this.index});

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _expanded
                    ? const Color(0xFFD97706).withOpacity(0.3)
                    : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(widget.index.toString(),
                            style: AppTextStyles.body(13,
                                color: const Color(0xFFD97706),
                                weight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(widget.item.judul,
                          style: AppTextStyles.body(14,
                              color: AppColors.text,
                              weight: FontWeight.w700)),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more_rounded,
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 14),
                  ...widget.item.poin.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Icon(Icons.fiber_manual_record,
                                  size: 6, color: Color(0xFFD97706)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(p,
                                  style: AppTextStyles.body(13,
                                      color: AppColors.textMid)),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
