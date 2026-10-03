import '../../data/models/vehicle_document.dart';
import '../../data/repositories/local_finance_repository.dart';
import '../../data/repositories/local_vehicle_document_repository.dart';

class DocumentInUseException implements Exception {
  const DocumentInUseException(this.referenceCount);

  final int referenceCount;

  @override
  String toString() => 'Document is referenced by $referenceCount records';
}

class DocumentDeletionService {
  DocumentDeletionService({
    VehicleDocumentRepository? documentRepository,
    FinanceRepository? financeRepository,
  })  : _documentRepository =
            documentRepository ?? LocalVehicleDocumentRepository(),
        _financeRepository = financeRepository ?? LocalFinanceRepository();

  final VehicleDocumentRepository _documentRepository;
  final FinanceRepository _financeRepository;

  Future<int> referenceCount(int documentId) async {
    final expenses = await _financeRepository.listExpenses();
    final fuel = await _financeRepository.listFuelEntries();
    final bookings = await _financeRepository.listBookings();
    return expenses.where((item) => item.documentId == documentId).length +
        fuel.where((item) => item.documentId == documentId).length +
        bookings.where((item) => item.documentId == documentId).length;
  }

  Future<void> deleteDocument(VehicleDocument document) async {
    final id = document.id;
    if (id == null) return;
    final references = await referenceCount(id);
    if (references > 0) throw DocumentInUseException(references);
    await _documentRepository.deleteDocument(document);
  }
}
