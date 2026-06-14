import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/services/weather_service.dart';
import '../../core/state/selected_location.dart';
import '../../core/theme/app_colors.dart';
import 'premium_card.dart';

class WeatherSummaryCard extends StatelessWidget {
  const WeatherSummaryCard({
    this.service = const WeatherService(),
    super.key,
  });

  final WeatherService service;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherSnapshot>(
      future: service.fetchCurrent(),
      builder: (context, snapshot) {
        final weather = snapshot.data;
        final hasLiveData = snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData;

        return PremiumCard(
          color: AppColors.forest,
          child: Row(
            children: [
              Icon(
                hasLiveData
                    ? Icons.cloud_sync_outlined
                    : Icons.wb_cloudy_outlined,
                size: 42,
                color: AppColors.gold,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather?.location ?? 'Lake Garda basecamp',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      weather == null
                          ? snapshot.hasError
                              ? 'Live weather unavailable, using route plan'
                              : 'Loading live Open-Meteo weather...'
                          : '${weather.temperature.round()} C, ${weather.condition}, wind ${weather.windSpeed.round()} km/h',
                    ),
                    if (weather != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Feels ${weather.apparentTemperature.round()} C - humidity ${weather.humidity}% - gusts ${weather.windGusts.round()} km/h',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                hasLiveData ? 'Live' : 'Plan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.gold,
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
    return ValueListenableBuilder<GeoLocationResult>(
      valueListenable: selectedLocationController,
      builder: (context, location, _) {
        return WeatherSummaryCard(
          key: ValueKey('${location.latitude},${location.longitude}'),
          service: _LocationWeatherService(service, location),
        );
      },
    );
  }
}

class _LocationWeatherService extends WeatherService {
  const _LocationWeatherService(this._delegate, this._location);

  final WeatherService _delegate;
  final GeoLocationResult _location;

  @override
  Future<WeatherSnapshot> fetchCurrent({
    double latitude = 45.6049,
    double longitude = 10.6351,
    String location = 'Lake Garda basecamp',
  }) {
    return _delegate.fetchCurrent(
      latitude: _location.latitude,
      longitude: _location.longitude,
      location: _location.label,
    );
  }
}
