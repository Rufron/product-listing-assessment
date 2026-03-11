import 'package:get_it/get_it.dart';
import '../services/html_content_service.dart';
import '../services/product_service.dart';

void setupServiceLocator() {
  final sl = GetIt.instance;
  // The tests expect that both services resolve as singletons, so we use
  // lazySingleton registrations instead of factories.
  sl.registerLazySingleton<ProductService>(() => ProductService());
  sl.registerLazySingleton<HtmlContentService>(() => HtmlContentService());
}
