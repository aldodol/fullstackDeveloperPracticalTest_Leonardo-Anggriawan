import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/material.dart';
import '../providers/material_provider.dart';
import '../providers/app_provider.dart';
import '../widgets/stock_status_badge.dart';
import '../widgets/material_form_dialog.dart';
import '../widgets/adjust_stock_dialog.dart';
import '../utils/theme.dart';

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});

  void _confirmDelete(BuildContext context, RawMaterial m) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus / Nonaktifkan Bahan Baku'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${m.name}" (${m.code})?\n\n'
          'Jika bahan baku ini memiliki riwayat transaksi barang keluar atau pengembalian, '
          'sistem akan menonaktifkannya secara aman agar integritas database tetap terjaga.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final provider = Provider.of<MaterialProvider>(context, listen: false);
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              final success = await provider.deleteMaterial(m.id);
              if (context.mounted) {
                if (success) {
                  appProvider.showNotification('Bahan baku berhasil diproses');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Gagal menghapus'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matProvider = Provider.of<MaterialProvider>(context);
    final materials = matProvider.materials;
    final categories = matProvider.categories;

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
                      'Master Bahan Baku',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kelola katalog bahan baku, satuan ukuran, dan parameter batas stok minimum.',
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
                    builder: (_) => const MaterialFormDialog(),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Bahan Baku'),
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
                      // Search field
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari kode atau nama bahan baku...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: matProvider.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => matProvider.setSearchQuery(''),
                                  )
                                : null,
                          ),
                          onChanged: (val) => matProvider.setSearchQuery(val),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Category filter
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int?>(
                          value: matProvider.selectedCategoryId,
                          decoration: const InputDecoration(
                            hintText: 'Semua Kategori',
                            prefixIcon: Icon(Icons.category_rounded, size: 20),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Semua Kategori'),
                            ),
                            ...categories.map((c) {
                              return DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.name, overflow: TextOverflow.ellipsis),
                              );
                            }),
                          ],
                          onChanged: (val) => matProvider.setCategoryFilter(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status filter chips
                  Row(
                    children: [
                      const Text(
                        'Filter Status: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Semua'),
                            selected: matProvider.selectedStockStatus == 'all',
                            onSelected: (_) => matProvider.setStockStatusFilter('all'),
                          ),
                          ChoiceChip(
                            label: const Text('Stok Aman'),
                            selected: matProvider.selectedStockStatus == 'normal',
                            onSelected: (_) => matProvider.setStockStatusFilter('normal'),
                          ),
                          ChoiceChip(
                            label: const Text('Stok Rendah'),
                            selected: matProvider.selectedStockStatus == 'low_stock',
                            selectedColor: AppTheme.warningLight,
                            onSelected: (_) => matProvider.setStockStatusFilter('low_stock'),
                          ),
                          ChoiceChip(
                            label: const Text('Stok Habis'),
                            selected: matProvider.selectedStockStatus == 'out_of_stock',
                            selectedColor: AppTheme.dangerLight,
                            onSelected: (_) => matProvider.setStockStatusFilter('out_of_stock'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data Table Card
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (matProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (materials.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(50),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textSecondary),
                          SizedBox(height: 12),
                          Text(
                            'Tidak ada bahan baku yang sesuai kriteria pencarian.',
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
                        DataColumn(label: Text('KODE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('NAMA BAHAN BAKU', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('KATEGORI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('SATUAN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('STOK TERKINI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('BATAS MINIMUM', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('STATUS STOK', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        DataColumn(label: Text('AKSI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      ],
                      rows: materials.map((m) {
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
                                  m.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryDark,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                  ),
                                  if (m.description != null && m.description!.isNotEmpty)
                                    Text(
                                      m.description!,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(Text(m.categoryName)),
                            DataCell(Text(m.unit)),
                            DataCell(
                              Text(
                                '${m.currentStock.toStringAsFixed(1)} ${m.unit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: m.isOutOfStock
                                      ? AppTheme.danger
                                      : (m.isLowStock ? AppTheme.warning : AppTheme.textPrimary),
                                ),
                              ),
                            ),
                            DataCell(Text('${m.minStock.toStringAsFixed(0)} ${m.unit}')),
                            DataCell(
                              StockStatusBadge(
                                status: m.stockStatus,
                                currentStock: m.currentStock,
                                minStock: m.minStock,
                                unit: m.unit,
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Adjust stock button
                                  IconButton(
                                    icon: const Icon(Icons.tune_rounded, size: 18),
                                    tooltip: 'Penyesuaian Stok (Opname)',
                                    color: AppTheme.primary,
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AdjustStockDialog(material: m),
                                      );
                                    },
                                  ),
                                  // Edit button
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Edit Data',
                                    color: AppTheme.textSecondary,
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => MaterialFormDialog(material: m),
                                      );
                                    },
                                  ),
                                  // Delete / Deactivate button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                    tooltip: 'Hapus / Nonaktifkan',
                                    color: AppTheme.danger,
                                    onPressed: () => _confirmDelete(context, m),
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
