import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  int _currentScreenIndex = 0;
  bool _isSidebarExpanded = true;
  String? _notificationMessage;
  bool _isErrorNotification = false;

  int get currentScreenIndex => _currentScreenIndex;
  bool get isSidebarExpanded => _isSidebarExpanded;
  String? get notificationMessage => _notificationMessage;
  bool get isErrorNotification => _isErrorNotification;

  void setScreenIndex(int index) {
    if (_currentScreenIndex != index) {
      _currentScreenIndex = index;
      notifyListeners();
    }
  }

  void toggleSidebar() {
    _isSidebarExpanded = !_isSidebarExpanded;
    notifyListeners();
  }

  void showNotification(String message, {bool isError = false}) {
    _notificationMessage = message;
    _isErrorNotification = isError;
    notifyListeners();
  }

  void clearNotification() {
    _notificationMessage = null;
    notifyListeners();
  }
}
