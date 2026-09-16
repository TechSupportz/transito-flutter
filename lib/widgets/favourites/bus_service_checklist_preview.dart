import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/widgets/favourites/bus_service_checklist.dart';

@Preview(name: 'Bus services - light', group: 'Favourites', size: Size(360, 300))
Widget busServiceChecklistLightPreview() => _checklistPreview(Brightness.light);

@Preview(name: 'Bus services - dark', group: 'Favourites', size: Size(360, 300))
Widget busServiceChecklistDarkPreview() => _checklistPreview(Brightness.dark);

Widget _checklistPreview(Brightness brightness) {
  Set<String> selection = {'10'};

  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.veryPurple, brightness: brightness),
      fontFamily: 'DMSans',
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StatefulBuilder(
          builder: (context, setState) => BusServiceChecklist(
            services: const ['10', '14', '14A', 'D1'],
            selectedServices: selection,
            onChanged: (value) => setState(() => selection = value),
          ),
        ),
      ),
    ),
  );
}
