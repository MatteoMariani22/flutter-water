import 'dart:convert';

import 'package:aqua/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('captures README demo frames', (tester) async {
    // Demo capture runs in the test harness without a platform preferences plugin.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await _loadAppFonts();
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: boundaryKey, child: const AquaApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await _capture(boundaryKey, '00-start');
    for (final frame in ['01-one-glass', '02-two-glasses', '03-four-glasses']) {
      final additions = frame == '03-four-glasses' ? 2 : 1;
      for (var i = 0; i < additions; i++) {
        await tester.tap(find.byKey(const Key('addGlassButton')));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 650));
      await _capture(boundaryKey, frame);
    }

    await tester.tap(find.byKey(const Key('addGlassButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('addGlassButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    await _capture(boundaryKey, '04-goal-before');
    await tester.tap(find.byKey(const Key('dailyGoalButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    await _capture(boundaryKey, '05-goal-after');
  });
}

Future<void> _loadAppFonts() async {
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;
  await Future.wait(manifest.map((entry) async {
    final font = entry as Map<String, dynamic>;
    final loader = FontLoader(font['family'] as String);
    for (final file in font['fonts'] as List<dynamic>) {
      loader.addFont(
        rootBundle.load((file as Map<String, dynamic>)['asset'] as String),
      );
    }
    await loader.load();
  }));
}

Future<void> _capture(GlobalKey boundaryKey, String name) async {
  await expectLater(
    find.byKey(boundaryKey),
    matchesGoldenFile('../assets/gif/$name.png'),
  );
}
