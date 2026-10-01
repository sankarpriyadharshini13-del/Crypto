import 'package:intl/intl.dart';

final _big = NumberFormat('#,##0.00');
final _mid = NumberFormat('#,##0.00##');
final _small = NumberFormat('0.0000##');
final _int = NumberFormat('#,##0');
final _compact = NumberFormat.compact();

String fmtPrice(double p) {
  if (p >= 1000) return _big.format(p);
  if (p >= 1) return _mid.format(p);
  if (p >= 0.01) return _small.format(p);
  return p.toStringAsFixed(8);
}

String fmtPercent(double p) => '${p >= 0 ? '+' : ''}${p.toStringAsFixed(2)}%';

String fmtCompact(double v) => _compact.format(v);

String fmtUsd(double v) => '\$${_compact.format(v)}';

String fmtInt(num v) => _int.format(v);

String fmtTime(DateTime t) => DateFormat('d MMM HH:mm').format(t);
