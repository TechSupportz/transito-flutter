import 'package:material_ui/material_ui.dart';
import 'package:transito/models/app/app_typography.dart';

/// The favourites service selector. Selection belongs to the containing screen.
class BusServiceChecklist extends StatelessWidget {
  const BusServiceChecklist({
    super.key,
    required this.services,
    required this.selectedServices,
    required this.onChanged,
  });

  final List<String> services;
  final Set<String> selectedServices;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final int selectedCount = services.where(selectedServices.contains).length;
    final bool? parentValue = selectedCount == 0
        ? false
        : selectedCount == services.length
        ? true
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ServiceCheckboxRow(
          label: 'Bus Services',
          value: parentValue,
          tristate: true,
          onChanged: services.isEmpty
              ? null
              : (_) {
                  // Preserve the existing behavior: a partial selection clears on tap.
                  onChanged(parentValue == false ? services.toSet() : <String>{});
                },
        ),
        const SizedBox(height: 2),
        for (final String service in services)
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: _ServiceCheckboxRow(
              label: service,
              value: selectedServices.contains(service),
              onChanged: (value) {
                final Set<String> selection = {...selectedServices};
                if (value == true) {
                  selection.add(service);
                } else {
                  selection.remove(service);
                }
                onChanged(selection);
              },
            ),
          ),
      ],
    );
  }
}

class _ServiceCheckboxRow extends StatelessWidget {
  const _ServiceCheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.tristate = false,
  });

  final String label;
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
          Flexible(child: Text(label, style: AppTypography.checkboxLabel)),
        ],
      ),
    );
  }
}
