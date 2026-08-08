// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pdf_jobs.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PdfCandidateFingerprint {

 String get sourceIdentity; String get configurationIdentity; List<int> get orderedPageQualities; bool get isProtected;
/// Create a copy of PdfCandidateFingerprint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfCandidateFingerprintCopyWith<PdfCandidateFingerprint> get copyWith => _$PdfCandidateFingerprintCopyWithImpl<PdfCandidateFingerprint>(this as PdfCandidateFingerprint, _$identity);

  /// Serializes this PdfCandidateFingerprint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfCandidateFingerprint&&(identical(other.sourceIdentity, sourceIdentity) || other.sourceIdentity == sourceIdentity)&&(identical(other.configurationIdentity, configurationIdentity) || other.configurationIdentity == configurationIdentity)&&const DeepCollectionEquality().equals(other.orderedPageQualities, orderedPageQualities)&&(identical(other.isProtected, isProtected) || other.isProtected == isProtected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sourceIdentity,configurationIdentity,const DeepCollectionEquality().hash(orderedPageQualities),isProtected);

@override
String toString() {
  return 'PdfCandidateFingerprint(sourceIdentity: $sourceIdentity, configurationIdentity: $configurationIdentity, orderedPageQualities: $orderedPageQualities, isProtected: $isProtected)';
}


}

