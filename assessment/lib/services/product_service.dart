import 'dart:convert';

import 'package:flutter/services.dart';
import '../models/product_model.dart';

class ProductService {
  Future<List<ProductModel>> fetchProducts() async {
    final jsonStr = await rootBundle.loadString('assets/products.json');
    await Future.delayed(const Duration(milliseconds: 500));
    final data = jsonDecode(jsonStr) as List;
    return data
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
