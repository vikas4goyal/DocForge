// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Failure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Failure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure()';
}


}

/// @nodoc
class $FailureCopyWith<$Res>  {
$FailureCopyWith(Failure _, $Res Function(Failure) __);
}


/// Adds pattern-matching-related methods to [Failure].
extension FailurePatterns on Failure {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CameraFailure value)?  camera,TResult Function( PermissionFailure value)?  permission,TResult Function( OcrFailure value)?  ocr,TResult Function( PdfFailure value)?  pdf,TResult Function( StorageFullFailure value)?  storageFull,TResult Function( ImportFailure value)?  import,TResult Function( ExportFailure value)?  export,TResult Function( AuthFailure value)?  auth,TResult Function( NotFoundFailure value)?  notFound,TResult Function( CorruptFileFailure value)?  corruptFile,TResult Function( SecureStorageFailure value)?  secureStorageUnavailable,TResult Function( StorageFailure value)?  storage,TResult Function( CancelledFailure value)?  cancelled,TResult Function( UnexpectedFailure value)?  unexpected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CameraFailure() when camera != null:
return camera(_that);case PermissionFailure() when permission != null:
return permission(_that);case OcrFailure() when ocr != null:
return ocr(_that);case PdfFailure() when pdf != null:
return pdf(_that);case StorageFullFailure() when storageFull != null:
return storageFull(_that);case ImportFailure() when import != null:
return import(_that);case ExportFailure() when export != null:
return export(_that);case AuthFailure() when auth != null:
return auth(_that);case NotFoundFailure() when notFound != null:
return notFound(_that);case CorruptFileFailure() when corruptFile != null:
return corruptFile(_that);case SecureStorageFailure() when secureStorageUnavailable != null:
return secureStorageUnavailable(_that);case StorageFailure() when storage != null:
return storage(_that);case CancelledFailure() when cancelled != null:
return cancelled(_that);case UnexpectedFailure() when unexpected != null:
return unexpected(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CameraFailure value)  camera,required TResult Function( PermissionFailure value)  permission,required TResult Function( OcrFailure value)  ocr,required TResult Function( PdfFailure value)  pdf,required TResult Function( StorageFullFailure value)  storageFull,required TResult Function( ImportFailure value)  import,required TResult Function( ExportFailure value)  export,required TResult Function( AuthFailure value)  auth,required TResult Function( NotFoundFailure value)  notFound,required TResult Function( CorruptFileFailure value)  corruptFile,required TResult Function( SecureStorageFailure value)  secureStorageUnavailable,required TResult Function( StorageFailure value)  storage,required TResult Function( CancelledFailure value)  cancelled,required TResult Function( UnexpectedFailure value)  unexpected,}){
final _that = this;
switch (_that) {
case CameraFailure():
return camera(_that);case PermissionFailure():
return permission(_that);case OcrFailure():
return ocr(_that);case PdfFailure():
return pdf(_that);case StorageFullFailure():
return storageFull(_that);case ImportFailure():
return import(_that);case ExportFailure():
return export(_that);case AuthFailure():
return auth(_that);case NotFoundFailure():
return notFound(_that);case CorruptFileFailure():
return corruptFile(_that);case SecureStorageFailure():
return secureStorageUnavailable(_that);case StorageFailure():
return storage(_that);case CancelledFailure():
return cancelled(_that);case UnexpectedFailure():
return unexpected(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CameraFailure value)?  camera,TResult? Function( PermissionFailure value)?  permission,TResult? Function( OcrFailure value)?  ocr,TResult? Function( PdfFailure value)?  pdf,TResult? Function( StorageFullFailure value)?  storageFull,TResult? Function( ImportFailure value)?  import,TResult? Function( ExportFailure value)?  export,TResult? Function( AuthFailure value)?  auth,TResult? Function( NotFoundFailure value)?  notFound,TResult? Function( CorruptFileFailure value)?  corruptFile,TResult? Function( SecureStorageFailure value)?  secureStorageUnavailable,TResult? Function( StorageFailure value)?  storage,TResult? Function( CancelledFailure value)?  cancelled,TResult? Function( UnexpectedFailure value)?  unexpected,}){
final _that = this;
switch (_that) {
case CameraFailure() when camera != null:
return camera(_that);case PermissionFailure() when permission != null:
return permission(_that);case OcrFailure() when ocr != null:
return ocr(_that);case PdfFailure() when pdf != null:
return pdf(_that);case StorageFullFailure() when storageFull != null:
return storageFull(_that);case ImportFailure() when import != null:
return import(_that);case ExportFailure() when export != null:
return export(_that);case AuthFailure() when auth != null:
return auth(_that);case NotFoundFailure() when notFound != null:
return notFound(_that);case CorruptFileFailure() when corruptFile != null:
return corruptFile(_that);case SecureStorageFailure() when secureStorageUnavailable != null:
return secureStorageUnavailable(_that);case StorageFailure() when storage != null:
return storage(_that);case CancelledFailure() when cancelled != null:
return cancelled(_that);case UnexpectedFailure() when unexpected != null:
return unexpected(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool inUseByAnotherApp,  String? debugDetail)?  camera,TResult Function( PermissionKind kind,  bool permanentlyDenied,  String? debugDetail)?  permission,TResult Function( String? debugDetail)?  ocr,TResult Function( String? debugDetail)?  pdf,TResult Function( String? debugDetail)?  storageFull,TResult Function( bool unsupportedType,  String? debugDetail)?  import,TResult Function( bool noReceivingApp,  String? debugDetail)?  export,TResult Function( bool rejected,  bool notEnrolled,  String? debugDetail)?  auth,TResult Function( String? debugDetail)?  notFound,TResult Function( String? debugDetail)?  corruptFile,TResult Function( String? debugDetail)?  secureStorageUnavailable,TResult Function( String? debugDetail)?  storage,TResult Function()?  cancelled,TResult Function( String? debugDetail)?  unexpected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CameraFailure() when camera != null:
return camera(_that.inUseByAnotherApp,_that.debugDetail);case PermissionFailure() when permission != null:
return permission(_that.kind,_that.permanentlyDenied,_that.debugDetail);case OcrFailure() when ocr != null:
return ocr(_that.debugDetail);case PdfFailure() when pdf != null:
return pdf(_that.debugDetail);case StorageFullFailure() when storageFull != null:
return storageFull(_that.debugDetail);case ImportFailure() when import != null:
return import(_that.unsupportedType,_that.debugDetail);case ExportFailure() when export != null:
return export(_that.noReceivingApp,_that.debugDetail);case AuthFailure() when auth != null:
return auth(_that.rejected,_that.notEnrolled,_that.debugDetail);case NotFoundFailure() when notFound != null:
return notFound(_that.debugDetail);case CorruptFileFailure() when corruptFile != null:
return corruptFile(_that.debugDetail);case SecureStorageFailure() when secureStorageUnavailable != null:
return secureStorageUnavailable(_that.debugDetail);case StorageFailure() when storage != null:
return storage(_that.debugDetail);case CancelledFailure() when cancelled != null:
return cancelled();case UnexpectedFailure() when unexpected != null:
return unexpected(_that.debugDetail);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool inUseByAnotherApp,  String? debugDetail)  camera,required TResult Function( PermissionKind kind,  bool permanentlyDenied,  String? debugDetail)  permission,required TResult Function( String? debugDetail)  ocr,required TResult Function( String? debugDetail)  pdf,required TResult Function( String? debugDetail)  storageFull,required TResult Function( bool unsupportedType,  String? debugDetail)  import,required TResult Function( bool noReceivingApp,  String? debugDetail)  export,required TResult Function( bool rejected,  bool notEnrolled,  String? debugDetail)  auth,required TResult Function( String? debugDetail)  notFound,required TResult Function( String? debugDetail)  corruptFile,required TResult Function( String? debugDetail)  secureStorageUnavailable,required TResult Function( String? debugDetail)  storage,required TResult Function()  cancelled,required TResult Function( String? debugDetail)  unexpected,}) {final _that = this;
switch (_that) {
case CameraFailure():
return camera(_that.inUseByAnotherApp,_that.debugDetail);case PermissionFailure():
return permission(_that.kind,_that.permanentlyDenied,_that.debugDetail);case OcrFailure():
return ocr(_that.debugDetail);case PdfFailure():
return pdf(_that.debugDetail);case StorageFullFailure():
return storageFull(_that.debugDetail);case ImportFailure():
return import(_that.unsupportedType,_that.debugDetail);case ExportFailure():
return export(_that.noReceivingApp,_that.debugDetail);case AuthFailure():
return auth(_that.rejected,_that.notEnrolled,_that.debugDetail);case NotFoundFailure():
return notFound(_that.debugDetail);case CorruptFileFailure():
return corruptFile(_that.debugDetail);case SecureStorageFailure():
return secureStorageUnavailable(_that.debugDetail);case StorageFailure():
return storage(_that.debugDetail);case CancelledFailure():
return cancelled();case UnexpectedFailure():
return unexpected(_that.debugDetail);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool inUseByAnotherApp,  String? debugDetail)?  camera,TResult? Function( PermissionKind kind,  bool permanentlyDenied,  String? debugDetail)?  permission,TResult? Function( String? debugDetail)?  ocr,TResult? Function( String? debugDetail)?  pdf,TResult? Function( String? debugDetail)?  storageFull,TResult? Function( bool unsupportedType,  String? debugDetail)?  import,TResult? Function( bool noReceivingApp,  String? debugDetail)?  export,TResult? Function( bool rejected,  bool notEnrolled,  String? debugDetail)?  auth,TResult? Function( String? debugDetail)?  notFound,TResult? Function( String? debugDetail)?  corruptFile,TResult? Function( String? debugDetail)?  secureStorageUnavailable,TResult? Function( String? debugDetail)?  storage,TResult? Function()?  cancelled,TResult? Function( String? debugDetail)?  unexpected,}) {final _that = this;
switch (_that) {
case CameraFailure() when camera != null:
return camera(_that.inUseByAnotherApp,_that.debugDetail);case PermissionFailure() when permission != null:
return permission(_that.kind,_that.permanentlyDenied,_that.debugDetail);case OcrFailure() when ocr != null:
return ocr(_that.debugDetail);case PdfFailure() when pdf != null:
return pdf(_that.debugDetail);case StorageFullFailure() when storageFull != null:
return storageFull(_that.debugDetail);case ImportFailure() when import != null:
return import(_that.unsupportedType,_that.debugDetail);case ExportFailure() when export != null:
return export(_that.noReceivingApp,_that.debugDetail);case AuthFailure() when auth != null:
return auth(_that.rejected,_that.notEnrolled,_that.debugDetail);case NotFoundFailure() when notFound != null:
return notFound(_that.debugDetail);case CorruptFileFailure() when corruptFile != null:
return corruptFile(_that.debugDetail);case SecureStorageFailure() when secureStorageUnavailable != null:
return secureStorageUnavailable(_that.debugDetail);case StorageFailure() when storage != null:
return storage(_that.debugDetail);case CancelledFailure() when cancelled != null:
return cancelled();case UnexpectedFailure() when unexpected != null:
return unexpected(_that.debugDetail);case _:
  return null;

}
}

}

