import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/material_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/stock_provider.dart';
import 'screens/main_layout.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => MaterialProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
      ],
      child: MaterialApp(
        title: 'Sistem Transaksi Bahan Baku',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainLayout(),
      ),
    );
  }
}
