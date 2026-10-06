import 'package:camperboss/data/models/checklist_item.dart';
import 'package:camperboss/data/repositories/local_checklist_repository.dart';
import 'package:camperboss/features/checklist/presentation/checklist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_localization.dart';

class FakeChecklistRepository implements ChecklistRepository {
  FakeChecklistRepository(this.items);

  final List<CamperChecklistItem> items;
  var nextId = 10;

  @override
  Future<List<CamperChecklistItem>> listItems() async => [...items];

  @override
  Future<CamperChecklistItem> saveItem(CamperChecklistItem item) async {
    final saved = item.id == null ? item.copyWith(id: nextId++) : item;
    final index = items.indexWhere((entry) => entry.id == saved.id);
    if (index == -1) {
      items.add(saved);
    } else {
      items[index] = saved;
    }
    return saved;
  }

  @override
  Future<void> deleteItem(int id) async {
    items.removeWhere((entry) => entry.id == id);
  }
}

void main() {
  testWidgets('checklist persists toggles, additions, and deletes', (
    tester,
  ) async {
    final repository = FakeChecklistRepository([
      const CamperChecklistItem(
        id: 1,
        title: 'Check water',
        subtitle: 'Before departure',
        checked: false,
        category: 'Pre-trip',
      ),
    ]);

    await pumpLocalizedHome(
      tester,
      home: ChecklistScreen(repository: repository),
    );

    expect(find.text('Check water'), findsOneWidget);
    expect(find.text('0% completed across routines'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(repository.items.single.checked, isTrue);
    expect(find.text('100% completed across routines'), findsOneWidget);

    await tester.tap(find.text('Add check'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).first, 'Pack leveling blocks');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Pack leveling blocks'), findsOneWidget);
    expect(repository.items.length, 2);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Check water'), findsNothing);
    expect(repository.items.length, 1);
  });
}
