import 'package:flutter_test/flutter_test.dart';
import 'package:friend_post/main.dart';

void main() {
  testWidgets('Friend Post app loads successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FriendPostApp());

    await tester.pumpAndSettle();

    expect(find.byType(FriendPostApp), findsOneWidget);
  });
}
