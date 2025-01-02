import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:stability_ai_dart/stability_ai_dart.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([MockSpec<http.Client>()])
import 'stability_ai_dart_test.mocks.dart';

void main() {
  group('StabilityAiClient', () {
    late MockClient mockClient;
    late StabilityAiClient client;

    setUp(() {
      mockClient = MockClient();
      client = StabilityAiClient(
        apiKey: 'test-api-key',
        httpClient: mockClient,
      );
    });

    test('listEngines returns list of engines', () async {
      when(mockClient.get(
        Uri.parse('https://api.stability.ai/v1/engines/list'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode([
              {
                'id': 'test-engine',
                'name': 'Test Engine',
                'description': 'A test engine',
                'type': 'test',
                'ready': true,
              }
            ]),
            200,
          ));

      final engines = await client.listEngines();
      expect(engines.length, 1);
      expect(engines.first.id, 'test-engine');
    });

    test('generateImage returns generation response', () async {
      when(mockClient.post(
        Uri.parse(
            'https://api.stability.ai/v1/generation/test-engine/text-to-image'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'artifacts': [
                {
                  'base64': 'test-base64',
                  'seed': 123,
                  'mime_type': 'image/png',
                }
              ],
            }),
            200,
          ));

      final request = TextToImageRequest(
        textPrompts: [TextPrompt(text: 'test prompt')],
      );

      final response = await client.generateImage(
        engineId: 'test-engine',
        request: request,
      );

      expect(response.artifacts.length, 1);
      expect(response.artifacts.first.base64, 'test-base64');
    });

    group('generateUltraImage', () {
      test('returns binary data when returnJson is false', () async {
        final expectedBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(expectedBytes),
            200,
            headers: {'content-type': 'image/png'},
          );
        });

        final request = UltraImageRequest(prompt: 'test prompt');
        final response = await client.generateUltraImage(request: request);

        expect(response, isA<UltraImageBytes>());
        expect((response as UltraImageBytes).bytes, expectedBytes);
      });

      test('returns UltraImageResponse when returnJson is true', () async {
        final expectedBase64 = base64.encode([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': expectedBase64,
              'finish_reason': 'SUCCESS',
              'seed': 123,
            }))),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final request = UltraImageRequest(prompt: 'test prompt');
        final response = await client.generateUltraImage(
          request: request,
          returnJson: true,
        );

        expect(response, isA<UltraImageResponse>());
        final jsonResponse = response as UltraImageResponse;
        expect(jsonResponse.image, expectedBase64);
        expect(jsonResponse.finishReason, FinishReason.success);
        expect(jsonResponse.seed, 123);
      });

      test('includes all optional parameters in request', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final request = UltraImageRequest(
          prompt: 'test prompt',
          negativePrompt: 'test negative',
          aspectRatio: AspectRatio.ratio16x9,
          seed: 123,
          outputFormat: OutputFormat.png,
          image: imageBytes,
          strength: 0.5,
        );

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value([]),
            200,
          );
        });

        await client.generateUltraImage(request: request);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.fields['prompt'], 'test prompt');
        expect(captured.fields['negative_prompt'], 'test negative');
        expect(captured.fields['aspect_ratio'], 'ratio16x9');
        expect(captured.fields['seed'], '123');
        expect(captured.fields['output_format'], 'png');
        expect(captured.fields['strength'], '0.5');
        expect(captured.files.length, 1);
        expect(captured.files.first.field, 'image');
      });

      test('throws exception with error details on error response', () async {
        when(mockClient.send(any)).thenAnswer((_) async {
          final response = http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': 'error-id',
              'name': 'bad_request',
              'errors': ['Invalid prompt', 'Invalid size'],
            }))),
            400,
            headers: {'content-type': 'application/json'},
          );
          return response;
        });

        final request = UltraImageRequest(prompt: 'test prompt');

        expect(
          () => client.generateUltraImage(request: request),
          throwsA(
            allOf(
              isA<StabilityAiException>(),
              predicate((StabilityAiException e) =>
                  e.statusCode == 400 &&
                  e.message == 'Invalid prompt, Invalid size' &&
                  e.id == 'error-id' &&
                  e.name == 'bad_request'),
            ),
          ),
        );
      });
    });

    group('removeBackground', () {
      test('returns binary data when returnJson is false', () async {
        final expectedBytes = Uint8List.fromList([1, 2, 3]);
        final imageBytes = Uint8List.fromList([4, 5, 6]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(expectedBytes),
            200,
            headers: {'content-type': 'image/png'},
          );
        });

        final request = RemoveBackgroundRequest(image: imageBytes);
        final response = await client.removeBackground(request: request);

        expect(response, isA<UltraImageBytes>());
        expect((response as UltraImageBytes).bytes, expectedBytes);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.files.length, 1);
        expect(captured.files.first.field, 'image');
      });

      test('returns RemoveBackgroundResponse when returnJson is true',
          () async {
        final expectedBase64 = base64.encode([1, 2, 3]);
        final imageBytes = Uint8List.fromList([4, 5, 6]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': expectedBase64,
              'finish_reason': 'SUCCESS',
              'seed': 123,
            }))),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final request = RemoveBackgroundRequest(
          image: imageBytes,
          outputFormat: OutputFormat.png,
        );
        final response = await client.removeBackground(
          request: request,
          returnJson: true,
        );

        expect(response, isA<RemoveBackgroundResponse>());
        final jsonResponse = response as RemoveBackgroundResponse;
        expect(jsonResponse.image, expectedBase64);
        expect(jsonResponse.finishReason, FinishReason.success);
        expect(jsonResponse.seed, 123);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.fields['output_format'], 'png');
      });

      test('throws exception with error details on error response', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          final response = http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': 'error-id',
              'name': 'bad_request',
              'errors': ['Invalid image format', 'Image too large'],
            }))),
            400,
            headers: {'content-type': 'application/json'},
          );
          return response;
        });

        final request = RemoveBackgroundRequest(image: imageBytes);

        expect(
          () => client.removeBackground(request: request),
          throwsA(
            allOf(
              isA<StabilityAiException>(),
              predicate((StabilityAiException e) =>
                  e.statusCode == 400 &&
                  e.message == 'Invalid image format, Image too large' &&
                  e.id == 'error-id' &&
                  e.name == 'bad_request'),
            ),
          ),
        );
      });
    });

    group('upscaleImage', () {
      test('returns upscale response with generation ID', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final expectedId = 'test-generation-id';

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': expectedId,
            }))),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
        );
        final response = await client.upscaleImage(request: request);

        expect(response, isA<UpscaleResponse>());
        expect(response.id, expectedId);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.files.length, 1);
        expect(captured.files.first.field, 'image');
        expect(captured.fields['prompt'], 'test prompt');
      });

      test('includes all optional parameters in request', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
          negativePrompt: 'test negative',
          outputFormat: OutputFormat.png,
          seed: 123,
          creativity: 0.3,
        );

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': 'test-id',
            }))),
            200,
          );
        });

        await client.upscaleImage(request: request);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.fields['prompt'], 'test prompt');
        expect(captured.fields['negative_prompt'], 'test negative');
        expect(captured.fields['output_format'], 'png');
        expect(captured.fields['seed'], '123');
        expect(captured.fields['creativity'], '0.3');
        expect(captured.files.length, 1);
        expect(captured.files.first.field, 'image');
      });

      test('throws exception with error details on error response', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          final response = http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': 'error-id',
              'name': 'bad_request',
              'errors': ['Invalid image size', 'Invalid prompt'],
            }))),
            400,
            headers: {'content-type': 'application/json'},
          );
          return response;
        });

        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
        );

        expect(
          () => client.upscaleImage(request: request),
          throwsA(
            allOf(
              isA<StabilityAiException>(),
              predicate((StabilityAiException e) =>
                  e.statusCode == 400 &&
                  e.message == 'Invalid image size, Invalid prompt' &&
                  e.id == 'error-id' &&
                  e.name == 'bad_request'),
            ),
          ),
        );
      });
    });

    group('getUpscaleResult', () {
      test('returns in-progress response when status is 202', () async {
        final expectedId = 'test-generation-id';

        when(mockClient.get(
          Uri.parse(
              'https://api.stability.ai/v2alpha/generation/stable-image/upscale/result/$expectedId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'id': expectedId,
                'status': 'in-progress',
              }),
              202,
            ));

        final result = await client.getUpscaleResult(id: expectedId);

        expect(result, isA<UpscaleInProgressResponse>());
        final response = result as UpscaleInProgressResponse;
        expect(response.id, expectedId);
        expect(response.status, 'in-progress');
      });

      test('returns raw bytes when returnJson is false', () async {
        final expectedId = 'test-generation-id';
        final expectedBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.get(
          Uri.parse(
              'https://api.stability.ai/v2alpha/generation/stable-image/upscale/result/$expectedId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response.bytes(
              expectedBytes,
              200,
              headers: {'content-type': 'image/png'},
            ));

        final result = await client.getUpscaleResult(id: expectedId);

        expect(result, isA<UpscaleResultBytes>());
        final response = result as UpscaleResultBytes;
        expect(response.bytes, expectedBytes);
      });

      test('returns JSON response when returnJson is true', () async {
        final expectedId = 'test-generation-id';
        final expectedBase64 = base64.encode([1, 2, 3]);

        when(mockClient.get(
          Uri.parse(
              'https://api.stability.ai/v2alpha/generation/stable-image/upscale/result/$expectedId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'image': expectedBase64,
                'finish_reason': 'SUCCESS',
                'seed': 123,
              }),
              200,
            ));

        final result = await client.getUpscaleResult(
          id: expectedId,
          returnJson: true,
        );

        expect(result, isA<UpscaleResultResponse>());
        final response = result as UpscaleResultResponse;
        expect(response.image, expectedBase64);
        expect(response.finishReason, FinishReason.success);
        expect(response.seed, 123);
      });

      test('throws exception with error details on error response', () async {
        final expectedId = 'test-generation-id';

        when(mockClient.get(
          Uri.parse(
              'https://api.stability.ai/v2alpha/generation/stable-image/upscale/result/$expectedId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'id': 'error-id',
                'name': 'generation_not_found',
                'errors': ['Generation not found or expired'],
              }),
              404,
            ));

        expect(
          () => client.getUpscaleResult(id: expectedId),
          throwsA(
            allOf(
              isA<StabilityAiException>(),
              predicate((StabilityAiException e) =>
                  e.statusCode == 404 &&
                  e.message == 'Generation not found or expired' &&
                  e.id == 'error-id' &&
                  e.name == 'generation_not_found'),
            ),
          ),
        );
      });
    });

    group('upscaleImageConservative', () {
      test('returns binary data when returnJson is false', () async {
        final expectedBytes = Uint8List.fromList([1, 2, 3]);
        final imageBytes = Uint8List.fromList([4, 5, 6]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(expectedBytes),
            200,
            headers: {'content-type': 'image/png'},
          );
        });

        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
        );
        final response =
            await client.upscaleImageConservative(request: request);

        expect(response, isA<UltraImageBytes>());
        expect((response as UltraImageBytes).bytes, expectedBytes);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.files.length, 1);
        expect(captured.files.first.field, 'image');
        expect(captured.fields['prompt'], 'test prompt');
      });

      test('returns UltraImageResponse when returnJson is true', () async {
        final expectedBase64 = base64.encode([1, 2, 3]);
        final imageBytes = Uint8List.fromList([4, 5, 6]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': expectedBase64,
              'finish_reason': 'SUCCESS',
              'seed': 123,
            }))),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
        );
        final response = await client.upscaleImageConservative(
          request: request,
          returnJson: true,
        );

        expect(response, isA<UltraImageResponse>());
        final jsonResponse = response as UltraImageResponse;
        expect(jsonResponse.image, expectedBase64);
        expect(jsonResponse.finishReason, FinishReason.success);
        expect(jsonResponse.seed, 123);
      });

      test('includes all optional parameters in request', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
          negativePrompt: 'test negative',
          outputFormat: OutputFormat.png,
          seed: 123,
          creativity: 0.3,
        );

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': 'test-base64',
              'finish_reason': 'SUCCESS',
            }))),
            200,
          );
        });

        await client.upscaleImageConservative(request: request);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.fields['prompt'], 'test prompt');
        expect(captured.fields['negative_prompt'], 'test negative');
        expect(captured.fields['output_format'], 'png');
        expect(captured.fields['seed'], '123');
        expect(captured.fields['creativity'], '0.3');
        expect(captured.files.length, 1);
        expect(captured.files.first.field, 'image');
      });

      test('throws exception with error details on error response', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          final response = http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': 'error-id',
              'name': 'bad_request',
              'errors': ['Invalid image size', 'Invalid prompt'],
            }))),
            400,
            headers: {'content-type': 'application/json'},
          );
          return response;
        });

        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
        );

        expect(
          () => client.upscaleImageConservative(request: request),
          throwsA(
            allOf(
              isA<StabilityAiException>(),
              predicate((StabilityAiException e) =>
                  e.statusCode == 400 &&
                  e.message == 'Invalid image size, Invalid prompt' &&
                  e.id == 'error-id' &&
                  e.name == 'bad_request'),
            ),
          ),
        );
      });

      test('uses correct endpoint URL', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
        );

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': 'test-base64',
              'finish_reason': 'SUCCESS',
            }))),
            200,
          );
        });

        await client.upscaleImageConservative(request: request);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(
          captured.url.toString(),
          'https://api.stability.ai/v2beta/stable-image/upscale/conservative',
        );
      });
    });

    group('upscaleImageCreative', () {
      test('returns upscale response with generation ID', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final expectedId = 'test-generation-id';

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': expectedId,
            }))),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
        );
        final response = await client.upscaleImageCreative(request: request);

        expect(response, isA<UpscaleResponse>());
        expect(response.id, expectedId);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.files.length, 1);
        expect(captured.files.first.field, 'image');
        expect(captured.fields['prompt'], 'test prompt');
      });

      test('includes all optional parameters in request', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
          negativePrompt: 'test negative',
          outputFormat: OutputFormat.png,
          seed: 123,
          creativity: 0.3,
        );

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': 'test-id',
            }))),
            200,
          );
        });

        await client.upscaleImageCreative(request: request);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.fields['prompt'], 'test prompt');
        expect(captured.fields['negative_prompt'], 'test negative');
        expect(captured.fields['output_format'], 'png');
        expect(captured.fields['seed'], '123');
        expect(captured.fields['creativity'], '0.3');
        expect(captured.files.length, 1);
        expect(captured.files.first.field, 'image');
      });

      test('throws exception with error details on error response', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          final response = http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': 'error-id',
              'name': 'bad_request',
              'errors': ['Invalid image size', 'Invalid prompt'],
            }))),
            400,
            headers: {'content-type': 'application/json'},
          );
          return response;
        });

        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
        );

        expect(
          () => client.upscaleImageCreative(request: request),
          throwsA(
            allOf(
              isA<StabilityAiException>(),
              predicate((StabilityAiException e) =>
                  e.statusCode == 400 &&
                  e.message == 'Invalid image size, Invalid prompt' &&
                  e.id == 'error-id' &&
                  e.name == 'bad_request'),
            ),
          ),
        );
      });

      test('uses correct endpoint URL', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
        );

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': 'test-id',
            }))),
            200,
          );
        });

        await client.upscaleImageCreative(request: request);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(
          captured.url.toString(),
          'https://api.stability.ai/v2beta/stable-image/upscale/creative',
        );
      });
    });

    group('upscaleImageCreativeAndWaitForResult', () {
      test('polls until result is ready', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final expectedId = 'test-generation-id';
        final expectedBase64 = base64.encode([4, 5, 6]);

        // Mock the initial upscale request
        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': expectedId,
            }))),
            200,
          );
        });

        // Mock the result polling - first in progress, then complete
        var pollCount = 0;
        when(mockClient.get(
          Uri.parse(
              'https://api.stability.ai/v2beta/stable-image/upscale/creative/result/$expectedId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async {
          pollCount++;
          if (pollCount == 1) {
            return http.Response(
              jsonEncode({
                'id': expectedId,
                'status': 'in-progress',
              }),
              202,
            );
          }
          return http.Response(
            jsonEncode({
              'image': expectedBase64,
              'finish_reason': 'SUCCESS',
              'seed': 123,
            }),
            200,
          );
        });

        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
        );
        final result = await client.upscaleImageCreativeAndWaitForResult(
          request: request,
          returnJson: true,
          pollInterval: Duration(milliseconds: 1), // Speed up test
        );

        expect(result, isA<UpscaleResultResponse>());
        final response = result as UpscaleResultResponse;
        expect(response.image, expectedBase64);
        expect(response.finishReason, FinishReason.success);
        expect(response.seed, 123);
        expect(pollCount, 2); // Verify we polled twice
      });

      test('returns raw bytes when returnJson is false', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final expectedId = 'test-generation-id';
        final expectedResultBytes = Uint8List.fromList([4, 5, 6]);

        // Mock the initial upscale request
        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': expectedId,
            }))),
            200,
          );
        });

        // Mock the result polling - return bytes immediately
        when(mockClient.get(
          Uri.parse(
              'https://api.stability.ai/v2beta/stable-image/upscale/creative/result/$expectedId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response.bytes(
              expectedResultBytes,
              200,
              headers: {'content-type': 'image/png'},
            ));

        final request = UpscaleRequest(
          image: imageBytes,
          prompt: 'test prompt',
        );
        final result = await client.upscaleImageCreativeAndWaitForResult(
          request: request,
          returnJson: false,
        );

        expect(result, isA<UpscaleResultBytes>());
        final response = result as UpscaleResultBytes;
        expect(response.bytes, expectedResultBytes);
      });
    });

    group('getCreativeUpscaleResult', () {
      test('returns in-progress response when status is 202', () async {
        final expectedId = 'test-generation-id';

        when(mockClient.get(
          Uri.parse(
              'https://api.stability.ai/v2beta/stable-image/upscale/creative/result/$expectedId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'id': expectedId,
                'status': 'in-progress',
              }),
              202,
            ));

        final result = await client.getCreativeUpscaleResult(id: expectedId);

        expect(result, isA<UpscaleInProgressResponse>());
        final response = result as UpscaleInProgressResponse;
        expect(response.id, expectedId);
        expect(response.status, 'in-progress');
      });

      test('returns raw bytes when returnJson is false', () async {
        final expectedId = 'test-generation-id';
        final expectedBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.get(
          Uri.parse(
              'https://api.stability.ai/v2beta/stable-image/upscale/creative/result/$expectedId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response.bytes(
              expectedBytes,
              200,
              headers: {'content-type': 'image/png'},
            ));

        final result = await client.getCreativeUpscaleResult(id: expectedId);

        expect(result, isA<UpscaleResultBytes>());
        final response = result as UpscaleResultBytes;
        expect(response.bytes, expectedBytes);
      });

      test('returns JSON response when returnJson is true', () async {
        final expectedId = 'test-generation-id';
        final expectedBase64 = base64.encode([1, 2, 3]);

        when(mockClient.get(
          Uri.parse(
              'https://api.stability.ai/v2beta/stable-image/upscale/creative/result/$expectedId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'image': expectedBase64,
                'finish_reason': 'SUCCESS',
                'seed': 123,
              }),
              200,
            ));

        final result = await client.getCreativeUpscaleResult(
          id: expectedId,
          returnJson: true,
        );

        expect(result, isA<UpscaleResultResponse>());
        final response = result as UpscaleResultResponse;
        expect(response.image, expectedBase64);
        expect(response.finishReason, FinishReason.success);
        expect(response.seed, 123);
      });

      test('throws exception with error details on error response', () async {
        final expectedId = 'test-generation-id';

        when(mockClient.get(
          Uri.parse(
              'https://api.stability.ai/v2beta/stable-image/upscale/creative/result/$expectedId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'id': 'error-id',
                'name': 'generation_not_found',
                'errors': ['Generation not found or expired'],
              }),
              404,
            ));

        expect(
          () => client.getCreativeUpscaleResult(id: expectedId),
          throwsA(
            allOf(
              isA<StabilityAiException>(),
              predicate((StabilityAiException e) =>
                  e.statusCode == 404 &&
                  e.message == 'Generation not found or expired' &&
                  e.id == 'error-id' &&
                  e.name == 'generation_not_found'),
            ),
          ),
        );
      });
    });

    group('generateCoreImage', () {
      test('returns binary data when returnJson is false', () async {
        final expectedBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(expectedBytes),
            200,
            headers: {'content-type': 'image/png'},
          );
        });

        final request = CoreImageRequest(prompt: 'test prompt');
        final response = await client.generateCoreImage(request: request);

        expect(response, isA<CoreImageBytes>());
        expect((response as CoreImageBytes).bytes, expectedBytes);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.fields['prompt'], 'test prompt');
      });

      test('returns CoreImageResponse when returnJson is true', () async {
        final expectedBase64 = base64.encode([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': expectedBase64,
              'finish_reason': 'SUCCESS',
              'seed': 123,
            }))),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final request = CoreImageRequest(prompt: 'test prompt');
        final response = await client.generateCoreImage(
          request: request,
          returnJson: true,
        );

        expect(response, isA<CoreImageResponse>());
        final jsonResponse = response as CoreImageResponse;
        expect(jsonResponse.image, expectedBase64);
        expect(jsonResponse.finishReason, FinishReason.success);
        expect(jsonResponse.seed, 123);
      });

      test('includes all optional parameters in request', () async {
        final request = CoreImageRequest(
          prompt: 'test prompt',
          negativePrompt: 'test negative',
          aspectRatio: AspectRatio.ratio16x9,
          seed: 123,
          outputFormat: OutputFormat.png,
          stylePreset: StylePreset.photographic,
        );

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': 'test-base64',
              'finish_reason': 'SUCCESS',
            }))),
            200,
          );
        });

        await client.generateCoreImage(request: request);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.fields['prompt'], 'test prompt');
        expect(captured.fields['negative_prompt'], 'test negative');
        expect(captured.fields['aspect_ratio'], 'ratio16x9');
        expect(captured.fields['seed'], '123');
        expect(captured.fields['output_format'], 'png');
        expect(captured.fields['style_preset'], 'photographic');
      });

      test('throws exception with error details on error response', () async {
        when(mockClient.send(any)).thenAnswer((_) async {
          final response = http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': 'error-id',
              'name': 'bad_request',
              'errors': ['Invalid prompt', 'Invalid style preset'],
            }))),
            400,
            headers: {'content-type': 'application/json'},
          );
          return response;
        });

        final request = CoreImageRequest(prompt: 'test prompt');

        expect(
          () => client.generateCoreImage(request: request),
          throwsA(
            allOf(
              isA<StabilityAiException>(),
              predicate((StabilityAiException e) =>
                  e.statusCode == 400 &&
                  e.message == 'Invalid prompt, Invalid style preset' &&
                  e.id == 'error-id' &&
                  e.name == 'bad_request'),
            ),
          ),
        );
      });

      test('uses correct endpoint URL', () async {
        final request = CoreImageRequest(prompt: 'test prompt');

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': 'test-base64',
              'finish_reason': 'SUCCESS',
            }))),
            200,
          );
        });

        await client.generateCoreImage(request: request);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(
          captured.url.toString(),
          'https://api.stability.ai/v2beta/stable-image/generate/core',
        );
      });
    });

    group('upscaleImageFast', () {
      test('returns binary data when returnJson is false', () async {
        final expectedBytes = Uint8List.fromList([1, 2, 3]);
        final imageBytes = Uint8List.fromList([4, 5, 6]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(expectedBytes),
            200,
            headers: {'content-type': 'image/png'},
          );
        });

        final request = FastUpscaleRequest(
          image: imageBytes,
        );
        final response = await client.upscaleImageFast(request: request);

        expect(response, isA<FastUpscaleBytes>());
        expect((response as FastUpscaleBytes).bytes, expectedBytes);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.files.length, 1);
        expect(captured.files.first.field, 'image');
      });

      test('returns FastUpscaleResponse when returnJson is true', () async {
        final expectedBase64 = base64.encode([1, 2, 3]);
        final imageBytes = Uint8List.fromList([4, 5, 6]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': expectedBase64,
              'finish_reason': 'SUCCESS',
              'seed': 123,
            }))),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final request = FastUpscaleRequest(
          image: imageBytes,
          outputFormat: OutputFormat.png,
        );
        final response = await client.upscaleImageFast(
          request: request,
          returnJson: true,
        );

        expect(response, isA<FastUpscaleResponse>());
        final jsonResponse = response as FastUpscaleResponse;
        expect(jsonResponse.image, expectedBase64);
        expect(jsonResponse.finishReason, FinishReason.success);
        expect(jsonResponse.seed, 123);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.fields['output_format'], 'png');
      });

      test('throws exception with error details on error response', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          final response = http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': 'error-id',
              'name': 'bad_request',
              'errors': ['Invalid image size', 'Image too large'],
            }))),
            400,
            headers: {'content-type': 'application/json'},
          );
          return response;
        });

        final request = FastUpscaleRequest(image: imageBytes);

        expect(
          () => client.upscaleImageFast(request: request),
          throwsA(
            allOf(
              isA<StabilityAiException>(),
              predicate((StabilityAiException e) =>
                  e.statusCode == 400 &&
                  e.message == 'Invalid image size, Image too large' &&
                  e.id == 'error-id' &&
                  e.name == 'bad_request'),
            ),
          ),
        );
      });

      test('uses correct endpoint URL', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final request = FastUpscaleRequest(image: imageBytes);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': 'test-base64',
              'finish_reason': 'SUCCESS',
            }))),
            200,
          );
        });

        await client.upscaleImageFast(request: request);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(
          captured.url.toString(),
          'https://api.stability.ai/v2beta/stable-image/upscale/fast',
        );
      });
    });

    group('generateSD3Image', () {
      test('returns binary data when returnJson is false', () async {
        final expectedBytes = Uint8List.fromList([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(expectedBytes),
            200,
            headers: {'content-type': 'image/png'},
          );
        });

        final request = SD3ImageRequest(prompt: 'test prompt');
        final response = await client.generateSD3Image(request: request);

        expect(response, isA<SD3ImageBytes>());
        expect((response as SD3ImageBytes).bytes, expectedBytes);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.fields['prompt'], 'test prompt');
      });

      test('returns SD3ImageResponse when returnJson is true', () async {
        final expectedBase64 = base64.encode([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': expectedBase64,
              'finish_reason': 'SUCCESS',
              'seed': 123,
            }))),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final request = SD3ImageRequest(prompt: 'test prompt');
        final response = await client.generateSD3Image(
          request: request,
          returnJson: true,
        );

        expect(response, isA<SD3ImageResponse>());
        final jsonResponse = response as SD3ImageResponse;
        expect(jsonResponse.image, expectedBase64);
        expect(jsonResponse.finishReason, FinishReason.success);
        expect(jsonResponse.seed, 123);
      });

      test('includes all optional parameters in request', () async {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        final request = SD3ImageRequest(
          prompt: 'test prompt',
          negativePrompt: 'test negative',
          mode: 'image-to-image',
          image: imageBytes,
          strength: 0.5,
          aspectRatio: AspectRatio.ratio16x9,
          model: SD3Model.sd35Large,
          seed: 123,
          outputFormat: OutputFormat.png,
          cfgScale: 7.5,
        );

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': 'test-base64',
              'finish_reason': 'SUCCESS',
            }))),
            200,
          );
        });

        await client.generateSD3Image(request: request);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(captured.fields['prompt'], 'test prompt');
        expect(captured.fields['negative_prompt'], 'test negative');
        expect(captured.fields['mode'], 'image-to-image');
        expect(captured.fields['strength'], '0.5');
        expect(captured.fields['aspect_ratio'], 'ratio16x9');
        expect(captured.fields['model'], 'sd3.5-large');
        expect(captured.fields['seed'], '123');
        expect(captured.fields['output_format'], 'png');
        expect(captured.fields['cfg_scale'], '7.5');
        expect(captured.files.length, 1);
        expect(captured.files.first.field, 'image');
      });

      test('throws exception with error details on error response', () async {
        when(mockClient.send(any)).thenAnswer((_) async {
          final response = http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'id': 'error-id',
              'name': 'bad_request',
              'errors': ['Invalid prompt', 'Invalid model'],
            }))),
            400,
            headers: {'content-type': 'application/json'},
          );
          return response;
        });

        final request = SD3ImageRequest(prompt: 'test prompt');

        expect(
          () => client.generateSD3Image(request: request),
          throwsA(
            allOf(
              isA<StabilityAiException>(),
              predicate((StabilityAiException e) =>
                  e.statusCode == 400 &&
                  e.message == 'Invalid prompt, Invalid model' &&
                  e.id == 'error-id' &&
                  e.name == 'bad_request'),
            ),
          ),
        );
      });

      test('uses correct endpoint URL', () async {
        final request = SD3ImageRequest(prompt: 'test prompt');

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'image': 'test-base64',
              'finish_reason': 'SUCCESS',
            }))),
            200,
          );
        });

        await client.generateSD3Image(request: request);

        final captured = verify(mockClient.send(captureAny)).captured.single
            as http.MultipartRequest;
        expect(
          captured.url.toString(),
          'https://api.stability.ai/v2beta/stable-image/generate/sd3',
        );
      });
    });
  });
}
