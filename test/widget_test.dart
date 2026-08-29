import 'package:flutter_test/flutter_test.dart';

import 'package:block_civilizations/app.dart';

void main() {
  testWidgets('App builds and shows the placeholder screen', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Block Civilizations'), findsOneWidget);
    expect(find.text('Under construction'), findsOneWidget);
  });
}
