import 'package:material_ui/material_ui.dart';

/// A fixed parent checkbox above a scrollable list of child checkboxes.
///
/// Requires a bounded height. Selection belongs to the containing screen.
class ParentChildCheckboxList<T> extends StatelessWidget {
  const ParentChildCheckboxList({
    super.key,
    required this.parent,
    required this.children,
    required this.selectedChildren,
    required this.childBuilder,
    required this.onChanged,
  });

  final Widget parent;
  final List<T> children;
  final Set<T> selectedChildren;
  final Widget Function(BuildContext context, T child) childBuilder;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) {
    final int selectedCount = children.where(selectedChildren.contains).length;
    final bool? parentValue = selectedCount == 0
        ? false
        : selectedCount == children.length
        ? true
        : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _CheckboxRow(
            label: parent,
            value: parentValue,
            tristate: true,
            onChanged: children.isEmpty
                ? null
                : (_) {
                    // Preserve the existing behavior: a partial selection clears on tap.
                    onChanged(parentValue == false ? children.toSet() : <T>{});
                  },
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              final Color surface = Theme.of(context).colorScheme.surface;
              return LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  surface,
                  surface.withValues(alpha: 0),
                  surface.withValues(alpha: 0),
                  surface,
                ],
                stops: const [0, 0.05, 0.95, 1],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstOut,
            child: ListView.builder(
              primary: false,
              padding: const EdgeInsets.only(left: 25, top: 8, bottom: 16),
              itemCount: children.length,
              itemBuilder: (context, index) {
                final T child = children[index];
                return _CheckboxRow(
                  label: childBuilder(context, child),
                  value: selectedChildren.contains(child),
                  onChanged: (value) {
                    final Set<T> selection = {...selectedChildren};
                    if (value == true) {
                      selection.add(child);
                    } else {
                      selection.remove(child);
                    }
                    onChanged(selection);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.tristate = false,
  });

  final Widget label;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool tristate;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          Transform.scale(
            scale: 1.35,
            child: Checkbox(
              value: value,
              tristate: tristate,
              splashRadius: 0,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(child: label),
        ],
      ),
    );
  }
}
