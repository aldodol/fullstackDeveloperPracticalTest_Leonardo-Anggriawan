import 'package:flutter/material.dart';
import '../models/goods_out.dart';
import '../models/goods_return.dart';
import '../services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<GoodsOut> _goodsOutList = [];
  List<GoodsReturn> _goodsReturnList = [];
  
  GoodsOut? _selectedGoodsOut;
  GoodsReturn? _selectedGoodsReturn;

  bool _isLoading = false;
  String? _errorMessage;

  // Search and date filters
  String _goodsOutSearch = '';
  String _goodsReturnSearch = '';

  List<GoodsOut> get goodsOutList => _goodsOutList;
  List<GoodsReturn> get goodsReturnList => _goodsReturnList;
  GoodsOut? get selectedGoodsOut => _selectedGoodsOut;
  GoodsReturn? get selectedGoodsReturn => _selectedGoodsReturn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadGoodsOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _goodsOutList = await _api.fetchGoodsOut(search: _goodsOutSearch);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGoodsReturns() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _goodsReturnList = await _api.fetchGoodsReturns(search: _goodsReturnSearch);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setGoodsOutSearch(String query) {
    _goodsOutSearch = query;
    loadGoodsOut();
  }

  void setGoodsReturnSearch(String query) {
    _goodsReturnSearch = query;
    loadGoodsReturns();
  }

  Future<void> selectGoodsOutDetail(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedGoodsOut = await _api.fetchGoodsOutById(id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectGoodsReturnDetail(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedGoodsReturn = await _api.fetchGoodsReturnById(id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGoodsOut(Map<String, dynamic> payload) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      await _api.createGoodsOut(payload);
      await loadGoodsOut();
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

  Future<bool> createGoodsReturn(Map<String, dynamic> payload) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      await _api.createGoodsReturn(payload);
      await Future.wait([
        loadGoodsReturns(),
        loadGoodsOut(), // Refresh return progress on goods out records
      ]);
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
