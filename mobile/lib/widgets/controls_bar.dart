import 'package:flutter/material.dart';
import '../models/view_spec.dart';
import '../theme/app_theme.dart';

/// Search field + quick filters + sort chips. Emits a new ViewSpec on every change.
class ControlsBar extends StatefulWidget {
  final ViewSpec spec;
  final ValueChanged<ViewSpec> onChanged;
  final bool showSort;
  final String hint;
  const ControlsBar({super.key, required this.spec, required this.onChanged, this.showSort = true, this.hint = 'Search coins'});

  @override
  State<ControlsBar> createState() => _ControlsBarState();
}

class _ControlsBarState extends State<ControlsBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: SizedBox(
          height: 46,
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onChanged: (v) => widget.onChanged(spec.copyWith(query: v)),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              suffixIcon: spec.query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged(spec.copyWith(query: ''));
                      }),
            ),
          ),
        ),
      ),
      SizedBox(
        height: 38,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          for (final f in QuickFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f.label),
                selected: spec.filter == f,
                onSelected: (_) => widget.onChanged(spec.copyWith(filter: f)),
                showCheckmark: false,
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.surface2,
                side: BorderSide(
                  color: spec.filter == f ? AppColors.accent : AppColors.border,
                  width: 1,
                ),
                labelStyle: TextStyle(
                  color: spec.filter == f ? AppColors.bg : AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
        ]),
      ),
      if (widget.showSort) ...[
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            for (final k in SortKey.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: spec.sort == k ? Icon(spec.ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: AppColors.bg) : null,
                  label: Text(k.label),
                  selected: spec.sort == k,
                  onSelected: (_) => widget.onChanged(spec.sort == k
                      ? spec.copyWith(ascending: !spec.ascending)
                      : spec.copyWith(sort: k, ascending: k == SortKey.name)),
                  showCheckmark: false,
                  selectedColor: AppColors.accentStrong,
                  backgroundColor: AppColors.surface2,
                  side: BorderSide(
                    color: spec.sort == k ? AppColors.accentStrong : AppColors.border,
                    width: 1,
                  ),
                  labelStyle: TextStyle(
                    color: spec.sort == k ? AppColors.text : AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
          ]),
        ),
      ],
      const SizedBox(height: 8),
    ]);
  }
}
