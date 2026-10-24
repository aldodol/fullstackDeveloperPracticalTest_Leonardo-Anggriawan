import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/goods_return.dart';
import '../providers/transaction_provider.dart';
import '../widgets/goods_return_form_dialog.dart';
import '../utils/theme.dart';

class GoodsReturnScreen extends StatelessWidget {
  const GoodsReturnScreen({super.key});

  void _showDetailDialog(BuildContext context, GoodsReturn gr) async {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    await txProvider.selectGoodsReturnDetail(gr.id);
    final detail = txProvider.selectedGoodsReturn ?? gr;

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
                          'Detail Pengembalian: ${detail.returnCode}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          dateFormat.format(detail.returnDate),
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
                    color: AppTheme.successLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pengembali & Dept:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            Text('${detail.returnerName} (${detail.department})', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Alasan Pengembalian:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            Text(detail.reason, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ref Barang Keluar:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            Text(detail.goodsOutCode ?? 'Tanpa Referensi', style: const TextStyle(fontWeight: FontWeight.w700)),
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

                const Text('Daftar Bahan Baku yang Dikembalikan:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
                      final isGood = item.isGood;

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isGood ? AppTheme.successLight : AppTheme.dangerLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isGood ? Icons.check_circle_outline_rounded : Icons.broken_image_outlined,
                            color: isGood ? AppTheme.success : AppTheme.danger,
                            size: 18,
                          ),
                        ),
                        title: Text(item.materialName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                        subtitle: Text(
                          '${item.materialCode} • Kondisi: ${isGood ? 'Bagus (Restock ke Stok)' : 'Rusak / Afval'}'
                          '${item.notes != null ? ' - ${item.notes}' : ''}',
                        ),
                        trailing: Text(
                          '+${item.quantity} ${item.unit}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: isGood ? AppTheme.success : AppTheme.danger,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
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
    final returnList = txProvider.goodsReturnList;
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
                      'Transaksi Pengembalian Barang',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Penerimaan kembali sisa pemakaian bahan baku ke dalam persediaan gudang.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const GoodsReturnFormDialog(),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Catat Pengembalian'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari no retur, pengembali, departemen, atau alasan...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
                onChanged: (val) => txProvider.setGoodsReturnSearch(val),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Transactions Table
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (txProvider.isLoading && returnList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (returnList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(50),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.assignment_return_rounded, size: 48, color: AppTheme.textSecondary),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada transaksi pengembalian bahan baku.',
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
                        DataColumn(label: Text('NO. RETUR', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('TANGGAL & WAKTU', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('REF. BARANG KELUAR', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('PENGEMBALI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('DEPARTEMEN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('ALASAN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('TOTAL VOLUME', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('AKSI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      ],
                      rows: returnList.map((gr) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.successLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  gr.returnCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.success,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(dateFormat.format(gr.returnDate))),
                            DataCell(
                              Text(
                                gr.goodsOutCode ?? '-',
                                style: TextStyle(
                                  fontWeight: gr.goodsOutCode != null ? FontWeight.w600 : FontWeight.normal,
                                  color: gr.goodsOutCode != null ? AppTheme.primary : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            DataCell(Text(gr.returnerName)),
                            DataCell(Text(gr.department)),
                            DataCell(Text(gr.reason)),
                            DataCell(
                              Text(
                                '+${gr.totalQty.toStringAsFixed(1)} unit',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.success),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 18),
                                tooltip: 'Lihat Detail Retur',
                                color: AppTheme.primary,
                                onPressed: () => _showDetailDialog(context, gr),
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
