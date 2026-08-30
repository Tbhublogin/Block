import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:block_civilizations/app.dart';
import 'package:block_civilizations/application/settings_controller.dart';

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefsValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('defaults to Arabic with RTL layout when no language is saved', (
    tester,
  ) async {
    final container = await _pumpApp(tester);

    // Arabic strings from app_ar.arb.
    expect(find.text('حضارات المكعبات'), findsOneWidget);
    expect(find.text('قيد الإنشاء'), findsOneWidget);

    // Directionality is derived from the Arabic locale.
    final context = tester.element(find.byType(Scaffold));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Localizations.localeOf(context), const Locale('ar'));
    expect(container.read(languageProvider), const Locale('ar'));
  });

  testWidgets('uses persisted English and LTR layout', (tester) async {
    final container = await _pumpApp(
      tester,
      prefsValues: {'settings.languageCode': 'en'},
    );

    expect(find.text('Block Civilizations'), findsOneWidget);
    expect(find.text('Under construction'), findsOneWidget);

    final context = tester.element(find.byType(Scaffold));
    expect(Directionality.of(context), TextDirection.ltr);
    expect(Localizations.localeOf(context), const Locale('en'));
    expect(container.read(languageProvider), const Locale('en'));
  });
}
