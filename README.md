# Stability AI Dart

A Dart library for interacting with the Stability AI REST API.

## Features

- List available engines
- Generate images from text prompts
- Full type safety with JSON serialization
- Proper error handling

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
}
```

### Generate images from text

```dart
final request = TextToImageRequest(
  textPrompts: [
    TextPrompt(text: 'A beautiful sunset over the ocean'),
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

// The response contains a list of generated images as base64-encoded strings
for (final artifact in response.artifacts) {
  print('Generated image: ${artifact.base64}');
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
}
```

### Cleanup

Don't forget to close the client when you're done:

```dart
client.close();
```

## License

MIT License - see the [LICENSE](LICENSE) file for details.
