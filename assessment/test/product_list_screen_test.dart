import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:winp_flux_assessment/models/product_model.dart';
import 'package:winp_flux_assessment/screens/product_list_screen.dart';
import 'package:winp_flux_assessment/services/html_content_service.dart';
import 'package:winp_flux_assessment/services/product_service.dart';

class _SuccessProductService extends ProductService {
  @override
  Future<List<ProductModel>> fetchProducts() async {
    return [
      ProductModel(
        id: 'p1',
        title: 'Test Jacket',
        imageUrl: 'https://example.com/jacket.jpg',
        htmlDescription: '<p>A warm jacket.</p>',
        variants: [
          const VariantModel(
            id: 'v1',
            label: 'S',
            price: 49.99,
            currency: 'USD',
          ),
          const VariantModel(
            id: 'v2',
            label: 'L',
            price: 54.99,
            currency: 'USD',
          ),
        ],
      ),
    ];
  }
}

class _TwoProductService extends ProductService {
  @override
  Future<List<ProductModel>> fetchProducts() async {
    return [
      ProductModel(
        id: 'p1',
        title: 'Test Jacket',
        imageUrl: 'https://example.com/jacket.jpg',
        htmlDescription: '<p>A warm jacket.</p>',
        variants: [
          const VariantModel(id: 'v1', label: 'S', price: 49.99, currency: 'USD'),
        ],
      ),
      ProductModel(
        id: 'p2',
        title: 'Silk Shirt',
        imageUrl: 'https://example.com/shirt.jpg',
        htmlDescription: '<p>A silk shirt.</p>',
        variants: [
          const VariantModel(id: 'v2', label: 'M', price: 29.99, currency: 'USD'),
        ],
      ),
    ];
  }
}

class _ControllableProductService extends ProductService {
  final List<ProductModel> _firstResult;
  int _callCount = 0;

  _ControllableProductService(this._firstResult);

  @override
  Future<List<ProductModel>> fetchProducts() {
    _callCount++;
    if (_callCount == 1) return Future.value(_firstResult);
    return Completer<List<ProductModel>>().future;
  }
}

class _FailingProductService extends ProductService {
  @override
  Future<List<ProductModel>> fetchProducts() async {
    throw Exception('Connection refused');
  }
}

Widget _buildScreen() {
  return const MaterialApp(home: ProductListScreen());
}

void main() {
  setUp(() {
    GetIt.instance
        .registerLazySingleton<HtmlContentService>(() => HtmlContentService());
  });

  tearDown(() => GetIt.instance.reset());

  group('ProductListScreen widget tests', () {
    testWidgets('shows skeleton grid while loading', (tester) async {
      GetIt.instance.registerLazySingleton<ProductService>(
          () => _NeverCompletingProductService());

      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Test Jacket'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      expect(find.text('Products'), findsOneWidget);
    });

    testWidgets('displays product title and initial price after load',
        (tester) async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SuccessProductService());

      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Test Jacket'), findsOneWidget);
      expect(find.text('USD 49.99'), findsOneWidget);
    });

    testWidgets('selecting a variant updates the displayed price',
        (tester) async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SuccessProductService());

      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('L'));
      await tester.pumpAndSettle();

      expect(find.text('USD 54.99'), findsOneWidget);
      expect(find.text('USD 49.99'), findsNothing);
    });

    testWidgets('error state shows message and Retry button', (tester) async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _FailingProductService());

      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('tapping Retry triggers another load attempt', (tester) async {
      var callCount = 0;
      GetIt.instance.registerLazySingleton<ProductService>(
          () => _CountingFailingService(onCall: () => callCount++));

      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(callCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(callCount, 2);
    });

    testWidgets('shows product grid with spinner during refresh, not skeleton',
        (tester) async {
      final products = [
        ProductModel(
          id: 'p1',
          title: 'Test Jacket',
          imageUrl: 'https://example.com/jacket.jpg',
          htmlDescription: '<p>A warm jacket.</p>',
          variants: [
            const VariantModel(id: 'v1', label: 'S', price: 49.99, currency: 'USD'),
          ],
        ),
      ];
      GetIt.instance.registerLazySingleton<ProductService>(
          () => _ControllableProductService(products));

      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Test Jacket'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('search field filters visible product cards', (tester) async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _TwoProductService());

      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Test Jacket'), findsOneWidget);
      expect(find.text('Silk Shirt'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'jacket');
      await tester.pumpAndSettle();

      expect(find.text('Test Jacket'), findsOneWidget);
      expect(find.text('Silk Shirt'), findsNothing);
    });
  });
}

class _NeverCompletingProductService extends ProductService {
  @override
  Future<List<ProductModel>> fetchProducts() {
    return Completer<List<ProductModel>>().future;
  }
}

class _CountingFailingService extends ProductService {
  final VoidCallback onCall;
  _CountingFailingService({required this.onCall});

  @override
  Future<List<ProductModel>> fetchProducts() async {
    onCall();
    throw Exception('fail');
  }
}
