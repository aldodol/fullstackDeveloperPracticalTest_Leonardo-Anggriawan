import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/material_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/stock_provider.dart';
import '../widgets/app_sidebar.dart';
import '../utils/api_constants.dart';
import '../utils/theme.dart';
import 'dashboard_screen.dart';
import 'materials_screen.dart';
import 'goods_out_screen.dart';
import 'goods_return_screen.dart';
import 'stock_ledger_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Initial fetch of data across providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    final matProvider = Provider.of<MaterialProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);

    await Future.wait([
      matProvider.init(),
      txProvider.loadGoodsOut(),
      txProvider.loadGoodsReturns(),
      stockProvider.refreshAll(),
    ]);
  }

  void _showApiConfigDialog() {
    final controller = TextEditingController(text: ApiConstants.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfigurasi Endpoint REST API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah alamat base URL REST API backend jika berjalan pada port atau host yang berbeda:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Base URL API',
                hintText: 'http://localhost:5000/api',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ApiConstants.baseUrl = controller.text.trim();
              Navigator.of(ctx).pop();
              _loadAllData();
              Provider.of<AppProvider>(context, listen: false).showNotification(
                'Endpoint API diubah ke: ${ApiConstants.baseUrl}',
              );
            },
            child: const Text('Simpan & Muat Ulang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentIndex = appProvider.currentScreenIndex;

    final screens = const [
      DashboardScreen(),
      MaterialsScreen(),
      GoodsOutScreen(),
      GoodsReturnScreen(),
      StockLedgerScreen(),
    ];

    final screenTitles = [
      'Dashboard & Ringkasan',
      'Master Bahan Baku',
      'Transaksi Barang Keluar',
      'Transaksi Pengembalian',
      'Riwayat Transaksi & Kartu Stok',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 850;

        return Scaffold(
          key: _scaffoldKey,
          drawer: isMobile ? const Drawer(child: AppSidebar()) : null,
          body: Row(
            children: [
              if (!isMobile) const AppSidebar(),
              Expanded(
                child: Column(
                  children: [
                    // Top App Bar
                    Container(
                      height: 68,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: AppTheme.border, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isMobile)
                            IconButton(
                              icon: const Icon(Icons.menu_rounded),
                              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            ),
                          Text(
                            screenTitles[currentIndex],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),

                          // API Config & Status Button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: _showApiConfigDialog,
                            icon: const Icon(Icons.dns_rounded, size: 16, color: AppTheme.primary),
                            label: const Text('API Config', style: TextStyle(fontSize: 12.5)),
                          ),
                          const SizedBox(width: 10),

                          // Refresh all data button
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                            tooltip: 'Segarkan Seluruh Data',
                            onPressed: () {
                              _loadAllData();
                              appProvider.showNotification('Data inventaris berhasil disegarkan');
                            },
                          ),
                        ],
                      ),
                    ),

                    // Notification banner if any
                    if (appProvider.notificationMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        color: appProvider.isErrorNotification ? AppTheme.danger : AppTheme.success,
                        child: Row(
                          children: [
                            Icon(
                              appProvider.isErrorNotification
                                  ? Icons.error_outline_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                appProvider.notificationMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 16),
                              onPressed: () => appProvider.clearNotification(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                    // Active Screen Body
                    Expanded(
                      child: IndexedStack(
                        index: currentIndex,
                        children: screens,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
