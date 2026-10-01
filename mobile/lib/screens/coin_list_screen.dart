import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/view_spec.dart';
import '../state/market_store.dart';
import '../state/watchlist_store.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_row.dart';
import '../widgets/connection_banner.dart';
import '../widgets/controls_bar.dart';
import '../widgets/state_views.dart';
import 'coin_details_screen.dart';

/// Shared body: banner + controls + virtualised live list with loading / error / empty states.
class CoinListBody extends StatefulWidget {
  final bool showSort;
  final Widget? header;
  final ViewSpec initial;
  final Future<void> Function()? onRefresh;
  const CoinListBody({super.key, this.showSort = false, this.header, this.initial = const ViewSpec(), this.onRefresh});

  @override
  State<CoinListBody> createState() => _CoinListBodyState();
}

class _CoinListBodyState extends State<CoinListBody> {
  late ViewSpec _spec = widget.initial;
  Timer? _resort;

  @override
  void initState() {
    super.initState();
    // Order follows live data, but re-sorts at most every 4s so rows don't jump around.
    _resort = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _resort?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MarketStore>();
    final watch = context.watch<WatchlistStore>();

    Widget content;
    if (store.loadState == LoadState.loading) {
      content = const LoadingView();
    } else if (store.loadState == LoadState.error) {
      content = MessageView(
        icon: Icons.cloud_off_rounded,
        title: 'Can’t load markets',
        body: store.error ?? 'The server didn’t respond.',
        actionLabel: 'Try again',
        onAction: () => store.refresh(),
      );
    } else {
      final symbols = _spec.apply(store.snapshot).map((t) => t.symbol).toList();
      if (symbols.isEmpty) {
        content = MessageView(
          icon: Icons.search_off_rounded,
          title: 'No coins match',
          body: _spec.query.isEmpty ? 'Nothing to show for this filter yet.' : 'Nothing matches “${_spec.query}”. Try a different symbol.',
          actionLabel: 'Clear search and filters',
          onAction: () => setState(() => _spec = _spec.copyWith(query: '', filter: QuickFilter.all)),
        );
      } else {
        content = RefreshIndicator(
          onRefresh: () async {
            await store.refresh(silent: true);
            await widget.onRefresh?.call();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (widget.header != null) SliverToBoxAdapter(child: widget.header),
              SliverFixedExtentList(
                itemExtent: 80,
                delegate: SliverChildBuilderDelegate(
                  (_, i) => CoinRow(
                    key: ValueKey(symbols[i]),
                    symbol: symbols[i],
                    onTap: () => Navigator.push(context, fadeSlideRoute(CoinDetailsScreen(symbol: symbols[i]))),
                    trailingAction: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(watch.contains(symbols[i]) ? Icons.star_rounded : Icons.star_border_rounded,
                          color: watch.contains(symbols[i]) ? AppColors.warn : AppColors.muted),
                      onPressed: () => watch.toggle(symbols[i]),
                    ),
                  ),
                  childCount: symbols.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      }
    }

    return Column(children: [
      const ConnectionBanner(),
      ControlsBar(spec: _spec, showSort: widget.showSort, onChanged: (s) => setState(() => _spec = s)),
      Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: KeyedSubtree(key: ValueKey(store.loadState), child: content))),
    ]);
  }
}

class CoinListScreen extends StatelessWidget {
  const CoinListScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Markets'), actions: const [StatusPill()]),
        body: const CoinListBody(),
      );
}