/// @nodoc


class CameraFailure extends Failure {
  const CameraFailure({this.inUseByAnotherApp = false, this.debugDetail}): super._();
  

/// True when another application currently holds the camera.
@JsonKey() final  bool inUseByAnotherApp;
 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CameraFailureCopyWith<CameraFailure> get copyWith => _$CameraFailureCopyWithImpl<CameraFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CameraFailure&&(identical(other.inUseByAnotherApp, inUseByAnotherApp) || other.inUseByAnotherApp == inUseByAnotherApp)&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,inUseByAnotherApp,debugDetail);

@override
String toString() {
  return 'Failure.camera(inUseByAnotherApp: $inUseByAnotherApp, debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $CameraFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $CameraFailureCopyWith(CameraFailure value, $Res Function(CameraFailure) _then) = _$CameraFailureCopyWithImpl;
@useResult
$Res call({
 bool inUseByAnotherApp, String? debugDetail
});




}
/// @nodoc
class _$CameraFailureCopyWithImpl<$Res>
    implements $CameraFailureCopyWith<$Res> {
  _$CameraFailureCopyWithImpl(this._self, this._then);

  final CameraFailure _self;
  final $Res Function(CameraFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? inUseByAnotherApp = null,Object? debugDetail = freezed,}) {
  return _then(CameraFailure(
inUseByAnotherApp: null == inUseByAnotherApp ? _self.inUseByAnotherApp : inUseByAnotherApp // ignore: cast_nullable_to_non_nullable
as bool,debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PermissionFailure extends Failure {
  const PermissionFailure({required this.kind, this.permanentlyDenied = false, this.debugDetail}): super._();
  

 final  PermissionKind kind;
/// True when the user chose "don't ask again", so only the system settings
/// screen can resolve it. This is the difference between offering a retry
/// and offering to open settings.
@JsonKey() final  bool permanentlyDenied;
 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PermissionFailureCopyWith<PermissionFailure> get copyWith => _$PermissionFailureCopyWithImpl<PermissionFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PermissionFailure&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.permanentlyDenied, permanentlyDenied) || other.permanentlyDenied == permanentlyDenied)&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,kind,permanentlyDenied,debugDetail);

@override
String toString() {
  return 'Failure.permission(kind: $kind, permanentlyDenied: $permanentlyDenied, debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $PermissionFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $PermissionFailureCopyWith(PermissionFailure value, $Res Function(PermissionFailure) _then) = _$PermissionFailureCopyWithImpl;
@useResult
$Res call({
 PermissionKind kind, bool permanentlyDenied, String? debugDetail
});




}
/// @nodoc
class _$PermissionFailureCopyWithImpl<$Res>
    implements $PermissionFailureCopyWith<$Res> {
  _$PermissionFailureCopyWithImpl(this._self, this._then);

  final PermissionFailure _self;
  final $Res Function(PermissionFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? permanentlyDenied = null,Object? debugDetail = freezed,}) {
  return _then(PermissionFailure(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PermissionKind,permanentlyDenied: null == permanentlyDenied ? _self.permanentlyDenied : permanentlyDenied // ignore: cast_nullable_to_non_nullable
as bool,debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class OcrFailure extends Failure {
  const OcrFailure({this.debugDetail}): super._();
  

 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OcrFailureCopyWith<OcrFailure> get copyWith => _$OcrFailureCopyWithImpl<OcrFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OcrFailure&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,debugDetail);

@override
String toString() {
  return 'Failure.ocr(debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $OcrFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $OcrFailureCopyWith(OcrFailure value, $Res Function(OcrFailure) _then) = _$OcrFailureCopyWithImpl;
@useResult
$Res call({
 String? debugDetail
});




}
/// @nodoc
class _$OcrFailureCopyWithImpl<$Res>
    implements $OcrFailureCopyWith<$Res> {
  _$OcrFailureCopyWithImpl(this._self, this._then);

  final OcrFailure _self;
  final $Res Function(OcrFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? debugDetail = freezed,}) {
  return _then(OcrFailure(
debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PdfFailure extends Failure {
  const PdfFailure({this.debugDetail}): super._();
  

 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfFailureCopyWith<PdfFailure> get copyWith => _$PdfFailureCopyWithImpl<PdfFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfFailure&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,debugDetail);

@override
String toString() {
  return 'Failure.pdf(debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $PdfFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $PdfFailureCopyWith(PdfFailure value, $Res Function(PdfFailure) _then) = _$PdfFailureCopyWithImpl;
@useResult
$Res call({
 String? debugDetail
});




}
/// @nodoc
class _$PdfFailureCopyWithImpl<$Res>
    implements $PdfFailureCopyWith<$Res> {
  _$PdfFailureCopyWithImpl(this._self, this._then);

  final PdfFailure _self;
  final $Res Function(PdfFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? debugDetail = freezed,}) {
  return _then(PdfFailure(
debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class StorageFullFailure extends Failure {
  const StorageFullFailure({this.debugDetail}): super._();
  

 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorageFullFailureCopyWith<StorageFullFailure> get copyWith => _$StorageFullFailureCopyWithImpl<StorageFullFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageFullFailure&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,debugDetail);

@override
String toString() {
  return 'Failure.storageFull(debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $StorageFullFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $StorageFullFailureCopyWith(StorageFullFailure value, $Res Function(StorageFullFailure) _then) = _$StorageFullFailureCopyWithImpl;
@useResult
$Res call({
 String? debugDetail
});




}
/// @nodoc
class _$StorageFullFailureCopyWithImpl<$Res>
    implements $StorageFullFailureCopyWith<$Res> {
  _$StorageFullFailureCopyWithImpl(this._self, this._then);

  final StorageFullFailure _self;
  final $Res Function(StorageFullFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? debugDetail = freezed,}) {
  return _then(StorageFullFailure(
debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ImportFailure extends Failure {
  const ImportFailure({this.unsupportedType = false, this.debugDetail}): super._();
  

/// True when the selected file is neither a supported image nor a PDF.
@JsonKey() final  bool unsupportedType;
 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportFailureCopyWith<ImportFailure> get copyWith => _$ImportFailureCopyWithImpl<ImportFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportFailure&&(identical(other.unsupportedType, unsupportedType) || other.unsupportedType == unsupportedType)&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,unsupportedType,debugDetail);

@override
String toString() {
  return 'Failure.import(unsupportedType: $unsupportedType, debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $ImportFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ImportFailureCopyWith(ImportFailure value, $Res Function(ImportFailure) _then) = _$ImportFailureCopyWithImpl;
@useResult
$Res call({
 bool unsupportedType, String? debugDetail
});




}
/// @nodoc
class _$ImportFailureCopyWithImpl<$Res>
    implements $ImportFailureCopyWith<$Res> {
  _$ImportFailureCopyWithImpl(this._self, this._then);

  final ImportFailure _self;
  final $Res Function(ImportFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? unsupportedType = null,Object? debugDetail = freezed,}) {
  return _then(ImportFailure(
unsupportedType: null == unsupportedType ? _self.unsupportedType : unsupportedType // ignore: cast_nullable_to_non_nullable
as bool,debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ExportFailure extends Failure {
  const ExportFailure({this.noReceivingApp = false, this.debugDetail}): super._();
  

/// True when the system reported that nothing can receive the shared
/// content, which the specs answer by offering export instead.
@JsonKey() final  bool noReceivingApp;
 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExportFailureCopyWith<ExportFailure> get copyWith => _$ExportFailureCopyWithImpl<ExportFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportFailure&&(identical(other.noReceivingApp, noReceivingApp) || other.noReceivingApp == noReceivingApp)&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,noReceivingApp,debugDetail);

@override
String toString() {
  return 'Failure.export(noReceivingApp: $noReceivingApp, debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $ExportFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ExportFailureCopyWith(ExportFailure value, $Res Function(ExportFailure) _then) = _$ExportFailureCopyWithImpl;
@useResult
$Res call({
 bool noReceivingApp, String? debugDetail
});




}
/// @nodoc
class _$ExportFailureCopyWithImpl<$Res>
    implements $ExportFailureCopyWith<$Res> {
  _$ExportFailureCopyWithImpl(this._self, this._then);

  final ExportFailure _self;
  final $Res Function(ExportFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? noReceivingApp = null,Object? debugDetail = freezed,}) {
  return _then(ExportFailure(
noReceivingApp: null == noReceivingApp ? _self.noReceivingApp : noReceivingApp // ignore: cast_nullable_to_non_nullable
as bool,debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class AuthFailure extends Failure {
  const AuthFailure({this.rejected = true, this.notEnrolled = false, this.debugDetail}): super._();
  

/// True when the user was rejected, false when the mechanism itself errored.
@JsonKey() final  bool rejected;
/// True when the device has no biometric or device credential configured.
@JsonKey() final  bool notEnrolled;
 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthFailureCopyWith<AuthFailure> get copyWith => _$AuthFailureCopyWithImpl<AuthFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthFailure&&(identical(other.rejected, rejected) || other.rejected == rejected)&&(identical(other.notEnrolled, notEnrolled) || other.notEnrolled == notEnrolled)&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,rejected,notEnrolled,debugDetail);

@override
String toString() {
  return 'Failure.auth(rejected: $rejected, notEnrolled: $notEnrolled, debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $AuthFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $AuthFailureCopyWith(AuthFailure value, $Res Function(AuthFailure) _then) = _$AuthFailureCopyWithImpl;
@useResult
$Res call({
 bool rejected, bool notEnrolled, String? debugDetail
});




}
/// @nodoc
class _$AuthFailureCopyWithImpl<$Res>
    implements $AuthFailureCopyWith<$Res> {
  _$AuthFailureCopyWithImpl(this._self, this._then);

  final AuthFailure _self;
  final $Res Function(AuthFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rejected = null,Object? notEnrolled = null,Object? debugDetail = freezed,}) {
  return _then(AuthFailure(
rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as bool,notEnrolled: null == notEnrolled ? _self.notEnrolled : notEnrolled // ignore: cast_nullable_to_non_nullable
as bool,debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class NotFoundFailure extends Failure {
  const NotFoundFailure({this.debugDetail}): super._();
  

 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotFoundFailureCopyWith<NotFoundFailure> get copyWith => _$NotFoundFailureCopyWithImpl<NotFoundFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotFoundFailure&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,debugDetail);

@override
String toString() {
  return 'Failure.notFound(debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $NotFoundFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $NotFoundFailureCopyWith(NotFoundFailure value, $Res Function(NotFoundFailure) _then) = _$NotFoundFailureCopyWithImpl;
@useResult
$Res call({
 String? debugDetail
});




}
/// @nodoc
class _$NotFoundFailureCopyWithImpl<$Res>
    implements $NotFoundFailureCopyWith<$Res> {
  _$NotFoundFailureCopyWithImpl(this._self, this._then);

  final NotFoundFailure _self;
  final $Res Function(NotFoundFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? debugDetail = freezed,}) {
  return _then(NotFoundFailure(
debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class CorruptFileFailure extends Failure {
  const CorruptFileFailure({this.debugDetail}): super._();
  

 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CorruptFileFailureCopyWith<CorruptFileFailure> get copyWith => _$CorruptFileFailureCopyWithImpl<CorruptFileFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CorruptFileFailure&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,debugDetail);

@override
String toString() {
  return 'Failure.corruptFile(debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $CorruptFileFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $CorruptFileFailureCopyWith(CorruptFileFailure value, $Res Function(CorruptFileFailure) _then) = _$CorruptFileFailureCopyWithImpl;
@useResult
$Res call({
 String? debugDetail
});




}
/// @nodoc
class _$CorruptFileFailureCopyWithImpl<$Res>
    implements $CorruptFileFailureCopyWith<$Res> {
  _$CorruptFileFailureCopyWithImpl(this._self, this._then);

  final CorruptFileFailure _self;
  final $Res Function(CorruptFileFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? debugDetail = freezed,}) {
  return _then(CorruptFileFailure(
debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class SecureStorageFailure extends Failure {
  const SecureStorageFailure({this.debugDetail}): super._();
  

 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecureStorageFailureCopyWith<SecureStorageFailure> get copyWith => _$SecureStorageFailureCopyWithImpl<SecureStorageFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecureStorageFailure&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,debugDetail);

@override
String toString() {
  return 'Failure.secureStorageUnavailable(debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $SecureStorageFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $SecureStorageFailureCopyWith(SecureStorageFailure value, $Res Function(SecureStorageFailure) _then) = _$SecureStorageFailureCopyWithImpl;
@useResult
$Res call({
 String? debugDetail
});




}
/// @nodoc
class _$SecureStorageFailureCopyWithImpl<$Res>
    implements $SecureStorageFailureCopyWith<$Res> {
  _$SecureStorageFailureCopyWithImpl(this._self, this._then);

  final SecureStorageFailure _self;
  final $Res Function(SecureStorageFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? debugDetail = freezed,}) {
  return _then(SecureStorageFailure(
debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class StorageFailure extends Failure {
  const StorageFailure({this.debugDetail}): super._();
  

 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorageFailureCopyWith<StorageFailure> get copyWith => _$StorageFailureCopyWithImpl<StorageFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageFailure&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,debugDetail);

@override
String toString() {
  return 'Failure.storage(debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $StorageFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $StorageFailureCopyWith(StorageFailure value, $Res Function(StorageFailure) _then) = _$StorageFailureCopyWithImpl;
@useResult
$Res call({
 String? debugDetail
});




}
/// @nodoc
class _$StorageFailureCopyWithImpl<$Res>
    implements $StorageFailureCopyWith<$Res> {
  _$StorageFailureCopyWithImpl(this._self, this._then);

  final StorageFailure _self;
  final $Res Function(StorageFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? debugDetail = freezed,}) {
  return _then(StorageFailure(
debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class CancelledFailure extends Failure {
  const CancelledFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CancelledFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.cancelled()';
}


}




/// @nodoc


class UnexpectedFailure extends Failure {
  const UnexpectedFailure({this.debugDetail}): super._();
  

 final  String? debugDetail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnexpectedFailureCopyWith<UnexpectedFailure> get copyWith => _$UnexpectedFailureCopyWithImpl<UnexpectedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnexpectedFailure&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,debugDetail);

@override
String toString() {
  return 'Failure.unexpected(debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $UnexpectedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $UnexpectedFailureCopyWith(UnexpectedFailure value, $Res Function(UnexpectedFailure) _then) = _$UnexpectedFailureCopyWithImpl;
@useResult
$Res call({
 String? debugDetail
});




}
/// @nodoc
class _$UnexpectedFailureCopyWithImpl<$Res>
    implements $UnexpectedFailureCopyWith<$Res> {
  _$UnexpectedFailureCopyWithImpl(this._self, this._then);

  final UnexpectedFailure _self;
  final $Res Function(UnexpectedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? debugDetail = freezed,}) {
  return _then(UnexpectedFailure(
debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
