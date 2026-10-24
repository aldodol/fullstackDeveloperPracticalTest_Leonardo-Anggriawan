class GoodsReturnItem {
  final int id;
  final int goodsReturnId;
  final int? goodsOutItemId;
  final int materialId;
  final String materialCode;
  final String materialName;
  final String categoryName;
  final double quantity;
  final String unit;
  final String conditionType; // 'GOOD', 'DAMAGED'
  final bool isRestocked;
  final String? notes;

  GoodsReturnItem({
    required this.id,
    required this.goodsReturnId,
    this.goodsOutItemId,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.categoryName,
    required this.quantity,
    required this.unit,
    required this.conditionType,
    required this.isRestocked,
    this.notes,
  });

  bool get isGood => conditionType == 'GOOD';
  bool get isDamaged => conditionType == 'DAMAGED';

  factory GoodsReturnItem.fromJson(Map<String, dynamic> json) {
    return GoodsReturnItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      goodsReturnId: json['goods_return_id'] is int
          ? json['goods_return_id']
          : int.tryParse(json['goods_return_id']?.toString() ?? '0') ?? 0,
      goodsOutItemId: json['goods_out_item_id'] != null
          ? int.tryParse(json['goods_out_item_id'].toString())
          : null,
      materialId: json['material_id'] is int
          ? json['material_id']
          : int.tryParse(json['material_id']?.toString() ?? '0') ?? 0,
      materialCode: json['material_code'] ?? '',
      materialName: json['material_name'] ?? '',
      categoryName: json['category_name'] ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      unit: json['unit'] ?? '',
      conditionType: json['condition_type'] ?? 'GOOD',
      isRestocked: json['is_restocked'] == 1 || json['is_restocked'] == true,
      notes: json['notes'],
    );
  }
}

class GoodsReturn {
  final int id;
  final String returnCode;
  final DateTime returnDate;
  final int? goodsOutId;
  final String? goodsOutCode;
  final String returnerName;
  final String department;
  final String reason;
  final String? notes;
  final int totalItems;
  final double totalQty;
  final List<GoodsReturnItem> items;

  GoodsReturn({
    required this.id,
    required this.returnCode,
    required this.returnDate,
    this.goodsOutId,
    this.goodsOutCode,
    required this.returnerName,
    required this.department,
    required this.reason,
    this.notes,
    required this.totalItems,
    required this.totalQty,
    this.items = const [],
  });

  factory GoodsReturn.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<GoodsReturnItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems.map((item) => GoodsReturnItem.fromJson(item)).toList();
    }

    return GoodsReturn(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      returnCode: json['return_code'] ?? '',
      returnDate: json['return_date'] != null
          ? DateTime.parse(json['return_date'])
          : DateTime.now(),
      goodsOutId: json['goods_out_id'] != null
          ? int.tryParse(json['goods_out_id'].toString())
          : null,
      goodsOutCode: json['goods_out_code'],
      returnerName: json['returner_name'] ?? '',
      department: json['department'] ?? '',
      reason: json['reason'] ?? '',
      notes: json['notes'],
      totalItems: json['total_items'] is int
          ? json['total_items']
          : int.tryParse(json['total_items']?.toString() ?? '0') ?? 0,
      totalQty: double.tryParse(json['total_qty']?.toString() ?? '0') ?? 0.0,
      items: parsedItems,
    );
  }
}
