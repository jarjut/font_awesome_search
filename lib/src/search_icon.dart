import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_search/font_awesome_search.dart';
import 'package:graphql/client.dart';
import 'icon_object.dart';

final _httpLink = HttpLink('https://api.fontawesome.com');

GraphQLClient getGraphQLClient() {
  return GraphQLClient(
    cache: GraphQLCache(),
    link: _httpLink,
  );
}

Future<List<IconData>> searchIcons(
  String query, {
  String version = "6.2.1",
  int limit = 15,
}) async {
  final client = getGraphQLClient();

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

  return getIconsFromIconObjects(iconObjects);
}

List<IconData> getIconsFromIconObjects(List<IconObject> iconObjects) {
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
