import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_web/main.dart';

void main() {
  testWidgets('AdminScreen renders main tabs', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(const AdminApp());
    await tester.pump();

    expect(find.text('Panel de Administración'), findsOneWidget);
    expect(find.text('Estructura'), findsWidgets);
    expect(find.text('Agregar'), findsWidgets);
    expect(find.text('Config'), findsWidgets);
    expect(find.text('Overlays'), findsWidgets);
  });
}