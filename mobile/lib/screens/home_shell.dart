import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/market_store.dart';
import 'coin_list_screen.dart';
import 'market_stats_screen.dart';
import 'watchlist_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mobile OSes silently drop sockets in the background; reconnect and resync on return.
    if (state == AppLifecycleState.resumed) {
      final store = context.read<MarketStore>();
      store.socket.reconnectNow();
      store.refresh(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: [
        const CoinListScreen(),
        const MarketStatsScreen(),
        WatchlistScreen(onBrowse: () => setState(() => _index = 0)),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: 'Markets'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Statistics'),
          NavigationDestination(icon: Icon(Icons.star_outline_rounded), selectedIcon: Icon(Icons.star_rounded), label: 'Watchlist'),
        ],
      ),
    );
  }
}
