import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:transito/widgets/common/parent_child_checkbox_list.dart';

void main() {
  testWidgets('renders in material_ui and keeps parent and child selections in sync', (
    tester,
  ) async {
    Set<String> selection = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ParentChildCheckboxList<String>(
              parent: const Text('Options'),
              children: const ['Alpha', 'Beta'],
              selectedChildren: selection,
              childBuilder: (context, child) => Text(child),
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
    expect(selection, {'Alpha', 'Beta'});
    expect(values(), [true, true, true]);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(selection, isEmpty);
    expect(values(), [false, false, false]);

    final Set<String> previousSelection = selection;
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    expect(previousSelection, isEmpty, reason: 'Callbacks must not mutate the screen snapshot.');
    expect(selection, {'Alpha'});
    expect(values(), [null, true, false]);

    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pump();
    expect(values(), [true, true, true]);

    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    expect(selection, {'Beta'});
    expect(values(), [null, false, true]);

    // Preserve the fork's partial-selection -> clear behavior.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(selection, isEmpty);
    expect(values(), [false, false, false]);
  });

  testWidgets('selection remains independent between checklists', (
    tester,
  ) async {
    final Set<int> savedChildren = {2};
    Set<int> selection = savedChildren;
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Column(
                children: [
                  Expanded(
                    child: ParentChildCheckboxList<int>(
                      parent: const Text('Numbers'),
                      children: const [1, 2],
                      selectedChildren: selection,
                      childBuilder: (context, child) => Text('$child'),
                      onChanged: (value) => setState(() => selection = value),
                    ),
                  ),
                  Expanded(
                    child: ParentChildCheckboxList<String>(
                      parent: const Text('Letters'),
                      children: const ['A'],
                      selectedChildren: const {'A'},
                      childBuilder: (context, child) => Text(child),
                      onChanged: (_) {},
                    ),
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
    expect(savedChildren, {2});
    expect(selection, isEmpty);
    expect(values(), [false, false, false, true, true]);

    rebuild(() {});
    await tester.pump();
    expect(values(), [false, false, false, true, true]);

    rebuild(() => selection = {1, 2});
    await tester.pump();
    expect(values(), [true, true, true, true, true]);
  });

  testWidgets('an empty child list has a disabled unchecked parent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParentChildCheckboxList<String>(
            parent: const Text('Options'),
            children: const [],
            selectedChildren: const {},
            childBuilder: (context, child) => Text(child),
            onChanged: (_) => fail('There are no children to select.'),
          ),
        ),
      ),
    );

    final Checkbox parent = tester.widget(find.byType(Checkbox));
    expect(parent.value, false);
    expect(parent.onChanged, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the parent fixed while the children scroll', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: ParentChildCheckboxList<int>(
              parent: const Text('Options'),
              children: List.generate(10, (index) => index),
              selectedChildren: const {},
              childBuilder: (context, child) => Text('Item $child'),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final double parentTop = tester.getTopLeft(find.text('Options')).dy;
    expect(find.text('Item 0'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Item 9'),
      100,
      scrollable: find.byType(Scrollable),
    );

    expect(tester.getTopLeft(find.text('Options')).dy, parentTop);
    expect(find.text('Item 0'), findsNothing);
    expect(find.text('Item 9'), findsOneWidget);
  });
}
