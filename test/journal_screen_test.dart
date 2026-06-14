import 'package:camperboss/data/models/journal_entry.dart';
import 'package:camperboss/data/repositories/local_journal_repository.dart';
import 'package:camperboss/features/journal/presentation/journal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeJournalRepository implements JournalRepository {
  FakeJournalRepository(this.entries);

  final List<JournalEntry> entries;
  var nextId = 30;

  @override
  Future<List<JournalEntry>> listEntries() async => [...entries];

  @override
  Future<JournalEntry> saveEntry(JournalEntry entry) async {
    final saved = entry.id == null ? entry.copyWith(id: nextId++) : entry;
    final index = entries.indexWhere((item) => item.id == saved.id);
    if (index == -1) {
      entries.insert(0, saved);
    } else {
      entries[index] = saved;
    }
    return saved;
  }

  @override
  Future<void> deleteEntry(int id) async {
    entries.removeWhere((entry) => entry.id == id);
  }
}

void main() {
  testWidgets('journal creates, edits, deletes, and updates metrics', (
    tester,
  ) async {
    final repository = FakeJournalRepository([
      JournalEntry(
        id: 1,
        title: 'Lake stop',
        summary: 'Quiet evening',
        createdAt: DateTime.utc(2026, 6, 14),
        place: 'Lake Garda',
        kilometers: 120,
        cost: 45,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: JournalScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lake stop'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Updated lake stop');
    await tester.enterText(find.byType(TextField).at(3), '150');
    await tester.enterText(find.byType(TextField).at(4), '60');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.entries.single.title, 'Updated lake stop');
    expect(repository.entries.single.kilometers, 150);
    expect(repository.entries.single.cost, 60);

    await tester.tap(find.text('Add journal note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Mountain breakfast');
    await tester.enterText(find.byType(TextField).at(1), 'Cold morning');
    await tester.enterText(find.byType(TextField).at(2), 'Dolomites');
    await tester.enterText(find.byType(TextField).at(3), '30');
    await tester.enterText(find.byType(TextField).at(4), '12');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.entries.length, 2);
    expect(find.text('180'), findsOneWidget);
    expect(find.text('72'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete note').first);
    await tester.pumpAndSettle();

    expect(repository.entries.length, 1);
  });
}
