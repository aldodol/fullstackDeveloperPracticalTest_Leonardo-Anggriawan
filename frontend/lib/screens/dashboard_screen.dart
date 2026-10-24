import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../providers/app_provider.dart';
import '../providers/material_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/goods_out_form_dialog.dart';
import '../widgets/goods_return_form_dialog.dart';
import '../utils/theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final overview = stockProvider.overview;

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return RefreshIndicator(
      onRefresh: () => stockProvider.refreshAll(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header & Quick Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Sistem & Stok Gudang',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Monitoring real-time ketersediaan bahan baku dan aktivitas transaksi.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const GoodsOutFormDialog(),
                        );
                      },
                      icon: const Icon(Icons.output_rounded, size: 18),
                      label: const Text('Barang Keluar'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const GoodsReturnFormDialog(),
                        );
                      },
                      icon: const Icon(Icons.assignment_return_rounded, size: 18),
                      label: const Text('Pengembalian'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (stockProvider.isLoading && overview == null) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (overview != null) ...[
              // KPI Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 4;
                  if (constraints.maxWidth < 700) {
                    crossAxisCount = 1;
                  } else if (constraints.maxWidth < 1100) {
                    crossAxisCount = 2;
                  }

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.1,
                    children: [
                      MetricCard(
                        title: 'TOTAL BAHAN BAKU',
                        value: '${overview.totalMaterials} Item',
                        subtitle: '${overview.activeMaterials} aktif dalam katalog',
                        icon: Icons.inventory_2_rounded,
                        color: AppTheme.info,
                        onTap: () => appProvider.setScreenIndex(1),
                      ),
                      MetricCard(
                        title: 'STOK RENDAH (WARNING)',
                        value: '${overview.lowStockMaterials} Item',
                        subtitle: 'Di bawah batas minimum safety stock',
                        icon: Icons.warning_amber_rounded,
                        color: AppTheme.warning,
                        onTap: () {
                          Provider.of<MaterialProvider>(context, listen: false).setStockStatusFilter('low_stock');
                          appProvider.setScreenIndex(1);
                        },
                      ),
                      MetricCard(
                        title: 'TOTAL BARANG KELUAR',
                        value: '${overview.totalGoodsOutCount} Transaksi',
                        subtitle: 'Total volume: ${overview.totalGoodsOutQty.toStringAsFixed(1)} unit',
                        icon: Icons.output_rounded,
                        color: AppTheme.primary,
                        onTap: () => appProvider.setScreenIndex(2),
                      ),
                      MetricCard(
                        title: 'TOTAL PENGEMBALIAN',
                        value: '${overview.totalReturnsCount} Transaksi',
                        subtitle: 'Total volume: ${overview.totalReturnsQty.toStringAsFixed(1)} unit',
                        icon: Icons.assignment_return_rounded,
                        color: AppTheme.success,
                        onTap: () => appProvider.setScreenIndex(3),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Two Column Dashboard Content: Low Stock Alerts + Recent Movements
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1000;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Urgent Low Stock Alert Card
                      Expanded(
                        flex: isWide ? 6 : 0,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.warningLight,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.notification_important_rounded,
                                            color: AppTheme.warning,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Peringatan Stok Kritis & Rendah',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Provider.of<MaterialProvider>(context, listen: false)
                                            .setStockStatusFilter('low_stock');
                                        appProvider.setScreenIndex(1);
                                      },
                                      child: const Text('Lihat Semua'),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                if (overview.lowStockList.isEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 40),
                                          SizedBox(height: 10),
                                          Text(
                                            'Semua bahan baku berada di atas batas safety stock.',
                                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: overview.lowStockList.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = overview.lowStockList[index];
                                      final isZero = item.currentStock <= 0;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isZero ? AppTheme.dangerLight : AppTheme.warningLight,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isZero ? Icons.warning_rounded : Icons.priority_high_rounded,
                                                color: isZero ? AppTheme.danger : AppTheme.warning,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13.5,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${item.code} • Kategori: ${item.categoryName}',
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                    color: isZero ? AppTheme.danger : AppTheme.warning,
                                                  ),
                                                ),
                                                Text(
                                                  'Min: ${item.minStock.toStringAsFixed(0)} ${item.unit}',
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),

                      // Right Column: Recent Stock Movements Ledger
                      Expanded(
                        flex: isWide ? 5 : 0,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryLight,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.history_rounded,
                                            color: AppTheme.primary,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Riwayat Pergerakan Stok Terkini',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () => appProvider.setScreenIndex(4),
                                      child: const Text('Buku Stok'),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                if (overview.recentMovements.isEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: Center(
                                      child: Text(
                                        'Belum ada aktivitas transaksi stok.',
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: overview.recentMovements.length.clamp(0, 6),
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final mov = overview.recentMovements[index];
                                      final isNeg = mov.isOutgoing;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                color: isNeg ? AppTheme.dangerLight : AppTheme.successLight,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                isNeg ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                                color: isNeg ? AppTheme.danger : AppTheme.success,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    mov.materialName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    dateFormat.format(mov.createdAt),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${isNeg ? '' : '+'}${mov.quantity.toStringAsFixed(1)} ${mov.unit}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                                color: isNeg ? AppTheme.danger : AppTheme.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
