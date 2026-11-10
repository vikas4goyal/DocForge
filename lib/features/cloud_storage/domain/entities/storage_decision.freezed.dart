// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'storage_decision.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StorageDecision {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageDecision);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StorageDecision()';
}


}

/// @nodoc
class $StorageDecisionCopyWith<$Res>  {
$StorageDecisionCopyWith(StorageDecision _, $Res Function(StorageDecision) __);
}


/// Adds pattern-matching-related methods to [StorageDecision].
extension StorageDecisionPatterns on StorageDecision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UseICloud value)?  useICloud,TResult Function( MigrateToICloud value)?  migrateToICloud,TResult Function( UseLocal value)?  useLocal,TResult Function( ICloudUnavailable value)?  iCloudUnavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UseICloud() when useICloud != null:
return useICloud(_that);case MigrateToICloud() when migrateToICloud != null:
return migrateToICloud(_that);case UseLocal() when useLocal != null:
return useLocal(_that);case ICloudUnavailable() when iCloudUnavailable != null:
return iCloudUnavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UseICloud value)  useICloud,required TResult Function( MigrateToICloud value)  migrateToICloud,required TResult Function( UseLocal value)  useLocal,required TResult Function( ICloudUnavailable value)  iCloudUnavailable,}){
final _that = this;
switch (_that) {
case UseICloud():
return useICloud(_that);case MigrateToICloud():
return migrateToICloud(_that);case UseLocal():
return useLocal(_that);case ICloudUnavailable():
return iCloudUnavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UseICloud value)?  useICloud,TResult? Function( MigrateToICloud value)?  migrateToICloud,TResult? Function( UseLocal value)?  useLocal,TResult? Function( ICloudUnavailable value)?  iCloudUnavailable,}){
final _that = this;
switch (_that) {
case UseICloud() when useICloud != null:
return useICloud(_that);case MigrateToICloud() when migrateToICloud != null:
return migrateToICloud(_that);case UseLocal() when useLocal != null:
return useLocal(_that);case ICloudUnavailable() when iCloudUnavailable != null:
return iCloudUnavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool writeMarker)?  useICloud,TResult Function( StorageMigrationCheckpoint? resume)?  migrateToICloud,TResult Function( CloudAvailabilityStatus reason)?  useLocal,TResult Function( CloudAvailabilityStatus reason)?  iCloudUnavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UseICloud() when useICloud != null:
return useICloud(_that.writeMarker);case MigrateToICloud() when migrateToICloud != null:
return migrateToICloud(_that.resume);case UseLocal() when useLocal != null:
return useLocal(_that.reason);case ICloudUnavailable() when iCloudUnavailable != null:
return iCloudUnavailable(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool writeMarker)  useICloud,required TResult Function( StorageMigrationCheckpoint? resume)  migrateToICloud,required TResult Function( CloudAvailabilityStatus reason)  useLocal,required TResult Function( CloudAvailabilityStatus reason)  iCloudUnavailable,}) {final _that = this;
switch (_that) {
case UseICloud():
return useICloud(_that.writeMarker);case MigrateToICloud():
return migrateToICloud(_that.resume);case UseLocal():
return useLocal(_that.reason);case ICloudUnavailable():
return iCloudUnavailable(_that.reason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool writeMarker)?  useICloud,TResult? Function( StorageMigrationCheckpoint? resume)?  migrateToICloud,TResult? Function( CloudAvailabilityStatus reason)?  useLocal,TResult? Function( CloudAvailabilityStatus reason)?  iCloudUnavailable,}) {final _that = this;
switch (_that) {
case UseICloud() when useICloud != null:
return useICloud(_that.writeMarker);case MigrateToICloud() when migrateToICloud != null:
return migrateToICloud(_that.resume);case UseLocal() when useLocal != null:
return useLocal(_that.reason);case ICloudUnavailable() when iCloudUnavailable != null:
return iCloudUnavailable(_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class UseICloud implements StorageDecision {
  const UseICloud({this.writeMarker = false});
  

@JsonKey() final  bool writeMarker;

/// Create a copy of StorageDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UseICloudCopyWith<UseICloud> get copyWith => _$UseICloudCopyWithImpl<UseICloud>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UseICloud&&(identical(other.writeMarker, writeMarker) || other.writeMarker == writeMarker));
}


@override
int get hashCode => Object.hash(runtimeType,writeMarker);

@override
String toString() {
  return 'StorageDecision.useICloud(writeMarker: $writeMarker)';
}


}

/// @nodoc
abstract mixin class $UseICloudCopyWith<$Res> implements $StorageDecisionCopyWith<$Res> {
  factory $UseICloudCopyWith(UseICloud value, $Res Function(UseICloud) _then) = _$UseICloudCopyWithImpl;
@useResult
$Res call({
 bool writeMarker
});




}
/// @nodoc
class _$UseICloudCopyWithImpl<$Res>
    implements $UseICloudCopyWith<$Res> {
  _$UseICloudCopyWithImpl(this._self, this._then);

  final UseICloud _self;
  final $Res Function(UseICloud) _then;

/// Create a copy of StorageDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? writeMarker = null,}) {
  return _then(UseICloud(
writeMarker: null == writeMarker ? _self.writeMarker : writeMarker // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class MigrateToICloud implements StorageDecision {
  const MigrateToICloud({this.resume});
  

 final  StorageMigrationCheckpoint? resume;

/// Create a copy of StorageDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MigrateToICloudCopyWith<MigrateToICloud> get copyWith => _$MigrateToICloudCopyWithImpl<MigrateToICloud>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MigrateToICloud&&(identical(other.resume, resume) || other.resume == resume));
}


@override
int get hashCode => Object.hash(runtimeType,resume);

@override
String toString() {
  return 'StorageDecision.migrateToICloud(resume: $resume)';
}


}

/// @nodoc
abstract mixin class $MigrateToICloudCopyWith<$Res> implements $StorageDecisionCopyWith<$Res> {
  factory $MigrateToICloudCopyWith(MigrateToICloud value, $Res Function(MigrateToICloud) _then) = _$MigrateToICloudCopyWithImpl;
@useResult
$Res call({
 StorageMigrationCheckpoint? resume
});




}
/// @nodoc
class _$MigrateToICloudCopyWithImpl<$Res>
    implements $MigrateToICloudCopyWith<$Res> {
  _$MigrateToICloudCopyWithImpl(this._self, this._then);

  final MigrateToICloud _self;
  final $Res Function(MigrateToICloud) _then;

/// Create a copy of StorageDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? resume = freezed,}) {
  return _then(MigrateToICloud(
resume: freezed == resume ? _self.resume : resume // ignore: cast_nullable_to_non_nullable
as StorageMigrationCheckpoint?,
  ));
}


}

/// @nodoc


class UseLocal implements StorageDecision {
  const UseLocal({required this.reason});
  

 final  CloudAvailabilityStatus reason;

/// Create a copy of StorageDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UseLocalCopyWith<UseLocal> get copyWith => _$UseLocalCopyWithImpl<UseLocal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UseLocal&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'StorageDecision.useLocal(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $UseLocalCopyWith<$Res> implements $StorageDecisionCopyWith<$Res> {
  factory $UseLocalCopyWith(UseLocal value, $Res Function(UseLocal) _then) = _$UseLocalCopyWithImpl;
@useResult
$Res call({
 CloudAvailabilityStatus reason
});




}
/// @nodoc
class _$UseLocalCopyWithImpl<$Res>
    implements $UseLocalCopyWith<$Res> {
  _$UseLocalCopyWithImpl(this._self, this._then);

  final UseLocal _self;
  final $Res Function(UseLocal) _then;

/// Create a copy of StorageDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(UseLocal(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as CloudAvailabilityStatus,
  ));
}


}

/// @nodoc


class ICloudUnavailable implements StorageDecision {
  const ICloudUnavailable({required this.reason});
  

 final  CloudAvailabilityStatus reason;

/// Create a copy of StorageDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ICloudUnavailableCopyWith<ICloudUnavailable> get copyWith => _$ICloudUnavailableCopyWithImpl<ICloudUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ICloudUnavailable&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'StorageDecision.iCloudUnavailable(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $ICloudUnavailableCopyWith<$Res> implements $StorageDecisionCopyWith<$Res> {
  factory $ICloudUnavailableCopyWith(ICloudUnavailable value, $Res Function(ICloudUnavailable) _then) = _$ICloudUnavailableCopyWithImpl;
@useResult
$Res call({
 CloudAvailabilityStatus reason
});




}
/// @nodoc
class _$ICloudUnavailableCopyWithImpl<$Res>
    implements $ICloudUnavailableCopyWith<$Res> {
  _$ICloudUnavailableCopyWithImpl(this._self, this._then);

  final ICloudUnavailable _self;
  final $Res Function(ICloudUnavailable) _then;

/// Create a copy of StorageDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(ICloudUnavailable(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as CloudAvailabilityStatus,
  ));
}


}

// dart format on
