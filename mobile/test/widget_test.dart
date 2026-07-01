import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smart_health_consulting/main.dart';
import 'package:smart_health_consulting/router/app_router.dart';
import 'package:smart_health_consulting/store/app_store.dart';

void main() {
  testWidgets('App launches splash screen', (WidgetTester tester) async {
    final store = AppStore();
    final router = AppRouter.create(store);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: SmartHealthApp(router: router),
      ),
    );

    expect(find.text('Smart Health'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
