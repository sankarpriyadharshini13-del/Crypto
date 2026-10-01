import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_shell.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'state/market_store.dart';
import 'state/watchlist_store.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CryptoPulseApp());
}

class CryptoPulseApp extends StatelessWidget {
  const CryptoPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<MarketStore>(
          create: (c) => MarketStore(c.read<ApiService>(), SocketService())..start(),
        ),
        ChangeNotifierProvider<WatchlistStore>(create: (_) => WatchlistStore()..load()),
      ],
      child: MaterialApp(
        title: 'Crypto Pulse',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        themeAnimationDuration: const Duration(milliseconds: 220),
        themeAnimationCurve: Curves.easeOutCubic,
        home: const HomeShell(),
      ),
    );
  }
}
