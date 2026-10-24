import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/material.dart';
import '../providers/material_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class AdjustStockDialog extends StatefulWidget {
  final RawMaterial material;

  const AdjustStockDialog({super.key, required this.material});

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  final _formKey = GlobalKey<FormState>();

  String _adjustmentType = 'ADD'; // 'ADD', 'SUBTRACT', 'SET'
  late TextEditingController _quantityController;
  late TextEditingController _reasonController;
  late TextEditingController _notesController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _reasonController = TextEditingController(text: 'Koreksi Hasil Stock Opname');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _previewStockAfter {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    if (_adjustmentType == 'ADD') {
      return widget.material.currentStock + qty;
    } else if (_adjustmentType == 'SUBTRACT') {
      return widget.material.currentStock - qty;
    } else {
      return qty;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_quantityController.text) ?? 0;
    if (_adjustmentType == 'SUBTRACT' && widget.material.currentStock < qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stok tidak cukup untuk dikurangi! Stok saat ini: ${widget.material.currentStock} ${widget.material.unit}',
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final matProvider = Provider.of<MaterialProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    final payload = {
      'adjustment_type': _adjustmentType,
      'quantity': qty,
      'reason': _reasonController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    final success = await matProvider.adjustStock(widget.material.id, payload);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        stockProvider.refreshAll();
        Navigator.of(context).pop();
        appProvider.showNotification(
          'Stok ${widget.material.name} berhasil disesuaikan menjadi ${_previewStockAfter.toStringAsFixed(1)} ${widget.material.unit}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(matProvider.errorMessage ?? 'Gagal menyesuaikan stok'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.material;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Penyesuaian Stok (Opname)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${m.name} (${m.code})',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const Divider(height: 28),

                // Current stock badge
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Stok Terkini di Sistem:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      Text(
                        '${m.currentStock.toStringAsFixed(1)} ${m.unit}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Adjustment Type Selector
                const Text(
                  'Jenis Penyesuaian',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('+ Tambah Stok')),
                        selected: _adjustmentType == 'ADD',
                        selectedColor: AppTheme.success.withOpacity(0.2),
                        onSelected: (val) {
                          if (val) setState(() => _adjustmentType = 'ADD');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('- Kurang Stok')),
                        selected: _adjustmentType == 'SUBTRACT',
                        selectedColor: AppTheme.danger.withOpacity(0.2),
                        onSelected: (val) {
                          if (val) setState(() => _adjustmentType = 'SUBTRACT');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('= Atur Ulang')),
                        selected: _adjustmentType == 'SET',
                        selectedColor: AppTheme.primary.withOpacity(0.2),
                        onSelected: (val) {
                          if (val) setState(() => _adjustmentType = 'SET');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Quantity
                Text(
                  _adjustmentType == 'SET' ? 'Jumlah Stok Baru *' : 'Jumlah Penyesuaian *',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    suffixText: m.unit,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Jumlah wajib diisi';
                    final n = double.tryParse(val);
                    if (n == null || n <= 0) return 'Harus angka > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Reason
                const Text(
                  'Alasan Penyesuaian *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Misal: Selisih audit fisik gudang, barang rusak, dsb.',
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Alasan wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // Notes
                const Text(
                  'Catatan Tambahan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Nomor Berita Acara atau nama auditor gudang',
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Proses Penyesuaian'),
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
