import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handle_hero/widgets/treasure_ui.dart';

void main() {
  testWidgets('calls its action when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TreasureButton(
              label: 'Continue',
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('CONTINUE'));
    expect(taps, 1);
  });

  testWidgets('does not call its action when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TreasureButton(
              label: 'Continue',
              onPressed: null,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('CONTINUE'));
    expect(taps, 0);
  });
}
