import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/change_badge.dart';
import '../widgets/coin_row.dart';
import '../widgets/connection_banner.dart';
import 'coin_details_screen.dart';
import 'coin_list_screen.dart';

class MarketStatsScreen extends StatefulWidget {
  const MarketStatsScreen({super.key});
  @override
  State<MarketStatsScreen> createState() => _MarketStatsScreenState();
}

class _MarketStatsScreenState extends State<MarketStatsScreen> {
  MarketOverview? _overview;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final o = await context.read<ApiService>().fetchOverview();
      if (mounted) setState(() { _overview = o; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics'), actions: const [StatusPill()]),
      body: CoinListBody(
        showSort: true,
        header: _Overview(overview: _overview, error: _error, onRetry: _load),
        onRefresh: _load,
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final MarketOverview? overview;
  final String? error;
  final VoidCallback onRetry;
  const _Overview({required this.overview, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final o = overview;
    if (o == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: error == null
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(error!, style: const TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ]),
        ),
      );
    }
    final total = (o.gainers + o.losers).clamp(1, 1 << 30);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Stat('24h volume', fmtUsd(o.totalQuoteVolume)),
            _Stat('Pairs', fmtInt(o.pairs)),
            _Stat('Avg change', fmtPercent(o.avgChangePercent), color: o.avgChangePercent >= 0 ? AppColors.up : AppColors.down),
          ]),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(children: [
                Expanded(flex: o.gainers == 0 ? 0 : o.gainers, child: Container(color: AppColors.up)),
                const SizedBox(width: 2),
                Expanded(flex: o.losers == 0 ? 0 : o.losers, child: Container(color: AppColors.down)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${o.gainers} up (${(o.gainers * 100 / total).round()}%)', style: const TextStyle(color: AppColors.up, fontSize: 12.5, fontWeight: FontWeight.w600)),
            Text('${o.losers} down', style: const TextStyle(color: AppColors.down, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          const Text('Top movers', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final t in [...o.topGainers.take(3), ...o.topLosers.take(3)]) _MoverChip(t),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Stat(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, fontFeatures: tabularFigures)),
        ]),
      );
}

class _MoverChip extends StatelessWidget {
  final Ticker t;
  const _MoverChip(this.t);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Navigator.push(context, fadeSlideRoute(CoinDetailsScreen(symbol: t.symbol))),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Text(t.baseAsset, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 8),
              ChangeBadge(t.changePercent),
            ]),
          ),
        ),
      );
}
