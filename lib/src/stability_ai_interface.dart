import 'models/models.dart';

/// Interface for interacting with the Stability AI REST API.
///
/// This interface defines the contract for all operations supported by the Stability AI API:
/// - Text-to-Image Generation
/// - Ultra Image Generation
/// - Background Removal
/// - Image Upscaling
/// - SD3 Image Generation
abstract class StabilityAiInterface {
  /// Lists all available engines.
  Future<List<Engine>> listEngines();

  /// Generates images from text prompts.
  Future<GenerationResponse> generateImage({
    required String engineId,
    required TextToImageRequest request,
  });

  /// Generates an image using the Stable Image Core API.
  Future<CoreImageResult> generateCoreImage({
    required CoreImageRequest request,
    bool returnJson = false,
  });

  /// Generates an image using the Stable Image Ultra API.
  Future<UltraImageResult> generateUltraImage({
    required UltraImageRequest request,
    bool returnJson = false,
  });

  /// Removes the background from an image.
  Future<UltraImageResult> removeBackground({
    required RemoveBackgroundRequest request,
    bool returnJson = false,
  });

  /// Upscales an image using the standard upscaler (up to 4K).
  Future<UpscaleResponse> upscaleImage({
    required UpscaleRequest request,
  });

  /// Upscales an image using the creative upscaler (up to 4K).
  Future<UpscaleResponse> upscaleImageCreative({
    required UpscaleRequest request,
  });

  /// Upscales an image using the conservative upscaler (up to 4K).
  Future<UltraImageResult> upscaleImageConservative({
    required UpscaleRequest request,
    bool returnJson = false,
  });

  /// Fetches the result of an upscale generation by ID.
  Future<Object> getUpscaleResult({
    required String id,
    bool returnJson = false,
  });

  /// Upscales an image using the standard upscaler and waits for the result.
  Future<UpscaleResult> upscaleImageAndWaitForResult({
    required UpscaleRequest request,
    bool returnJson = false,
    Duration pollInterval = const Duration(seconds: 10),
  });

  /// Fetches the result of a creative upscale generation by ID.
  Future<Object> getCreativeUpscaleResult({
    required String id,
    bool returnJson = false,
  });

  /// Upscales an image using the conservative upscaler and waits for the result.
  Future<UltraImageResult> upscaleImageConservativeAndWaitForResult({
    required UpscaleRequest request,
    bool returnJson = false,
    Duration pollInterval = const Duration(seconds: 10),
  });

  /// Generates an image using the Stable Diffusion 3.0 & 3.5 API.
  Future<SD3ImageResult> generateSD3Image({
    required SD3ImageRequest request,
    bool returnJson = false,
  });

  /// Upscales an image using the fast upscaler (4x).
  Future<FastUpscaleResult> upscaleImageFast({
    required FastUpscaleRequest request,
    bool returnJson = false,
  });

  /// Upscales an image using the creative upscaler and waits for the result.
  Future<UpscaleResult> upscaleImageCreativeAndWaitForResult({
    required UpscaleRequest request,
    bool returnJson = false,
    Duration pollInterval = const Duration(seconds: 10),
  });

  /// Closes any resources used by the client.
  void close();
}
