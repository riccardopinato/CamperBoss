/// X10-021: profile preferences, not OAuth credentials or account identity.
/// Storage is injected: consumers must scope it to the correct local owner.
import 'dart:convert';

enum ProfileTheme { system, light, dark }

const _supportedLocales = {'system', 'it', 'en', 'es', 'fr', 'de', 'pt'};

class ProfilePreferences {
  const ProfilePreferences({
    this.displayName = '',
    this.locale = 'system',
    this.theme = ProfileTheme.system,
    this.analyticsOptIn = false,
  });

  final String displayName;
  final String locale;
  final ProfileTheme theme;
  final bool analyticsOptIn;

  ProfilePreferences copyWith({
    String? displayName,
    String? locale,
    ProfileTheme? theme,
    bool? analyticsOptIn,
  }) =>
      ProfilePreferences(
        displayName: displayName ?? this.displayName,
        locale: locale ?? this.locale,
        theme: theme ?? this.theme,
        analyticsOptIn: analyticsOptIn ?? this.analyticsOptIn,
      );

  void validate() {
    if (displayName.trim().length > 80 ||
        displayName.contains(RegExp(r'[\x00-\x1F]'))) {
      throw const FormatException('invalid_display_name');
    }
    if (!_supportedLocales.contains(locale)) {
      throw const FormatException('unsupported_locale');
    }
  }

  Map<String, Object> toJson() {
    validate();
    return {
      'schema_version': 1,
      'display_name': displayName,
      'locale': locale,
      'theme': theme.name,
      'analytics_opt_in': analyticsOptIn,
    };
  }

  static ProfilePreferences fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('profile_not_object');
    }
    final version = raw['schema_version'];
    if (version != 0 && version != 1) {
      throw const FormatException('unsupported_profile_schema');
    }
    final name = version == 0 ? (raw['name'] ?? '') : (raw['display_name'] ?? '');
    final locale = version == 0 ? (raw['language'] ?? 'system') : (raw['locale'] ?? 'system');
    final theme = raw['theme'] ?? 'system';
    if (name is! String || locale is! String || theme is! String) {
      throw const FormatException('profile_field_type');
    }
    final match = ProfileTheme.values.where((value) => value.name == theme);
    if (match.length != 1) {
      throw const FormatException('unsupported_theme');
    }
    final consent = version == 0 ? false : raw['analytics_opt_in'] ?? false;
    if (consent is! bool) {
      throw const FormatException('analytics_consent_type');
    }
    final prefs = ProfilePreferences(
      displayName: name,
      locale: locale,
      theme: match.single,
      analyticsOptIn: consent,
    );
    prefs.validate();
    return prefs;
  }
}

/// Must guarantee atomic replace or leave prior preferences intact.
abstract interface class ProfilePreferencesStore {
  Future<String?> read();
  Future<void> writeAtomically(String jsonDocument);
}

class ProfileSettingsController {
  ProfileSettingsController(this._store);

  final ProfilePreferencesStore _store;
  ProfilePreferences _current = const ProfilePreferences();
  Future<void> _tail = Future<void>.value();
  bool _loaded = false;
  bool _corrupt = false;
  Future<ProfilePreferences>? _loading;

  ProfilePreferences get current => _current;
  bool get loaded => _loaded;
  bool get recoveredFromInvalidPreferences => _corrupt;

  // One shared read prevents a delayed, older read from overwriting a
  // successful update after a concurrent load has already completed.
  Future<ProfilePreferences> load() {
    if (_loaded) return Future.value(_current);
    return _loading ??= _loadOnce();
  }

  Future<ProfilePreferences> _loadOnce() async {
    try {
      final document = await _store.read();
      if (document != null) {
        try {
          _current = ProfilePreferences.fromJson(jsonDecode(document));
        } on FormatException {
          // Keep prior bytes for independent recovery: no automatic wipe.
          _corrupt = true;
        }
      }
      _loaded = true;
      return _current;
    } catch (_) {
      // Storage/network read failure is retryable, without marking loaded.
      _loading = null;
      rethrow;
    }
  }

  /// Serializes concurrent updates. Do not expose a successful state until
  /// the injected atomic storage has successfully committed the new snapshot.
  Future<ProfilePreferences> update(
    ProfilePreferences Function(ProfilePreferences) edit,
  ) {
    final result = _tail.then((_) async {
      if (!_loaded) throw StateError('profile_not_loaded');
      final next = edit(_current);
      final data = jsonEncode(next.toJson());
      await _store.writeAtomically(data);
      _current = next;
      _corrupt = false;
      return next;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}
