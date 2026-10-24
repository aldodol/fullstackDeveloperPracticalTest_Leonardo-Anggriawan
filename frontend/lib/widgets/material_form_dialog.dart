import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/material.dart';
import '../providers/material_provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class MaterialFormDialog extends StatefulWidget {
  final RawMaterial? material;

  const MaterialFormDialog({super.key, this.material});

  @override
  State<MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends State<MaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _unitController;
  late TextEditingController _minStockController;
  late TextEditingController _initialStockController;
  late TextEditingController _descController;

  int? _selectedCategoryId;
  bool _isLoading = false;

  final List<String> _suggestedUnits = [
    'kg',
    'pcs',
    'meter',
    'liter',
    'lembar',
    'roll',
    'batang',
    'box',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.material;
    _codeController = TextEditingController(text: m?.code ?? '');
    _nameController = TextEditingController(text: m?.name ?? '');
    _unitController = TextEditingController(text: m?.unit ?? 'pcs');
    _minStockController = TextEditingController(text: m != null ? m.minStock.toStringAsFixed(0) : '10');
    _initialStockController = TextEditingController(text: '0');
    _descController = TextEditingController(text: m?.description ?? '');
    _selectedCategoryId = m?.categoryId;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _minStockController.dispose();
    _initialStockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori bahan baku')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final matProvider = Provider.of<MaterialProvider>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    bool success;
    if (widget.material == null) {
      // Create new material
      final payload = {
        'code': _codeController.text.trim(),
        'name': _nameController.text.trim(),
        'category_id': _selectedCategoryId,
        'unit': _unitController.text.trim(),
        'min_stock': double.tryParse(_minStockController.text) ?? 0,
        'initial_stock': double.tryParse(_initialStockController.text) ?? 0,
        'description': _descController.text.trim(),
      };
      success = await matProvider.createMaterial(payload);
    } else {
      // Update existing material
      final payload = {
        'code': _codeController.text.trim(),
        'name': _nameController.text.trim(),
        'category_id': _selectedCategoryId,
        'unit': _unitController.text.trim(),
        'min_stock': double.tryParse(_minStockController.text) ?? 0,
        'description': _descController.text.trim(),
      };
      success = await matProvider.updateMaterial(widget.material!.id, payload);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        appProvider.showNotification(
          widget.material == null
              ? 'Bahan baku berhasil ditambahkan'
              : 'Data bahan baku berhasil diperbarui',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(matProvider.errorMessage ?? 'Gagal menyimpan data'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<MaterialProvider>(context).categories;
    final isEditing = widget.material != null;

    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Bahan Baku' : 'Tambah Bahan Baku Baru',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEditing
                        ? 'Perbarui detail data master dan batas stok minimum.'
                        : 'Daftarkan bahan baku baru ke dalam katalog sistem inventaris.',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const Divider(height: 32),

                  // Code & Category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kode Bahan Baku *',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _codeController,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: RM-MET-001',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Kode wajib diisi';
                                }
                                return null;
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
                              'Kategori *',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              decoration: const InputDecoration(),
                              items: categories.map((cat) {
                                return DropdownMenuItem<int>(
                                  value: cat.id,
                                  child: Text(cat.name, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedCategoryId = val);
                              },
                              validator: (val) => val == null ? 'Pilih kategori' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Name
                  const Text(
                    'Nama Bahan Baku *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Plat Baja SPCC 1.2mm',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama bahan baku wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Unit & Min Stock
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Satuan (UoM) *',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Autocomplete<String>(
                              initialValue: TextEditingValue(text: _unitController.text),
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return _suggestedUnits;
                                }
                                return _suggestedUnits.where(
                                  (u) => u.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                                );
                              },
                              onSelected: (val) => _unitController.text = val,
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                controller.addListener(() {
                                  _unitController.text = controller.text;
                                });
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(hintText: 'kg / pcs / roll'),
                                  validator: (val) =>
                                      (val == null || val.trim().isEmpty) ? 'Satuan wajib diisi' : null,
                                );
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
                              'Minimum Safety Stock *',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _minStockController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: 'Batas peringatan',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                                final num = double.tryParse(val);
                                if (num == null || num < 0) return 'Harus angka >= 0';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Initial stock field only on creation
                  if (!isEditing) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Stok Awal (Opsional)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _initialStockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'Jumlah fisik saat ini (otomatis dicatat ke buku stok)',
                      ),
                      validator: (val) {
                        if (val != null && val.isNotEmpty) {
                          final num = double.tryParse(val);
                          if (num == null || num < 0) return 'Harus angka >= 0';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 18),
                  const Text(
                    'Deskripsi / Lokasi Rak / Catatan',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Keterangan spesifikasi, rak gudang, atau instruksi penyimpanan',
                    ),
                  ),

                  const SizedBox(height: 28),
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
                            : Text(isEditing ? 'Simpan Perubahan' : 'Tambahkan Bahan Baku'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
