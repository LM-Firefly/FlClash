import 'package:fl_clash/manager/app_manager.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Non-stable is the channel that used to show the env badge.
    globalState.appEnv = 'pre';
  });

  Future<void> pump(WidgetTester tester, {required bool safeMode}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [safeModeProvider.overrideWithValue(safeMode)],
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: AppEnvManager(child: SizedBox(key: Key('child'))),
        ),
      ),
    );
  }

  testWidgets('a non-stable build carries no env badge', (tester) async {
    await pump(tester, safeMode: false);

    expect(find.byKey(const Key('child')), findsOneWidget);
    expect(find.byType(Banner), findsNothing);
  });

  testWidgets('a safe mode build is bannered on any channel', (tester) async {
    await pump(tester, safeMode: true);

    final banner = tester.widget<Banner>(find.byType(Banner));
    expect(banner.message, 'SAFE MODE');
    expect(find.byKey(const Key('child')), findsOneWidget);
  });
}
