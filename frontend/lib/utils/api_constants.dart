class ApiConstants {
  // Default backend API base URL
  static String baseUrl = 'http://localhost:5000/api';

  // Endpoints
  static String get categories => '$baseUrl/categories';
  static String get materials => '$baseUrl/materials';
  static String get goodsOut => '$baseUrl/goods-out';
  static String get goodsReturns => '$baseUrl/goods-returns';
  static String get stockOverview => '$baseUrl/stock/overview';
  static String get stockMovements => '$baseUrl/stock/movements';
  static String materialLedger(int id) => '$baseUrl/stock/materials/$id/ledger';
  static String adjustStock(int id) => '$baseUrl/materials/$id/adjust-stock';
}
