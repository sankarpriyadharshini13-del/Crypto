import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/market_store.dart';
import '../state/watchlist_store.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_row.dart';
import '../widgets/connection_banner.dart';
import '../widgets/state_views.dart';
import 'coin_details_screen.dart';

class WatchlistScreen extends StatelessWidget {
  final VoidCallback onBrowse;
  const WatchlistScreen({super.key, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<WatchlistStore>();
    final store = context.watch<MarketStore>();
    final symbols = watch.symbols.where((s) => store.notifier(s) != null).toList();

    Widget body;
    if (!watch.loaded || store.loadState == LoadState.loading) {
      body = const LoadingView(label: 'Loading watchlist…');
    } else if (watch.symbols.isEmpty) {
      body = MessageView(
        icon: Icons.star_border_rounded,
        title: 'Your watchlist is empty',
        body: 'Tap the star on any coin to follow its live price here.',
        actionLabel: 'Browse markets',
        onAction: onBrowse,
      );
    } else if (symbols.isEmpty) {
      body = MessageView(
        icon: Icons.cloud_off_rounded,
        title: 'Prices unavailable',
        body: 'Your coins are saved, but the server isn’t sending prices right now.',
        actionLabel: 'Try again',
        onAction: () => store.refresh(),
      );
    } else {
      body = ListView.builder(
        itemExtent: 68,
        itemCount: symbols.length,
        itemBuilder: (_, i) {
          final s = symbols[i];
          return Dismissible(
            key: ValueKey(s),
            direction: DismissDirection.endToStart,
            background: Container(
              color: AppColors.down.withOpacity(0.2),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(Icons.delete_outline, color: AppColors.down),
            ),
            onDismissed: (_) => watch.remove(s),
            child: CoinRow(
              symbol: s,
              onTap: () => Navigator.push(context, fadeSlideRoute(CoinDetailsScreen(symbol: s))),
              trailingAction: IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove from watchlist',
                icon: const Icon(Icons.star_rounded, color: AppColors.warn),
                onPressed: () => watch.remove(s),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist'), actions: const [StatusPill()]),
      body: Column(children: [
        const ConnectionBanner(),
        Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: KeyedSubtree(key: ValueKey('${symbols.isEmpty}-${watch.symbols.isEmpty}-${store.loadState}'), child: body))),
      ]),
    );
  }
}
