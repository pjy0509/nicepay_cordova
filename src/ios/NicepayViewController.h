#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <Cordova/CDVCommandDelegate.h>
#import "NicepayCordova.h"

@interface NicepayViewController: UIViewController<WKUIDelegate, WKNavigationDelegate, NicepayDelegate>

@property () NicepayCordova *delegate;
@property (strong, nonatomic) NSArray *endpoint;
@property (strong, nonatomic) IBOutlet WKWebView *webView;
@property () BOOL isWebViewLoaded;
@property (strong, nonatomic) NSString *callbackId;
@property (nonatomic, weak) id <CDVCommandDelegate> commandDelegate;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSObject *params;
@property (strong, nonatomic) NSObject *header;
@property () BOOL isRequestedWithHeader;

- (id) init;
- (void) onDidReceiveData: (NSNotification *) notification;
- (BOOL) isEnd: (NSString *) url;
- (BOOL) isFail: (NSString *) url;
- (BOOL) isApp: (NSString *) url;
- (void) openBankApp: (NSURL *) url;
- (NSString *) parseJSONString: (NSObject *) object;
- (void) onBack;
- (void) onClose;
- (NSString *) decodeUnicodeString: (NSString *) string;
- (void) callback: (NSDictionary *) result status: (CDVCommandStatus *) status withRemoveWKWebView: (BOOL) withRemoveWKWebView;

@end
