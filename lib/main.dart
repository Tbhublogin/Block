import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/museum_controller.dart';
import 'application/progress_controller.dart';
import 'application/settings_controller.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload preferences so the persisted language is available on the very
  // first frame (no Arabic flash for English users).
  final prefs = await SharedPreferences.getInstance();

  // Open the Hive boxes for structured progress data (PRD 3) before the
  // first frame, mirroring the SharedPreferences preload, so the progress
  // and museum controllers read persisted state in their build().
  await Hive.initFlutter();
  final progressBox = await Hive.openBox<Map>(progressBoxName);
  final museumBox = await Hive.openBox<List>(museumBoxName);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        progressBoxProvider.overrideWithValue(progressBox),
        museumBoxProvider.overrideWithValue(museumBox),
      ],
      child: const App(),
    ),
  );
}
