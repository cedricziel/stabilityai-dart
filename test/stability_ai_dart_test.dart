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

        expect(response, expectedBytes);
      });

      test('returns base64 when returnJson is true', () async {
        final expectedBase64 = base64.encode([1, 2, 3]);

        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({'base64': expectedBase64}))),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final request = UltraImageRequest(prompt: 'test prompt');
        final response = await client.generateUltraImage(
          request: request,
          returnJson: true,
        );

        expect(response, expectedBase64);
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

      test('throws exception on error response', () async {
        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'message': 'Invalid request',
            }))),
            400,
          );
        });

        final request = UltraImageRequest(prompt: 'test prompt');

        expect(
          () => client.generateUltraImage(request: request),
          throwsA(isA<StabilityAiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', 'Invalid request')),
        );
      });
    });
  });
}
