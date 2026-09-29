export 'local_key_value_store_base.dart';

import 'local_key_value_store_base.dart';
import 'local_key_value_store_stub.dart'
    if (dart.library.html) 'local_key_value_store_web.dart'
    if (dart.library.io) 'local_key_value_store_io.dart' as impl;

LocalKeyValueStore createLocalKeyValueStore() {
  return impl.createLocalKeyValueStore();
}