/// @nodoc
abstract mixin class $PdfCandidateFingerprintCopyWith<$Res>  {
  factory $PdfCandidateFingerprintCopyWith(PdfCandidateFingerprint value, $Res Function(PdfCandidateFingerprint) _then) = _$PdfCandidateFingerprintCopyWithImpl;
@useResult
$Res call({
 String sourceIdentity, String configurationIdentity, List<int> orderedPageQualities, bool isProtected
});




}
/// @nodoc
class _$PdfCandidateFingerprintCopyWithImpl<$Res>
    implements $PdfCandidateFingerprintCopyWith<$Res> {
  _$PdfCandidateFingerprintCopyWithImpl(this._self, this._then);

  final PdfCandidateFingerprint _self;
  final $Res Function(PdfCandidateFingerprint) _then;

/// Create a copy of PdfCandidateFingerprint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceIdentity = null,Object? configurationIdentity = null,Object? orderedPageQualities = null,Object? isProtected = null,}) {
  return _then(_self.copyWith(
sourceIdentity: null == sourceIdentity ? _self.sourceIdentity : sourceIdentity // ignore: cast_nullable_to_non_nullable
as String,configurationIdentity: null == configurationIdentity ? _self.configurationIdentity : configurationIdentity // ignore: cast_nullable_to_non_nullable
as String,orderedPageQualities: null == orderedPageQualities ? _self.orderedPageQualities : orderedPageQualities // ignore: cast_nullable_to_non_nullable
as List<int>,isProtected: null == isProtected ? _self.isProtected : isProtected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PdfCandidateFingerprint].
extension PdfCandidateFingerprintPatterns on PdfCandidateFingerprint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PdfCandidateFingerprint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PdfCandidateFingerprint() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PdfCandidateFingerprint value)  $default,){
final _that = this;
switch (_that) {
case _PdfCandidateFingerprint():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PdfCandidateFingerprint value)?  $default,){
final _that = this;
switch (_that) {
case _PdfCandidateFingerprint() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sourceIdentity,  String configurationIdentity,  List<int> orderedPageQualities,  bool isProtected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PdfCandidateFingerprint() when $default != null:
return $default(_that.sourceIdentity,_that.configurationIdentity,_that.orderedPageQualities,_that.isProtected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sourceIdentity,  String configurationIdentity,  List<int> orderedPageQualities,  bool isProtected)  $default,) {final _that = this;
switch (_that) {
case _PdfCandidateFingerprint():
return $default(_that.sourceIdentity,_that.configurationIdentity,_that.orderedPageQualities,_that.isProtected);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sourceIdentity,  String configurationIdentity,  List<int> orderedPageQualities,  bool isProtected)?  $default,) {final _that = this;
switch (_that) {
case _PdfCandidateFingerprint() when $default != null:
return $default(_that.sourceIdentity,_that.configurationIdentity,_that.orderedPageQualities,_that.isProtected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PdfCandidateFingerprint implements PdfCandidateFingerprint {
  const _PdfCandidateFingerprint({required this.sourceIdentity, required this.configurationIdentity, required final  List<int> orderedPageQualities, required this.isProtected}): _orderedPageQualities = orderedPageQualities;
  factory _PdfCandidateFingerprint.fromJson(Map<String, dynamic> json) => _$PdfCandidateFingerprintFromJson(json);

@override final  String sourceIdentity;
@override final  String configurationIdentity;
 final  List<int> _orderedPageQualities;
@override List<int> get orderedPageQualities {
  if (_orderedPageQualities is EqualUnmodifiableListView) return _orderedPageQualities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orderedPageQualities);
}

@override final  bool isProtected;

/// Create a copy of PdfCandidateFingerprint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PdfCandidateFingerprintCopyWith<_PdfCandidateFingerprint> get copyWith => __$PdfCandidateFingerprintCopyWithImpl<_PdfCandidateFingerprint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PdfCandidateFingerprintToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PdfCandidateFingerprint&&(identical(other.sourceIdentity, sourceIdentity) || other.sourceIdentity == sourceIdentity)&&(identical(other.configurationIdentity, configurationIdentity) || other.configurationIdentity == configurationIdentity)&&const DeepCollectionEquality().equals(other._orderedPageQualities, _orderedPageQualities)&&(identical(other.isProtected, isProtected) || other.isProtected == isProtected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sourceIdentity,configurationIdentity,const DeepCollectionEquality().hash(_orderedPageQualities),isProtected);

@override
String toString() {
  return 'PdfCandidateFingerprint(sourceIdentity: $sourceIdentity, configurationIdentity: $configurationIdentity, orderedPageQualities: $orderedPageQualities, isProtected: $isProtected)';
}


}

/// @nodoc
abstract mixin class _$PdfCandidateFingerprintCopyWith<$Res> implements $PdfCandidateFingerprintCopyWith<$Res> {
  factory _$PdfCandidateFingerprintCopyWith(_PdfCandidateFingerprint value, $Res Function(_PdfCandidateFingerprint) _then) = __$PdfCandidateFingerprintCopyWithImpl;
@override @useResult
$Res call({
 String sourceIdentity, String configurationIdentity, List<int> orderedPageQualities, bool isProtected
});




}
/// @nodoc
class __$PdfCandidateFingerprintCopyWithImpl<$Res>
    implements _$PdfCandidateFingerprintCopyWith<$Res> {
  __$PdfCandidateFingerprintCopyWithImpl(this._self, this._then);

  final _PdfCandidateFingerprint _self;
  final $Res Function(_PdfCandidateFingerprint) _then;

/// Create a copy of PdfCandidateFingerprint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceIdentity = null,Object? configurationIdentity = null,Object? orderedPageQualities = null,Object? isProtected = null,}) {
  return _then(_PdfCandidateFingerprint(
sourceIdentity: null == sourceIdentity ? _self.sourceIdentity : sourceIdentity // ignore: cast_nullable_to_non_nullable
as String,configurationIdentity: null == configurationIdentity ? _self.configurationIdentity : configurationIdentity // ignore: cast_nullable_to_non_nullable
as String,orderedPageQualities: null == orderedPageQualities ? _self._orderedPageQualities : orderedPageQualities // ignore: cast_nullable_to_non_nullable
as List<int>,isProtected: null == isProtected ? _self.isProtected : isProtected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PdfCandidate {

 String get handle; int get exactBytes; int get pageCount; PdfCandidateFingerprint get fingerprint;
/// Create a copy of PdfCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfCandidateCopyWith<PdfCandidate> get copyWith => _$PdfCandidateCopyWithImpl<PdfCandidate>(this as PdfCandidate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfCandidate&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.exactBytes, exactBytes) || other.exactBytes == exactBytes)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,handle,exactBytes,pageCount,fingerprint);

@override
String toString() {
  return 'PdfCandidate(handle: $handle, exactBytes: $exactBytes, pageCount: $pageCount, fingerprint: $fingerprint)';
}


}

/// @nodoc
abstract mixin class $PdfCandidateCopyWith<$Res>  {
  factory $PdfCandidateCopyWith(PdfCandidate value, $Res Function(PdfCandidate) _then) = _$PdfCandidateCopyWithImpl;
@useResult
$Res call({
 String handle, int exactBytes, int pageCount, PdfCandidateFingerprint fingerprint
});




}
/// @nodoc
class _$PdfCandidateCopyWithImpl<$Res>
    implements $PdfCandidateCopyWith<$Res> {
  _$PdfCandidateCopyWithImpl(this._self, this._then);

  final PdfCandidate _self;
  final $Res Function(PdfCandidate) _then;

/// Create a copy of PdfCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? handle = null,Object? exactBytes = null,Object? pageCount = null,Object? fingerprint = null,}) {
  return _then(PdfCandidate(
handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String,exactBytes: null == exactBytes ? _self.exactBytes : exactBytes // ignore: cast_nullable_to_non_nullable
as int,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as PdfCandidateFingerprint,
  ));
}

}


/// Adds pattern-matching-related methods to [PdfCandidate].
extension PdfCandidatePatterns on PdfCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}


/// @nodoc
mixin _$JobProgress {

 int get percent;
/// Create a copy of JobProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobProgressCopyWith<JobProgress> get copyWith => _$JobProgressCopyWithImpl<JobProgress>(this as JobProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobProgress&&(identical(other.percent, percent) || other.percent == percent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,percent);

@override
String toString() {
  return 'JobProgress(percent: $percent)';
}


}

/// @nodoc
abstract mixin class $JobProgressCopyWith<$Res>  {
  factory $JobProgressCopyWith(JobProgress value, $Res Function(JobProgress) _then) = _$JobProgressCopyWithImpl;
@useResult
$Res call({
 int percent
});




}
/// @nodoc
class _$JobProgressCopyWithImpl<$Res>
    implements $JobProgressCopyWith<$Res> {
  _$JobProgressCopyWithImpl(this._self, this._then);

  final JobProgress _self;
  final $Res Function(JobProgress) _then;

/// Create a copy of JobProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? percent = null,}) {
  return _then(JobProgress(
percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [JobProgress].
extension JobProgressPatterns on JobProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

/// @nodoc
mixin _$JobResultSummary {

 int get exactBytes; int get pageCount; String? get candidateHandle;
/// Create a copy of JobResultSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobResultSummaryCopyWith<JobResultSummary> get copyWith => _$JobResultSummaryCopyWithImpl<JobResultSummary>(this as JobResultSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobResultSummary&&(identical(other.exactBytes, exactBytes) || other.exactBytes == exactBytes)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.candidateHandle, candidateHandle) || other.candidateHandle == candidateHandle));
}


@override
int get hashCode => Object.hash(runtimeType,exactBytes,pageCount,candidateHandle);

@override
String toString() {
  return 'JobResultSummary(exactBytes: $exactBytes, pageCount: $pageCount, candidateHandle: $candidateHandle)';
}


}

/// @nodoc
abstract mixin class $JobResultSummaryCopyWith<$Res>  {
  factory $JobResultSummaryCopyWith(JobResultSummary value, $Res Function(JobResultSummary) _then) = _$JobResultSummaryCopyWithImpl;
@useResult
$Res call({
 int exactBytes, int pageCount, String? candidateHandle
});




}
/// @nodoc
class _$JobResultSummaryCopyWithImpl<$Res>
    implements $JobResultSummaryCopyWith<$Res> {
  _$JobResultSummaryCopyWithImpl(this._self, this._then);

  final JobResultSummary _self;
  final $Res Function(JobResultSummary) _then;

/// Create a copy of JobResultSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exactBytes = null,Object? pageCount = null,Object? candidateHandle = freezed,}) {
  return _then(_self.copyWith(
exactBytes: null == exactBytes ? _self.exactBytes : exactBytes // ignore: cast_nullable_to_non_nullable
as int,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,candidateHandle: freezed == candidateHandle ? _self.candidateHandle : candidateHandle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [JobResultSummary].
extension JobResultSummaryPatterns on JobResultSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobResultSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobResultSummary() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobResultSummary value)  $default,){
final _that = this;
switch (_that) {
case _JobResultSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobResultSummary value)?  $default,){
final _that = this;
switch (_that) {
case _JobResultSummary() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int exactBytes,  int pageCount,  String? candidateHandle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobResultSummary() when $default != null:
return $default(_that.exactBytes,_that.pageCount,_that.candidateHandle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int exactBytes,  int pageCount,  String? candidateHandle)  $default,) {final _that = this;
switch (_that) {
case _JobResultSummary():
return $default(_that.exactBytes,_that.pageCount,_that.candidateHandle);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int exactBytes,  int pageCount,  String? candidateHandle)?  $default,) {final _that = this;
switch (_that) {
case _JobResultSummary() when $default != null:
return $default(_that.exactBytes,_that.pageCount,_that.candidateHandle);case _:
  return null;

}
}

}

/// @nodoc


class _JobResultSummary implements JobResultSummary {
  const _JobResultSummary({required this.exactBytes, required this.pageCount, this.candidateHandle});
  

@override final  int exactBytes;
@override final  int pageCount;
@override final  String? candidateHandle;

/// Create a copy of JobResultSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobResultSummaryCopyWith<_JobResultSummary> get copyWith => __$JobResultSummaryCopyWithImpl<_JobResultSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobResultSummary&&(identical(other.exactBytes, exactBytes) || other.exactBytes == exactBytes)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.candidateHandle, candidateHandle) || other.candidateHandle == candidateHandle));
}


@override
int get hashCode => Object.hash(runtimeType,exactBytes,pageCount,candidateHandle);

@override
String toString() {
  return 'JobResultSummary(exactBytes: $exactBytes, pageCount: $pageCount, candidateHandle: $candidateHandle)';
}


}

/// @nodoc
abstract mixin class _$JobResultSummaryCopyWith<$Res> implements $JobResultSummaryCopyWith<$Res> {
  factory _$JobResultSummaryCopyWith(_JobResultSummary value, $Res Function(_JobResultSummary) _then) = __$JobResultSummaryCopyWithImpl;
@override @useResult
$Res call({
 int exactBytes, int pageCount, String? candidateHandle
});




}
/// @nodoc
class __$JobResultSummaryCopyWithImpl<$Res>
    implements _$JobResultSummaryCopyWith<$Res> {
  __$JobResultSummaryCopyWithImpl(this._self, this._then);

  final _JobResultSummary _self;
  final $Res Function(_JobResultSummary) _then;

/// Create a copy of JobResultSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exactBytes = null,Object? pageCount = null,Object? candidateHandle = freezed,}) {
  return _then(_JobResultSummary(
exactBytes: null == exactBytes ? _self.exactBytes : exactBytes // ignore: cast_nullable_to_non_nullable
as int,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,candidateHandle: freezed == candidateHandle ? _self.candidateHandle : candidateHandle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AsyncJobView {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AsyncJobView);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AsyncJobView()';
}


}

/// @nodoc
class $AsyncJobViewCopyWith<$Res>  {
$AsyncJobViewCopyWith(AsyncJobView _, $Res Function(AsyncJobView) __);
}


/// Adds pattern-matching-related methods to [AsyncJobView].
extension AsyncJobViewPatterns on AsyncJobView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AsyncJobIdle value)?  idle,TResult Function( AsyncJobQueued value)?  queued,TResult Function( AsyncJobRunning value)?  running,TResult Function( AsyncJobSucceeded value)?  succeeded,TResult Function( AsyncJobCancelled value)?  cancelled,TResult Function( AsyncJobFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AsyncJobIdle() when idle != null:
return idle(_that);case AsyncJobQueued() when queued != null:
return queued(_that);case AsyncJobRunning() when running != null:
return running(_that);case AsyncJobSucceeded() when succeeded != null:
return succeeded(_that);case AsyncJobCancelled() when cancelled != null:
return cancelled(_that);case AsyncJobFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AsyncJobIdle value)  idle,required TResult Function( AsyncJobQueued value)  queued,required TResult Function( AsyncJobRunning value)  running,required TResult Function( AsyncJobSucceeded value)  succeeded,required TResult Function( AsyncJobCancelled value)  cancelled,required TResult Function( AsyncJobFailed value)  failed,}){
final _that = this;
switch (_that) {
case AsyncJobIdle():
return idle(_that);case AsyncJobQueued():
return queued(_that);case AsyncJobRunning():
return running(_that);case AsyncJobSucceeded():
return succeeded(_that);case AsyncJobCancelled():
return cancelled(_that);case AsyncJobFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AsyncJobIdle value)?  idle,TResult? Function( AsyncJobQueued value)?  queued,TResult? Function( AsyncJobRunning value)?  running,TResult? Function( AsyncJobSucceeded value)?  succeeded,TResult? Function( AsyncJobCancelled value)?  cancelled,TResult? Function( AsyncJobFailed value)?  failed,}){
final _that = this;
switch (_that) {
case AsyncJobIdle() when idle != null:
return idle(_that);case AsyncJobQueued() when queued != null:
return queued(_that);case AsyncJobRunning() when running != null:
return running(_that);case AsyncJobSucceeded() when succeeded != null:
return succeeded(_that);case AsyncJobCancelled() when cancelled != null:
return cancelled(_that);case AsyncJobFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( int generation)?  queued,TResult Function( int generation,  JobProgress progress)?  running,TResult Function( int generation,  JobResultSummary summary)?  succeeded,TResult Function( int generation)?  cancelled,TResult Function( int generation,  Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AsyncJobIdle() when idle != null:
return idle();case AsyncJobQueued() when queued != null:
return queued(_that.generation);case AsyncJobRunning() when running != null:
return running(_that.generation,_that.progress);case AsyncJobSucceeded() when succeeded != null:
return succeeded(_that.generation,_that.summary);case AsyncJobCancelled() when cancelled != null:
return cancelled(_that.generation);case AsyncJobFailed() when failed != null:
return failed(_that.generation,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( int generation)  queued,required TResult Function( int generation,  JobProgress progress)  running,required TResult Function( int generation,  JobResultSummary summary)  succeeded,required TResult Function( int generation)  cancelled,required TResult Function( int generation,  Failure failure)  failed,}) {final _that = this;
switch (_that) {
case AsyncJobIdle():
return idle();case AsyncJobQueued():
return queued(_that.generation);case AsyncJobRunning():
return running(_that.generation,_that.progress);case AsyncJobSucceeded():
return succeeded(_that.generation,_that.summary);case AsyncJobCancelled():
return cancelled(_that.generation);case AsyncJobFailed():
return failed(_that.generation,_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( int generation)?  queued,TResult? Function( int generation,  JobProgress progress)?  running,TResult? Function( int generation,  JobResultSummary summary)?  succeeded,TResult? Function( int generation)?  cancelled,TResult? Function( int generation,  Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case AsyncJobIdle() when idle != null:
return idle();case AsyncJobQueued() when queued != null:
return queued(_that.generation);case AsyncJobRunning() when running != null:
return running(_that.generation,_that.progress);case AsyncJobSucceeded() when succeeded != null:
return succeeded(_that.generation,_that.summary);case AsyncJobCancelled() when cancelled != null:
return cancelled(_that.generation);case AsyncJobFailed() when failed != null:
return failed(_that.generation,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class AsyncJobIdle implements AsyncJobView {
  const AsyncJobIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AsyncJobIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AsyncJobView.idle()';
}


}




/// @nodoc


class AsyncJobQueued implements AsyncJobView {
  const AsyncJobQueued({required this.generation});
  

 final  int generation;

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AsyncJobQueuedCopyWith<AsyncJobQueued> get copyWith => _$AsyncJobQueuedCopyWithImpl<AsyncJobQueued>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AsyncJobQueued&&(identical(other.generation, generation) || other.generation == generation));
}


@override
int get hashCode => Object.hash(runtimeType,generation);

@override
String toString() {
  return 'AsyncJobView.queued(generation: $generation)';
}


}

/// @nodoc
abstract mixin class $AsyncJobQueuedCopyWith<$Res> implements $AsyncJobViewCopyWith<$Res> {
  factory $AsyncJobQueuedCopyWith(AsyncJobQueued value, $Res Function(AsyncJobQueued) _then) = _$AsyncJobQueuedCopyWithImpl;
@useResult
$Res call({
 int generation
});




}
/// @nodoc
class _$AsyncJobQueuedCopyWithImpl<$Res>
    implements $AsyncJobQueuedCopyWith<$Res> {
  _$AsyncJobQueuedCopyWithImpl(this._self, this._then);

  final AsyncJobQueued _self;
  final $Res Function(AsyncJobQueued) _then;

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? generation = null,}) {
  return _then(AsyncJobQueued(
generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class AsyncJobRunning implements AsyncJobView {
  const AsyncJobRunning({required this.generation, required this.progress});
  

 final  int generation;
 final  JobProgress progress;

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AsyncJobRunningCopyWith<AsyncJobRunning> get copyWith => _$AsyncJobRunningCopyWithImpl<AsyncJobRunning>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AsyncJobRunning&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.progress, progress) || other.progress == progress));
}


@override
int get hashCode => Object.hash(runtimeType,generation,progress);

@override
String toString() {
  return 'AsyncJobView.running(generation: $generation, progress: $progress)';
}


}

/// @nodoc
abstract mixin class $AsyncJobRunningCopyWith<$Res> implements $AsyncJobViewCopyWith<$Res> {
  factory $AsyncJobRunningCopyWith(AsyncJobRunning value, $Res Function(AsyncJobRunning) _then) = _$AsyncJobRunningCopyWithImpl;
@useResult
$Res call({
 int generation, JobProgress progress
});


$JobProgressCopyWith<$Res> get progress;

}
/// @nodoc
class _$AsyncJobRunningCopyWithImpl<$Res>
    implements $AsyncJobRunningCopyWith<$Res> {
  _$AsyncJobRunningCopyWithImpl(this._self, this._then);

  final AsyncJobRunning _self;
  final $Res Function(AsyncJobRunning) _then;

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? generation = null,Object? progress = null,}) {
  return _then(AsyncJobRunning(
generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as JobProgress,
  ));
}

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JobProgressCopyWith<$Res> get progress {
  
  return $JobProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}

/// @nodoc


class AsyncJobSucceeded implements AsyncJobView {
  const AsyncJobSucceeded({required this.generation, required this.summary});
  

 final  int generation;
 final  JobResultSummary summary;

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AsyncJobSucceededCopyWith<AsyncJobSucceeded> get copyWith => _$AsyncJobSucceededCopyWithImpl<AsyncJobSucceeded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AsyncJobSucceeded&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,generation,summary);

@override
String toString() {
  return 'AsyncJobView.succeeded(generation: $generation, summary: $summary)';
}


}

/// @nodoc
abstract mixin class $AsyncJobSucceededCopyWith<$Res> implements $AsyncJobViewCopyWith<$Res> {
  factory $AsyncJobSucceededCopyWith(AsyncJobSucceeded value, $Res Function(AsyncJobSucceeded) _then) = _$AsyncJobSucceededCopyWithImpl;
@useResult
$Res call({
 int generation, JobResultSummary summary
});


$JobResultSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$AsyncJobSucceededCopyWithImpl<$Res>
    implements $AsyncJobSucceededCopyWith<$Res> {
  _$AsyncJobSucceededCopyWithImpl(this._self, this._then);

  final AsyncJobSucceeded _self;
  final $Res Function(AsyncJobSucceeded) _then;

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? generation = null,Object? summary = null,}) {
  return _then(AsyncJobSucceeded(
generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as JobResultSummary,
  ));
}

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JobResultSummaryCopyWith<$Res> get summary {
  
  return $JobResultSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

/// @nodoc


class AsyncJobCancelled implements AsyncJobView {
  const AsyncJobCancelled({required this.generation});
  

 final  int generation;

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AsyncJobCancelledCopyWith<AsyncJobCancelled> get copyWith => _$AsyncJobCancelledCopyWithImpl<AsyncJobCancelled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AsyncJobCancelled&&(identical(other.generation, generation) || other.generation == generation));
}


@override
int get hashCode => Object.hash(runtimeType,generation);

@override
String toString() {
  return 'AsyncJobView.cancelled(generation: $generation)';
}


}

/// @nodoc
abstract mixin class $AsyncJobCancelledCopyWith<$Res> implements $AsyncJobViewCopyWith<$Res> {
  factory $AsyncJobCancelledCopyWith(AsyncJobCancelled value, $Res Function(AsyncJobCancelled) _then) = _$AsyncJobCancelledCopyWithImpl;
@useResult
$Res call({
 int generation
});




}
/// @nodoc
class _$AsyncJobCancelledCopyWithImpl<$Res>
    implements $AsyncJobCancelledCopyWith<$Res> {
  _$AsyncJobCancelledCopyWithImpl(this._self, this._then);

  final AsyncJobCancelled _self;
  final $Res Function(AsyncJobCancelled) _then;

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? generation = null,}) {
  return _then(AsyncJobCancelled(
generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class AsyncJobFailed implements AsyncJobView {
  const AsyncJobFailed({required this.generation, required this.failure});
  

 final  int generation;
 final  Failure failure;

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AsyncJobFailedCopyWith<AsyncJobFailed> get copyWith => _$AsyncJobFailedCopyWithImpl<AsyncJobFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AsyncJobFailed&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,generation,failure);

@override
String toString() {
  return 'AsyncJobView.failed(generation: $generation, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $AsyncJobFailedCopyWith<$Res> implements $AsyncJobViewCopyWith<$Res> {
  factory $AsyncJobFailedCopyWith(AsyncJobFailed value, $Res Function(AsyncJobFailed) _then) = _$AsyncJobFailedCopyWithImpl;
@useResult
$Res call({
 int generation, Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$AsyncJobFailedCopyWithImpl<$Res>
    implements $AsyncJobFailedCopyWith<$Res> {
  _$AsyncJobFailedCopyWithImpl(this._self, this._then);

  final AsyncJobFailed _self;
  final $Res Function(AsyncJobFailed) _then;

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? generation = null,Object? failure = null,}) {
  return _then(AsyncJobFailed(
generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of AsyncJobView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
