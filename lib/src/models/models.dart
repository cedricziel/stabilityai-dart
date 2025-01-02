import 'package:json_annotation/json_annotation.dart';
import 'dart:typed_data';
import 'dart:convert';

part 'models.g.dart';

/// Response from the Ultra Image generation API.
/// Can either contain raw bytes ([UltraImageBytes]) or a JSON response ([UltraImageResponse]).
sealed class UltraImageResult {}

/// Raw bytes response from the Ultra Image generation API.
class UltraImageBytes implements UltraImageResult {
  final Uint8List bytes;

  UltraImageBytes(this.bytes);
}

/// Converts between [Uint8List] and base64 encoded strings for JSON serialization
class Uint8ListConverter implements JsonConverter<Uint8List?, String?> {
  const Uint8ListConverter();

  @override
  Uint8List? fromJson(String? json) {
    if (json == null) return null;
    return base64.decode(json);
  }

  @override
  String? toJson(Uint8List? object) {
    if (object == null) return null;
    return base64.encode(object);
  }
}

/// Represents a Stability AI engine.
@JsonSerializable()
class Engine {
  /// The unique identifier of the engine.
  final String id;

  /// The name of the engine.
  final String name;

  /// The description of the engine.
  final String description;

  /// The type of the engine.
  final String type;

  /// Whether the engine is ready for use.
  final bool ready;

  /// The token strength of the engine.
  @JsonKey(name: 'tokenizer_strength')
  final String? tokenizerStrength;

  Engine({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.ready,
    this.tokenizerStrength,
  });

  factory Engine.fromJson(Map<String, dynamic> json) => _$EngineFromJson(json);
  Map<String, dynamic> toJson() => _$EngineToJson(this);
}

/// The aspect ratio of the generated image.
enum AspectRatio {
  @JsonValue('16:9')
  ratio16x9,
  @JsonValue('1:1')
  ratio1x1,
  @JsonValue('21:9')
  ratio21x9,
  @JsonValue('2:3')
  ratio2x3,
  @JsonValue('3:2')
  ratio3x2,
  @JsonValue('4:5')
  ratio4x5,
  @JsonValue('5:4')
  ratio5x4,
  @JsonValue('9:16')
  ratio9x16,
  @JsonValue('9:21')
  ratio9x21,
}

/// The reason why the generation finished.
enum FinishReason {
  @JsonValue('SUCCESS')
  success,
  @JsonValue('CONTENT_FILTERED')
  contentFiltered,
}

/// The output format of the generated image.
enum OutputFormat {
  @JsonValue('jpeg')
  jpeg,
  @JsonValue('png')
  png,
  @JsonValue('webp')
  webp,
}

/// Request parameters for the remove background API.
@JsonSerializable()
class RemoveBackgroundRequest {
  /// The image whose background you wish to remove.
  @JsonKey(fromJson: _uint8ListFromJson, toJson: _uint8ListToJson)
  final Uint8List image;

  static Uint8List _uint8ListFromJson(String json) => base64.decode(json);
  static String _uint8ListToJson(Uint8List bytes) => base64.encode(bytes);

  /// The format of the output image.
  final OutputFormat? outputFormat;

  RemoveBackgroundRequest({
    required this.image,
    this.outputFormat,
  });

  factory RemoveBackgroundRequest.fromJson(Map<String, dynamic> json) =>
      _$RemoveBackgroundRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RemoveBackgroundRequestToJson(this);
}

/// Response from the remove background API when JSON output is requested.
@JsonSerializable()
class RemoveBackgroundResponse implements UltraImageResult {
  /// The generated image, encoded to base64.
  final String image;

  /// The reason the generation finished.
  @JsonKey(name: 'finish_reason')
  final FinishReason finishReason;

  /// The seed used as random noise for this generation.
  final int? seed;

  RemoveBackgroundResponse({
    required this.image,
    required this.finishReason,
    this.seed,
  });

  factory RemoveBackgroundResponse.fromJson(Map<String, dynamic> json) =>
      _$RemoveBackgroundResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RemoveBackgroundResponseToJson(this);
}

