# Stability AI Dart

A Dart library for interacting with the Stability AI REST API.

## Features

- Text-to-Image Generation
  - Generate images from text prompts
  - Control image dimensions, samples, and steps
  - Adjust configuration scale and seed
- Ultra Image Generation
  - Higher quality image generation
  - Support for aspect ratio control
  - Optional image input for variations
  - Multiple output formats (JPEG, PNG, WebP)
- Background Removal
  - Remove backgrounds from images
  - Support for multiple output formats
- Engine Management
  - List available engines
  - Engine details including type and status
- Full Type Safety
  - JSON serialization/deserialization
  - Proper error handling with detailed messages
  - Input validation

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  stability_ai_dart: ^0.1.0
```

## Usage

### Initialize the client

```dart
import 'package:stability_ai_dart/stability_ai_dart.dart';

final client = StabilityAiClient(
  apiKey: 'your-api-key-here',
);
```

### List available engines

```dart
final engines = await client.listEngines();
for (final engine in engines) {
  print('${engine.id}: ${engine.name}');
  print('Description: ${engine.description}');
  print('Type: ${engine.type}');
  print('Status: ${engine.ready ? 'Ready' : 'Not Ready'}');
}
```

### Generate images from text

```dart
final request = TextToImageRequest(
  textPrompts: [
    TextPrompt(text: 'A beautiful sunset over the ocean'),
    TextPrompt(text: 'vibrant colors', weight: 0.5),
  ],
  height: 512,
  width: 512,
  numberOfSamples: 1,
  numberOfSteps: 50,
  cfgScale: 7.0,
  seed: 42, // optional: for reproducible results
);

final response = await client.generateImage(
  engineId: 'stable-diffusion-v1-5',
  request: request,
);

// The response contains a list of generated images as base64-encoded strings
for (final artifact in response.artifacts) {
  print('Generated image: ${artifact.base64}');
  print('Seed used: ${artifact.seed}');
  print('MIME type: ${artifact.mimeType}');
}
```

### Generate Ultra Images

```dart
final request = UltraImageRequest(
  prompt: 'A majestic mountain landscape',
  negativePrompt: 'blur, haze, people', // optional: what not to include
  aspectRatio: AspectRatio.ratio16x9,
  outputFormat: OutputFormat.png,
  seed: 123, // optional: for reproducible results
);

// Get raw bytes
final result = await client.generateUltraImage(
  request: request,
  returnJson: false,
);

if (result is UltraImageBytes) {
  // Use the raw bytes
  final bytes = result.bytes;
}

// Or get JSON response with base64 and metadata
final jsonResult = await client.generateUltraImage(
  request: request,
  returnJson: true,
);

if (jsonResult is UltraImageResponse) {
  print('Generated image: ${jsonResult.image}');
  print('Finish reason: ${jsonResult.finishReason}');
  print('Seed used: ${jsonResult.seed}');
}
```

### Generate Image Variations

```dart
final request = UltraImageRequest(
  prompt: 'Similar to this, but more vibrant',
  image: imageBytes, // Uint8List of the source image
  strength: 0.7, // How much to vary from the source (0.0 to 1.0)
  outputFormat: OutputFormat.png,
);

final result = await client.generateUltraImage(
  request: request,
  returnJson: false,
);
```

### Remove Image Backgrounds

```dart
final request = RemoveBackgroundRequest(
  image: imageBytes, // Uint8List of the source image
  outputFormat: OutputFormat.png,
);

// Get raw bytes
final result = await client.removeBackground(
  request: request,
  returnJson: false,
);

if (result is UltraImageBytes) {
  // Use the raw bytes
  final bytes = result.bytes;
}

// Or get JSON response with base64 and metadata
final jsonResult = await client.removeBackground(
  request: request,
  returnJson: true,
);

if (jsonResult is RemoveBackgroundResponse) {
  print('Processed image: ${jsonResult.image}');
  print('Finish reason: ${jsonResult.finishReason}');
}
```

### Error Handling

The library throws `StabilityAiException` when the API returns an error:

```dart
try {
  final response = await client.generateImage(
    engineId: 'invalid-engine',
    request: request,
  );
} on StabilityAiException catch (e) {
  print('API error: ${e.statusCode} - ${e.message}');
  if (e.id != null) print('Error ID: ${e.id}');
  if (e.name != null) print('Error name: ${e.name}');
}
```

### Available Aspect Ratios

The Ultra Image API supports the following aspect ratios:
- 16:9 (`AspectRatio.ratio16x9`)
- 1:1 (`AspectRatio.ratio1x1`)
- 21:9 (`AspectRatio.ratio21x9`)
- 2:3 (`AspectRatio.ratio2x3`)
- 3:2 (`AspectRatio.ratio3x2`)
- 4:5 (`AspectRatio.ratio4x5`)
- 5:4 (`AspectRatio.ratio5x4`)
- 9:16 (`AspectRatio.ratio9x16`)
- 9:21 (`AspectRatio.ratio9x21`)

### Output Formats

The following output formats are supported:
- JPEG (`OutputFormat.jpeg`)
- PNG (`OutputFormat.png`)
- WebP (`OutputFormat.webp`)

### Cleanup

Don't forget to close the client when you're done:

```dart
client.close();
```

## License

MIT License - see the [LICENSE](LICENSE) file for details.
