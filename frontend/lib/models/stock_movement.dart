class StockMovement {
  final int id;
  final String movementCode;
  final int materialId;
  final String materialCode;
  final String materialName;
  final String? categoryName;
  final String unit;
  final String movementType; // 'INITIAL', 'OUT_USAGE', 'IN_RETURN', 'ADJUSTMENT'
  final String referenceType; // 'GOODS_OUT', 'GOODS_RETURN', 'MANUAL_ADJUSTMENT', 'INITIAL_STOCK'
  final int? referenceId;
  final double quantity;
  final double stockBefore;
  final double stockAfter;
  final String? notes;
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.movementCode,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    this.categoryName,
    required this.unit,
    required this.movementType,
    required this.referenceType,
    this.referenceId,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    this.notes,
    required this.createdAt,
  });

  bool get isOutgoing => quantity < 0;
  bool get isIncoming => quantity > 0;

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      movementCode: json['movement_code'] ?? '',
      materialId: json['material_id'] is int
          ? json['material_id']
          : int.tryParse(json['material_id'].toString()) ?? 0,
      materialCode: json['material_code'] ?? '',
      materialName: json['material_name'] ?? '',
      categoryName: json['category_name'],
      unit: json['unit'] ?? '',
      movementType: json['movement_type'] ?? 'ADJUSTMENT',
      referenceType: json['reference_type'] ?? '',
      referenceId: json['reference_id'] != null
          ? int.tryParse(json['reference_id'].toString())
          : null,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      stockBefore: double.tryParse(json['stock_before']?.toString() ?? '0') ?? 0.0,
      stockAfter: double.tryParse(json['stock_after']?.toString() ?? '0') ?? 0.0,
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
