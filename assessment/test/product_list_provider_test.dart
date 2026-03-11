import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:winp_flux_assessment/models/product_model.dart';
import 'package:winp_flux_assessment/providers/product_list_provider.dart';
import 'package:winp_flux_assessment/services/product_service.dart';

class _SuccessProductService extends ProductService {
  @override
  Future<List<ProductModel>> fetchProducts() async {
    return [
      ProductModel(
        id: 'p1',
        title: 'Test Shirt',
        imageUrl: 'https://example.com/shirt.jpg',
        htmlDescription: '<p>A comfortable shirt.</p>',
        variants: [
          const VariantModel(
            id: 'v1',
            label: 'S',
            price: 19.99,
            currency: 'USD',
          ),
          const VariantModel(
            id: 'v2',
            label: 'M',
            price: 21.99,
            currency: 'USD',
            imageUrl: 'https://example.com/shirt-m.jpg',
          ),
        ],
      ),
    ];
  }
}

class _FailingProductService extends ProductService {
  @override
  Future<List<ProductModel>> fetchProducts() async {
    throw Exception('Network unavailable');
  }
}

void main() {
  tearDown(() => GetIt.instance.reset());

  group('ProductListProvider state transitions', () {
    test('starts in initial state', () {
      final provider = ProductListProvider();
      expect(provider.state, ProductListState.initial);
      expect(provider.products, isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('transitions initial → loading → loaded on success', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SuccessProductService());

      final provider = ProductListProvider();
      final states = <ProductListState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadProducts();

      expect(states, [ProductListState.loading, ProductListState.loaded]);
      expect(provider.state, ProductListState.loaded);
    });

    test('products list is populated after successful load', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SuccessProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      expect(provider.products, hasLength(1));
      expect(provider.products.first.id, 'p1');
    });

    test('default selected variant is the first variant after load', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SuccessProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      final selected = provider.selectedVariantFor('p1');
      expect(selected, isNotNull);
      expect(selected!.id, 'v1');
    });

    test('transitions initial → loading → error on failure', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _FailingProductService());

      final provider = ProductListProvider();
      final states = <ProductListState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadProducts();

      expect(states, [ProductListState.loading, ProductListState.error]);
      expect(provider.state, ProductListState.error);
    });

    test('errorMessage is set when load fails', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _FailingProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('Network unavailable'));
    });

    test('products list is empty after failed load', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _FailingProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      expect(provider.products, isEmpty);
    });

    test('selectVariant updates the selected variant and notifies listeners',
        () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SuccessProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      var notified = false;
      provider.addListener(() => notified = true);

      const newVariant = VariantModel(
        id: 'v2',
        label: 'M',
        price: 21.99,
        currency: 'USD',
        imageUrl: 'https://example.com/shirt-m.jpg',
      );

      provider.selectVariant('p1', newVariant);

      expect(provider.selectedVariantFor('p1')!.id, 'v2');
      expect(notified, isTrue);
    });

    test('selecting a variant on one product does not affect another', () async {
      GetIt.instance.registerLazySingleton<ProductService>(() {
        return _TwoProductService();
      });

      final provider = ProductListProvider();
      await provider.loadProducts();

      final p2VariantBefore = provider.selectedVariantFor('p2')!.id;

      provider.selectVariant(
        'p1',
        const VariantModel(id: 'v2', label: 'M', price: 21.99, currency: 'USD'),
      );

      expect(provider.selectedVariantFor('p2')!.id, p2VariantBefore);
    });
  });

  group('refreshing state', () {
    test('loadProducts from loaded state enters refreshing, not loading',
        () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SuccessProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      final states = <ProductListState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadProducts();

      expect(states, [
        ProductListState.refreshing,
        ProductListState.loaded,
      ]);
    });

    test('products are visible during refreshing state', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SuccessProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      GetIt.instance.reset();
      GetIt.instance.registerLazySingleton<ProductService>(
          () => _NeverCompletingProductService());

      var productsVisibleDuringRefresh = false;
      provider.addListener(() {
        if (provider.state == ProductListState.refreshing) {
          productsVisibleDuringRefresh = provider.products.isNotEmpty;
        }
      });

      provider.loadProducts();
      await Future.microtask(() {});

      expect(provider.state, ProductListState.refreshing);
      expect(productsVisibleDuringRefresh, isTrue);
    });

    test('refreshing transitions to error on failure', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SuccessProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      GetIt.instance.reset();
      GetIt.instance.registerLazySingleton<ProductService>(
          () => _FailingProductService());

      final states = <ProductListState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadProducts();

      expect(states, [
        ProductListState.refreshing,
        ProductListState.error,
      ]);
    });

    test('calling loadProducts while refreshing does not revert to loading',
        () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SuccessProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      GetIt.instance.reset();
      GetIt.instance.registerLazySingleton<ProductService>(
          () => _NeverCompletingProductService());

      provider.loadProducts();
      await Future.microtask(() {});
      expect(provider.state, ProductListState.refreshing);

      provider.loadProducts();
      await Future.microtask(() {});
      expect(provider.state, ProductListState.refreshing);
      expect(provider.products, isNotEmpty);
    });
  });

  group('filter', () {
    test('filteredProducts equals products when query is empty', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _FilterProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      expect(provider.filteredProducts.length, provider.products.length);
    });

    test('filterProducts returns only matching titles', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _FilterProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.filterProducts('jacket');

      expect(provider.filteredProducts, hasLength(1));
      expect(provider.filteredProducts.first.id, 'p1');
    });

    test('filterProducts is case-insensitive', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _FilterProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.filterProducts('JACKET');

      expect(provider.filteredProducts, hasLength(1));
      expect(provider.filteredProducts.first.id, 'p1');
    });

    test('original products list is unchanged after filter', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _FilterProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.filterProducts('jacket');

      expect(provider.products, hasLength(2));
      expect(provider.filteredProducts, hasLength(1));
    });

    test('filterProducts before loadProducts returns empty list, does not crash',
        () {
      final provider = ProductListProvider();

      provider.filterProducts('jacket');

      expect(provider.filteredProducts, isEmpty);
      expect(provider.state, ProductListState.initial);
    });

    test('filterProducts trims whitespace from query', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _FilterProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.filterProducts('  jacket  ');

      expect(provider.filteredProducts, hasLength(1));
      expect(provider.filteredProducts.first.id, 'p1');
    });

    test('filterProducts with empty string returns all products', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _FilterProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.filterProducts('jacket');
      expect(provider.filteredProducts, hasLength(1));

      provider.filterProducts('');
      expect(provider.filteredProducts, hasLength(2));
    });
  });

  group('sortByPrice', () {
    test('sortByPrice ascending orders by selected variant price', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SortProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.selectVariant(
        'pa',
        const VariantModel(id: 'va2', label: 'M', price: 8.00, currency: 'USD'),
      );

      provider.sortByPrice(ascending: true);

      expect(provider.filteredProducts[0].id, 'pa');
      expect(provider.filteredProducts[1].id, 'pb');
    });

    test('sortByPrice descending orders by selected variant price', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SortProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.selectVariant(
        'pa',
        const VariantModel(id: 'va2', label: 'M', price: 8.00, currency: 'USD'),
      );

      provider.sortByPrice(ascending: false);

      expect(provider.filteredProducts[0].id, 'pb');
      expect(provider.filteredProducts[1].id, 'pa');
    });

    test('sortByPrice does not reset filter state', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _FilterProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.filterProducts('jacket');
      expect(provider.filteredProducts, hasLength(1));

      provider.sortByPrice(ascending: true);

      expect(provider.filteredProducts, hasLength(1));
      expect(provider.filteredProducts.first.id, 'p1');
    });

    test('sortByPrice notifies listeners', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SortProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      var notified = false;
      provider.addListener(() => notified = true);

      provider.sortByPrice(ascending: true);

      expect(notified, isTrue);
    });

    test('product with no selected variant sorts to end ascending', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SortProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      GetIt.instance.reset();
      GetIt.instance.registerLazySingleton<ProductService>(() =>
          _NoVariantProductService());

      final provider2 = ProductListProvider();
      await provider2.loadProducts();

      provider2.sortByPrice(ascending: true);

      expect(provider2.filteredProducts.last.id, 'p-no-variant');
    });
  });

  group('filter and sort interaction', () {
    test('filtering after sort preserves sort order', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SortProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.selectVariant(
        'pa',
        const VariantModel(id: 'va2', label: 'M', price: 8.00, currency: 'USD'),
      );

      provider.sortByPrice(ascending: true);
      expect(provider.filteredProducts[0].id, 'pa');
      expect(provider.filteredProducts[1].id, 'pb');

      provider.filterProducts('Product');

      expect(provider.filteredProducts, hasLength(2));
      expect(provider.filteredProducts[0].id, 'pa');
      expect(provider.filteredProducts[1].id, 'pb');
    });

    test('clearing filter after sort restores sorted full list', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SortProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.selectVariant(
        'pa',
        const VariantModel(id: 'va2', label: 'M', price: 8.00, currency: 'USD'),
      );

      provider.sortByPrice(ascending: true);
      provider.filterProducts('Product A');
      expect(provider.filteredProducts, hasLength(1));

      provider.filterProducts('');

      expect(provider.filteredProducts, hasLength(2));
      expect(provider.filteredProducts[0].id, 'pa');
      expect(provider.filteredProducts[1].id, 'pb');
    });

    test('sort after filter only sorts filtered results', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SortProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.selectVariant(
        'pa',
        const VariantModel(id: 'va2', label: 'M', price: 8.00, currency: 'USD'),
      );

      provider.filterProducts('Product');
      provider.sortByPrice(ascending: true);

      expect(provider.filteredProducts, hasLength(2));
      expect(provider.filteredProducts[0].id, 'pa');
      expect(provider.filteredProducts[1].id, 'pb');
    });
  });

  group('favorites', () {
    test('favoriteIds is empty on construction', () {
      final provider = ProductListProvider();
      expect(provider.favoriteIds, isEmpty);
    });

    test('toggleFavorite adds product to favorites', () {
      final provider = ProductListProvider();
      provider.toggleFavorite('p1');
      expect(provider.isFavorite('p1'), isTrue);
    });

    test('toggling favorite twice returns to unfavorited', () {
      final provider = ProductListProvider();
      provider.toggleFavorite('p1');
      provider.toggleFavorite('p1');
      expect(provider.isFavorite('p1'), isFalse);
    });

    test('toggling one product does not affect another', () {
      final provider = ProductListProvider();
      provider.toggleFavorite('p1');
      expect(provider.isFavorite('p2'), isFalse);
    });

    test('favoriteIds is unmodifiable', () {
      final provider = ProductListProvider();
      expect(
        () => provider.favoriteIds.add('x'),
        throwsUnsupportedError,
      );
    });

    test('favorites are preserved across loadProducts calls', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SuccessProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.toggleFavorite('p1');
      expect(provider.isFavorite('p1'), isTrue);

      await provider.loadProducts();

      expect(provider.isFavorite('p1'), isTrue);
    });

    test('favorites survive error state', () async {
      GetIt.instance
          .registerLazySingleton<ProductService>(() => _SuccessProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      provider.toggleFavorite('p1');
      expect(provider.isFavorite('p1'), isTrue);

      GetIt.instance.reset();
      GetIt.instance.registerLazySingleton<ProductService>(
          () => _FailingProductService());

      await provider.loadProducts();
      expect(provider.state, ProductListState.error);
      expect(provider.isFavorite('p1'), isTrue);
    });

    test('toggleFavorite notifies listeners', () {
      final provider = ProductListProvider();

      var notified = false;
      provider.addListener(() => notified = true);

      provider.toggleFavorite('p1');

      expect(notified, isTrue);
    });
  });
}

