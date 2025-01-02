import 'dart:io';
import 'package:stability_ai_dart/stability_ai_dart.dart';

// This example demonstrates image upscaling capabilities
void main() async {
  final client = StabilityAiFactory.create(
    apiKey: 'your-api-key-here',
  );

  try {
    // Read an image file for upscaling
    print('📄 Reading source image...');
    final imageBytes = await File('source_image.png').readAsBytes();

    // Standard upscaling
    print('\n🔍 Performing standard upscaling...');
    final request = UpscaleRequest(
      image: imageBytes,
      prompt: 'A high resolution photo',
      outputFormat: OutputFormat.png,
      creativity: 0.3,
    );

    final result = await client.upscaleImageAndWaitForResult(
      request: request,
      returnJson: false,
      pollInterval: Duration(seconds: 10),
    );

    if (result is UpscaleResultBytes) {
      await File('upscaled_standard.png').writeAsBytes(result.bytes);
      print('✅ Standard upscaled image saved as upscaled_standard.png');
    }

    // Creative upscaling
    print('\n🎨 Performing creative upscaling...');
    final creativeResult = await client.upscaleImageCreativeAndWaitForResult(
      request: request,
      returnJson: false,
      pollInterval: Duration(seconds: 10),
    );

    if (creativeResult is UpscaleResultBytes) {
      await File('upscaled_creative.png').writeAsBytes(creativeResult.bytes);
      print('✅ Creative upscaled image saved as upscaled_creative.png');
    }

    // Conservative upscaling
    print('\n🎯 Performing conservative upscaling...');
    final conservativeResult = await client.upscaleImageConservative(
      request: request,
      returnJson: false,
    );

    if (conservativeResult is UltraImageBytes) {
      await File('upscaled_conservative.png')
          .writeAsBytes(conservativeResult.bytes);
      print('✅ Conservative upscaled image saved as upscaled_conservative.png');
    }

    // Manual polling example
    print('\n⏳ Demonstrating manual polling...');
    final upscaleResponse = await client.upscaleImage(request: request);
    print('Generation ID: ${upscaleResponse.id}');

    while (true) {
      final pollResult = await client.getUpscaleResult(
        id: upscaleResponse.id,
        returnJson: false,
      );

      if (pollResult is UpscaleInProgressResponse) {
        print('Still processing... waiting 10 seconds');
        await Future.delayed(Duration(seconds: 10));
        continue;
      }

      if (pollResult is UpscaleResultBytes) {
        await File('upscaled_manual.png').writeAsBytes(pollResult.bytes);
        print('✅ Manual polling upscaled image saved as upscaled_manual.png');
        break;
      }
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
