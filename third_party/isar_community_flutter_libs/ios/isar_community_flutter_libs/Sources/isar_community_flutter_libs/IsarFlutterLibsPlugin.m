#import "IsarFlutterLibsPlugin.h"
#import "binding.h"

@implementation IsarFlutterLibsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
}

// Keeping a native Isar symbol in the object file makes SwiftPM link the
// static XCFramework. Dart accesses the remaining symbols through FFI.
- (void)dummyMethodToEnforceBundling {
  isar_get_error(0);
}
@end
