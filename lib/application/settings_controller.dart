import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key under which the user's language choice ('ar' | 'en') is stored in
/// shared_preferences.
const String _languagePrefKey = 'settings.languageCode';

/// Supported language codes, mirroring the ARB files in lib/l10n.
const Set<String> _supportedLanguageCodes = {'ar', 'en'};

/// Exposes the app-wide [SharedPreferences] instance.
///
/// Must be overridden with a real instance (main.dart does this after
/// preloading) before anything reads it; tests override it with mocks.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a preloaded '
    'SharedPreferences instance in main() (or a mock in tests).',
  );
});

/// Riverpod controller for language (ar/en) settings, persisted via
/// shared_preferences (PRD 4/7). Volume settings follow in a later phase.
final languageProvider = NotifierProvider<LanguageController, Locale>(
  LanguageController.new,
);

class LanguageController extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final code = prefs.getString(_languagePrefKey);
    return Locale(
      code != null && _supportedLanguageCodes.contains(code) ? code : 'ar',
    );
  }

  /// Switches the app language instantly (no restart, PRD 7) and persists
  /// the choice.
  Future<void> setLanguage(Locale locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_languagePrefKey, locale.languageCode);
  }
}
