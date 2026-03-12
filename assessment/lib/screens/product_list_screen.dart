import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_list_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/responsive_layout.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductListProvider()..loadProducts(),
      child: const _ProductListView(),
    );
  }
}

class _ProductListView extends StatelessWidget {
  const _ProductListView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductListProvider>();

    final grid = switch (provider.state) {
      ProductListState.initial ||
      ProductListState.loading =>
        const _SkeletonGrid(),
      ProductListState.refreshing => Stack(
          children: [
            ResponsiveLayout(
              mobile: _ProductGrid(provider: provider, crossAxisCount: 1),
              tablet: _ProductGrid(provider: provider, crossAxisCount: 2),
              desktop: _ProductGrid(provider: provider, crossAxisCount: 3),
            ),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ProductListState.error => _ErrorView(
          message: provider.errorMessage,
          onRetry: provider.loadProducts,
        ),
      ProductListState.loaded => ResponsiveLayout(
          mobile: _ProductGrid(provider: provider, crossAxisCount: 1),
          tablet: _ProductGrid(provider: provider, crossAxisCount: 2),
          desktop: _ProductGrid(provider: provider, crossAxisCount: 3),
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: provider.filterProducts,
            ),
          ),
          Expanded(child: grid),
        ],
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message ?? 'Something went wrong.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final ProductListProvider provider;
  final int crossAxisCount;

  const _ProductGrid({
    required this.provider,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.55,
      ),
      itemCount: provider.filteredProducts.length,
      itemBuilder: (_, index) {
        final product = provider.filteredProducts[index];
        final selected = provider.selectedVariantFor(product.id);

        if (selected == null) return const SizedBox.shrink();

        return ProductCard(
          product: product,
          selectedVariant: selected,
          onVariantSelected: (variant) =>
              provider.selectVariant(product.id, variant),
        );
      },
    );
  }
}
