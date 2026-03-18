import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporta/main.dart';

void main() {
  testWidgets('Sporta app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SportaApp());
  });
}
