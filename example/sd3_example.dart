import 'dart:io';
import 'dart:convert';
import 'package:stability_ai_dart/stability_ai_dart.dart';

// This example demonstrates Stable Diffusion 3.0 and 3.5 capabilities
void main() async {
  final client = StabilityAiFactory.create(
    apiKey: 'your-api-key-here',
  );

  try {
    // Generate image with SD 3.5 Large
    print('🎨 Generating image with SD 3.5 Large...');
    final largeRequest = SD3ImageRequest(
      prompt: 'A futuristic cityscape at night with flying cars',
      model: SD3Model.sd35Large,
      aspectRatio: AspectRatio.ratio16x9,
      cfgScale: 7.0,
      outputFormat: OutputFormat.png,
    );

    final largeResult = await client.generateSD3Image(
      request: largeRequest,
      returnJson: false,
    );

    if (largeResult is SD3ImageBytes) {
      await File('sd35_large_output.png').writeAsBytes(largeResult.bytes);
      print('✅ SD 3.5 Large image saved as sd35_large_output.png');
    }

    // Generate image with SD 3.5 Turbo for faster results
    print('\n⚡ Generating image with SD 3.5 Turbo...');
    final turboRequest = SD3ImageRequest(
      prompt: 'A magical forest with glowing mushrooms',
      model: SD3Model.sd35LargeTurbo,
      aspectRatio: AspectRatio.ratio1x1,
      cfgScale: 7.0,
      outputFormat: OutputFormat.png,
    );

    final turboResult = await client.generateSD3Image(
      request: turboRequest,
      returnJson: false,
    );

    if (turboResult is SD3ImageBytes) {
      await File('sd35_turbo_output.png').writeAsBytes(turboResult.bytes);
      print('✅ SD 3.5 Turbo image saved as sd35_turbo_output.png');
    }

    // Generate image with SD 3.5 Medium for balanced performance
    print('\n🎯 Generating image with SD 3.5 Medium...');
    final mediumRequest = SD3ImageRequest(
      prompt: 'An underwater scene with bioluminescent creatures',
      model: SD3Model.sd35Medium,
      aspectRatio: AspectRatio.ratio3x2,
      cfgScale: 7.0,
      seed: 42, // Optional: for reproducible results
      outputFormat: OutputFormat.png,
    );

    final mediumResult = await client.generateSD3Image(
      request: mediumRequest,
      returnJson: true, // Get JSON response for metadata
    );

    if (mediumResult is SD3ImageResponse) {
      final imageBytes = base64Decode(mediumResult.image);
      await File('sd35_medium_output.png').writeAsBytes(imageBytes);
      print('✅ SD 3.5 Medium image saved as sd35_medium_output.png');
      print('Finish reason: ${mediumResult.finishReason}');
      print('Seed used: ${mediumResult.seed}');
    }

    // Print credit costs for reference
    print('\n💰 SD3 Model Credit Costs:');
    print('- SD 3.5 Large: 6.5 credits');
    print('- SD 3.5 Large Turbo: 4 credits');
    print('- SD 3.5 Medium: 3.5 credits');
    print('- SD 3.0 Large: 6.5 credits');
    print('- SD 3.0 Large Turbo: 4 credits');
    print('- SD 3.0 Medium: 3.5 credits');
  } on StabilityAiException catch (e) {
    print('❌ API error: ${e.statusCode} - ${e.message}');
    if (e.id != null) print('Error ID: ${e.id}');
    if (e.name != null) print('Error name: ${e.name}');
  } finally {
    // Clean up
    client.close();
  }
}
