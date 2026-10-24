import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goods_out.dart';
import '../models/material.dart';
import '../providers/material_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class _ReturnLineItemInput {
  int? materialId;
  int? goodsOutItemId;
  double maxReturnable;
  String unit;
  String conditionType; // 'GOOD', 'DAMAGED'
  bool isRestocked;
  final TextEditingController qtyController;
  final TextEditingController notesController;

  _ReturnLineItemInput({
    this.materialId,
    this.goodsOutItemId,
    this.maxReturnable = 999999,
    this.unit = 'pcs',
    this.conditionType = 'GOOD',
    this.isRestocked = true,
  })  : qtyController = TextEditingController(text: '1'),
        notesController = TextEditingController();

  void dispose() {
    qtyController.dispose();
    notesController.dispose();
  }
}

class GoodsReturnFormDialog extends StatefulWidget {
  final GoodsOut? initialGoodsOut;

  const GoodsReturnFormDialog({super.key, this.initialGoodsOut});

  @override
  State<GoodsReturnFormDialog> createState() => _GoodsReturnFormDialogState();
}

class _GoodsReturnFormDialogState extends State<GoodsReturnFormDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedGoodsOutId;
  final TextEditingController _returnerController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController(text: 'Sisa Pemakaian Produksi');
  final TextEditingController _notesController = TextEditingController();

  final List<_ReturnLineItemInput> _lineItems = [];
  bool _isLoading = false;

  final List<String> _suggestedReasons = [
    'Sisa Pemakaian Produksi',
    'Kelebihan Estimasi Bahan',
    'Salah Ambil Ukuran/Spesifikasi',
    'Pembatalan Instruksi Kerja',
    'Barang Cacat/Afval',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialGoodsOut != null) {
      _applyGoodsOutReference(widget.initialGoodsOut!);
    } else {
      _addLineItem();
    }
  }

  void _applyGoodsOutReference(GoodsOut go) {
    setState(() {
      _selectedGoodsOutId = go.id;
      _returnerController.text = go.recipientName;
      _deptController.text = go.department;

      for (var item in _lineItems) {
        item.dispose();
      }
      _lineItems.clear();

      if (go.items.isNotEmpty) {
        for (var item in go.items) {
          if (item.returnableQty > 0) {
            final line = _ReturnLineItemInput(
              materialId: item.materialId,
              goodsOutItemId: item.id,
              maxReturnable: item.returnableQty,
              unit: item.unit,
              conditionType: 'GOOD',
              isRestocked: true,
            );
            line.qtyController.text = item.returnableQty.toStringAsFixed(1);
            _lineItems.add(line);
          }
        }
      }

      if (_lineItems.isEmpty) {
        _addLineItem();
      }
    });
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(_ReturnLineItemInput());
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
        const SnackBar(content: Text('Minimal harus ada 1 barang dikembalikan')),
      );
    }
  }

  @override
  void dispose() {
    _returnerController.dispose();
    _deptController.dispose();
    _reasonController.dispose();
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
      final qty = double.tryParse(line.qtyController.text) ?? 0;
      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jumlah pengembalian baris ke-${i + 1} harus lebih dari 0')),
        );
        return;
      }

      if (line.goodsOutItemId != null && qty > line.maxReturnable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Jumlah ${mat?.name ?? 'material'} melebihi sisa yang dapat dikembalikan! Maksimal: ${line.maxReturnable} ${line.unit}',
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }

      itemsPayload.add({
        'material_id': line.materialId,
        'goods_out_item_id': line.goodsOutItemId,
        'quantity': qty,
        'condition_type': line.conditionType,
        'is_restocked': line.isRestocked,
        'notes': line.notesController.text.trim(),
      });
    }

    setState(() => _isLoading = true);

    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    final payload = {
      'goods_out_id': _selectedGoodsOutId,
      'returner_name': _returnerController.text.trim(),
      'department': _deptController.text.trim(),
      'reason': _reasonController.text.trim(),
      'notes': _notesController.text.trim(),
      'items': itemsPayload,
    };

    final success = await txProvider.createGoodsReturn(payload);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        matProvider.loadMaterials();
        stockProvider.refreshAll();

        Navigator.of(context).pop();
        appProvider.showNotification('Pengembalian barang berhasil diproses dan stok telah diperbarui.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(txProvider.errorMessage ?? 'Gagal memproses pengembalian barang'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final materials = Provider.of<MaterialProvider>(context).materials;
    final goodsOutList = Provider.of<TransactionProvider>(context).goodsOutList;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 760),
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
                            color: AppTheme.successLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.assignment_return_rounded, color: AppTheme.success),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Form Pengembalian Barang',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Penerimaan sisa bahan baku atau pengembalian ke gudang.',
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
                        // Goods Out reference selector
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Referensi No. Barang Keluar (Opsional)',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int?>(
                                    value: _selectedGoodsOutId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      hintText: '-- Tanpa Referensi (Pengembalian Bebas) --',
                                    ),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('-- Tanpa Referensi / Mandiri --'),
                                      ),
                                      ...goodsOutList.map((go) {
                                        return DropdownMenuItem<int?>(
                                          value: go.id,
                                          child: Text(
                                            '${go.transactionCode} (${go.department} - ${go.recipientName})',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      if (val == null) {
                                        setState(() => _selectedGoodsOutId = null);
                                      } else {
                                        final txProvider = Provider.of<TransactionProvider>(context, listen: false);
                                        txProvider.selectGoodsOutDetail(val).then((_) {
                                          if (txProvider.selectedGoodsOut != null) {
                                            _applyGoodsOutReference(txProvider.selectedGoodsOut!);
                                          }
                                        });
                                      }
                                    },
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
                                    'Alasan Pengembalian *',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _suggestedReasons.contains(_reasonController.text)
                                        ? _reasonController.text
                                        : _suggestedReasons.first,
                                    isExpanded: true,
                                    decoration: const InputDecoration(),
                                    items: _suggestedReasons.map((r) {
                                      return DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _reasonController.text = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Returner name & Department
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nama Pengembali *',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _returnerController,
                                    decoration: const InputDecoration(hintText: 'Nama personil'),
                                    validator: (val) =>
                                        (val == null || val.trim().isEmpty) ? 'Nama wajib diisi' : null,
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
                                    'Departemen Asal *',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _deptController,
                                    decoration: const InputDecoration(hintText: 'Divisi atau proyek'),
                                    validator: (val) =>
                                        (val == null || val.trim().isEmpty) ? 'Departemen wajib diisi' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Items list
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daftar Bahan Baku yang Dikembalikan',
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

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _lineItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final line = _lineItems[index];
                            final selectedMat = materials
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
                                        flex: 4,
                                        child: DropdownButtonFormField<int>(
                                          value: line.materialId,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Bahan Baku *',
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          ),
                                          items: materials.map((m) {
                                            return DropdownMenuItem<int>(
                                              value: m.id,
                                              child: Text(
                                                '${m.name} (${m.code})',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: line.goodsOutItemId != null
                                              ? null // Locked if linked to specific goods out item
                                              : (val) {
                                                  setState(() {
                                                    line.materialId = val;
                                                  });
                                                },
                                          validator: (val) => val == null ? 'Pilih material' : null,
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Quantity
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: line.qtyController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText: 'Jumlah *',
                                            suffixText: selectedMat?.unit ?? line.unit,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            helperText: line.goodsOutItemId != null
                                                ? 'Maks: ${line.maxReturnable}'
                                                : null,
                                          ),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return 'Wajib';
                                            final n = double.tryParse(val);
                                            if (n == null || n <= 0) return '> 0';
                                            if (line.goodsOutItemId != null && n > line.maxReturnable) {
                                              return 'Maks ${line.maxReturnable}';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Condition selector
                                      Expanded(
                                        flex: 3,
                                        child: DropdownButtonFormField<String>(
                                          value: line.conditionType,
                                          decoration: const InputDecoration(
                                            labelText: 'Kondisi *',
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'GOOD',
                                              child: Text('Bagus (Restock)'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'DAMAGED',
                                              child: Text('Rusak / Afval'),
                                            ),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                line.conditionType = val;
                                                line.isRestocked = val == 'GOOD';
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Delete button
                                      IconButton(
                                        onPressed: () => _removeLineItem(index),
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Notes
                                  TextFormField(
                                    controller: line.notesController,
                                    decoration: const InputDecoration(
                                      hintText: 'Keterangan kondisi fisik atau alasan sisa',
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
                          label: const Text('Simpan Pengembalian'),
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
