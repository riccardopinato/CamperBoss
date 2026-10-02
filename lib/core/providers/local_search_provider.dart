import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_system_services.dart';
import '../services/local_search_service.dart';

final localSearchServiceProvider = Provider<LocalSearchService>((ref) {
  return AppSystemServices.instance.search;
});

final searchIndexSnapshotProvider = FutureProvider((ref) {
  return ref.watch(localSearchServiceProvider).snapshot();
});
