import 'package:flutter/foundation.dart';
import '../models/ticker.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

enum LoadState { loading, ready, error }

@immutable
class ConnInfo {
  final LinkState link;
  final bool? binance;
  final bool? redis;
  final bool? postgres;
  const ConnInfo(this.link, {this.binance, this.redis, this.postgres});

  ConnInfo copyWith({LinkState? link, bool? binance, bool? redis, bool? postgres}) => ConnInfo(
        link ?? this.link,
        binance: binance ?? this.binance,
        redis: redis ?? this.redis,
        postgres: postgres ?? this.postgres,
      );
}

/// Holds one ValueNotifier per symbol so a price tick rebuilds only that row.
/// The store itself notifies only when the *set* of symbols or the load state changes.
class MarketStore extends ChangeNotifier {
  MarketStore(this.api, this.socket);

  final ApiService api;
  final SocketService socket;

  final Map<String, ValueNotifier<Ticker>> _tickers = {};
  final ValueNotifier<ConnInfo> conn = ValueNotifier(const ConnInfo(LinkState.connecting));

  LoadState loadState = LoadState.loading;
  String? error;

  List<Ticker> get snapshot => _tickers.values.map((n) => n.value).toList();
  ValueNotifier<Ticker>? notifier(String symbol) => _tickers[symbol];

  Future<void> start() async {
    socket.onTickers = _apply;
    socket.onStatus = (m) => conn.value = conn.value.copyWith(
          binance: m['binance'] as bool?,
          redis: m['redis'] as bool?,
          postgres: m['postgres'] as bool?,
        );
    socket.onLink = (s) => conn.value = conn.value.copyWith(link: s);
    // After every (re)connect, re-sync with a REST snapshot so nothing missed while offline stays stale.
    socket.onOpen = () => refresh(silent: true);
    socket.connect();
    await refresh();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      loadState = LoadState.loading;
      error = null;
      notifyListeners();
    }
    try {
      final list = await api.fetchTickers();
      _apply(list);
      loadState = LoadState.ready;
      error = null;
    } catch (e) {
      if (_tickers.isEmpty) {
        loadState = LoadState.error;
        error = e.toString();
      } else {
        loadState = LoadState.ready;
      }
    }
    notifyListeners();
  }

  void _apply(List<Ticker> updates) {
    var added = false;
    for (final t in updates) {
      final n = _tickers[t.symbol];
      if (n == null) {
        _tickers[t.symbol] = ValueNotifier<Ticker>(t);
        added = true;
      } else {
        n.value = t;
      }
    }
    if (added && loadState == LoadState.ready) notifyListeners();
  }

  @override
  void dispose() {
    socket.dispose();
    for (final n in _tickers.values) {
      n.dispose();
    }
    conn.dispose();
    super.dispose();
  }
}
