import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'models/models.dart';

/// The main client for interacting with the Stability AI REST API.
class StabilityAiClient {
  final String apiKey;
  final String baseUrl;
  final http.Client _httpClient;

  /// Creates a new instance of the Stability AI client.
  ///
  /// [apiKey] is required for authentication.
  /// [baseUrl] defaults to the production API endpoint.
  StabilityAiClient({
    required this.apiKey,
    this.baseUrl = 'https://api.stability.ai',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Lists all available engines.
  Future<List<Engine>> listEngines() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/v1/engines/list'),
      headers: _headers,
    );

    _checkResponse(response);
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Engine.fromJson(json)).toList();
  }

  /// Generates images from text prompts.
  Future<GenerationResponse> generateImage({
    required String engineId,
    required TextToImageRequest request,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/v1/generation/$engineId/text-to-image'),
      headers: _headers,
      body: json.encode(request.toJson()),
    );

    _checkResponse(response);
    return GenerationResponse.fromJson(json.decode(response.body));
  }

  /// Generates an image using the Stable Image Ultra API.
  ///
  /// Returns either an [UltraImageResponse] containing the base64 encoded image and metadata
  /// when [returnJson] is true, or [UltraImageBytes] containing the raw image data when
  /// [returnJson] is false.
  ///
  /// The resolution of the generated image will be 1 megapixel. The default resolution is 1024x1024.
  Future<UltraImageResult> generateUltraImage({
    required UltraImageRequest request,
    bool returnJson = false,
  }) async {
    final uri = Uri.parse('$baseUrl/v2beta/stable-image/generate/ultra');
    final multipart = http.MultipartRequest('POST', uri);

    // Add headers
    multipart.headers.addAll(_ultraHeaders(returnJson: returnJson));

    // Add required fields
    multipart.fields['prompt'] = request.prompt;

    // Add optional fields
    if (request.negativePrompt != null) {
      multipart.fields['negative_prompt'] = request.negativePrompt!;
    }
    if (request.aspectRatio != null) {
      multipart.fields['aspect_ratio'] =
          request.aspectRatio.toString().split('.').last;
    }
    if (request.seed != null) {
      multipart.fields['seed'] = request.seed.toString();
    }
    if (request.outputFormat != null) {
      multipart.fields['output_format'] =
          request.outputFormat.toString().split('.').last;
    }
    if (request.strength != null) {
      multipart.fields['strength'] = request.strength.toString();
    }

    // Add image if provided
    if (request.image != null) {
      final imageFile = http.MultipartFile.fromBytes(
        'image',
        request.image!,
        filename: 'image',
        contentType: MediaType('image', '*'),
      );
      multipart.files.add(imageFile);
    }

    final streamedResponse = await _httpClient.send(multipart);
    final response = await http.Response.fromStream(streamedResponse);

    _checkResponse(response);

    if (returnJson) {
      return UltraImageResponse.fromJson(json.decode(response.body));
    } else {
      return UltraImageBytes(response.bodyBytes);
    }
  }

  /// Closes the client and frees up resources.
  void close() {
    _httpClient.close();
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> _ultraHeaders({bool returnJson = false}) => {
        'Authorization': 'Bearer $apiKey',
        'Accept': returnJson ? 'application/json' : 'image/*',
      };

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      try {
        // Try to parse the response body as JSON
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // If it's in our error format, parse it
        if (jsonData.containsKey('errors') &&
            jsonData.containsKey('id') &&
            jsonData.containsKey('name')) {
          final error = ErrorResponse.fromJson(jsonData);
          throw StabilityAiException(
            statusCode: response.statusCode,
            message: error.errors.join(', '),
            id: error.id,
            name: error.name,
          );
        }

        // If it has a message field, use that
        if (jsonData.containsKey('message')) {
          throw StabilityAiException(
            statusCode: response.statusCode,
            message: jsonData['message'] as String,
          );
        }

        // Otherwise use the raw body
        throw StabilityAiException(
          statusCode: response.statusCode,
          message: response.body,
        );
      } on FormatException {
        // If JSON parsing fails, use raw body
        throw StabilityAiException(
          statusCode: response.statusCode,
          message: response.body,
        );
      }
    }
  }
}

/// Exception thrown when the API returns an error.
class StabilityAiException implements Exception {
  /// The HTTP status code of the error.
  final int statusCode;

  /// The error message.
  final String message;

  /// A unique identifier associated with this error.
  final String? id;

  /// Short-hand name for the error.
  final String? name;

  StabilityAiException({
    required this.statusCode,
    required this.message,
    this.id,
    this.name,
  });

  @override
  String toString() {
    final buffer = StringBuffer('StabilityAiException: $statusCode');
    if (name != null) buffer.write(' ($name)');
    buffer.write(' - $message');
    if (id != null) buffer.write(' [ID: $id]');
    return buffer.toString();
  }
}
