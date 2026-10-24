import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/material.dart';
import '../models/goods_out.dart';
import '../models/goods_return.dart';
import '../models/stock_movement.dart';
import '../models/stock_overview.dart';
import '../utils/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Format respon server tidak valid (Status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    } else {
      String errorMessage = 'Terjadi kesalahan pada server';
      List<dynamic>? errors;

      if (body is Map<String, dynamic>) {
        if (body.containsKey('message')) {
          errorMessage = body['message'].toString();
        }
        if (body.containsKey('errors')) {
          errors = body['errors'] as List<dynamic>?;
        }
      }

      throw ApiException(
        errorMessage,
        statusCode: response.statusCode,
        errors: errors,
      );
    }
  }

  // ================= CATEGORIES =================
  Future<List<Category>> fetchCategories() async {
    try {
      final res = await http.get(Uri.parse(ApiConstants.categories), headers: _headers);
      final data = _handleResponse(res) as List;
      return data.map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server: ${e.toString()}');
    }
  }

  Future<Category> createCategory(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.categories),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = _handleResponse(res);
      return Category.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal menambahkan kategori: ${e.toString()}');
    }
  }

  // ================= MATERIALS =================
  Future<List<RawMaterial>> fetchMaterials({
    String? search,
    int? categoryId,
    String? stockStatus,
    bool? isActive,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.materials).replace(
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'category_id': categoryId.toString(),
          if (stockStatus != null && stockStatus != 'all') 'stock_status': stockStatus,
          if (isActive != null) 'is_active': isActive.toString(),
        },
      );

      final res = await http.get(uri, headers: _headers);
      final data = _handleResponse(res) as List;
      return data.map((e) => RawMaterial.fromJson(e)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengambil daftar bahan baku: ${e.toString()}');
    }
  }

  Future<RawMaterial> fetchMaterialById(int id) async {
    try {
      final res = await http.get(Uri.parse('${ApiConstants.materials}/$id'), headers: _headers);
      final data = _handleResponse(res);
      return RawMaterial.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengambil data material: ${e.toString()}');
    }
  }

  Future<RawMaterial> createMaterial(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.materials),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = _handleResponse(res);
      return RawMaterial.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal membuat bahan baku: ${e.toString()}');
    }
  }

  Future<RawMaterial> updateMaterial(int id, Map<String, dynamic> payload) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiConstants.materials}/$id'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = _handleResponse(res);
      return RawMaterial.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal memperbarui bahan baku: ${e.toString()}');
    }
  }

  Future<void> deleteMaterial(int id) async {
    try {
      final res = await http.delete(Uri.parse('${ApiConstants.materials}/$id'), headers: _headers);
      _handleResponse(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal menghapus bahan baku: ${e.toString()}');
    }
  }

  Future<RawMaterial> adjustStock(int id, Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.adjustStock(id)),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = _handleResponse(res);
      return RawMaterial.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal menyesuaikan stok: ${e.toString()}');
    }
  }

  // ================= GOODS OUT =================
  Future<List<GoodsOut>> fetchGoodsOut({String? search, String? startDate, String? endDate}) async {
    try {
      final uri = Uri.parse(ApiConstants.goodsOut).replace(
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
      );

      final res = await http.get(uri, headers: _headers);
      final data = _handleResponse(res) as List;
      return data.map((e) => GoodsOut.fromJson(e)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengambil daftar barang keluar: ${e.toString()}');
    }
  }

  Future<GoodsOut> fetchGoodsOutById(int id) async {
    try {
      final res = await http.get(Uri.parse('${ApiConstants.goodsOut}/$id'), headers: _headers);
      final data = _handleResponse(res);
      return GoodsOut.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengambil detail barang keluar: ${e.toString()}');
    }
  }

  Future<GoodsOut> createGoodsOut(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.goodsOut),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = _handleResponse(res);
      return GoodsOut.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal membuat transaksi barang keluar: ${e.toString()}');
    }
  }

  // ================= GOODS RETURNS =================
  Future<List<GoodsReturn>> fetchGoodsReturns({String? search, String? startDate, String? endDate}) async {
    try {
      final uri = Uri.parse(ApiConstants.goodsReturns).replace(
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
      );

      final res = await http.get(uri, headers: _headers);
      final data = _handleResponse(res) as List;
      return data.map((e) => GoodsReturn.fromJson(e)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengambil daftar pengembalian: ${e.toString()}');
    }
  }

  Future<GoodsReturn> fetchGoodsReturnById(int id) async {
    try {
      final res = await http.get(Uri.parse('${ApiConstants.goodsReturns}/$id'), headers: _headers);
      final data = _handleResponse(res);
      return GoodsReturn.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengambil detail pengembalian: ${e.toString()}');
    }
  }

  Future<GoodsReturn> createGoodsReturn(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.goodsReturns),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = _handleResponse(res);
      return GoodsReturn.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal memproses pengembalian barang: ${e.toString()}');
    }
  }

  // ================= STOCK & LEDGER =================
  Future<StockOverview> fetchStockOverview() async {
    try {
      final res = await http.get(Uri.parse(ApiConstants.stockOverview), headers: _headers);
      final data = _handleResponse(res);
      return StockOverview.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengambil ringkasan stok: ${e.toString()}');
    }
  }

  Future<List<StockMovement>> fetchStockMovements({
    int? materialId,
    String? movementType,
    String? referenceType,
    String? search,
    String? startDate,
    String? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.stockMovements).replace(
        queryParameters: {
          if (materialId != null) 'material_id': materialId.toString(),
          if (movementType != null && movementType != 'ALL') 'movement_type': movementType,
          if (referenceType != null && referenceType != 'ALL') 'reference_type': referenceType,
          if (search != null && search.isNotEmpty) 'search': search,
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final res = await http.get(uri, headers: _headers);
      final data = _handleResponse(res);
      final movements = data['movements'] as List? ?? [];
      return movements.map((e) => StockMovement.fromJson(e)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengambil kartu pergerakan stok: ${e.toString()}');
    }
  }
}
