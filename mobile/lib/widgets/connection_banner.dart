import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../state/market_store.dart';
import '../theme/app_theme.dart';

/// Slim banner that appears only when something is wrong; collapses away when the feed is healthy.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final conn = context.read<MarketStore>().conn;
    return ValueListenableBuilder<ConnInfo>(
      valueListenable: conn,
      builder: (_, c, __) {
        String? text;
        Color color = AppColors.warn;
        if (c.link != LinkState.live) {
          text = c.link == LinkState.connecting ? 'Connecting to server…' : 'Connection lost. Reconnecting — showing last known prices.';
        } else if (c.redis == false) {
          text = 'Live distribution is interrupted. Prices may be delayed.';
        } else if (c.binance == false) {
          text = 'Binance feed interrupted. Prices may be stale until it reconnects.';
        }
        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: text == null
              ? const SizedBox(width: double.infinity)
              : Container(
                  width: double.infinity,
                  color: color.withOpacity(0.14),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: color)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600))),
                  ]),
                ),
        );
      },
    );
  }
}

/// Small status dot + label for app bars.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key});

  @override
  Widget build(BuildContext context) {
    final conn = context.read<MarketStore>().conn;
    return ValueListenableBuilder<ConnInfo>(
      valueListenable: conn,
      builder: (_, c, __) {
        final live = c.link == LinkState.live && c.binance != false && c.redis != false;
        final color = live ? AppColors.up : AppColors.warn;
        final label = c.link != LinkState.live ? 'Offline' : (live ? 'Live' : 'Delayed');
        return Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        );
      },
    );
  }
}
