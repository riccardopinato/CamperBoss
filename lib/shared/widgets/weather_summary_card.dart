import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/services/weather_service.dart';
import '../../core/state/selected_location.dart';
import 'premium_card.dart';

class WeatherSummaryCard extends StatelessWidget {
  const WeatherSummaryCard({
    required this.location,
    this.service = const WeatherService(),
    super.key,
  });

  final GeoLocationResult location;
  final WeatherService service;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<WeatherSnapshot>(
      future: service.fetchCurrent(
        latitude: location.latitude,
        longitude: location.longitude,
        location: location.label,
      ),
      builder: (context, snapshot) {
        final weather = snapshot.data;
        final hasLiveData =
            snapshot.connectionState == ConnectionState.done && snapshot.hasData;

        return PremiumCard(
          color: scheme.primaryContainer,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasLiveData
                    ? Icons.cloud_sync_outlined
                    : Icons.wb_cloudy_outlined,
                size: 38,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      weather == null
                          ? snapshot.hasError
                              ? 'weather_unavailable'.tr()
                              : 'weather_loading'.tr()
                          : 'weather_summary'.tr(
                              namedArgs: {
                                'temperature':
                                    weather.temperature.round().toString(),
                                'condition': weather.conditionKey.tr(),
                                'wind': weather.windSpeed.round().toString(),
                              },
                            ),
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                    if (weather != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'weather_details'.tr(
                          namedArgs: {
                            'apparent': weather.apparentTemperature.round().toString(),
                            'humidity': weather.humidity.toString(),
                            'gusts': weather.windGusts.round().toString(),
                          },
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onPrimaryContainer
                                  .withValues(alpha: 0.78),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                hasLiveData ? 'weather_live'.tr() : 'weather_waiting'.tr(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SelectedLocationWeatherCard extends StatelessWidget {
  const SelectedLocationWeatherCard({
    this.service = const WeatherService(),
    super.key,
  });

  final WeatherService service;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GeoLocationResult?>(
      valueListenable: selectedLocationController,
      builder: (context, location, _) {
        if (location == null) {
          return PremiumCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_off_outlined),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'weather_no_location_title'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('weather_no_location_body'.tr()),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return WeatherSummaryCard(
          key: ValueKey('${location.latitude},${location.longitude}'),
          service: service,
          location: location,
        );
      },
    );
  }
}
