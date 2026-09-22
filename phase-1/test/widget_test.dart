import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/ui/widgets/pin_numpad.dart';

void main() {
  testWidgets('PinNumpad accepts 4 digits and invokes onPinComplete callback',
      (WidgetTester tester) async {
    String? enteredPin;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinNumpad(
            onPinComplete: (pin) {
              enteredPin = pin;
            },
          ),
        ),
      ),
    );

    // Verify key digits exist on screen
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);

    // Tap digits 1, 2, 3, 4
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(enteredPin, isNull);

    await tester.tap(find.text('2'));
    await tester.pump();
    expect(enteredPin, isNull);

    await tester.tap(find.text('3'));
    await tester.pump();
    expect(enteredPin, isNull);

    await tester.tap(find.text('4'));
    await tester.pump();

    // Callback should fire with '1234'
    expect(enteredPin, '1234');
  });

  testWidgets('PinNumpad backspace removes previously entered digit',
      (WidgetTester tester) async {
    String? enteredPin;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinNumpad(
            onPinComplete: (pin) {
              enteredPin = pin;
            },
          ),
        ),
      ),
    );

    // Tap 1, 2, Backspace, 3, 4, 5 -> Pin should be 1345
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();

    expect(enteredPin, '1345');
  });
}
