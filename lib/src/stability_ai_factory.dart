import 'package:http/http.dart' as http;
import 'stability_ai_interface.dart';
import 'stability_ai_client.dart';

/// Factory for creating instances of [StabilityAiInterface].
class StabilityAiFactory {
  /// Creates a new instance of [StabilityAiInterface].
  ///
  /// [apiKey] is required for authentication.
  /// [baseUrl] defaults to the production API endpoint.
  /// [httpClient] can be provided to customize the HTTP client used for requests.
  static StabilityAiInterface create({
    required String apiKey,
    String baseUrl = 'https://api.stability.ai',
    http.Client? httpClient,
  }) {
    return StabilityAiClientImpl(
      apiKey: apiKey,
      baseUrl: baseUrl,
      httpClient: httpClient,
    );
  }
}
