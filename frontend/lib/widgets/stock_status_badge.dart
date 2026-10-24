import 'package:flutter/material.dart';
import '../utils/theme.dart';

class StockStatusBadge extends StatelessWidget {
  final String status;
  final double currentStock;
  final double minStock;
  final String unit;

  const StockStatusBadge({
    super.key,
    required this.status,
    required this.currentStock,
    required this.minStock,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (currentStock <= 0 || status == 'OUT_OF_STOCK') {
      bg = AppTheme.dangerLight;
      fg = AppTheme.danger;
      label = 'Habis';
      icon = Icons.cancel_outlined;
    } else if (currentStock <= minStock || status == 'LOW_STOCK') {
      bg = AppTheme.warningLight;
      fg = AppTheme.warning;
      label = 'Stok Rendah';
      icon = Icons.warning_amber_rounded;
    } else {
      bg = AppTheme.successLight;
      fg = AppTheme.success;
      label = 'Aman';
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
