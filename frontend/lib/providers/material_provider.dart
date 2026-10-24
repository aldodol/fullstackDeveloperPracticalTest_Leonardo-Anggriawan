import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/material.dart';
import '../services/api_service.dart';

class MaterialProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<RawMaterial> _materials = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter states
  String _searchQuery = '';
  int? _selectedCategoryId;
  String _selectedStockStatus = 'all'; // 'all', 'normal', 'low_stock', 'out_of_stock'

  List<RawMaterial> get materials => _materials;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  String get selectedStockStatus => _selectedStockStatus;

  Future<void> init() async {
    await Future.wait([
      loadCategories(),
      loadMaterials(),
    ]);
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _api.fetchCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMaterials() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _materials = await _api.fetchMaterials(
        search: _searchQuery,
        categoryId: _selectedCategoryId,
        stockStatus: _selectedStockStatus,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadMaterials();
  }

  void setCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    loadMaterials();
  }

  void setStockStatusFilter(String status) {
    _selectedStockStatus = status;
    loadMaterials();
  }

  Future<bool> createMaterial(Map<String, dynamic> payload) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _api.createMaterial(payload);
      await loadMaterials();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMaterial(int id, Map<String, dynamic> payload) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _api.updateMaterial(id, payload);
      await loadMaterials();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMaterial(int id) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _api.deleteMaterial(id);
      await loadMaterials();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> adjustStock(int id, Map<String, dynamic> payload) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _api.adjustStock(id, payload);
      await loadMaterials();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
