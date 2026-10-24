class RawMaterial {
  final int id;
  final String code;
  final String name;
  final int categoryId;
  final String categoryName;
  final String unit;
  final double minStock;
  final double currentStock;
  final String? description;
  final bool isActive;
  final String stockStatus; // 'NORMAL', 'LOW_STOCK', 'OUT_OF_STOCK'
  final DateTime? createdAt;

  RawMaterial({
    required this.id,
    required this.code,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.unit,
    required this.minStock,
    required this.currentStock,
    this.description,
    this.isActive = true,
    required this.stockStatus,
    this.createdAt,
  });

  bool get isOutOfStock => currentStock <= 0;
  bool get isLowStock => currentStock <= minStock && currentStock > 0;
  bool get isSafe => currentStock > minStock;

  factory RawMaterial.fromJson(Map<String, dynamic> json) {
    return RawMaterial(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id'].toString()) ?? 0,
      categoryName: json['category_name'] ?? 'Umum',
      unit: json['unit'] ?? '',
      minStock: double.tryParse(json['min_stock']?.toString() ?? '0') ?? 0.0,
      currentStock: double.tryParse(json['current_stock']?.toString() ?? '0') ?? 0.0,
      description: json['description'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      stockStatus: json['stock_status'] ?? 'NORMAL',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'category_id': categoryId,
    'unit': unit,
    'min_stock': minStock,
    'current_stock': currentStock,
    'description': description,
    'is_active': isActive,
  };
}
