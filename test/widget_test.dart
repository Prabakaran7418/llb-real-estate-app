import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llb_real_estate/main.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LLB Real Estate launches directly to Home discovery screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LLBRealEstateApp(),
      ),
    );

    // Pump frames to let GoRouter and Riverpod evaluate
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify LLB Real Estate branding and required headline exist on launch
    expect(find.text('LLB'), findsWidgets);
    expect(find.text('Find Your Perfect Plot. Build Your Dream Home.'), findsWidgets);
    expect(find.text('EXPLORE AVAILABLE PLOTS'), findsWidgets);
    expect(find.text('LOGIN'), findsWidgets);
    expect(find.text('CREATE ACCOUNT'), findsWidgets);
  });
}
