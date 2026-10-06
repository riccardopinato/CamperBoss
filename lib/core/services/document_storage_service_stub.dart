abstract interface class DocumentStorageService {
  Future<String> copyIntoPrivateDocuments(String pathOrUri);
  Future<void> deleteFiles(Iterable<String?> paths);
  Future<List<String>> listManagedFiles();
}

DocumentStorageService createDocumentStorageService() {
  return UnsupportedDocumentStorageService();
}

class UnsupportedDocumentStorageService implements DocumentStorageService {
  @override
  Future<String> copyIntoPrivateDocuments(String pathOrUri) {
    throw UnsupportedError('document_error_platform_unsupported');
  }

  @override
  Future<void> deleteFiles(Iterable<String?> paths) async {}

  @override
  Future<List<String>> listManagedFiles() async => const [];
}
