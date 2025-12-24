import 'package:flutter_test/flutter_test.dart';
import 'package:luma/main.dart';

void main() {
  testWidgets('app builds', (tester) async {
    await tester.pumpWidget(const LumaApp());
    expect(find.byType(LumaApp), findsOneWidget);
  });
}
