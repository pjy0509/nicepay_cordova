#import <Cordova/CDV.h>
#import <Cordova/CDVCommandDelegate.h>

@protocol NicepayDelegate <NSObject>
@end

@interface NicepayCordova: CDVPlugin {
    id <NicepayDelegate> _delegate;
}

- (void) setup: (CDVInvokedUrlCommand*) command;
- (NSString *) getDefault: (id) object defaultValue: (NSString *) defaultValue;
- (BOOL) parseBoolean: (id) object;
- (UIColor *) colorSelector: (NSString *) string;
- (UIColor *) colorSelector: (NSString *) string defaultColor: (UIColor *) defaultColor;
- (void) setDelegate: (id<NicepayDelegate>) delegate;
- (void) callback: (NSString*) message callbackId: (NSString*) callbackId commandDelegate: (id<CDVCommandDelegate>) commandDelegate status: (CDVCommandStatus) status;

@end
