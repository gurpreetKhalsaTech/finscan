import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finscan/app.dart';

void main() {
  testWidgets('App renders home screen with scan buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FinScanApp()));
    await tester.pumpAndSettle();

    expect(find.text('FinScan'), findsOneWidget);
    expect(find.text('Scan Credit / Debit Card'), findsOneWidget);
    expect(find.text('Scan Bank Passbook'), findsOneWidget);
  });
}