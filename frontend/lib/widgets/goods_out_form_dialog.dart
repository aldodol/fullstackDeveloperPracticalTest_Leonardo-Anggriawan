import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/material.dart';
import '../providers/material_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class _LineItemInput {
  int? materialId;
  final TextEditingController qtyController = TextEditingController(text: '1');
  final TextEditingController notesController = TextEditingController();

  void dispose() {
    qtyController.dispose();
    notesController.dispose();
  }
}

class GoodsOutFormDialog extends StatefulWidget {
  const GoodsOutFormDialog({super.key});

  @override
  State<GoodsOutFormDialog> createState() => _GoodsOutFormDialogState();
}

class _GoodsOutFormDialogState extends State<GoodsOutFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _deptController = TextEditingController(text: 'Divisi Produksi');
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<_LineItemInput> _lineItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add one initial line item
    _addLineItem();
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(_LineItemInput());
    });
  }

  void _removeLineItem(int index) {
    if (_lineItems.length > 1) {
      setState(() {
        final removed = _lineItems.removeAt(index);
        removed.dispose();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 barang keluar')),
      );
    }
  }

  @override
  void dispose() {
    _deptController.dispose();
    _recipientController.dispose();
    _notesController.dispose();
    for (var item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final matProvider = Provider.of<MaterialProvider>(context, listen: false);
    final materialsMap = {for (var m in matProvider.materials) m.id: m};

    // Validate item selections and stock availability
    final itemsPayload = <Map<String, dynamic>>[];
    for (int i = 0; i < _lineItems.length; i++) {
      final line = _lineItems[i];
      if (line.materialId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silakan pilih material pada baris ke-${i + 1}')),
        );
        return;
      }

      final mat = materialsMap[line.materialId];
      if (mat == null) continue;

      final qty = double.tryParse(line.qtyController.text) ?? 0;
      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jumlah untuk ${mat.name} harus lebih dari 0')),
        );
        return;
      }

      if (qty > mat.currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stok tidak cukup untuk ${mat.name}! Tersedia: ${mat.currentStock} ${mat.unit}, Diminta: $qty ${mat.unit}',
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }

      itemsPayload.add({
        'material_id': line.materialId,
        'quantity': qty,
        'notes': line.notesController.text.trim(),
      });
    }

    setState(() => _isLoading = true);

    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    final payload = {
      'department': _deptController.text.trim(),
      'recipient_name': _recipientController.text.trim(),
      'notes': _notesController.text.trim(),
      'items': itemsPayload,
    };

    final success = await txProvider.createGoodsOut(payload);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Refresh materials and stock overview
        matProvider.loadMaterials();
        stockProvider.refreshAll();

        Navigator.of(context).pop();
        appProvider.showNotification('Transaksi barang keluar berhasil diproses dan stok telah berkurang.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(txProvider.errorMessage ?? 'Gagal membuat transaksi barang keluar'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final materials = Provider.of<MaterialProvider>(context).materials;
    final activeMaterials = materials.where((m) => m.isActive).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.output_rounded, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Form Transaksi Barang Keluar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Pencatatan pengeluaran bahan baku untuk produksi / operasional.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(height: 28),

                // Form Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header info: Dept & Recipient
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Departemen / Divisi Pemohon *',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _deptController,
                                    decoration: const InputDecoration(
                                      hintText: 'Contoh: Divisi Fabrikasi / Proyek A',
                                    ),
                                    validator: (val) =>
                                        (val == null || val.trim().isEmpty) ? 'Departemen wajib diisi' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nama Penerima / Pemohon *',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _recipientController,
                                    decoration: const InputDecoration(
                                      hintText: 'Nama lengkap personil',
                                    ),
                                    validator: (val) =>
                                        (val == null || val.trim().isEmpty) ? 'Nama penerima wajib diisi' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Purpose / Notes
                        const Text(
                          'Catatan Pengeluaran / Tujuan Penggunaan',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            hintText: 'Misal: Kebutuhan perakitan batch rangka box mesin',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Dynamic Line Items Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daftar Bahan Baku yang Dikeluarkan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _addLineItem,
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              label: const Text('Tambah Baris'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Line items list
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _lineItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final line = _lineItems[index];
                            final selectedMat = activeMaterials
                                .cast<RawMaterial?>()
                                .firstWhere((m) => m?.id == line.materialId, orElse: () => null);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Material selector
                                      Expanded(
                                        flex: 5,
                                        child: DropdownButtonFormField<int>(
                                          value: line.materialId,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Pilih Bahan Baku *',
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          ),
                                          items: activeMaterials.map((m) {
                                            return DropdownMenuItem<int>(
                                              value: m.id,
                                              child: Text(
                                                '${m.name} (${m.code}) — Sisa: ${m.currentStock.toStringAsFixed(1)} ${m.unit}',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: m.currentStock <= 0 ? Colors.red : Colors.black87,
                                                  fontWeight: m.currentStock <= 0 ? FontWeight.w300 : FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              line.materialId = val;
                                            });
                                          },
                                          validator: (val) => val == null ? 'Pilih material' : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Quantity
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: line.qtyController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText: 'Jumlah *',
                                            suffixText: selectedMat?.unit ?? '',
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          ),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return 'Wajib';
                                            final n = double.tryParse(val);
                                            if (n == null || n <= 0) return '> 0';
                                            if (selectedMat != null && n > selectedMat.currentStock) {
                                              return 'Maks ${selectedMat.currentStock}';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Delete button
                                      IconButton(
                                        onPressed: () => _removeLineItem(index),
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                                        tooltip: 'Hapus baris',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Row note
                                  TextFormField(
                                    controller: line.notesController,
                                    decoration: const InputDecoration(
                                      hintText: 'Keterangan item (opsional, misal: bagian potongan atau posisi)',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 24),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Item: ${_lineItems.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleSubmit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text('Simpan & Kurangi Stok'),
                        ),
                      ],
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
}
