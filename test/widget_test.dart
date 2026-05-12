import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_near/app.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ShopNearApp(),
      ),
    );

    // Verify that our onboarding screen shows the brand name.
    // Note: findsOneWidget might fail if onboarding isn't the first screen, 
    // but we use ProviderScope as required by Riverpod.
    expect(find.byType(ShopNearApp), findsOneWidget);
    
    // Verify that the app builds without errors.
    expect(find.text('ShopNear', findRichText: true), findsOneWidget);
  });
}
