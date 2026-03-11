import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:winp_flux_assessment/di/service_locator.dart';
import 'package:winp_flux_assessment/services/html_content_service.dart';
import 'package:winp_flux_assessment/services/product_service.dart';

void main() {
  tearDown(() {
    // Reset get_it between tests so registrations don't leak.
    GetIt.instance.reset();
  });

  group('service locator', () {
    test('resolves ProductService as the same instance (singleton)', () {
      setupServiceLocator();

      final first = GetIt.instance<ProductService>();
      final second = GetIt.instance<ProductService>();

      expect(identical(first, second), isTrue);
    });

    test('resolves HtmlContentService as the same instance (singleton)', () {
      setupServiceLocator();

      final first = GetIt.instance<HtmlContentService>();
      final second = GetIt.instance<HtmlContentService>();

      expect(identical(first, second), isTrue);
    });

    test('ProductService and HtmlContentService are distinct objects', () {
      setupServiceLocator();

      final productService = GetIt.instance<ProductService>();
      final htmlService = GetIt.instance<HtmlContentService>();

      expect(productService, isNot(equals(htmlService)));
    });
  });
}
