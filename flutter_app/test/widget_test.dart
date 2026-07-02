import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanpdf/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanPdfApp());
    
    // 验证应用启动后显示首页
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // 验证显示应用标题
    expect(find.text('ScanPDF'), findsOneWidget);
  });

  testWidgets('Home screen displays empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanPdfApp());
    await tester.pumpAndSettle();
    
    // 验证显示空状态提示
    expect(find.text('暂无文档'), findsOneWidget);
    expect(find.text('点击下方按钮开始扫描'), findsOneWidget);
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
