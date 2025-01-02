# Stability AI Dart 🎨

A Dart library for interacting with the Stability AI REST API.

## Table of Contents 📑

- [Stability AI Dart 🎨](#stability-ai-dart-)
  - [Table of Contents 📑](#table-of-contents-)
  - [Features ✨](#features-)
  - [Installation 📦](#installation-)
  - [Usage 🚀](#usage-)
    - [Initialize the client 🔑](#initialize-the-client-)
    - [List available engines 🔍](#list-available-engines-)
    - [Generate images from text ✍️](#generate-images-from-text-️)
    - [Generate Core Images 🖼️](#generate-core-images-️)
    - [Available Style Presets 🎨](#available-style-presets-)
    - [Generate Ultra Images 🌟](#generate-ultra-images-)
    - [Generate Image Variations 🔄](#generate-image-variations-)
    - [Remove Image Backgrounds ✂️](#remove-image-backgrounds-️)
    - [Upscale Images 📐](#upscale-images-)
      - [Standard Upscaler](#standard-upscaler)
      - [Using the Convenience Method](#using-the-convenience-method)
      - [Creative Upscaler](#creative-upscaler)
      - [Conservative Upscaler](#conservative-upscaler)
      - [Manual Polling (Standard Upscaler)](#manual-polling-standard-upscaler)
    - [Error Handling ⚠️](#error-handling-️)
    - [Available Aspect Ratios 📏](#available-aspect-ratios-)
    - [Output Formats 💾](#output-formats-)
    - [Generate Images with SD3 🎯](#generate-images-with-sd3-)
    - [SD3 Models and Credit Costs 💰](#sd3-models-and-credit-costs-)
    - [Cleanup 🧹](#cleanup-)
  - [License 📄](#license-)

## Features ✨

- Text-to-Image Generation
  - Generate images from text prompts
  - Control image dimensions, samples, and steps
  - Adjust configuration scale and seed
- Core Image Generation
  - Primary text-to-image generation service
  - Multiple style presets (photographic, anime, digital art, etc.)
  - Support for aspect ratio control
  - Multiple output formats (JPEG, PNG, WebP)
- Ultra Image Generation
  - Higher quality image generation
  - Support for aspect ratio control
  - Optional image input for variations
  - Multiple output formats (JPEG, PNG, WebP)
- Background Removal
  - Remove backgrounds from images
  - Support for multiple output formats
- Image Upscaling
  - Upscale images up to 4K resolution
  - 20-40x size increase while preserving quality
  - Creative enhancement options
  - Support for multiple output formats
- Engine Management
  - List available engines
  - Engine details including type and status
- Stable Diffusion 3.0 & 3.5 Image Generation
  - Multiple model variants (large, medium, turbo)
  - Support for aspect ratio control
  - Optional image input for variations
  - Multiple output formats (JPEG, PNG, WebP)
- Full Type Safety
  - JSON serialization/deserialization
  - Proper error handling with detailed messages
  - Input validation

## Installation 📦

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  stability_ai_dart: ^0.0.1
```

## Usage 🚀

### Initialize the client 🔑

The library uses an interface-based architecture with a factory pattern for creating clients. This allows for better testing and flexibility:

```dart
import 'package:stability_ai_dart/stability_ai_dart.dart';

// Create a client using the factory
final client = StabilityAiFactory.create(
  apiKey: 'your-api-key-here',
  // Optional: customize base URL or HTTP client
  // baseUrl: 'https://api.stability.ai',
  // httpClient: customHttpClient,
);

// The client implements StabilityAiInterface, which defines
// all available operations for interacting with the API
```

The interface-based design provides several benefits:
- Clear contract for all supported operations
- Easier testing through mock implementations
- Flexibility to swap implementations
- Better dependency injection support

### List available engines 🔍

```dart
final engines = await client.listEngines();
for (final engine in engines) {
  print('${engine.id}: ${engine.name}');
  print('Description: ${engine.description}');
  print('Type: ${engine.type}');
  print('Status: ${engine.ready ? 'Ready' : 'Not Ready'}');
}
```

### Generate images from text ✍️

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

### Generate Core Images 🖼️

```dart
final request = CoreImageRequest(
  prompt: 'A lighthouse on a cliff overlooking the ocean',
  negativePrompt: 'blur, haze, fog', // optional: what not to include
  aspectRatio: AspectRatio.ratio16x9,
  outputFormat: OutputFormat.png,
  seed: 123, // optional: for reproducible results
  stylePreset: StylePreset.photographic, // optional: guide the image style
);

// Get raw bytes
final result = await client.generateCoreImage(
  request: request,
  returnJson: false,
);

if (result is CoreImageBytes) {
  // Use the raw bytes
  await File('lighthouse.png').writeAsBytes(result.bytes);
}

// Or get JSON response with base64 and metadata
final jsonResult = await client.generateCoreImage(
  request: request,
  returnJson: true,
);

if (jsonResult is CoreImageResponse) {
  print('Generated image: ${jsonResult.image}');
  print('Finish reason: ${jsonResult.finishReason}');
  print('Seed used: ${jsonResult.seed}');
}
```

### Available Style Presets 🎨

The Core Image API supports the following style presets:

- `enhance` - General enhancement
- `anime` - Anime style
- `photographic` - Photographic style
- `digital-art` - Digital art style
- `comic-book` - Comic book style
- `fantasy-art` - Fantasy art style
- `line-art` - Line art style
- `analog-film` - Analog film style
- `neon-punk` - Neon punk style
- `isometric` - Isometric style
- `low-poly` - Low poly style
- `origami` - Origami style
- `modeling-compound` - Modeling compound style
- `cinematic` - Cinematic style
- `3d-model` - 3D model style
- `pixel-art` - Pixel art style
- `tile-texture` - Tile texture style

### Generate Ultra Images 🌟

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

### Generate Image Variations 🔄

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

### Remove Image Backgrounds ✂️

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

### Upscale Images 📐

There are four upscaling options available:

1. Standard Upscaler: Enhances quality while upscaling
2. Creative Upscaler: Best for highly degraded images, performs heavy reimagining
3. Conservative Upscaler: Minimizes alterations while upscaling
4. Fast Upscaler: Quick 4x upscaling with good quality, ideal for social media

Each upscaler can be used either with a convenience method or manual polling.

#### Standard Upscaler

#### Using the Convenience Method

```dart
final request = UpscaleRequest(
  image: imageBytes, // Uint8List of image (64x64 to 1 megapixel)
  prompt: 'A high resolution landscape photo',
  negativePrompt: 'blur, noise', // optional: what not to include
  outputFormat: OutputFormat.png,
  seed: 123, // optional: for reproducible results
  creativity: 0.3, // optional: control creative enhancement (0.0 to 0.35)
);

// Upscale and wait for result in one call
final result = await client.upscaleImageAndWaitForResult(
  request: request,
  returnJson: false, // true for JSON response with metadata
  pollInterval: Duration(seconds: 10), // optional: customize polling interval
);

if (result is UpscaleResultBytes) {
  // Handle raw bytes
  await File('upscaled.png').writeAsBytes(result.bytes);
} else if (result is UpscaleResultResponse) {
  // Handle JSON response
  print('Finish reason: ${result.finishReason}');
  final bytes = base64.decode(result.image);
  await File('upscaled.png').writeAsBytes(bytes);
}
```

#### Creative Upscaler

The creative upscaler is optimized for highly degraded images and performs heavy reimagining:

```dart
final request = UpscaleRequest(
  image: imageBytes, // Uint8List of image (64x64 to 1 megapixel)
  prompt: 'A high resolution landscape photo',
  negativePrompt: 'blur, noise', // optional: what not to include
  outputFormat: OutputFormat.png,
  seed: 123, // optional: for reproducible results
  creativity: 0.3, // optional: control creative enhancement (0.0 to 0.35)
);

// Get the result with polling handled automatically
final result = await client.upscaleImageCreativeAndWaitForResult(
  request: request,
  returnJson: false,
  pollInterval: Duration(seconds: 10), // optional: customize polling interval
);

if (result is UpscaleResultBytes) {
  // Handle raw bytes
  await File('upscaled.png').writeAsBytes(result.bytes);
} else if (result is UpscaleResultResponse) {
  // Handle JSON response
  print('Finish reason: ${result.finishReason}');
  final bytes = base64.decode(result.image);
  await File('upscaled.png').writeAsBytes(bytes);
}

// Or start the upscale and handle polling manually
final response = await client.upscaleImageCreative(request: request);
print('Generation ID: ${response.id}');

// Poll for the result
while (true) {
  final result = await client.getCreativeUpscaleResult(
    id: response.id,
    returnJson: false,
  );

  if (result is UpscaleInProgressResponse) {
    // Still processing, wait before trying again
    await Future.delayed(Duration(seconds: 10));
    continue;
  }

  // Generation complete
  if (result is UpscaleResultBytes) {
    await File('upscaled.png').writeAsBytes(result.bytes);
    break;
  } else if (result is UpscaleResultResponse) {
    print('Finish reason: ${result.finishReason}');
    final bytes = base64.decode(result.image);
    await File('upscaled.png').writeAsBytes(bytes);
    break;
  }
}
```

#### Conservative Upscaler

The conservative upscaler preserves the original image's aspects more strictly:

```dart
final request = UpscaleRequest(
  image: imageBytes, // Uint8List of image (64x64 to 1 megapixel)
  prompt: 'A high resolution landscape photo',
  negativePrompt: 'blur, noise', // optional: what not to include
  outputFormat: OutputFormat.png,
  seed: 123, // optional: for reproducible results
  creativity: 0.3, // optional: control creative enhancement (0.0 to 0.35)
);

// Get the result directly
final result = await client.upscaleImageConservative(
  request: request,
  returnJson: false, // true for JSON response with metadata
);

if (result is UltraImageBytes) {
  // Handle raw bytes
  await File('upscaled.png').writeAsBytes(result.bytes);
} else if (result is UltraImageResponse) {
  // Handle JSON response
  print('Finish reason: ${result.finishReason}');
  final bytes = base64.decode(result.image);
  await File('upscaled.png').writeAsBytes(bytes);
}

// Or use the convenience method
final result = await client.upscaleImageConservativeAndWaitForResult(
  request: request,
  returnJson: false,
  pollInterval: Duration(seconds: 10), // optional: customize polling interval
);
```

#### Manual Polling (Standard Upscaler)

For more control over the polling process with the standard upscaler, you can use the separate methods:

```dart
final request = UpscaleRequest(
  image: imageBytes,
  prompt: 'A high resolution landscape photo',
  outputFormat: OutputFormat.png,
);

// Start the upscale
final response = await client.upscaleImage(request: request);
print('Generation ID: ${response.id}');

// Poll for the result
while (true) {
  final result = await client.getUpscaleResult(
    id: response.id,
    returnJson: false,
  );

  if (result is UpscaleInProgressResponse) {
    // Still processing, wait before trying again
    await Future.delayed(Duration(seconds: 10));
    continue;
  }

  // Generation complete
  if (result is UpscaleResultBytes) {
    await File('upscaled.png').writeAsBytes(result.bytes);
    break;
  } else if (result is UpscaleResultResponse) {
    print('Finish reason: ${result.finishReason}');
    final bytes = base64.decode(result.image);
    await File('upscaled.png').writeAsBytes(bytes);
    break;
  }
}
```

### Error Handling ⚠️

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

### Available Aspect Ratios 📏

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

### Output Formats 💾

The following output formats are supported:

- JPEG (`OutputFormat.jpeg`)
- PNG (`OutputFormat.png`)
- WebP (`OutputFormat.webp`)

### Generate Images with SD3 🎯

```dart
final request = SD3ImageRequest(
  prompt: 'A lighthouse on a cliff overlooking the ocean',
  model: SD3Model.sd35Large, // or sd35LargeTurbo, sd35Medium, sd3Large, sd3Medium, etc.
  aspectRatio: AspectRatio.ratio16x9,
  cfgScale: 7.0, // optional: control how closely the image follows the prompt
  seed: 42, // optional: for reproducible results
  outputFormat: OutputFormat.png,
);

// Get raw bytes
final result = await client.generateSD3Image(
  request: request,
  returnJson: false,
);

if (result is SD3ImageBytes) {
  // Use the raw bytes
  await File('lighthouse.png').writeAsBytes(result.bytes);
}

// Or get JSON response with base64 and metadata
final jsonResult = await client.generateSD3Image(
  request: request,
  returnJson: true,
);

if (jsonResult is SD3ImageResponse) {
  print('Generated image: ${jsonResult.image}');
  print('Finish reason: ${jsonResult.finishReason}');
  print('Seed used: ${jsonResult.seed}');
}
```

### SD3 Models and Credit Costs 💰

The following models are available for SD3 image generation:

- SD 3.5 Large (6.5 credits)
  - Highest quality model
  - Best for detailed, high-fidelity images
- SD 3.5 Large Turbo (4 credits)
  - Faster generation
  - Good balance of speed and quality
- SD 3.5 Medium (3.5 credits)
  - Lighter model with good quality
  - More economical option
- SD 3.0 Large (6.5 credits)
  - Original SD3 high-quality model
- SD 3.0 Large Turbo (4 credits)
  - Faster version of SD3 large
- SD 3.0 Medium (3.5 credits)
  - Balanced SD3 model

### Cleanup 🧹

Don't forget to close the client when you're done:

```dart
client.close();
```

## License 📄

MIT License - see the [LICENSE](LICENSE) file for details.