/// Response from the Stable Image Ultra API when JSON output is requested.
@JsonSerializable()
class UltraImageResponse implements UltraImageResult {
  /// The generated image, encoded to base64.
  final String image;

  /// The reason the generation finished.
  @JsonKey(name: 'finish_reason')
  final FinishReason finishReason;

  /// The seed used as random noise for this generation.
  final int? seed;

  UltraImageResponse({
    required this.image,
    required this.finishReason,
    this.seed,
  });

  factory UltraImageResponse.fromJson(Map<String, dynamic> json) =>
      _$UltraImageResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UltraImageResponseToJson(this);
}

/// Error response from the API.
@JsonSerializable()
class ErrorResponse {
  /// A unique identifier associated with this error.
  final String id;

  /// Short-hand name for the error.
  final String name;

  /// One or more error messages indicating what went wrong.
  final List<String> errors;

  ErrorResponse({
    required this.id,
    required this.name,
    required this.errors,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);
}

/// Request parameters for the Stable Image Ultra API.
@JsonSerializable()
class UltraImageRequest {
  /// What you wish to see in the output image.
  final String prompt;

  /// Keywords of what you do not wish to see in the output image.
  final String? negativePrompt;

  /// The aspect ratio of the output image.
  final AspectRatio? aspectRatio;

  /// The randomness seed to use for generation.
  final int? seed;

  /// The format of the output image.
  final OutputFormat? outputFormat;

  /// The image to use as the starting point for the generation.
  @Uint8ListConverter()
  final Uint8List? image;

  /// Controls how much influence the image parameter has on the output image.
  final double? strength;

  UltraImageRequest({
    required this.prompt,
    this.negativePrompt,
    this.aspectRatio,
    this.seed,
    this.outputFormat,
    this.image,
    this.strength,
  }) {
    if (image != null && strength == null) {
      throw ArgumentError('strength is required when image is provided');
    }
    if (image == null && strength != null) {
      throw ArgumentError('image is required when strength is provided');
    }
    if (strength != null && (strength! < 0 || strength! > 1)) {
      throw ArgumentError('strength must be between 0 and 1');
    }
    if (seed != null && (seed! < 0 || seed! > 4294967294)) {
      throw ArgumentError('seed must be between 0 and 4294967294');
    }
  }

  factory UltraImageRequest.fromJson(Map<String, dynamic> json) =>
      _$UltraImageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UltraImageRequestToJson(this);
}

/// Represents a text-to-image generation request.
@JsonSerializable()
class TextToImageRequest {
  /// The text prompt to generate images from.
  @JsonKey(name: 'text_prompts')
  final List<TextPrompt> textPrompts;

  /// The height of the generated image in pixels.
  final int? height;

  /// The width of the generated image in pixels.
  final int? width;

  /// The number of images to generate.
  @JsonKey(name: 'samples')
  final int? numberOfSamples;

  /// The number of diffusion steps to run.
  @JsonKey(name: 'steps')
  final int? numberOfSteps;

  /// The random seed to use for generation.
  @JsonKey(name: 'seed')
  final int? seed;

  /// The configuration for the Stable Diffusion sampler.
  @JsonKey(name: 'cfg_scale')
  final double? cfgScale;

  TextToImageRequest({
    required this.textPrompts,
    this.height = 512,
    this.width = 512,
    this.numberOfSamples = 1,
    this.numberOfSteps = 50,
    this.seed,
    this.cfgScale = 7.0,
  });

  factory TextToImageRequest.fromJson(Map<String, dynamic> json) =>
      _$TextToImageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$TextToImageRequestToJson(this);
}

/// Represents a text prompt with weight.
@JsonSerializable()
class TextPrompt {
  /// The text to use for generation.
  final String text;

  /// The weight to give this prompt (defaults to 1).
  final double? weight;

  TextPrompt({
    required this.text,
    this.weight = 1.0,
  });

