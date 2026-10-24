import 'stock_movement.dart';

class LowStockAlertItem {
  final int id;
  final String code;
  final String name;
  final String categoryName;
  final String unit;
  final double minStock;
  final double currentStock;
  final double deficitQty;
  final String urgencyLevel; // 'OUT_OF_STOCK', 'LOW_STOCK'

  LowStockAlertItem({
    required this.id,
    required this.code,
    required this.name,
    required this.categoryName,
    required this.unit,
    required this.minStock,
    required this.currentStock,
    required this.deficitQty,
    required this.urgencyLevel,
  });

  factory LowStockAlertItem.fromJson(Map<String, dynamic> json) {
    return LowStockAlertItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      categoryName: json['category_name'] ?? '',
      unit: json['unit'] ?? '',
      minStock: double.tryParse(json['min_stock']?.toString() ?? '0') ?? 0.0,
      currentStock: double.tryParse(json['current_stock']?.toString() ?? '0') ?? 0.0,
      deficitQty: double.tryParse(json['deficit_qty']?.toString() ?? '0') ?? 0.0,
      urgencyLevel: json['urgency_level'] ?? 'LOW_STOCK',
    );
  }
}

class StockOverview {
  final int totalMaterials;
  final int activeMaterials;
  final int outOfStockMaterials;
  final int lowStockMaterials;
  final int safeStockMaterials;
  final int totalGoodsOutCount;
  final double totalGoodsOutQty;
  final int totalReturnsCount;
  final double totalReturnsQty;
  final List<LowStockAlertItem> lowStockList;
  final List<StockMovement> recentMovements;

  StockOverview({
    required this.totalMaterials,
    required this.activeMaterials,
    required this.outOfStockMaterials,
    required this.lowStockMaterials,
    required this.safeStockMaterials,
    required this.totalGoodsOutCount,
    required this.totalGoodsOutQty,
    required this.totalReturnsCount,
    required this.totalReturnsQty,
    required this.lowStockList,
    required this.recentMovements,
  });

  factory StockOverview.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? {};
    final lowStockRaw = json['lowStockList'] as List? ?? [];
    final movementsRaw = json['recentMovements'] as List? ?? [];

    return StockOverview(
      totalMaterials: int.tryParse(stats['totalMaterials']?.toString() ?? '0') ?? 0,
      activeMaterials: int.tryParse(stats['activeMaterials']?.toString() ?? '0') ?? 0,
      outOfStockMaterials: int.tryParse(stats['outOfStockMaterials']?.toString() ?? '0') ?? 0,
      lowStockMaterials: int.tryParse(stats['lowStockMaterials']?.toString() ?? '0') ?? 0,
      safeStockMaterials: int.tryParse(stats['safeStockMaterials']?.toString() ?? '0') ?? 0,
      totalGoodsOutCount: int.tryParse(stats['totalGoodsOutCount']?.toString() ?? '0') ?? 0,
      totalGoodsOutQty: double.tryParse(stats['totalGoodsOutQty']?.toString() ?? '0') ?? 0.0,
      totalReturnsCount: int.tryParse(stats['totalReturnsCount']?.toString() ?? '0') ?? 0,
      totalReturnsQty: double.tryParse(stats['totalReturnsQty']?.toString() ?? '0') ?? 0.0,
      lowStockList: lowStockRaw.map((e) => LowStockAlertItem.fromJson(e)).toList(),
      recentMovements: movementsRaw.map((e) => StockMovement.fromJson(e)).toList(),
    );
  }
}
