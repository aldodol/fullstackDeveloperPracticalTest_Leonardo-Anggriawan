import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/goods_out.dart';
import '../providers/transaction_provider.dart';
import '../widgets/goods_out_form_dialog.dart';
import '../widgets/goods_return_form_dialog.dart';
import '../utils/theme.dart';

class GoodsOutScreen extends StatelessWidget {
  const GoodsOutScreen({super.key});

  void _showDetailDialog(BuildContext context, GoodsOut go) async {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    await txProvider.selectGoodsOutDetail(go.id);
    final detail = txProvider.selectedGoodsOut ?? go;

    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Barang Keluar: ${detail.transactionCode}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          dateFormat.format(detail.transactionDate),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Summary details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Departemen / Divisi:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            Text(detail.department, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Penerima / Pemohon:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            Text(detail.recipientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Volume:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            Text('${detail.totalQty} unit (${detail.totalItems} macam)', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (detail.notes != null && detail.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Catatan: ${detail.notes}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                ],
                const SizedBox(height: 18),

                const Text('Daftar Bahan Baku:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 10),

                // Items list table
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detail.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = detail.items[index];
                      return ListTile(
                        title: Text(item.materialName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                        subtitle: Text('${item.materialCode} • Dikembalikan: ${item.returnedQty} ${item.unit}'),
                        trailing: Text(
                          '${item.quantity} ${item.unit}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primaryDark),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!detail.isFullyReturned)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                        onPressed: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (_) => GoodsReturnFormDialog(initialGoodsOut: detail),
                          );
                        },
                        icon: const Icon(Icons.assignment_return_rounded, size: 16),
                        label: const Text('Proses Pengembalian'),
                      ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final goodsOutList = txProvider.goodsOutList;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaksi Barang Keluar',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kelola pengeluaran bahan baku untuk lantai produksi, proyek, dan divisi pemohon.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const GoodsOutFormDialog(),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Catat Barang Keluar'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari no transaksi, departemen, atau nama penerima...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                ),
                onChanged: (val) => txProvider.setGoodsOutSearch(val),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Transactions Table
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (txProvider.isLoading && goodsOutList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (goodsOutList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(50),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.output_rounded, size: 48, color: AppTheme.textSecondary),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada transaksi barang keluar.',
                            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      horizontalMargin: 24,
                      columnSpacing: 28,
                      columns: const [
                        DataColumn(label: Text('NO. TRANSAKSI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('TANGGAL & WAKTU', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('DEPARTEMEN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('PENERIMA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('TOTAL ITEM', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('TOTAL VOLUME', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('STATUS KEMBALI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('AKSI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      ],
                      rows: goodsOutList.map((go) {
                        final hasReturn = go.totalReturnedQty > 0;
                        final isFull = go.isFullyReturned;

                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  go.transactionCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryDark,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(dateFormat.format(go.transactionDate))),
                            DataCell(Text(go.department, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(go.recipientName)),
                            DataCell(Text('${go.totalItems} macam')),
                            DataCell(Text('${go.totalQty.toStringAsFixed(1)} unit', style: const TextStyle(fontWeight: FontWeight.w700))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isFull
                                      ? AppTheme.successLight
                                      : (hasReturn ? AppTheme.warningLight : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isFull
                                      ? 'Kembali Penuh'
                                      : (hasReturn ? 'Kembali Sebagian (${go.totalReturnedQty.toStringAsFixed(1)})' : 'Belum Kembali'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isFull
                                        ? AppTheme.success
                                        : (hasReturn ? AppTheme.warning : AppTheme.textSecondary),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 18),
                                    tooltip: 'Lihat Detail Item',
                                    color: AppTheme.primary,
                                    onPressed: () => _showDetailDialog(context, go),
                                  ),
                                  if (!isFull)
                                    IconButton(
                                      icon: const Icon(Icons.assignment_return_outlined, size: 18),
                                      tooltip: 'Pengembalian Barang',
                                      color: AppTheme.success,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => GoodsReturnFormDialog(initialGoodsOut: go),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
