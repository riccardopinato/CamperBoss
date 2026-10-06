import 'package:flutter/foundation.dart';

import '../services/geocoding_service.dart';

class SelectedLocationController extends ValueNotifier<GeoLocationResult?> {
  SelectedLocationController() : super(null);

  void clear() => value = null;
}

final selectedLocationController = SelectedLocationController();
