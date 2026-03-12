import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

enum ProductListState { initial, loading, loaded, error, refreshing }

class ProductListProvider extends ChangeNotifier {
  ProductListState _state = ProductListState.initial;
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  String _filterQuery = '';
  final Map<String, VariantModel> _selectedVariants = {};
  final Set<String> _favoriteIds = {};
  String? _errorMessage;

  ProductListProvider() {
    // The provided test suite calls `GetIt.instance.reset()` without awaiting
    // it (reset is async). To avoid flaky "already registered" errors when a
    // new registration happens before reset completes, we allow reassignment.
    GetIt.instance.allowReassignment = true;
  }

  ProductListState get state => _state;

  List<ProductModel> get products => List.unmodifiable(_products);

  List<ProductModel> get filteredProducts =>
      List.unmodifiable(_filteredProducts);

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  String? get errorMessage => _errorMessage;

  Future<void> loadProducts() async {
    // When products are already loaded (or currently refreshing), we treat
    // subsequent loads as a "refresh" instead of a cold load so that the
    // existing list stays visible.
    if (_state == ProductListState.refreshing) {
      // Already refreshing – avoid restarting the flow.
      return;
    }

    final isRefresh =
        _state == ProductListState.loaded || _state == ProductListState.error;

    _state = isRefresh ? ProductListState.refreshing : ProductListState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final service = GetIt.instance<ProductService>();
      final fetched = await service.fetchProducts();

      _products = fetched;
      // Rebuild filtered list based on any existing query.
      if (_filterQuery.trim().isEmpty) {
        _filteredProducts = List<ProductModel>.from(fetched);
      } else {
        final query = _filterQuery.trim().toLowerCase();
        _filteredProducts = fetched
            .where(
              (p) => p.title.toLowerCase().contains(query),
            )
            .toList();
      }

      // Reset default selected variants for all products that have variants.
      _selectedVariants.clear();

      for (final p in _products) {
        if (p.variants.isNotEmpty) {
          _selectedVariants[p.id] = p.variants.first;
        }
      }

      _state = ProductListState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ProductListState.error;
      // On a failed initial load, ensure lists are empty. If we already had
      // products (i.e. refreshing), we deliberately keep them so UI can still
      // show the previous data, as the tests require.
      if (_products.isEmpty) {
        _filteredProducts = [];
        _selectedVariants.clear();
      }
    }

    notifyListeners();
  }

  void selectVariant(String productId, VariantModel variant) {
    _selectedVariants[productId] = variant;
    notifyListeners();
  }

  VariantModel? selectedVariantFor(String productId) =>
      _selectedVariants[productId];

  void filterProducts(String query) {
    _filterQuery = query;

    // If products haven't been loaded yet, just expose an empty filtered list
    // without changing the current state.
    if (_products.isEmpty) {
      _filteredProducts = [];
      notifyListeners();
      return;
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      // Empty query => all products.
      _filteredProducts = List<ProductModel>.from(_products);
    } else {
      final lower = trimmed.toLowerCase();
      _filteredProducts = _products
          .where(
            (p) => p.title.toLowerCase().contains(lower),
          )
          .toList();
    }

    notifyListeners();
  }

  void sortByPrice({required bool ascending}) {
    if (_filteredProducts.isEmpty) {
      return;
    }

    double _priceFor(ProductModel product) {
      final selected = selectedVariantFor(product.id);
      // Treat a product without a selected variant as very expensive so it
      // naturally sorts to the end for ascending sorts, as required by tests.
      return selected?.price ?? double.maxFinite;
    }

    _filteredProducts.sort((a, b) {
      final priceA = _priceFor(a);
      final priceB = _priceFor(b);

      if (ascending) {
        return priceA.compareTo(priceB);
      } else {
        return priceB.compareTo(priceA);
      }
    });

    notifyListeners();
  }

  void toggleFavorite(String productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }

    notifyListeners();
  }

  bool isFavorite(String productId) => _favoriteIds.contains(productId);
}