  factory TextPrompt.fromJson(Map<String, dynamic> json) =>
      _$TextPromptFromJson(json);
  Map<String, dynamic> toJson() => _$TextPromptToJson(this);
}

/// Represents a generated image response.
@JsonSerializable()
class GenerationResponse {
  /// The list of artifacts (images) generated.
  final List<Artifact> artifacts;

  GenerationResponse({required this.artifacts});

  factory GenerationResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GenerationResponseToJson(this);
}

/// Represents a generated artifact (image).
@JsonSerializable()
class Artifact {
  /// The base64 encoded image data.
  final String base64;

  /// The seed used to generate this artifact.
  final int seed;

  /// The MIME type of the artifact.
  @JsonKey(name: 'mime_type')
  final String mimeType;

  Artifact({
    required this.base64,
    required this.seed,
    required this.mimeType,
  });

  factory Artifact.fromJson(Map<String, dynamic> json) =>
      _$ArtifactFromJson(json);
  Map<String, dynamic> toJson() => _$ArtifactToJson(this);
}

/// Request parameters for the upscale API.
@JsonSerializable()
class UpscaleRequest {
  /// The image to upscale.
  @JsonKey(fromJson: _uint8ListFromJson, toJson: _uint8ListToJson)
  final Uint8List image;

  /// What you wish to see in the output image.
  final String prompt;

  /// Keywords of what you do not wish to see in the output image.
  final String? negativePrompt;

  /// The format of the output image.
  final OutputFormat? outputFormat;

  /// The randomness seed to use for generation.
  final int? seed;

  /// Indicates how creative the model should be when upscaling an image.
  final double? creativity;

  static Uint8List _uint8ListFromJson(String json) => base64.decode(json);
  static String _uint8ListToJson(Uint8List bytes) => base64.encode(bytes);

  UpscaleRequest({
    required this.image,
    required this.prompt,
    this.negativePrompt,
    this.outputFormat,
    this.seed,
    this.creativity,
  }) {
    if (seed != null && (seed! < 0 || seed! > 4294967294)) {
      throw ArgumentError('seed must be between 0 and 4294967294');
    }
    if (creativity != null && (creativity! < 0 || creativity! > 0.35)) {
      throw ArgumentError('creativity must be between 0 and 0.35');
    }
  }

  factory UpscaleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpscaleRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpscaleRequestToJson(this);
}

/// Response from the upscale API.
@JsonSerializable()
class UpscaleResponse {
  /// The unique identifier for this generation.
  final String id;

  UpscaleResponse({
    required this.id,
  });

  factory UpscaleResponse.fromJson(Map<String, dynamic> json) =>
      _$UpscaleResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UpscaleResponseToJson(this);
}

/// Response from the upscale result API when the generation is still in progress.
@JsonSerializable()
class UpscaleInProgressResponse {
  /// The unique identifier for this generation.
  final String id;

  /// The status of the generation.
  final String status;

  UpscaleInProgressResponse({
    required this.id,
    required this.status,
  });

  factory UpscaleInProgressResponse.fromJson(Map<String, dynamic> json) =>
      _$UpscaleInProgressResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UpscaleInProgressResponseToJson(this);
}

/// Response from the upscale result API.
/// Can either contain raw bytes ([UpscaleResultBytes]) or a JSON response ([UpscaleResultResponse]).
sealed class UpscaleResult {}

/// Raw bytes response from the upscale result API.
class UpscaleResultBytes implements UpscaleResult {
  final Uint8List bytes;

  UpscaleResultBytes(this.bytes);
}

/// JSON response from the upscale result API.
@JsonSerializable()
class UpscaleResultResponse implements UpscaleResult {
  /// The generated image, encoded to base64.
  final String image;

  /// The reason the generation finished.
  @JsonKey(name: 'finish_reason')
  final FinishReason finishReason;

  /// The seed used as random noise for this generation.
  final int? seed;

  UpscaleResultResponse({
    required this.image,
    required this.finishReason,
    this.seed,
  });

  factory UpscaleResultResponse.fromJson(Map<String, dynamic> json) =>
      _$UpscaleResultResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UpscaleResultResponseToJson(this);
}
