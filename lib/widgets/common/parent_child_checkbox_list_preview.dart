import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/common/parent_child_checkbox_list.dart';

@Preview(name: 'Parent-child checklist - light', group: 'Common', size: Size(360, 300))
Widget parentChildCheckboxListLightPreview() => _checklistPreview(Brightness.light);

@Preview(name: 'Parent-child checklist - dark', group: 'Common', size: Size(360, 300))
Widget parentChildCheckboxListDarkPreview() => _checklistPreview(Brightness.dark);

Widget _checklistPreview(Brightness brightness) {
  Set<String> selection = {'Service updates'};

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
          builder: (context, setState) => ParentChildCheckboxList<String>(
            parent: const Text('Notifications', style: AppTypography.checkboxLabel),
            children: const [
              'Service updates',
              'Arrival reminders',
              'Travel alerts',
              'Favourite changes',
              'Product news',
              'Weekly summary',
              'Nearby disruptions',
              'Account activity',
            ],
            selectedChildren: selection,
            childBuilder: (context, child) => Text(child, style: AppTypography.checkboxLabel),
            onChanged: (value) => setState(() => selection = value),
          ),
        ),
      ),
    ),
  );
}
