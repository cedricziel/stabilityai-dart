import 'dart:io';
import 'dart:convert';
import 'package:stability_ai_dart/stability_ai_dart.dart';

// This example demonstrates basic usage of the Stability AI Dart package
void main() async {
  // Initialize the client
  final client = StabilityAiFactory.create(
    apiKey: 'your-api-key-here',
  );

  try {
    // List available engines
    print('\n📋 Listing available engines:');
    final engines = await client.listEngines();
    for (final engine in engines) {
      print('${engine.id}: ${engine.name}');
      print('Description: ${engine.description}');
      print('Type: ${engine.type}');
      print('Status: ${engine.ready ? 'Ready' : 'Not Ready'}\n');
    }

    // Generate an image using text prompts
    print('🎨 Generating an image from text...');
    final request = TextToImageRequest(
      textPrompts: [
        TextPrompt(text: 'A serene mountain lake at sunset'),
        TextPrompt(text: 'vibrant colors', weight: 0.5),
      ],
      height: 512,
      width: 512,
      numberOfSamples: 1,
      numberOfSteps: 50,
      cfgScale: 7.0,
    );

    final response = await client.generateImage(
      engineId: 'stable-diffusion-v1-5',
      request: request,
    );

    // Save the generated image
    for (final artifact in response.artifacts) {
      final imageBytes = base64Decode(artifact.base64);
      await File('example_output.png').writeAsBytes(imageBytes);
      print('✅ Image generated and saved as example_output.png');
      print('Seed used: ${artifact.seed}');
    }

    // Generate an image using the Core API
    print('\n🖼️ Generating an image using Core API...');
    final coreRequest = CoreImageRequest(
      prompt: 'A lighthouse on a cliff overlooking the ocean',
      negativePrompt: 'blur, haze, fog',
      aspectRatio: AspectRatio.ratio16x9,
      outputFormat: OutputFormat.png,
      stylePreset: StylePreset.photographic,
    );

    final coreResult = await client.generateCoreImage(
      request: coreRequest,
      returnJson: false,
    );

    if (coreResult is CoreImageBytes) {
      await File('example_core_output.png').writeAsBytes(coreResult.bytes);
      print('✅ Core image generated and saved as example_core_output.png');
    }
  } on StabilityAiException catch (e) {
    print('❌ API error: ${e.statusCode} - ${e.message}');
    if (e.id != null) print('Error ID: ${e.id}');
    if (e.name != null) print('Error name: ${e.name}');
  } finally {
    // Clean up
    client.close();
  }
}
