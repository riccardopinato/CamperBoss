import 'package:camperboss/core/services/document_deletion_service.dart';
import 'package:camperboss/core/services/document_services_models.dart';
import 'package:camperboss/data/models/finance_models.dart';
import 'package:camperboss/data/models/vehicle_document.dart';
import 'package:camperboss/data/repositories/local_finance_repository.dart';
import 'package:camperboss/data/repositories/local_vehicle_document_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Documents implements VehicleDocumentRepository {
  _Documents(this.documents);
  final List<VehicleDocument> documents;

  @override
  Future<void> deleteDocument(VehicleDocument document) async {
    documents.removeWhere((item) => item.id == document.id);
  }

  @override
  Future<List<VehicleDocument>> listDocuments() async => [...documents];

  @override
  Future<VehicleDocument> saveDocument(VehicleDocument document) async =>
      document;
}

class _Finance implements FinanceRepository {
  _Finance({this.documentId});
  final int? documentId;

  @override
  Future<List<Expense>> listExpenses() async => [
        if (documentId != null)
          Expense(
            id: 'expense',
            scope: ExpenseScope.vehicle,
            category: ExpenseCategory.other,
            amountMinor: 100,
            currencyCode: 'EUR',
            occurredAt: DateTime(2026, 1, 1),
            documentId: documentId,
          ),
      ];

  @override
  Future<List<FuelEntry>> listFuelEntries() async => const [];
  @override
  Future<List<TripBooking>> listBookings() async => const [];
  @override
  Future<TripBudget?> loadTripBudget(int tripId) async => null;
  @override
  Future<void> deleteBooking(String id) async {}
  @override
  Future<void> deleteExpense(String id) async {}
  @override
  Future<void> deleteFuelEntry(String id) async {}
  @override
  Future<void> deleteTripBudget(int tripId) async {}
  @override
  Future<TripBooking> saveBooking(TripBooking booking) async => booking;
  @override
  Future<Expense> saveExpense(Expense expense) async => expense;
  @override
  Future<FuelEntry> saveFuelEntry(FuelEntry entry) async => entry;
  @override
  Future<void> saveTripBudget(TripBudget budget) async {}
}

VehicleDocument _document() => const VehicleDocument(
      id: 7,
      category: 'invoice',
      title: 'Invoice',
      localFilePath: '/private/invoice.pdf',
      mimeType: 'application/pdf',
      ocrStatus: DocumentOcrStatus.notRequested,
    );

void main() {
  test('blocks document deletion while finance references remain', () async {
    final docs = _Documents([_document()]);
    final service = DocumentDeletionService(
      documentRepository: docs,
      financeRepository: _Finance(documentId: 7),
    );

    await expectLater(service.deleteDocument(_document()),
        throwsA(isA<DocumentInUseException>()));
    expect(docs.documents, hasLength(1));
  });

  test('deletes unreferenced document', () async {
    final docs = _Documents([_document()]);
    final service = DocumentDeletionService(
      documentRepository: docs,
      financeRepository: _Finance(),
    );

    await service.deleteDocument(_document());

    expect(docs.documents, isEmpty);
  });
}
