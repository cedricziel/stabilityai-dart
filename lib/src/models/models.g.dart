// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Engine _$EngineFromJson(Map<String, dynamic> json) => Engine(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      ready: json['ready'] as bool,
      tokenizerStrength: json['tokenizer_strength'] as String?,
    );

Map<String, dynamic> _$EngineToJson(Engine instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': instance.type,
      'ready': instance.ready,
      'tokenizer_strength': instance.tokenizerStrength,
    };

RemoveBackgroundRequest _$RemoveBackgroundRequestFromJson(
        Map<String, dynamic> json) =>
    RemoveBackgroundRequest(
      image:
          RemoveBackgroundRequest._uint8ListFromJson(json['image'] as String),
      outputFormat:
          $enumDecodeNullable(_$OutputFormatEnumMap, json['outputFormat']),
    );

Map<String, dynamic> _$RemoveBackgroundRequestToJson(
        RemoveBackgroundRequest instance) =>
    <String, dynamic>{
      'image': RemoveBackgroundRequest._uint8ListToJson(instance.image),
      'outputFormat': _$OutputFormatEnumMap[instance.outputFormat],
    };

const _$OutputFormatEnumMap = {
  OutputFormat.jpeg: 'jpeg',
  OutputFormat.png: 'png',
  OutputFormat.webp: 'webp',
};

