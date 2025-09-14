import 'package:flutter_test/flutter_test.dart';
import 'package:sddkm_frontend/main.dart';

void main() {
  testWidgets('renders E2E OK text', (tester) async {
    await tester.pumpWidget(const SddkmApp());
    expect(find.text('SDDKM MVP: E2E OK'), findsOneWidget);
  });
}
