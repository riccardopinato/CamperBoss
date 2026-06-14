export 'local_key_value_store_base.dart';

import 'local_key_value_store_base.dart';
import 'local_key_value_store_stub.dart'
    if (dart.library.html) 'local_key_value_store_web.dart' as impl;

LocalKeyValueStore createLocalKeyValueStore() {
  return impl.createLocalKeyValueStore();
}
