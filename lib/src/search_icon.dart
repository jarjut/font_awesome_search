import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_search/font_awesome_search.dart';
import 'package:graphql/client.dart';
import 'icon_object.dart';

final _httpLink = HttpLink('https://api.fontawesome.com');

GraphQLClient _getGraphQLClient() {
  return GraphQLClient(
    cache: GraphQLCache(),
    link: _httpLink,
  );
}

/// Search for icons from [query] and return a list of [IconData].
///
/// Results for an icon query, using the same Algolia search engine that powers
/// the FontAwesome Icon Gallery.
///
/// This function call graphql API from https://api.fontawesome.com.
/// for more information about the API, please visit
/// https://fontawesome.com/docs/apis/graphql/query-fields
Future<List<IconData>> searchFontAwesomeIcons(
  String query, {
  String version = "6.2.1",
  int limit = 100,
}) async {
  final client = _getGraphQLClient();

  final docQuery = gql('''
    query {
      search(query: "$query", version: "$version", first: $limit) {
        id,
        label,
        familyStylesByLicense{
            free{
                family,
                style,
            }
        }
      }
    }
  ''');

  final result = await client.query(
    QueryOptions(
      document: docQuery,
    ),
  );

  if (result.hasException) {
    throw Exception();
  }

  final data = result.data?['search'] as List;
  final iconObjects = data.map((json) => IconObject.fromJson(json)).toList();

  return _getIconsFromIconObjects(iconObjects);
}

List<IconData> _getIconsFromIconObjects(List<IconObject> iconObjects) {
  List<IconData> icons = [];

  for (final iconObject in iconObjects) {
    for (final familyStyle in iconObject.familyStyle) {
      final icon = faIconNameMapping['${familyStyle.style} ${iconObject.id}'] ??
          FontAwesomeIcons.circleQuestion;
      icons.add(icon);
    }
  }
  return icons;
}
