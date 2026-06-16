import 'package:camperboss/data/models/maintenance_record.dart';
import 'package:camperboss/data/repositories/local_maintenance_repository.dart';
import 'package:camperboss/features/maintenance/presentation/maintenance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMaintenanceRepository implements MaintenanceRepository {
  final records = <MaintenanceRecord>[];

  @override
  Future<void> deleteRecord(int id) async {
    records.removeWhere((record) => record.id == id);
  }

  @override
  Future<List<MaintenanceRecord>> listRecords() async => records;

  @override
  Future<MaintenanceRecord> saveRecord(MaintenanceRecord record) async {
    final saved = record.copyWith(id: record.id ?? records.length + 1);
    final index = records.indexWhere((item) => item.id == saved.id);
    if (index == -1) {
      records.add(saved);
    } else {
      records[index] = saved;
    }
    return saved;
  }
}

void main() {
  testWidgets('maintenance screen saves service records with due intervals',
      (tester) async {
    final repository = FakeMaintenanceRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaintenanceScreen(repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add service'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Oil service');
    await tester.enterText(fields.at(1), '24000');
    await tester.enterText(fields.at(2), '210');
    await tester.enterText(fields.at(3), 'Garage Rossi');
    await tester.enterText(fields.at(4), '12');
    await tester.enterText(fields.at(5), '15000');
    await tester.enterText(fields.at(7), '/private/invoice.pdf');
    await tester.enterText(fields.at(8), 'Use approved oil.');

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Oil service'), findsOneWidget);
    expect(repository.records.single.intervalMonths, 12);
    expect(repository.records.single.intervalKilometers, 15000);
    expect(repository.records.single.nextDueMileage, 39000);
    expect(repository.records.single.attachmentPaths, ['/private/invoice.pdf']);
  });
}
