class GoodsOutItem {
  final int id;
  final int goodsOutId;
  final int materialId;
  final String materialCode;
  final String materialName;
  final String categoryName;
  final double quantity;
  final String unit;
  final double returnedQty;
  final double returnableQty;
  final String? notes;

  GoodsOutItem({
    required this.id,
    required this.goodsOutId,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.categoryName,
    required this.quantity,
    required this.unit,
    required this.returnedQty,
    required this.returnableQty,
    this.notes,
  });

  factory GoodsOutItem.fromJson(Map<String, dynamic> json) {
    return GoodsOutItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      goodsOutId: json['goods_out_id'] is int
          ? json['goods_out_id']
          : int.tryParse(json['goods_out_id'].toString()) ?? 0,
      materialId: json['material_id'] is int
          ? json['material_id']
          : int.tryParse(json['material_id'].toString()) ?? 0,
      materialCode: json['material_code'] ?? '',
      materialName: json['material_name'] ?? '',
      categoryName: json['category_name'] ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      unit: json['unit'] ?? '',
      returnedQty: double.tryParse(json['returned_qty']?.toString() ?? '0') ?? 0.0,
      returnableQty: double.tryParse(json['returnable_qty']?.toString() ?? '0') ?? 0.0,
      notes: json['notes'],
    );
  }
}

class GoodsOut {
  final int id;
  final String transactionCode;
  final DateTime transactionDate;
  final String department;
  final String recipientName;
  final String? notes;
  final int totalItems;
  final double totalQty;
  final double totalReturnedQty;
  final List<GoodsOutItem> items;

  GoodsOut({
    required this.id,
    required this.transactionCode,
    required this.transactionDate,
    required this.department,
    required this.recipientName,
    this.notes,
    required this.totalItems,
    required this.totalQty,
    this.totalReturnedQty = 0.0,
    this.items = const [],
  });

  bool get isFullyReturned => totalReturnedQty >= totalQty && totalQty > 0;

  factory GoodsOut.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<GoodsOutItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems.map((item) => GoodsOutItem.fromJson(item)).toList();
    }

    return GoodsOut(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      transactionCode: json['transaction_code'] ?? '',
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'])
          : DateTime.now(),
      department: json['department'] ?? '',
      recipientName: json['recipient_name'] ?? '',
      notes: json['notes'],
      totalItems: json['total_items'] is int
          ? json['total_items']
          : int.tryParse(json['total_items']?.toString() ?? '0') ?? 0,
      totalQty: double.tryParse(json['total_qty']?.toString() ?? '0') ?? 0.0,
      totalReturnedQty: double.tryParse(json['total_returned_qty']?.toString() ?? '0') ?? 0.0,
      items: parsedItems,
    );
  }
}
