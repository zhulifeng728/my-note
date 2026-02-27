import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('app launches successfully', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 验证主页面加载
      expect(find.text('我的笔记'), findsOneWidget);
    });

    testWidgets('can navigate to search screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 点击搜索按钮
      final searchButton = find.byIcon(Icons.search);
      expect(searchButton, findsOneWidget);
      await tester.tap(searchButton);
      await tester.pumpAndSettle();

      // 验证搜索页面
      expect(find.text('搜索笔记...'), findsOneWidget);
    });

    testWidgets('can navigate to settings screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 点击设置按钮
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // 验证设置页面
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('can create a new note', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 点击添加按钮
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // 验证编辑器页面
      expect(find.text('编辑笔记'), findsOneWidget);
    });
  });
}