class _NeverCompletingProductService extends ProductService {
  @override
  Future<List<ProductModel>> fetchProducts() {
    return Completer<List<ProductModel>>().future;
  }
}

class _FilterProductService extends ProductService {
  @override
  Future<List<ProductModel>> fetchProducts() async {
    return [
      ProductModel(
        id: 'p1',
        title: 'Winter Jacket',
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

class _SortProductService extends ProductService {
  @override
  Future<List<ProductModel>> fetchProducts() async {
    return [
      ProductModel(
        id: 'pa',
        title: 'Product A',
        imageUrl: 'https://example.com/a.jpg',
        htmlDescription: '<p>A</p>',
        variants: [
          const VariantModel(id: 'va1', label: 'S', price: 20.00, currency: 'USD'),
          const VariantModel(id: 'va2', label: 'M', price: 8.00, currency: 'USD'),
        ],
      ),
      ProductModel(
        id: 'pb',
        title: 'Product B',
        imageUrl: 'https://example.com/b.jpg',
        htmlDescription: '<p>B</p>',
        variants: [
          const VariantModel(id: 'vb1', label: 'S', price: 15.00, currency: 'USD'),
          const VariantModel(id: 'vb2', label: 'M', price: 40.00, currency: 'USD'),
        ],
      ),
    ];
  }
}

class _NoVariantProductService extends ProductService {
  @override
  Future<List<ProductModel>> fetchProducts() async {
    return [
      ProductModel(
        id: 'p-with-variant',
        title: 'Has Variant',
        imageUrl: 'https://example.com/a.jpg',
        htmlDescription: '<p>A</p>',
        variants: [
          const VariantModel(id: 'v1', label: 'S', price: 10.00, currency: 'USD'),
        ],
      ),
      const ProductModel(
        id: 'p-no-variant',
        title: 'No Variant',
        imageUrl: 'https://example.com/b.jpg',
        htmlDescription: '<p>B</p>',
        variants: [],
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
        title: 'Shirt',
        imageUrl: 'https://example.com/shirt.jpg',
        htmlDescription: '<p>Shirt</p>',
        variants: [
          const VariantModel(id: 'v1', label: 'S', price: 19.99, currency: 'USD'),
          const VariantModel(id: 'v2', label: 'M', price: 21.99, currency: 'USD'),
        ],
      ),
      ProductModel(
        id: 'p2',
        title: 'Pants',
        imageUrl: 'https://example.com/pants.jpg',
        htmlDescription: '<p>Pants</p>',
        variants: [
          const VariantModel(id: 'v3', label: '30', price: 39.99, currency: 'USD'),
        ],
      ),
    ];
  }
}
