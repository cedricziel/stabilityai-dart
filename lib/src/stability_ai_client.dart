import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'models/models.dart';

/// A client for interacting with the Stability AI REST API.
///
/// This client provides access to Stability AI's image generation and manipulation APIs:
///
/// Text-to-Image Generation:
/// ```dart
/// final request = TextToImageRequest(
///   textPrompts: [TextPrompt(text: 'A serene landscape at sunset')],
/// );
/// final response = await client.generateImage(
///   engineId: 'stable-diffusion-v1-5',
///   request: request,
/// );
/// ```
///
/// Ultra Image Generation:
/// ```dart
/// final request = UltraImageRequest(
///   prompt: 'A futuristic cityscape',
///   aspectRatio: AspectRatio.ratio16x9,
/// );
/// final response = await client.generateUltraImage(request: request);
/// ```
///
/// Background Removal:
/// ```dart
/// final request = RemoveBackgroundRequest(
///   image: imageBytes,
///   outputFormat: OutputFormat.png,
/// );
/// final response = await client.removeBackground(request: request);
/// ```
///
/// Image Upscaling:
/// ```dart
/// final request = UpscaleRequest(
///   image: imageBytes,
///   prompt: 'High resolution landscape photo',
/// );
/// final response = await client.upscaleImage(request: request);
/// ```
///
/// The client handles:
/// - Authentication via API key
/// - Request formatting and validation
/// - Response parsing and error handling
/// - File uploads for image-based operations
///
/// Remember to call [close] when you're done with the client to free up resources.
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

  /// Removes the background from an image.
  ///
  /// Returns either a [RemoveBackgroundResponse] containing the base64 encoded image and metadata
  /// when [returnJson] is true, or [UltraImageBytes] containing the raw image data when
  /// [returnJson] is false.
  Future<UltraImageResult> removeBackground({
    required RemoveBackgroundRequest request,
    bool returnJson = false,
  }) async {
    final uri =
        Uri.parse('$baseUrl/v2beta/stable-image/edit/remove-background');
    final multipart = http.MultipartRequest('POST', uri);

    // Add headers
    multipart.headers.addAll(_ultraHeaders(returnJson: returnJson));

    // Add image file
    final imageFile = http.MultipartFile.fromBytes(
      'image',
      request.image,
      filename: 'image',
      contentType: MediaType('image', '*'),
    );
    multipart.files.add(imageFile);

    // Add optional output format
    if (request.outputFormat != null) {
      multipart.fields['output_format'] =
          request.outputFormat.toString().split('.').last;
    }

    final streamedResponse = await _httpClient.send(multipart);
    final response = await http.Response.fromStream(streamedResponse);

    _checkResponse(response);

    if (returnJson) {
      return RemoveBackgroundResponse.fromJson(json.decode(response.body));
    } else {
      return UltraImageBytes(response.bodyBytes);
    }
  }

  /// Upscales an image using the standard upscaler (up to 4K).
  ///
  /// Takes images between 64x64 and 1 megapixel and upscales them while preserving
  /// and often enhancing quality. The upscaling process can increase the image size
  /// by 20-40 times.
  ///
  /// The [request] must include:
  /// - An image file between 64x64 and 1 megapixel in size
  /// - A prompt describing what you wish to see in the output image
  ///
  /// Optional parameters in the request:
  /// - [negativePrompt]: Keywords of what you do not wish to see
  /// - [outputFormat]: Desired format of the output image (jpeg, png, or webp)
  /// - [seed]: Specific value to guide the randomness (0-4294967294)
  /// - [creativity]: Controls how creative the model should be (0-0.35)
  ///
  /// Returns an [UpscaleResponse] containing a generation ID that can be used to
  /// fetch the result from the upscale/result/{id} endpoint.
  ///
  /// Example:
  /// ```dart
  /// final request = UpscaleRequest(
  ///   image: imageBytes,
  ///   prompt: 'A cute fluffy white kitten floating in space, pastel colors',
  ///   outputFormat: OutputFormat.webp,
  /// );
  /// final response = await client.upscaleImage(request: request);
  /// print('Generation ID: ${response.id}');
  /// ```
  ///
  /// Note: This endpoint has a flat rate of 25 credits per generation.
  Future<UpscaleResponse> upscaleImage({
    required UpscaleRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl/v2alpha/generation/stable-image/upscale');
    final multipart = http.MultipartRequest('POST', uri);

    // Add headers
    multipart.headers.addAll(_headers);

    // Add image file
    final imageFile = http.MultipartFile.fromBytes(
      'image',
      request.image,
      filename: 'image',
      contentType: MediaType('image', '*'),
    );
    multipart.files.add(imageFile);

    // Add required prompt
    multipart.fields['prompt'] = request.prompt;

    // Add optional fields
    if (request.negativePrompt != null) {
      multipart.fields['negative_prompt'] = request.negativePrompt!;
    }
    if (request.outputFormat != null) {
      multipart.fields['output_format'] =
          request.outputFormat.toString().split('.').last;
    }
    if (request.seed != null) {
      multipart.fields['seed'] = request.seed.toString();
    }
    if (request.creativity != null) {
      multipart.fields['creativity'] = request.creativity.toString();
    }

    final streamedResponse = await _httpClient.send(multipart);
    final response = await http.Response.fromStream(streamedResponse);

    _checkResponse(response);
    return UpscaleResponse.fromJson(json.decode(response.body));
  }

  /// Upscales an image using the creative upscaler (up to 4K).
  ///
  /// Takes images between 64x64 and 1 megapixel and upscales them all the way to 4K resolution.
  /// Put more generally, it can upscale images ~20-40x times while preserving, and often enhancing, quality.
  /// Creative Upscale works best on highly degraded images and is not for photos of 1mp or above as it performs
  /// heavy reimagining (controlled by creativity scale).
  ///
  /// The [request] must include:
  /// - An image file between 64x64 and 1 megapixel in size
  /// - A prompt describing what you wish to see in the output image
  ///
  /// Optional parameters in the request:
  /// - [negativePrompt]: Keywords of what you do not wish to see
  /// - [outputFormat]: Desired format of the output image (jpeg, png, or webp)
  /// - [seed]: Specific value to guide the randomness (0-4294967294)
  /// - [creativity]: Controls how creative the model should be (0-0.35)
  ///
  /// Returns an [UpscaleResponse] containing a generation ID that can be used to
  /// fetch the result from the results/{id} endpoint.
  ///
  /// Example:
  /// ```dart
  /// final request = UpscaleRequest(
  ///   image: imageBytes,
  ///   prompt: 'A cute fluffy white kitten floating in space, pastel colors',
  ///   outputFormat: OutputFormat.webp,
  /// );
  /// final response = await client.upscaleImageCreative(request: request);
  /// print('Generation ID: ${response.id}');
  /// ```
  ///
  /// Note: This endpoint has a flat rate of 25 credits per generation.
  Future<UpscaleResponse> upscaleImageCreative({
    required UpscaleRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl/v2beta/stable-image/upscale/creative');
    final multipart = http.MultipartRequest('POST', uri);

    // Add headers
    multipart.headers.addAll(_headers);

    // Add image file
    final imageFile = http.MultipartFile.fromBytes(
      'image',
      request.image,
      filename: 'image',
      contentType: MediaType('image', '*'),
    );
    multipart.files.add(imageFile);

    // Add required prompt
    multipart.fields['prompt'] = request.prompt;

    // Add optional fields
    if (request.negativePrompt != null) {
      multipart.fields['negative_prompt'] = request.negativePrompt!;
    }
    if (request.outputFormat != null) {
      multipart.fields['output_format'] =
          request.outputFormat.toString().split('.').last;
    }
    if (request.seed != null) {
      multipart.fields['seed'] = request.seed.toString();
    }
    if (request.creativity != null) {
      multipart.fields['creativity'] = request.creativity.toString();
    }

    final streamedResponse = await _httpClient.send(multipart);
    final response = await http.Response.fromStream(streamedResponse);

    _checkResponse(response);
    return UpscaleResponse.fromJson(json.decode(response.body));
  }

  /// Upscales an image using the conservative upscaler (up to 4K).
  ///
  /// Takes images between 64x64 and 1 megapixel and upscales them while preserving
  /// all aspects. Conservative Upscale minimizes alterations to the image and should
  /// not be used to reimagine an image.
  ///
  /// Returns either an [UltraImageResponse] containing the base64 encoded image and metadata
  /// when [returnJson] is true, or [UltraImageBytes] containing the raw image data when
  /// [returnJson] is false.
  ///
  /// The resolution of the generated image will be 4 megapixels.
  ///
  /// Note: This endpoint has a flat rate of 25 credits per generation.
  Future<UltraImageResult> upscaleImageConservative({
    required UpscaleRequest request,
    bool returnJson = false,
  }) async {
    final uri = Uri.parse('$baseUrl/v2beta/stable-image/upscale/conservative');
    final multipart = http.MultipartRequest('POST', uri);

    // Add headers
    multipart.headers.addAll(_ultraHeaders(returnJson: returnJson));

    // Add image file
    final imageFile = http.MultipartFile.fromBytes(
      'image',
      request.image,
      filename: 'image',
      contentType: MediaType('image', '*'),
    );
    multipart.files.add(imageFile);

    // Add required prompt
    multipart.fields['prompt'] = request.prompt;

    // Add optional fields
    if (request.negativePrompt != null) {
      multipart.fields['negative_prompt'] = request.negativePrompt!;
    }
    if (request.outputFormat != null) {
      multipart.fields['output_format'] =
          request.outputFormat.toString().split('.').last;
    }
    if (request.seed != null) {
      multipart.fields['seed'] = request.seed.toString();
    }
    if (request.creativity != null) {
      multipart.fields['creativity'] = request.creativity.toString();
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

  /// Fetches the result of an upscale generation by ID.
  ///
  /// Returns either an [UpscaleResultResponse] containing the base64 encoded image and metadata
  /// when [returnJson] is true, or [UpscaleResultBytes] containing the raw image data when
  /// [returnJson] is false.
  ///
  /// If the generation is still in progress (status code 202), returns an [UpscaleInProgressResponse].
  ///
  /// Make sure to use the same API key to fetch the generation result that you used to create
  /// the generation, otherwise you will receive a 404 response.
  ///
  /// Results are stored for 24 hours after generation. After that, the results are deleted.
  ///
  /// Example:
  /// ```dart
  /// // First, upscale an image
  /// final upscaleResponse = await client.upscaleImage(request: request);
  ///
  /// // Then, poll for the result
  /// while (true) {
  ///   final result = await client.getUpscaleResult(
  ///     id: upscaleResponse.id,
  ///     returnJson: false,
  ///   );
  ///
  ///   if (result is UpscaleInProgressResponse) {
  ///     // Still processing, wait and try again
  ///     await Future.delayed(Duration(seconds: 10));
  ///     continue;
  ///   }
  ///
  ///   // Generation complete
  ///   if (result is UpscaleResultBytes) {
  ///     // Handle raw bytes
  ///     await File('upscaled.png').writeAsBytes(result.bytes);
  ///   } else if (result is UpscaleResultResponse) {
  ///     // Handle JSON response
  ///     print('Finish reason: ${result.finishReason}');
  ///     final bytes = base64.decode(result.image);
  ///     await File('upscaled.png').writeAsBytes(bytes);
  ///   }
  ///   break;
  /// }
  /// ```
  Future<Object> getUpscaleResult({
    required String id,
    bool returnJson = false,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/v2alpha/generation/stable-image/upscale/result/$id'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': returnJson ? 'application/json' : 'image/*',
      },
    );

    if (response.statusCode == 202) {
      return UpscaleInProgressResponse.fromJson(json.decode(response.body));
    }

    _checkResponse(response);

    if (returnJson) {
      return UpscaleResultResponse.fromJson(json.decode(response.body));
    } else {
      return UpscaleResultBytes(response.bodyBytes);
    }
  }

  /// Upscales an image using the standard upscaler and waits for the result.
  ///
  /// This is a convenience method that combines [upscaleImage] and [getUpscaleResult]
  /// into a single call. It handles polling for the result internally.
  ///
  /// The [request] must include:
  /// - An image file between 64x64 and 1 megapixel in size
  /// - A prompt describing what you wish to see in the output image
  ///
  /// Optional parameters in the request:
  /// - [negativePrompt]: Keywords of what you do not wish to see
  /// - [outputFormat]: Desired format of the output image (jpeg, png, or webp)
  /// - [seed]: Specific value to guide the randomness (0-4294967294)
  /// - [creativity]: Controls how creative the model should be (0-0.35)
  ///
  /// Returns either an [UpscaleResultResponse] containing the base64 encoded image and metadata
  /// when [returnJson] is true, or [UpscaleResultBytes] containing the raw image data when
  /// [returnJson] is false.
  ///
  /// Example:
  /// ```dart
  /// final request = UpscaleRequest(
  ///   image: imageBytes,
  ///   prompt: 'A high resolution landscape photo',
  ///   outputFormat: OutputFormat.png,
  /// );
  /// final result = await client.upscaleImageAndWaitForResult(
  ///   request: request,
  ///   returnJson: false,
  /// );
  /// if (result is UpscaleResultBytes) {
  ///   await File('upscaled.png').writeAsBytes(result.bytes);
  /// }
  /// ```
  ///
  /// Note: This endpoint has a flat rate of 25 cents per generation.
  Future<UpscaleResult> upscaleImageAndWaitForResult({
    required UpscaleRequest request,
    bool returnJson = false,
    Duration pollInterval = const Duration(seconds: 10),
  }) async {
    final response = await upscaleImage(request: request);

    while (true) {
      final result = await getUpscaleResult(
        id: response.id,
        returnJson: returnJson,
      );

      if (result is UpscaleInProgressResponse) {
        await Future.delayed(pollInterval);
        continue;
      }

      return result as UpscaleResult;
    }
  }

  /// Fetches the result of a creative upscale generation by ID.
  ///
  /// Returns either an [UpscaleResultResponse] containing the base64 encoded image and metadata
  /// when [returnJson] is true, or [UpscaleResultBytes] containing the raw image data when
  /// [returnJson] is false.
  ///
  /// If the generation is still in progress (status code 202), returns an [UpscaleInProgressResponse].
  ///
  /// Make sure to use the same API key to fetch the generation result that you used to create
  /// the generation, otherwise you will receive a 404 response.
  ///
  /// Results are stored for 24 hours after generation. After that, the results are deleted.
  ///
  /// Example:
  /// ```dart
  /// // First, upscale an image
  /// final upscaleResponse = await client.upscaleImageCreative(request: request);
  ///
  /// // Then, poll for the result
  /// while (true) {
  ///   final result = await client.getCreativeUpscaleResult(
  ///     id: upscaleResponse.id,
  ///     returnJson: false,
  ///   );
  ///
  ///   if (result is UpscaleInProgressResponse) {
  ///     // Still processing, wait and try again
  ///     await Future.delayed(Duration(seconds: 10));
  ///     continue;
  ///   }
  ///
  ///   // Generation complete
  ///   if (result is UpscaleResultBytes) {
  ///     // Handle raw bytes
  ///     await File('upscaled.png').writeAsBytes(result.bytes);
  ///   } else if (result is UpscaleResultResponse) {
  ///     // Handle JSON response
  ///     print('Finish reason: ${result.finishReason}');
  ///     final bytes = base64.decode(result.image);
  ///     await File('upscaled.png').writeAsBytes(bytes);
  ///   }
  ///   break;
  /// }
  /// ```
  Future<Object> getCreativeUpscaleResult({
    required String id,
    bool returnJson = false,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/v2beta/stable-image/upscale/creative/result/$id'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': returnJson ? 'application/json' : 'image/*',
      },
    );

    if (response.statusCode == 202) {
      return UpscaleInProgressResponse.fromJson(json.decode(response.body));
    }

    _checkResponse(response);

    if (returnJson) {
      return UpscaleResultResponse.fromJson(json.decode(response.body));
    } else {
      return UpscaleResultBytes(response.bodyBytes);
    }
  }

  Future<UltraImageResult> upscaleImageConservativeAndWaitForResult({
    required UpscaleRequest request,
    bool returnJson = false,
    Duration pollInterval = const Duration(seconds: 10),
  }) async {
    return upscaleImageConservative(request: request, returnJson: returnJson);
  }

  /// Upscales an image using the fast upscaler (4x).
  ///
  /// Our Fast Upscaler service enhances image resolution by 4x using predictive and generative AI.
  /// This lightweight and fast service (processing in ~1 second) is ideal for enhancing the quality
  /// of compressed images, making it suitable for social media posts and other applications.
  ///
  /// Returns either a [FastUpscaleResponse] containing the base64 encoded image and metadata
  /// when [returnJson] is true, or [FastUpscaleBytes] containing the raw image data when
  /// [returnJson] is false.
  ///
  /// The resolution of the generated image is 4 times that of the input image with a maximum
  /// size of 16 megapixels.
  ///
  /// Validation Rules:
  /// - Width must be between 32 and 1,536 pixels
  /// - Height must be between 32 and 1,536 pixels
  /// - Total pixel count must be between 1,024 and 1,048,576 pixels
  ///
  /// Example:
  /// ```dart
  /// final request = FastUpscaleRequest(
  ///   image: imageBytes,
  ///   outputFormat: OutputFormat.webp,
  /// );
  /// final result = await client.upscaleImageFast(
  ///   request: request,
  ///   returnJson: false,
  /// );
  /// if (result is FastUpscaleBytes) {
  ///   await File('upscaled.webp').writeAsBytes(result.bytes);
  /// }
  /// ```
  ///
  /// Note: This endpoint has a flat rate of 1 credit per successful generation.
  Future<FastUpscaleResult> upscaleImageFast({
    required FastUpscaleRequest request,
    bool returnJson = false,
  }) async {
    final uri = Uri.parse('$baseUrl/v2beta/stable-image/upscale/fast');
    final multipart = http.MultipartRequest('POST', uri);

    // Add headers
    multipart.headers.addAll(_ultraHeaders(returnJson: returnJson));

    // Add image file
    final imageFile = http.MultipartFile.fromBytes(
      'image',
      request.image,
      filename: 'image',
      contentType: MediaType('image', '*'),
    );
    multipart.files.add(imageFile);

    // Add optional output format
    if (request.outputFormat != null) {
      multipart.fields['output_format'] =
          request.outputFormat.toString().split('.').last;
    }

    final streamedResponse = await _httpClient.send(multipart);
    final response = await http.Response.fromStream(streamedResponse);

    _checkResponse(response);

    if (returnJson) {
      return FastUpscaleResponse.fromJson(json.decode(response.body));
    } else {
      return FastUpscaleBytes(response.bodyBytes);
    }
  }

  /// Upscales an image using the creative upscaler and waits for the result.
  ///
  /// This is a convenience method that combines [upscaleImageCreative] and [getCreativeUpscaleResult]
  /// into a single call. It handles polling for the result internally.
  ///
  /// Takes images between 64x64 and 1 megapixel and upscales them all the way to 4K resolution.
  /// Put more generally, it can upscale images ~20-40x times while preserving, and often enhancing, quality.
  /// Creative Upscale works best on highly degraded images and is not for photos of 1mp or above as it performs
  /// heavy reimagining (controlled by creativity scale).
  ///
  /// The [request] must include:
  /// - An image file between 64x64 and 1 megapixel in size
  /// - A prompt describing what you wish to see in the output image
  ///
  /// Optional parameters in the request:
  /// - [negativePrompt]: Keywords of what you do not wish to see
  /// - [outputFormat]: Desired format of the output image (jpeg, png, or webp)
  /// - [seed]: Specific value to guide the randomness (0-4294967294)
  /// - [creativity]: Controls how creative the model should be (0-0.35)
  ///
  /// Returns either an [UpscaleResultResponse] containing the base64 encoded image and metadata
  /// when [returnJson] is true, or [UpscaleResultBytes] containing the raw image data when
  /// [returnJson] is false.
  ///
  /// Example:
  /// ```dart
  /// final request = UpscaleRequest(
  ///   image: imageBytes,
  ///   prompt: 'A high resolution landscape photo',
  ///   outputFormat: OutputFormat.png,
  ///   creativity: 0.3,
  /// );
  /// final result = await client.upscaleImageCreativeAndWaitForResult(
  ///   request: request,
  ///   returnJson: false,
  /// );
  /// if (result is UpscaleResultBytes) {
  ///   await File('upscaled.png').writeAsBytes(result.bytes);
  /// }
  /// ```
  ///
  /// Note: This endpoint has a flat rate of 25 credits per generation.
  Future<UpscaleResult> upscaleImageCreativeAndWaitForResult({
    required UpscaleRequest request,
    bool returnJson = false,
    Duration pollInterval = const Duration(seconds: 10),
  }) async {
    final response = await upscaleImageCreative(request: request);

    while (true) {
      final result = await getCreativeUpscaleResult(
        id: response.id,
        returnJson: returnJson,
      );

      if (result is UpscaleInProgressResponse) {
        await Future.delayed(pollInterval);
        continue;
      }

      return result as UpscaleResult;
    }
  }

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
