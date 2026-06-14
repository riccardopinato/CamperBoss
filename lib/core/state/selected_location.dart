import 'package:flutter/foundation.dart';

import '../services/geocoding_service.dart';

class SelectedLocationController extends ValueNotifier<GeoLocationResult> {
  SelectedLocationController()
      : super(
          const GeoLocationResult(
            name: 'Lake Garda',
            latitude: 45.6049,
            longitude: 10.6351,
            country: 'Italy',
            admin1: 'Lombardy',
          ),
        );
}

final selectedLocationController = SelectedLocationController();
