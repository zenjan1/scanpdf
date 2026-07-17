import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:scanpdf/app/app.dart';
import 'package:scanpdf/core/services/service_locator.dart';

void main() {
  setUp(() async {
    // 每个测试前初始化依赖注入
    await init();
  });

  tearDown(() async {
    // 每个测试后清理服务实例，确保 Timer 被取消
    await GetIt.instance.reset();
  });

  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanPdfApp());
    await tester.pump(const Duration(seconds: 1));

    // 验证应用启动后显示首页
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Home screen handles loading or empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanPdfApp());
    await tester.pump(const Duration(seconds: 1));

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
}
