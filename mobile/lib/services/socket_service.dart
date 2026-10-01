import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../models/ticker.dart';

enum LinkState { connecting, live, reconnecting }

/// Single WebSocket to OUR backend (never Binance). Reconnects with exponential backoff and
/// treats a silent socket (backend sends a status frame every 5s) as dead.
class SocketService {
  void Function(List<Ticker>)? onTickers;
  void Function(Map<String, dynamic>)? onStatus;
  void Function(LinkState)? onLink;
  void Function()? onOpen;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _retry;
  Timer? _watchdog;
  DateTime _lastMessage = DateTime.now();
  int _attempt = 0;
  bool _disposed = false;
  final _rand = Random();

  void connect() {
    if (_channel != null || _disposed) return; // never open two sockets
    onLink?.call(_attempt == 0 ? LinkState.connecting : LinkState.reconnecting);
    final WebSocketChannel ch;
    try {
      ch = WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl));
    } catch (_) {
      _scheduleRetry();
      return;
    }
    _channel = ch;

    void closed() {
      if (!identical(_channel, ch)) return; // already handled
      _teardown();
      _scheduleRetry();
    }

    ch.ready.then((_) {
      if (!identical(_channel, ch)) return;
      _attempt = 0;
      _lastMessage = DateTime.now();
      onLink?.call(LinkState.live);
      onOpen?.call();
    }).catchError((_) => closed());

    _sub = ch.stream.listen(_onData, onError: (_) => closed(), onDone: closed);

    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      if (DateTime.now().difference(_lastMessage) > const Duration(seconds: 15)) closed();
    });
  }

  void _onData(dynamic raw) {
    _lastMessage = DateTime.now();
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      switch (msg['type']) {
        case 'tickers':
          final list =
              (msg['data'] as List).map((e) => Ticker.fromJson(e as Map<String, dynamic>)).toList();
          onTickers?.call(list);
          break;
        case 'status':
          onStatus?.call(msg);
          break;
      }
    } catch (_) {
      // ignore malformed frames
    }
  }

  void _teardown() {
    _watchdog?.cancel();
    _sub?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _sub = null;
  }

  void _scheduleRetry() {
    if (_disposed) return;
    onLink?.call(LinkState.reconnecting);
    final base = min(1000 * pow(2, _attempt).toInt(), 15000);
    _attempt++;
    final delay = Duration(milliseconds: (base * (0.8 + _rand.nextDouble() * 0.4)).round());
    _retry?.cancel();
    _retry = Timer(delay, connect);
  }

  /// Called when the app returns to the foreground: reconnect immediately.
  void reconnectNow() {
    if (_disposed) return;
    _retry?.cancel();
    _teardown();
    _attempt = 0;
    connect();
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _teardown();
  }
}
