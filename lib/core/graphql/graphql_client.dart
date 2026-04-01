import 'package:ferry/ferry.dart';
import 'package:gql_http_link/gql_http_link.dart';

/// Ferry client factory.
///
/// Usage:
/// ```dart
/// final client = FerryClientSetup.create(
///   endpoint: 'https://api.example.com/graphql',
/// );
/// ```
class FerryClientSetup {
  FerryClientSetup._();

  /// Create and return a Ferry [Client] with optional auth token.
  static Client create({
    required String endpoint,
    String? authToken,
  }) {
    final httpLink = HttpLink(
      endpoint,
      defaultHeaders: authToken != null
          ? {'Authorization': 'Bearer $authToken'}
          : {},
    );

    return Client(link: httpLink);
  }
}

