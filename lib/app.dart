import 'package:flutter/material.dart';

/// Root widget: MaterialApp with routing and localization delegates.
///
// TODO (Phase 1): wire localization delegates/supportedLocales from the ARB
// files, the Riverpod locale provider, and per-civilization theming
// (BUILD_PROMPTS 0.2 / PRD 4, 7).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO (Phase 1): move title and placeholder text into app_ar.arb /
    // app_en.arb once localization is set up (AI_RULES #6/#7).
    return MaterialApp(
      title: 'Block Civilizations',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _PlaceholderScreen(),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Block Civilizations')),
      body: const Center(child: Text('Under construction')),
    );
  }
}
