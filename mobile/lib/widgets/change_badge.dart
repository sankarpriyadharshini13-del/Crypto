import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class ChangeBadge extends StatelessWidget {
  final double percent;
  final bool large;
  const ChangeBadge(this.percent, {super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = percent > 0 ? AppColors.up : (percent < 0 ? AppColors.down : AppColors.muted);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 6 : 4),
      decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(8)),
      child: Text(
        fmtPercent(percent),
        style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: large ? 15 : 13, fontFeatures: tabularFigures),
      ),
    );
  }
}
