<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# Font Awesome Search

[![Pub](https://img.shields.io/pub/v/font_awesome_search.svg)](https://pub.dev/packages/font_awesome_search)

Provide a search function for [font_awesome_flutter](https://pub.dev/packages/font_awesome_flutter) package using the same Algolia search engine that powers the FontAwesome Icon Gallery

This function call graphql API from https://api.fontawesome.com. For more information about the API, please visit
https://fontawesome.com/docs/apis/graphql/query-fields

!! This package doesn't support custom icons yet, you can only search for free icons !!

## Installation
```yaml
dependencies:
  font_awesome_flutter: 
  font_awesome_search: 
```

## Usage

```dart
import 'package:font_awesome_search/font_awesome_search.dart';

final icons = await searchFontAwesomeIcons('query');
```

## Important Notice

To make this package work you need to disables icon tree shaking. This means unused
icons will not be automatically removed and thus make the overall app size
larger. You may need to pass --no-tree-shake-icons to the flutter build command for it
to complete successfully.

Example:

```
flutter build apk --no-tree-shake-icons
```


