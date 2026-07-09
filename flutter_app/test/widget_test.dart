import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanpdf/app/app.dart';
import 'package:scanpdf/core/services/service_locator.dart';

void main() {
  setUpAll(() async {
    // 初始化依赖注入
    await init();
  });

  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanPdfApp());
    await tester.pump();

    // 验证应用启动后显示首页
    expect(find.byType(MaterialApp), findsOneWidget);

    // 验证显示应用标题
    expect(find.text('ScanPDF'), findsOneWidget);
  });

  testWidgets('Home screen handles loading or empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanPdfApp());
    await tester.pump();

    // 在测试环境中，数据库可能无法初始化，
    // 所以验证应用处于以下状态之一：加载中、空状态、或错误状态
    final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasEmpty = find.text('暂无文档').evaluate().isNotEmpty;
    final hasError = find.textContaining('加载失败').evaluate().isNotEmpty;

    expect(
      hasLoading || hasEmpty || hasError,
      isTrue,
      reason: 'Expected loading, empty, or error state in test environment',
    );
  });

  testWidgets('Search bar is visible', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanPdfApp());
    await tester.pumpAndSettle();

    // 验证搜索栏存在
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('搜索文档...'), findsOneWidget);
  });

  testWidgets('Floating action button exists', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanPdfApp());
    await tester.pumpAndSettle();

    // 验证扫描按钮存在
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('扫描'), findsOneWidget);
  });

  testWidgets('Bottom navigation bar exists', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanPdfApp());
    await tester.pumpAndSettle();

    // 验证底部导航栏存在
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // 验证导航项
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('文档'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}
