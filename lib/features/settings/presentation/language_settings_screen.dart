import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/screen_scaffold.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  static const _languages = <String, String>{
    'en': 'language_english',
    'it': 'language_italian',
    'de': 'language_german',
    'fr': 'language_french',
    'es': 'language_spanish',
    'pt': 'language_portuguese',
  };

  Future<void> _select(BuildContext context, Locale? locale) async {
    if (locale == null) {
      await context.deleteSaveLocale();
      if (!context.mounted) return;
      await context.resetLocale();
      return;
    }
    await context.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.savedLocale;
    final supportedCodes =
        context.supportedLocales.map((locale) => locale.languageCode).toSet();

    return ScreenScaffold(
      title: 'language_title'.tr(),
      subtitle: 'language_subtitle'.tr(),
      children: [
        PremiumCard(
          child: RadioGroup<String>(
            groupValue: saved?.languageCode ?? '__system__',
            onChanged: (code) {
              if (code == null) return;
              if (code == '__system__') {
                _select(context, null);
              } else {
                _select(context, Locale(code));
              }
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  value: '__system__',
                  title: Text('language_system'.tr()),
                  subtitle: Text(context.deviceLocale.toLanguageTag()),
                ),
                for (final entry in _languages.entries)
                  if (supportedCodes.contains(entry.key))
                    RadioListTile<String>(
                      value: entry.key,
                      title: Text(entry.value.tr()),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
