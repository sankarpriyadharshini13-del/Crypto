import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Watchlist is stored on the device; live prices still come from the backend stream.
class WatchlistStore extends ChangeNotifier {
  static const _key = 'watchlist_v1';
  final List<String> _symbols = [];
  bool loaded = false;

  List<String> get symbols => List.unmodifiable(_symbols);
  bool contains(String s) => _symbols.contains(s);

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _symbols);
    } catch (_) {}
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _symbols
        ..clear()
        ..addAll(prefs.getStringList(_key) ?? const <String>[]);
    } catch (_) {}
    loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String symbol) async {
    contains(symbol) ? _symbols.remove(symbol) : _symbols.add(symbol);
    notifyListeners();
    await _save();
  }

  Future<void> remove(String symbol) async {
    if (_symbols.remove(symbol)) {
      notifyListeners();
      await _save();
    }
  }
}
