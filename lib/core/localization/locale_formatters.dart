import 'package:intl/intl.dart';

String localizedDate(DateTime value, {String? locale}) {
  return DateFormat.yMd(locale).format(value);
}

String localizedDateTime(DateTime value, {String? locale}) {
  return DateFormat.yMd(locale).add_jm().format(value);
}

String localizedDecimal(
  num value, {
  String? locale,
  int maximumFractionDigits = 1,
}) {
  final formatter = NumberFormat.decimalPattern(locale)
    ..maximumFractionDigits = maximumFractionDigits;
  return formatter.format(value);
}

String localizedCurrency(
  num value, {
  required String currencyCode,
  String? locale,
}) {
  return NumberFormat.simpleCurrency(
    name: currencyCode,
    locale: locale,
  ).format(value);
}

String localizedDistanceMeters(num meters, {String? locale}) {
  if (meters < 1000) {
    return '${localizedDecimal(meters.round(), locale: locale, maximumFractionDigits: 0)} m';
  }
  return '${localizedDecimal(meters / 1000, locale: locale)} km';
}

String localizedDurationSeconds(int seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}

String localizedByteSize(int bytes, {String? locale}) {
  if (bytes <= 0) return '0 B';
  if (bytes >= 1024 * 1024 * 1024) {
    return '${localizedDecimal(bytes / (1024 * 1024 * 1024), locale: locale)} GB';
  }
  if (bytes >= 1024 * 1024) {
    return '${localizedDecimal(bytes / (1024 * 1024), locale: locale)} MB';
  }
  if (bytes >= 1024) {
    return '${localizedDecimal(bytes / 1024, locale: locale)} KB';
  }
  return '${localizedDecimal(bytes, locale: locale, maximumFractionDigits: 0)} B';
}
