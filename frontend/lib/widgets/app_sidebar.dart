import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentIndex = appProvider.currentScreenIndex;

    final navItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_rounded, 'subtitle': 'Ringkasan & Alert'},
      {'title': 'Master Bahan Baku', 'icon': Icons.inventory_2_rounded, 'subtitle': 'Katalog & Stok'},
      {'title': 'Barang Keluar', 'icon': Icons.output_rounded, 'subtitle': 'Pengeluaran Bahan'},
      {'title': 'Pengembalian', 'icon': Icons.assignment_return_rounded, 'subtitle': 'Barang Kembali'},
      {'title': 'Riwayat & Kartu Stok', 'icon': Icons.receipt_long_rounded, 'subtitle': 'Audit Trail Ledger'},
    ];

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppTheme.secondary,
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo & Branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.layers_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BahanBaku',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Inventory Management',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 16),

          // Menu Navigation List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: navItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = currentIndex == index;

                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      appProvider.setScreenIndex(index);
                      // Close drawer if opened on mobile screen
                      if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                        Navigator.of(context).pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 13.5,
                                  ),
                                ),
                                Text(
                                  item['subtitle'] as String,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white.withOpacity(0.8) : const Color(0xFF64748B),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer status badge
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REST API & MySQL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Online • v1.0.0',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
