import 'ticker.dart';

enum SortKey { name, price, change, volume, trades }

enum QuickFilter { all, gainers, losers, highVolume }

extension SortKeyLabel on SortKey {
  String get label => const {
        SortKey.name: 'Name',
        SortKey.price: 'Price',
        SortKey.change: '24h %',
        SortKey.volume: 'Volume',
        SortKey.trades: 'Trades',
      }[this]!;
}

extension QuickFilterLabel on QuickFilter {
  String get label => const {
        QuickFilter.all: 'All',
        QuickFilter.gainers: 'Gainers',
        QuickFilter.losers: 'Losers',
        QuickFilter.highVolume: r'Volume > $50M',
      }[this]!;
}

/// Search + filter + sort, applied client-side so live updates never need a refetch.
class ViewSpec {
  final String query;
  final SortKey sort;
  final bool ascending;
  final QuickFilter filter;

  const ViewSpec({
    this.query = '',
    this.sort = SortKey.volume,
    this.ascending = false,
    this.filter = QuickFilter.all,
  });

  ViewSpec copyWith({String? query, SortKey? sort, bool? ascending, QuickFilter? filter}) => ViewSpec(
        query: query ?? this.query,
        sort: sort ?? this.sort,
        ascending: ascending ?? this.ascending,
        filter: filter ?? this.filter,
      );

  List<Ticker> apply(List<Ticker> all) {
    final q = query.trim().toUpperCase();
    final out = all.where((t) {
      if (q.isNotEmpty && !t.symbol.contains(q) && !t.baseAsset.contains(q)) return false;
      switch (filter) {
        case QuickFilter.all:
          return true;
        case QuickFilter.gainers:
          return t.changePercent > 0;
        case QuickFilter.losers:
          return t.changePercent < 0;
        case QuickFilter.highVolume:
          return t.quoteVolume >= 50e6;
      }
    }).toList();

    int cmp(Ticker a, Ticker b) {
      switch (sort) {
        case SortKey.name:
          return a.baseAsset.compareTo(b.baseAsset);
        case SortKey.price:
          return a.price.compareTo(b.price);
        case SortKey.change:
          return a.changePercent.compareTo(b.changePercent);
        case SortKey.volume:
          return a.quoteVolume.compareTo(b.quoteVolume);
        case SortKey.trades:
          return a.trades.compareTo(b.trades);
      }
    }

    out.sort((a, b) => ascending ? cmp(a, b) : cmp(b, a));
    return out;
  }
}
