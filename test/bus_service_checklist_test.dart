import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:transito/widgets/favourites/bus_service_checklist.dart';

void main() {
  testWidgets('renders in material_ui and keeps parent and service selections in sync', (
    tester,
  ) async {
    Set<String> selection = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => BusServiceChecklist(
              services: const ['10', '14'],
              selectedServices: selection,
              onChanged: (value) => setState(() => selection = value),
            ),
          ),
        ),
      ),
    );

    List<bool?> values() =>
        tester.widgetList<Checkbox>(find.byType(Checkbox)).map((c) => c.value).toList();

    // The old package throws "No Material widget found" in this scaffold.
    expect(tester.takeException(), isNull);
    expect(values(), [false, false, false]);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(selection, {'10', '14'});
    expect(values(), [true, true, true]);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(selection, isEmpty);
    expect(values(), [false, false, false]);

    final Set<String> previousSelection = selection;
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    expect(previousSelection, isEmpty, reason: 'Callbacks must not mutate the screen snapshot.');
    expect(selection, {'10'});
    expect(values(), [null, true, false]);

    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pump();
    expect(values(), [true, true, true]);

    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    expect(selection, {'14'});
    expect(values(), [null, false, true]);

    // Preserve the fork's partial-selection -> clear behavior.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(selection, isEmpty);
    expect(values(), [false, false, false]);
  });

  testWidgets('saved and updated screen selections remain independent between checklists', (
    tester,
  ) async {
    final Set<String> savedServices = {'14'};
    Set<String> selection = savedServices;
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Column(
                children: [
                  BusServiceChecklist(
                    services: const ['10', '14'],
                    selectedServices: selection,
                    onChanged: (value) => setState(() => selection = value),
                  ),
                  BusServiceChecklist(
                    services: const ['D1'],
                    selectedServices: const {'D1'},
                    onChanged: (_) {},
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    List<bool?> values() =>
        tester.widgetList<Checkbox>(find.byType(Checkbox)).map((c) => c.value).toList();

    expect(values(), [null, false, true, true, true]);
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pump();
    expect(savedServices, {'14'});
    expect(selection, isEmpty);
    expect(values(), [false, false, false, true, true]);

    rebuild(() {});
    await tester.pump();
    expect(values(), [false, false, false, true, true]);

    rebuild(() => selection = {'10', '14'});
    await tester.pump();
    expect(values(), [true, true, true, true, true]);
  });

  testWidgets('an empty service list has a disabled unchecked parent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BusServiceChecklist(
            services: const [],
            selectedServices: const {},
            onChanged: (_) => fail('There are no services to select.'),
          ),
        ),
      ),
    );

    final Checkbox parent = tester.widget(find.byType(Checkbox));
    expect(parent.value, false);
    expect(parent.onChanged, isNull);
    expect(tester.takeException(), isNull);
  });
}
