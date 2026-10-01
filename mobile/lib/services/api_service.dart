import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ticker.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client = http.Client();
  static const _timeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse(AppConfig.apiBaseUrl).replace(path: path, queryParameters: query);
    try {
      final res = await _client.get(uri).timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        throw ApiException((body['error'] ?? 'Request failed (${res.statusCode})') as String);
      }
      return body;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Cannot reach the server. Check your connection and the backend address.');
    }
  }

  Future<List<Ticker>> fetchTickers() async {
    final body = await _get('/api/market/tickers', {'limit': '1000'});
    return (body['data'] as List).map((e) => Ticker.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MarketOverview> fetchOverview() async {
    final body = await _get('/api/market/stats');
    return MarketOverview.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<Candle>> fetchHistory(String symbol, String range) async {
    final body = await _get('/api/market/history/$symbol', {'range': range});
    return (body['data'] as List).map((e) => Candle.fromJson(e as Map<String, dynamic>)).toList();
  }
}
