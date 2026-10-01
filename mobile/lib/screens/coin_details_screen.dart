import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticker.dart';
import '../services/api_service.dart';
import '../state/market_store.dart';
import '../state/watchlist_store.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/change_badge.dart';
import '../widgets/connection_banner.dart';
import '../widgets/flash_price.dart';
import '../widgets/price_chart.dart';
import '../widgets/state_views.dart';

const _ranges = ['1h', '24h', '7d', '30d'];

class CoinDetailsScreen extends StatefulWidget {
  final String symbol;
  const CoinDetailsScreen({super.key, required this.symbol});
  @override
  State<CoinDetailsScreen> createState() => _CoinDetailsScreenState();
}

class _CoinDetailsScreenState extends State<CoinDetailsScreen> {
  String _range = '24h';
  List<Candle>? _candles;
  String? _error;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    final range = _range;
    try {
      final data = await context.read<ApiService>().fetchHistory(widget.symbol, range);
      if (!mounted || range != _range) return;
      setState(() { _candles = data; _loading = false; _error = null; });
    } catch (e) {
      if (!mounted || range != _range) return;
      setState(() { _loading = false; if (_candles == null || !silent) _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<MarketStore>().notifier(widget.symbol);
    final watch = context.watch<WatchlistStore>();
    if (notifier == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const MessageView(icon: Icons.help_outline, title: 'Unknown coin', body: 'This symbol isn’t available.'),
      );
    }
    final starred = watch.contains(widget.symbol);
    final first = notifier.value; // static bits (title) only; live values use the builders below
    return Scaffold(
      appBar: AppBar(
        title: Text('${first.baseAsset}/${first.quoteAsset}', style: const TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            tooltip: starred ? 'Remove from watchlist' : 'Add to watchlist',
            icon: Icon(starred ? Icons.star_rounded : Icons.star_border_rounded, color: starred ? AppColors.warn : AppColors.muted),
            onPressed: () => watch.toggle(widget.symbol),
          ),
          const StatusPill(),
        ],
      ),
      body: Column(children: [
        const ConnectionBanner(),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            ValueListenableBuilder<Ticker>(
              valueListenable: notifier,
              builder: (_, t, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FlashPrice(t.price, fontSize: 38, weight: FontWeight.w800),
                const SizedBox(height: 8),
                Row(children: [
                  ChangeBadge(t.changePercent, large: true),
                  const SizedBox(width: 10),
                  Text('${t.change >= 0 ? '+' : ''}${fmtPrice(t.change)} today',
                      style: TextStyle(color: t.change >= 0 ? AppColors.up : AppColors.down, fontWeight: FontWeight.w600, fontFeatures: tabularFigures)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            _chartCard(),
            const SizedBox(height: 20),
            const Text('24h statistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ValueListenableBuilder<Ticker>(valueListenable: notifier, builder: (_, t, __) => _statsGrid(t)),
          ]),
        ),
      ]),
    );
  }

  Widget _chartCard() {
    Widget body;
    if (_loading && _candles == null) {
      body = const LoadingView(label: 'Loading history…');
    } else if (_error != null && (_candles == null || _candles!.isEmpty)) {
      body = MessageView(icon: Icons.show_chart, title: 'History unavailable', body: _error!, actionLabel: 'Retry', onAction: _load);
    } else if (_candles == null || _candles!.length < 2) {
      body = const MessageView(
        icon: Icons.hourglass_top_rounded,
        title: 'Collecting history',
        body: 'The server records prices as they stream in. The chart fills in after a couple of minutes.',
      );
    } else {
      body = PriceChart(candles: _candles!);
    }
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final r in _ranges)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(r.toUpperCase()),
                selected: _range == r,
                onSelected: (_) {
                  if (_range == r) return;
                  setState(() { _range = r; _candles = null; });
                  _load();
                },
                showCheckmark: false,
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.surface2,
                side: BorderSide(
                  color: _range == r ? AppColors.accent : AppColors.border,
                  width: 1,
                ),
                labelStyle: TextStyle(
                  color: _range == r ? AppColors.bg : AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        SizedBox(height: 240, child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey('$_range-${_candles?.length ?? -1}-$_loading-$_error'), child: body))),
        if (_candles != null && _candles!.length >= 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(fmtTime(_candles!.first.time), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
              Text(fmtTime(_candles!.last.time), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
            ]),
          ),
      ]),
    );
  }

  Widget _statsGrid(Ticker t) {
    final tiles = <(String, String)>[
      ('24h high', fmtPrice(t.high)),
      ('24h low', fmtPrice(t.low)),
      ('24h open', fmtPrice(t.open)),
      ('Volume (${t.baseAsset})', fmtCompact(t.volume)),
      ('Volume (${t.quoteAsset})', fmtUsd(t.quoteVolume)),
      ('Trades', fmtInt(t.trades)),
    ];
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (final (label, value) in tiles)
        LayoutBuilder(builder: (context, _) {
          final w = (MediaQuery.of(context).size.width - 32 - 10) / 2;
          return Container(
            width: w,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFeatures: tabularFigures)),
            ]),
          );
        }),
    ]);
  }
}
