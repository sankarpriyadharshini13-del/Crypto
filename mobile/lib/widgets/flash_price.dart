import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Price text that briefly tints green/red when the value moves. Only this widget repaints on a tick.
class FlashPrice extends StatefulWidget {
  final double price;
  final double fontSize;
  final FontWeight weight;
  const FlashPrice(this.price, {super.key, this.fontSize = 16, this.weight = FontWeight.w700});

  @override
  State<FlashPrice> createState() => _FlashPriceState();
}

class _FlashPriceState extends State<FlashPrice> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600), value: 1);
  Color _from = AppColors.text;

  @override
  void didUpdateWidget(FlashPrice old) {
    super.didUpdateWidget(old);
    if (widget.price != old.price) {
      _from = widget.price > old.price ? AppColors.up : AppColors.down;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Text(
        fmtPrice(widget.price),
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: widget.weight,
          fontFeatures: tabularFigures,
          color: Color.lerp(_from, AppColors.text, Curves.easeOut.transform(_c.value)),
        ),
      ),
    );
  }
}
