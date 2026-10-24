import 'package:flutter/material.dart';
import '../models/stock_movement.dart';
import '../models/stock_overview.dart';
import '../services/api_service.dart';

class StockProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  StockOverview? _overview;
  List<StockMovement> _movements = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter states
  int? _selectedMaterialId;
  String _selectedMovementType = 'ALL';
  String _searchQuery = '';

  StockOverview? get overview => _overview;
  List<StockMovement> get movements => _movements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int? get selectedMaterialId => _selectedMaterialId;
  String get selectedMovementType => _selectedMovementType;
  String get searchQuery => _searchQuery;

  Future<void> loadOverview() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _overview = await _api.fetchStockOverview();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMovements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _movements = await _api.fetchStockMovements(
        materialId: _selectedMaterialId,
        movementType: _selectedMovementType,
        search: _searchQuery,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setMaterialFilter(int? materialId) {
    _selectedMaterialId = materialId;
    loadMovements();
  }

  void setMovementTypeFilter(String type) {
    _selectedMovementType = type;
    loadMovements();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadMovements();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadOverview(),
      loadMovements(),
    ]);
  }
}
