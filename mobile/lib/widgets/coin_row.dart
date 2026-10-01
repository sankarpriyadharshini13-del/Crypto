import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticker.dart';
import '../state/market_store.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'change_badge.dart';
import 'flash_price.dart';

PageRouteBuilder<T> fadeSlideRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved), child: child),
        );
      },
    );

/// One list row. Listens to its own symbol's notifier, so a tick rebuilds only this row.
class CoinRow extends StatelessWidget {
  final String symbol;
  final VoidCallback onTap;
  final Widget? trailingAction;
  const CoinRow({super.key, required this.symbol, required this.onTap, this.trailingAction});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<MarketStore>().notifier(symbol);
    if (notifier == null) return const SizedBox.shrink();
    return ValueListenableBuilder<Ticker>(
      valueListenable: notifier,
      builder: (_, t, __) {
        final isUp = t.changePercent >= 0;
        final accent = isUp ? AppColors.up : AppColors.down;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.surface.withOpacity(0.92),
                AppColors.surface2.withOpacity(0.72),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isUp ? accent.withOpacity(0.25) : AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Row(children: [
              _Avatar(t.baseAsset),
              const SizedBox(width: 12),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.baseAsset, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Vol ${fmtUsd(t.quoteVolume)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted, fontFeatures: tabularFigures)),
                ]),
              ),
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                FlashPrice(t.price),
                const SizedBox(height: 4),
                ChangeBadge(t.changePercent),
              ]),
              if (trailingAction != null) ...[const SizedBox(width: 4), trailingAction!],
            ]),
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  final String asset;
  const _Avatar(this.asset);

  @override
  Widget build(BuildContext context) {
    final hue = (asset.hashCode % 360).toDouble();
    final color = HSLColor.fromAHSL(1, hue, 0.55, 0.62).toColor();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withOpacity(0.16), shape: BoxShape.circle),
      child: Text(asset.isEmpty ? '?' : asset.substring(0, asset.length >= 2 ? 2 : 1),
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }
}