RemoveBackgroundResponse _$RemoveBackgroundResponseFromJson(
        Map<String, dynamic> json) =>
    RemoveBackgroundResponse(
      image: json['image'] as String,
      finishReason: $enumDecode(_$FinishReasonEnumMap, json['finish_reason']),
      seed: (json['seed'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RemoveBackgroundResponseToJson(
        RemoveBackgroundResponse instance) =>
    <String, dynamic>{
      'image': instance.image,
      'finish_reason': _$FinishReasonEnumMap[instance.finishReason]!,
      'seed': instance.seed,
    };

const _$FinishReasonEnumMap = {
  FinishReason.success: 'SUCCESS',
  FinishReason.contentFiltered: 'CONTENT_FILTERED',
};

UltraImageResponse _$UltraImageResponseFromJson(Map<String, dynamic> json) =>
    UltraImageResponse(
      image: json['image'] as String,
      finishReason: $enumDecode(_$FinishReasonEnumMap, json['finish_reason']),
      seed: (json['seed'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UltraImageResponseToJson(UltraImageResponse instance) =>
    <String, dynamic>{
      'image': instance.image,
      'finish_reason': _$FinishReasonEnumMap[instance.finishReason]!,
      'seed': instance.seed,
    };

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    ErrorResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      errors:
          (json['errors'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'errors': instance.errors,
    };

UltraImageRequest _$UltraImageRequestFromJson(Map<String, dynamic> json) =>
    UltraImageRequest(
      prompt: json['prompt'] as String,
      negativePrompt: json['negativePrompt'] as String?,
      aspectRatio:
          $enumDecodeNullable(_$AspectRatioEnumMap, json['aspectRatio']),
      seed: (json['seed'] as num?)?.toInt(),
      outputFormat:
          $enumDecodeNullable(_$OutputFormatEnumMap, json['outputFormat']),
      image: const Uint8ListConverter().fromJson(json['image'] as String?),
      strength: (json['strength'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$UltraImageRequestToJson(UltraImageRequest instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'negativePrompt': instance.negativePrompt,
      'aspectRatio': _$AspectRatioEnumMap[instance.aspectRatio],
      'seed': instance.seed,
      'outputFormat': _$OutputFormatEnumMap[instance.outputFormat],
      'image': const Uint8ListConverter().toJson(instance.image),
      'strength': instance.strength,
    };

const _$AspectRatioEnumMap = {
  AspectRatio.ratio16x9: '16:9',
  AspectRatio.ratio1x1: '1:1',
  AspectRatio.ratio21x9: '21:9',
  AspectRatio.ratio2x3: '2:3',
  AspectRatio.ratio3x2: '3:2',
  AspectRatio.ratio4x5: '4:5',
  AspectRatio.ratio5x4: '5:4',
  AspectRatio.ratio9x16: '9:16',
  AspectRatio.ratio9x21: '9:21',
};

TextToImageRequest _$TextToImageRequestFromJson(Map<String, dynamic> json) =>
    TextToImageRequest(
      textPrompts: (json['text_prompts'] as List<dynamic>)
          .map((e) => TextPrompt.fromJson(e as Map<String, dynamic>))
          .toList(),
      height: (json['height'] as num?)?.toInt() ?? 512,
      width: (json['width'] as num?)?.toInt() ?? 512,
      numberOfSamples: (json['samples'] as num?)?.toInt() ?? 1,
      numberOfSteps: (json['steps'] as num?)?.toInt() ?? 50,
      seed: (json['seed'] as num?)?.toInt(),
      cfgScale: (json['cfg_scale'] as num?)?.toDouble() ?? 7.0,
    );

Map<String, dynamic> _$TextToImageRequestToJson(TextToImageRequest instance) =>
    <String, dynamic>{
      'text_prompts': instance.textPrompts,
      'height': instance.height,
      'width': instance.width,
      'samples': instance.numberOfSamples,
      'steps': instance.numberOfSteps,
      'seed': instance.seed,
      'cfg_scale': instance.cfgScale,
    };

TextPrompt _$TextPromptFromJson(Map<String, dynamic> json) => TextPrompt(
      text: json['text'] as String,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$TextPromptToJson(TextPrompt instance) =>
    <String, dynamic>{
      'text': instance.text,
      'weight': instance.weight,
    };

GenerationResponse _$GenerationResponseFromJson(Map<String, dynamic> json) =>
    GenerationResponse(
      artifacts: (json['artifacts'] as List<dynamic>)
          .map((e) => Artifact.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GenerationResponseToJson(GenerationResponse instance) =>
    <String, dynamic>{
      'artifacts': instance.artifacts,
    };

Artifact _$ArtifactFromJson(Map<String, dynamic> json) => Artifact(
      base64: json['base64'] as String,
      seed: (json['seed'] as num).toInt(),
      mimeType: json['mime_type'] as String,
    );

Map<String, dynamic> _$ArtifactToJson(Artifact instance) => <String, dynamic>{
      'base64': instance.base64,
      'seed': instance.seed,
      'mime_type': instance.mimeType,
    };

UpscaleRequest _$UpscaleRequestFromJson(Map<String, dynamic> json) =>
    UpscaleRequest(
      image: UpscaleRequest._uint8ListFromJson(json['image'] as String),
      prompt: json['prompt'] as String,
      negativePrompt: json['negativePrompt'] as String?,
      outputFormat:
          $enumDecodeNullable(_$OutputFormatEnumMap, json['outputFormat']),
      seed: (json['seed'] as num?)?.toInt(),
      creativity: (json['creativity'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$UpscaleRequestToJson(UpscaleRequest instance) =>
    <String, dynamic>{
      'image': UpscaleRequest._uint8ListToJson(instance.image),
      'prompt': instance.prompt,
      'negativePrompt': instance.negativePrompt,
      'outputFormat': _$OutputFormatEnumMap[instance.outputFormat],
      'seed': instance.seed,
      'creativity': instance.creativity,
    };

UpscaleResponse _$UpscaleResponseFromJson(Map<String, dynamic> json) =>
    UpscaleResponse(
      id: json['id'] as String,
    );

Map<String, dynamic> _$UpscaleResponseToJson(UpscaleResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
    };

UpscaleInProgressResponse _$UpscaleInProgressResponseFromJson(
        Map<String, dynamic> json) =>
    UpscaleInProgressResponse(
      id: json['id'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$UpscaleInProgressResponseToJson(
        UpscaleInProgressResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
    };

FastUpscaleResponse _$FastUpscaleResponseFromJson(Map<String, dynamic> json) =>
    FastUpscaleResponse(
      image: json['image'] as String,
      finishReason: $enumDecode(_$FinishReasonEnumMap, json['finish_reason']),
      seed: (json['seed'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FastUpscaleResponseToJson(
        FastUpscaleResponse instance) =>
    <String, dynamic>{
      'image': instance.image,
      'finish_reason': _$FinishReasonEnumMap[instance.finishReason]!,
      'seed': instance.seed,
    };

FastUpscaleRequest _$FastUpscaleRequestFromJson(Map<String, dynamic> json) =>
    FastUpscaleRequest(
      image: FastUpscaleRequest._uint8ListFromJson(json['image'] as String),
      outputFormat:
          $enumDecodeNullable(_$OutputFormatEnumMap, json['outputFormat']),
    );

Map<String, dynamic> _$FastUpscaleRequestToJson(FastUpscaleRequest instance) =>
    <String, dynamic>{
      'image': FastUpscaleRequest._uint8ListToJson(instance.image),
      'outputFormat': _$OutputFormatEnumMap[instance.outputFormat],
    };

CoreImageResponse _$CoreImageResponseFromJson(Map<String, dynamic> json) =>
    CoreImageResponse(
      image: json['image'] as String,
      finishReason: $enumDecode(_$FinishReasonEnumMap, json['finish_reason']),
      seed: (json['seed'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CoreImageResponseToJson(CoreImageResponse instance) =>
    <String, dynamic>{
      'image': instance.image,
      'finish_reason': _$FinishReasonEnumMap[instance.finishReason]!,
      'seed': instance.seed,
    };

CoreImageRequest _$CoreImageRequestFromJson(Map<String, dynamic> json) =>
    CoreImageRequest(
      prompt: json['prompt'] as String,
      negativePrompt: json['negative_prompt'] as String?,
      aspectRatio:
          $enumDecodeNullable(_$AspectRatioEnumMap, json['aspect_ratio']),
      seed: (json['seed'] as num?)?.toInt(),
      outputFormat:
          $enumDecodeNullable(_$OutputFormatEnumMap, json['output_format']),
      stylePreset:
          $enumDecodeNullable(_$StylePresetEnumMap, json['style_preset']),
    );

Map<String, dynamic> _$CoreImageRequestToJson(CoreImageRequest instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'negative_prompt': instance.negativePrompt,
      'aspect_ratio': _$AspectRatioEnumMap[instance.aspectRatio],
      'seed': instance.seed,
      'output_format': _$OutputFormatEnumMap[instance.outputFormat],
      'style_preset': _$StylePresetEnumMap[instance.stylePreset],
    };

const _$StylePresetEnumMap = {
  StylePreset.enhance: 'enhance',
  StylePreset.anime: 'anime',
  StylePreset.photographic: 'photographic',
  StylePreset.digitalArt: 'digital-art',
  StylePreset.comicBook: 'comic-book',
  StylePreset.fantasyArt: 'fantasy-art',
  StylePreset.lineArt: 'line-art',
  StylePreset.analogFilm: 'analog-film',
  StylePreset.neonPunk: 'neon-punk',
  StylePreset.isometric: 'isometric',
  StylePreset.lowPoly: 'low-poly',
  StylePreset.origami: 'origami',
  StylePreset.modelingCompound: 'modeling-compound',
  StylePreset.cinematic: 'cinematic',
  StylePreset.threeDModel: '3d-model',
  StylePreset.pixelArt: 'pixel-art',
  StylePreset.tileTexture: 'tile-texture',
};

UpscaleResultResponse _$UpscaleResultResponseFromJson(
        Map<String, dynamic> json) =>
    UpscaleResultResponse(
      image: json['image'] as String,
      finishReason: $enumDecode(_$FinishReasonEnumMap, json['finish_reason']),
      seed: (json['seed'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UpscaleResultResponseToJson(
        UpscaleResultResponse instance) =>
    <String, dynamic>{
      'image': instance.image,
      'finish_reason': _$FinishReasonEnumMap[instance.finishReason]!,
      'seed': instance.seed,
    };

SD3ImageResponse _$SD3ImageResponseFromJson(Map<String, dynamic> json) =>
    SD3ImageResponse(
      image: json['image'] as String,
      finishReason: $enumDecode(_$FinishReasonEnumMap, json['finish_reason']),
      seed: (json['seed'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SD3ImageResponseToJson(SD3ImageResponse instance) =>
    <String, dynamic>{
      'image': instance.image,
      'finish_reason': _$FinishReasonEnumMap[instance.finishReason]!,
      'seed': instance.seed,
    };

SD3ImageRequest _$SD3ImageRequestFromJson(Map<String, dynamic> json) =>
    SD3ImageRequest(
      prompt: json['prompt'] as String,
      negativePrompt: json['negative_prompt'] as String?,
      mode: json['mode'] as String? ?? 'text-to-image',
      image: const Uint8ListConverter().fromJson(json['image'] as String?),
      strength: (json['strength'] as num?)?.toDouble(),
      aspectRatio:
          $enumDecodeNullable(_$AspectRatioEnumMap, json['aspect_ratio']),
      model: $enumDecodeNullable(_$SD3ModelEnumMap, json['model']) ??
          SD3Model.sd35Large,
      seed: (json['seed'] as num?)?.toInt(),
      outputFormat:
          $enumDecodeNullable(_$OutputFormatEnumMap, json['output_format']) ??
              OutputFormat.png,
      cfgScale: (json['cfg_scale'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SD3ImageRequestToJson(SD3ImageRequest instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'negative_prompt': instance.negativePrompt,
      'mode': instance.mode,
      'image': const Uint8ListConverter().toJson(instance.image),
      'strength': instance.strength,
      'aspect_ratio': _$AspectRatioEnumMap[instance.aspectRatio],
      'model': _$SD3ModelEnumMap[instance.model],
      'seed': instance.seed,
      'output_format': _$OutputFormatEnumMap[instance.outputFormat],
      'cfg_scale': instance.cfgScale,
    };

const _$SD3ModelEnumMap = {
  SD3Model.sd35Large: 'sd3.5-large',
  SD3Model.sd35LargeTurbo: 'sd3.5-large-turbo',
  SD3Model.sd35Medium: 'sd3.5-medium',
  SD3Model.sd3Medium: 'sd3-medium',
  SD3Model.sd3Large: 'sd3-large',
  SD3Model.sd3LargeTurbo: 'sd3-large-turbo',
};
