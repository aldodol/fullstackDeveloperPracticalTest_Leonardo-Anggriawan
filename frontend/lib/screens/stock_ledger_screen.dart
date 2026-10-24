import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/stock_movement.dart';
import '../providers/stock_provider.dart';
import '../providers/material_provider.dart';
import '../utils/theme.dart';

class StockLedgerScreen extends StatelessWidget {
  const StockLedgerScreen({super.key});

  Widget _buildMovementBadge(StockMovement mov) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (mov.movementType) {
      case 'INITIAL':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        label = 'Saldo Awal';
        icon = Icons.flag_rounded;
        break;
      case 'OUT_USAGE':
        bg = AppTheme.dangerLight;
        fg = AppTheme.danger;
        label = 'Barang Keluar';
        icon = Icons.arrow_downward_rounded;
        break;
      case 'IN_RETURN':
        bg = AppTheme.successLight;
        fg = AppTheme.success;
        label = 'Pengembalian';
        icon = Icons.arrow_upward_rounded;
        break;
      case 'ADJUSTMENT':
      default:
        bg = AppTheme.warningLight;
        fg = AppTheme.warning;
        label = 'Penyesuaian';
        icon = Icons.tune_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    final matProvider = Provider.of<MaterialProvider>(context);
    final movements = stockProvider.movements;
    final materials = matProvider.materials;

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
                      'Riwayat Transaksi & Kartu Stok',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Audit trail seluruh pergerakan persediaan: barang keluar, retur masuk, saldo awal, dan penyesuaian opname.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => stockProvider.loadMovements(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Segarkan'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Material dropdown filter
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int?>(
                          value: stockProvider.selectedMaterialId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: 'Semua Bahan Baku',
                            prefixIcon: Icon(Icons.inventory_2_rounded, size: 20),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Semua Bahan Baku'),
                            ),
                            ...materials.map((m) {
                              return DropdownMenuItem<int?>(
                                value: m.id,
                                child: Text('${m.name} (${m.code})', overflow: TextOverflow.ellipsis),
                              );
                            }),
                          ],
                          onChanged: (val) => stockProvider.setMaterialFilter(val),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Movement Type Filter
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: stockProvider.selectedMovementType,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.swap_vert_rounded, size: 20),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('Semua Tipe Transaksi')),
                            DropdownMenuItem(value: 'OUT_USAGE', child: Text('Barang Keluar (OUT)')),
                            DropdownMenuItem(value: 'IN_RETURN', child: Text('Pengembalian (IN)')),
                            DropdownMenuItem(value: 'ADJUSTMENT', child: Text('Penyesuaian (Opname)')),
                            DropdownMenuItem(value: 'INITIAL', child: Text('Saldo Awal')),
                          ],
                          onChanged: (val) {
                            if (val != null) stockProvider.setMovementTypeFilter(val);
                          },
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Keyword Search
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari kode gerak, nama, atau catatan...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: stockProvider.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => stockProvider.setSearchQuery(''),
                                  )
                                : null,
                          ),
                          onChanged: (val) => stockProvider.setSearchQuery(val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Movements Ledger Table
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (stockProvider.isLoading && movements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (movements.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(50),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.receipt_long_rounded, size: 48, color: AppTheme.textSecondary),
                          SizedBox(height: 12),
                          Text(
                            'Tidak ada data pergerakan stok sesuai kriteria filter.',
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
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('NO. BUKTI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('TANGGAL & WAKTU', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('BAHAN BAKU', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('TIPE TRANSAKSI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('PERUBAHAN (QTY)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('STOK SEBELUM', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('STOK SESUDAH', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('KETERANGAN & CATATAN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      ],
                      rows: movements.map((mov) {
                        final isNeg = mov.isOutgoing;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                mov.movementCode,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ),
                            DataCell(Text(dateFormat.format(mov.createdAt))),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(mov.materialName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(mov.materialCode, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                            DataCell(_buildMovementBadge(mov)),
                            DataCell(
                              Text(
                                '${isNeg ? '' : '+'}${mov.quantity.toStringAsFixed(1)} ${mov.unit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: isNeg ? AppTheme.danger : AppTheme.success,
                                ),
                              ),
                            ),
                            DataCell(Text('${mov.stockBefore.toStringAsFixed(1)} ${mov.unit}')),
                            DataCell(
                              Text(
                                '${mov.stockAfter.toStringAsFixed(1)} ${mov.unit}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 250),
                                child: Text(
                                  mov.notes ?? '-',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
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
