# WINP Flux — Product Listing Assessment

**Role:** Flutter Engineer
**Time limit:** 2 days


## Prerequisites

- Flutter SDK (stable channel)
- A code editor with Dart/Flutter support



## Getting Started

```bash
flutter pub get
flutter test --reporter=expanded
```

You will see a mix of passing and failing tests. Your goal is to make **all 55 tests pass**.


## Project Structure

```
assets/
└── products.json                   # Local mock product data
lib/
├── main.dart
├── router.dart
├── di/
│   └── service_locator.dart        # GetIt service registration
├── models/
│   └── product_model.dart          # ProductModel + VariantModel
├── services/
│   ├── product_service.dart        # Loads product data from local JSON asset
│   └── html_content_service.dart   # HTML utility methods
├── providers/
│   └── product_list_provider.dart  # ChangeNotifier state management
├── screens/
│   └── product_list_screen.dart    # Main screen with provider wiring
└── widgets/
    ├── product_card.dart           # Product display card
    └── responsive_layout.dart      # Layout breakpoints
```



## Key Packages

| Package                         | Purpose                                |
| ------------------------------- | -------------------------------------- |
| `get_it`                        | Service locator / dependency injection |
| `provider`                      | ChangeNotifier-based state management  |
| `dio`                           | HTTP client                            |
| `go_router`                     | Declarative routing                    |
| `flutter_widget_from_html_core` | Rendering HTML content                 |



## Your Task

The scaffold contains **deliberate bugs** and **unimplemented feature stubs**. You need to:

1. **Fix existing bugs** — some tests fail due to issues already in the code. Diagnose and fix them.
2. **Implement features** — the test suite describes exactly what each feature must do. Read the tests carefully.
3. **Write unit tests** — create `test/html_content_service_test.dart` with 8 tests for the `HtmlContentService` class.




## Test Suite

| Category                             | Tests  |
| ------------------------------------ | ------ |
| Service resolution                   | 3      |
| Provider state machine               | 9      |
| Refreshing state                     | 4      |
| Filter                               | 7      |
| Sort                                 | 5      |
| Filter + sort interaction            | 3      |
| Favorites                            | 8      |
| Screen widgets                       | 7      |
| HtmlContentService (you write these) | 8      |
| **Total**                            | **55** |

47 tests are provided in the scaffold. You write the remaining 8.


## Submission

Push your completed work to the provided repository.
