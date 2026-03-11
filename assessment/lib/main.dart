import 'package:flutter/material.dart';
import 'di/service_locator.dart';
import 'router.dart';

void main() {
  setupServiceLocator();
  runApp(const ProductListing());
}

class ProductListing extends StatelessWidget {
  const ProductListing({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Product Listing Assessment',
      routerConfig: appRouter,
    );
  }
}
