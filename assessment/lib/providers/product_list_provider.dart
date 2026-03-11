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

  ProductListState get state => _state;

  List<ProductModel> get products => List.unmodifiable(_products);

  List<ProductModel> get filteredProducts => List.unmodifiable(_filteredProducts);

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  String? get errorMessage => _errorMessage;

  Future<void> loadProducts() async {
    _state = ProductListState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final service = GetIt.instance<ProductService>();
      final fetched = await service.fetchProducts();

      _products = fetched;
      _filteredProducts = List.from(fetched);
      notifyListeners();

      for (final p in _products) {
        if (p.variants.isNotEmpty) {
          _selectedVariants[p.id] = p.variants.first;
        }
      }

      _state = ProductListState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ProductListState.error;
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
  }

  void sortByPrice({required bool ascending}) {
  }

  void toggleFavorite(String productId) {
  }

  bool isFavorite(String productId) => false;
}
