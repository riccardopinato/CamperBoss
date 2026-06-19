import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_search_service.dart';

final localSearchServiceProvider = Provider<LocalSearchService>((ref) {
  return LocalSearchService();
});

final searchIndexSnapshotProvider = FutureProvider((ref) {
  return ref.watch(localSearchServiceProvider).snapshot();
});
