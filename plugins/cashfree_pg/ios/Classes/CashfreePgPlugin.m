#import "CashfreePgPlugin.h"
#if __has_include(<cashfree_pg/cashfree_pg-Swift.h>)
#import <cashfree_pg/cashfree_pg-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cashfree_pg-Swift.h"
#endif

@implementation CashfreePgPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCashfreePgPlugin registerWithRegistrar:registrar];
}
@end
