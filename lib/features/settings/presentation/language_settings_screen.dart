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
          child: Column(
            children: [
              RadioListTile<String?>(
                value: null,
                groupValue: saved?.languageCode,
                title: Text('language_system'.tr()),
                subtitle: Text(context.deviceLocale.toLanguageTag()),
                onChanged: (_) => _select(context, null),
              ),
              for (final entry in _languages.entries)
                if (supportedCodes.contains(entry.key))
                  RadioListTile<String?>(
                    value: entry.key,
                    groupValue: saved?.languageCode,
                    title: Text(entry.value.tr()),
                    onChanged: (code) {
                      if (code != null) {
                        _select(context, Locale(code));
                      }
                    },
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
