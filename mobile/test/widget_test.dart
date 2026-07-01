import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smart_health_consulting/main.dart';
import 'package:smart_health_consulting/store/app_store.dart';

void main() {
  testWidgets('App launches splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStore(),
        child: const SmartHealthApp(),
      ),
    );

    expect(find.text('Smart Health'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
