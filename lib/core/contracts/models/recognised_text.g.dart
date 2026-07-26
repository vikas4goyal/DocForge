// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognised_text.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NormalisedRect _$NormalisedRectFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NormalisedRect', json, ($checkedConvert) {
      final val = _NormalisedRect(
        left: $checkedConvert('left', (v) => (v as num).toDouble()),
        top: $checkedConvert('top', (v) => (v as num).toDouble()),
        right: $checkedConvert('right', (v) => (v as num).toDouble()),
        bottom: $checkedConvert('bottom', (v) => (v as num).toDouble()),
      );
      return val;
    });

Map<String, dynamic> _$NormalisedRectToJson(_NormalisedRect instance) =>
    <String, dynamic>{
      'left': instance.left,
      'top': instance.top,
      'right': instance.right,
      'bottom': instance.bottom,
    };

_TextBlock _$TextBlockFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_TextBlock', json, ($checkedConvert) {
      final val = _TextBlock(
        text: $checkedConvert('text', (v) => v as String),
        bounds: $checkedConvert(
          'bounds',
          (v) => NormalisedRect.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TextBlockToJson(_TextBlock instance) =>
    <String, dynamic>{
      'text': instance.text,
      'bounds': instance.bounds.toJson(),
    };

_RecognisedText _$RecognisedTextFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RecognisedText', json, ($checkedConvert) {
      final val = _RecognisedText(
        pageId: $checkedConvert('pageId', (v) => PageId.fromJson(v as String)),
        blocks: $checkedConvert(
          'blocks',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => TextBlock.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <TextBlock>[],
        ),
        languageTag: $checkedConvert('languageTag', (v) => v as String),
        recognisedAt: $checkedConvert(
          'recognisedAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$RecognisedTextToJson(_RecognisedText instance) =>
    <String, dynamic>{
      'pageId': instance.pageId.toJson(),
      'blocks': instance.blocks.map((e) => e.toJson()).toList(),
      'languageTag': instance.languageTag,
      'recognisedAt': instance.recognisedAt.toIso8601String(),
    };
