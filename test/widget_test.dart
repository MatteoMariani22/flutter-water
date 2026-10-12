import 'package:aqua/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('adds a glass and updates daily progress', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AquaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('0.00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addGlassButton')));
    await tester.pump();

    expect(find.text('0.25'), findsOneWidget);
    expect(find.text('Nice start!'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getInt('hydration_ml'),
      250,
    );
  });

  testWidgets('undoes a glass and allows changing the goal', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AquaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('addGlassButton')));
    await tester.pump();
    await tester.tap(find.text('Undo last glass'));
    await tester.pump();
    expect(find.text('0.00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dailyGoalButton')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('dailyGoalButton')),
        matching: find.text('2.5 L'),
      ),
      findsOneWidget,
    );
    expect(
      (await SharedPreferences.getInstance()).getInt('hydration_goal'),
      2500,
    );
  });

  testWidgets('fits a compact phone screen without layout overflows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AquaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('stay in your flow.'), findsOneWidget);
  });
}
