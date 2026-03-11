import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get_it/get_it.dart';
import '../models/product_model.dart';
import '../services/html_content_service.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VariantModel selectedVariant;
  final ValueChanged<VariantModel> onVariantSelected;

  const ProductCard({
    super.key,
    required this.product,
    required this.selectedVariant,
    required this.onVariantSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            selectedVariant.imageUrl ?? product.imageUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 180,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported, size: 48),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selectedVariant.currency} '
                    '${selectedVariant.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: product.variants.map((v) {
                      return ChoiceChip(
                        label: Text(v.label),
                        selected: v == selectedVariant,
                        onSelected: (_) => onVariantSelected(v),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  _HtmlDescription(html: product.htmlDescription),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HtmlDescription extends StatelessWidget {
  final String html;

  const _HtmlDescription({required this.html});

  @override
  Widget build(BuildContext context) {
    final htmlService = GetIt.instance<HtmlContentService>();

    if (htmlService.hasBlockContent(html)) {
      return HtmlWidget(html);
    }
    return Text(
      htmlService.stripTags(html),
      style: const TextStyle(fontSize: 13),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
