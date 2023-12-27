#import "NicepayViewController.h"

#define APP_STORE_PREFIX @"https://itunes.apple.com/kr/app/"
static NSString *APP_STORE_FIND_BY_ID(NSString *appId) { return [APP_STORE_PREFIX stringByAppendingString:[NSString stringWithFormat:@"id%@", appId]]; }
static NSString *APP_STORE_FIND_BY_SEARCH_KEYWORD(NSString *keyword) { return [APP_STORE_PREFIX stringByAppendingString:[NSString stringWithFormat:@"search?term=%@", keyword]]; }
static NSMutableDictionary<NSString *, NSString *> *BANK_APP_SCHEME = nil;

__attribute__((constructor))
static void initializeBankAppScheme() {
    BANK_APP_SCHEME = [NSMutableDictionary dictionary];
    
    [BANK_APP_SCHEME setObject:@"369125087" forKey:@"ispmobile"];
    [BANK_APP_SCHEME setObject:@"398456030" forKey:@"kftc-bankpay"];
    [BANK_APP_SCHEME setObject:@"1573528126" forKey:@"newliiv"];
    [BANK_APP_SCHEME setObject:@"362057947" forKey:@"kakaotalk"];
    [BANK_APP_SCHEME setObject:@"847268987" forKey:@"cloudpay"];
    [BANK_APP_SCHEME setObject:@"688047200" forKey:@"lotteappcard"];
    [BANK_APP_SCHEME setObject:@"535125356" forKey:@"mpocket.online.ansimclick"];
    [BANK_APP_SCHEME setObject:@"702653088" forKey:@"hdcardappcardansimclick"];
    [BANK_APP_SCHEME setObject:@"1177889176" forKey:@"nhallonepayansimclick"];
    [BANK_APP_SCHEME setObject:@"572462317" forKey:@"shinsegaeeasypayment"];
    [BANK_APP_SCHEME setObject:@"473250588" forKey:@"shinhan-sr-ansimclick-lpay"];
    [BANK_APP_SCHEME setObject:@"924292102" forKey:@"payco"];
    [BANK_APP_SCHEME setObject:@"572462317" forKey:@"shinhan-sr-ansimclick"];
    [BANK_APP_SCHEME setObject:@"1499598869" forKey:@"com.wooricard.wcard"];
    [BANK_APP_SCHEME setObject:@"1470181651" forKey:@"newsmartpib"];
    [BANK_APP_SCHEME setObject:@"1026609372" forKey:@"yonseipay"];
    [BANK_APP_SCHEME setObject:@"473250588" forKey:@"lmslpay"];
    [BANK_APP_SCHEME setObject:@"839333328" forKey:@"supertoss"];
    [BANK_APP_SCHEME setObject:@"695436326" forKey:@"kb-acp"];
    [BANK_APP_SCHEME setObject:@"1126232922" forKey:@"liivbank"];
    [BANK_APP_SCHEME setObject:@"668497947" forKey:@"lottesmartpay"];
    [BANK_APP_SCHEME setObject:@"1036098908" forKey:@"lpayapp"];
    [BANK_APP_SCHEME setObject:@"1038288833" forKey:@"hanawalletmembers"];
    [BANK_APP_SCHEME setObject:@"1201113419" forKey:@"wooripay"];
    [BANK_APP_SCHEME setObject:@"1179759666" forKey:@"citimobileapp"];
    [BANK_APP_SCHEME setObject:@"393499958" forKey:@"naversearchthirdlogin"];
    [BANK_APP_SCHEME setObject:@"373742138" forKey:@"kbbank"];
}

@implementation NicepayViewController: UIViewController

- (id) init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidReceiveData:) name:CDVPluginHandleOpenURLNotification object:nil];
    }
    return self;
}

- (void) loadView
{
    [super loadView];

    _isWebViewLoaded = NO;
    _isRequestedWithHeader = NO;
    
    _webView = ({
        WKPreferences *preferences = [[WKPreferences alloc] init];
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        WKProcessPool *processPool = [[WKProcessPool alloc] init];
        
        WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
        webView.allowsBackForwardNavigationGestures = NO;
        webView.configuration.processPool = processPool;
        webView.configuration.preferences = preferences;
        
        [WKWebsiteDataStore.defaultDataStore removeDataOfTypes:[WKWebsiteDataStore allWebsiteDataTypes] modifiedSince:[NSDate dateWithTimeIntervalSince1970:0] completionHandler:^{}];
        
        webView;
    });
    
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;
    
    self.view = _webView;
    
    _delegate = [[NicepayCordova alloc] init];
    [_delegate setDelegate:self];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [_webView loadHTMLString:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"nicepay-webview" ofType:@"html" inDirectory:@"www"] encoding:NSUTF8StringEncoding error:nil] baseURL:[[NSBundle mainBundle] bundleURL]];
}

- (void) viewDidDisappear: (BOOL) animated
{
    [super viewDidDisappear:animated];

    NSDictionary *result = @{
        @"status": @"fail",
        @"resultCode": @"-100",
        @"message": @"사용자 취소"
    };

    [_delegate callback:[self parseJSONString:result] callbackId:_callbackId commandDelegate:_commandDelegate status:CDVCommandStatus_ERROR];
}

- (void) webView: (WKWebView *) webView decidePolicyForNavigationAction: (nonnull WKNavigationAction *) navigationAction decisionHandler: (nonnull void (^)(WKNavigationActionPolicy)) decisionHandler
{
    NSString *url = navigationAction.request.URL.absoluteString;
    
    if ([self isEnd:url]) {
        NSDictionary *result = @{
            @"status": @"success",
            @"resultCode": @"100",
            @"message": @"결제 완료"
        };

        if (_header != nil && [url hasPrefix:[_params valueForKey:@"ReturnURL"]]) {
            if (!_isRequestedWithHeader) {
                _isRequestedWithHeader = YES;

                NSDictionary *headerDictionary = [NSJSONSerialization JSONObjectWithData:[NSJSONSerialization dataWithJSONObject:_header options:NSJSONWritingPrettyPrinted error:nil] options:NSJSONReadingMutableContainers error:nil];
                NSMutableURLRequest *mutableRequest = [navigationAction.request mutableCopy];
                NSMutableDictionary *headers = [mutableRequest.allHTTPHeaderFields mutableCopy];

                if (headers == nil) {
                    headers = [NSMutableDictionary dictionary];
                }

                [headerDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [headers setObject:obj forKey:key];
                }];

                mutableRequest.allHTTPHeaderFields = headers;

                decisionHandler(WKNavigationActionPolicyCancel);

                [self.webView loadRequest:mutableRequest];
            } else {
                decisionHandler(WKNavigationActionPolicyAllow);

                [self callback: result status:&((CDVCommandStatus){CDVCommandStatus_OK}) withRemoveWKWebView:NO];
            }
        } else {
            decisionHandler(WKNavigationActionPolicyAllow);

            [self callback: result status:&((CDVCommandStatus){CDVCommandStatus_OK}) withRemoveWKWebView:YES];
        }
    } else if ([self isFail:url]) {
        NSURLComponents *urlComponents = [NSURLComponents componentsWithString:url];
        NSMutableDictionary *queryParameters = [NSMutableDictionary dictionary];

        for (NSURLQueryItem *queryItem in urlComponents.queryItems) {
            [queryParameters setObject:[self decodeUnicodeString: queryItem.value] forKey:queryItem.name];
        }

        NSDictionary *result = @{
            @"status": @"fail",
            @"resultCode": [queryParameters valueForKey:@"errCd"],
            @"message": [queryParameters valueForKey:@"errMsg"]
        };

        [self callback: result status:&((CDVCommandStatus){CDVCommandStatus_ERROR}) withRemoveWKWebView:YES];

        decisionHandler(WKNavigationActionPolicyAllow);
    } else if ([self isApp:url]) {
        [self openBankApp:navigationAction.request.URL];

        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void) webView: (WKWebView *) webView didFinishNavigation: (null_unspecified WKNavigation *) navigation
{
    if (_isWebViewLoaded == NO) {
        [webView evaluateJavaScript:[NSString stringWithFormat:@"%@%@%@", @"requestPayment(", [self parseJSONString:_params], @")"] completionHandler:nil];
        _isWebViewLoaded = YES;
    }
}

- (void) webView: (WKWebView *) webView runJavaScriptAlertPanelWithMessage: (NSString *) message initiatedByFrame: (WKFrameInfo *) frame completionHandler: (void (^)(void)) completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"닫기" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        completionHandler();
    }]];
    [self presentViewController:alertController animated:YES completion:^{}];
}

- (void) webView: (WKWebView *) webView runJavaScriptConfirmPanelWithMessage: (NSString *) message initiatedByFrame: (WKFrameInfo *) frame completionHandler: (void (^)(BOOL result)) completionHandler
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"취소", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        completionHandler(NO);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"확인", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        completionHandler(YES);
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL) isEnd: (NSString *) url
{
    if ([_endpoint isKindOfClass:[NSArray class]]) {
        NSArray *filteredArray = nil;
        
        filteredArray = [_endpoint filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
            return [url hasPrefix:[obj description]];
        }]];
        
        return [filteredArray count] > 0;
    } else {
        return NO;
    }
    
    return NO;
}

- (BOOL) isFail: (NSString *) url
{
    return [url hasPrefix:@"https://web.nicepay.co.kr/v3/smart/common/error.jsp"];;
}

- (BOOL) isApp: (NSString *)url
{
    return ![url hasPrefix:@"http"] && ![url hasPrefix:@"https"] && ![url hasPrefix:@"about:blank"] && ![url hasPrefix:@"file"];
}

- (void) openBankApp: (NSURL *) url
{
    NSString *scheme = url.scheme;
    NSString *appId = [BANK_APP_SCHEME valueForKey:url.scheme];
    
    if ([scheme hasPrefix:@"itms"]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {}];
    } else if (appId != nil) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:APP_STORE_FIND_BY_ID(appId)] options:@{} completionHandler:^(BOOL success) {}];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:APP_STORE_FIND_BY_SEARCH_KEYWORD(scheme)] options:@{} completionHandler:^(BOOL success) {}];
    }
}

- (NSString*) parseJSONString: (NSObject*) object
{
    NSError *err = nil;
    
    @try {
        return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&err] encoding:NSUTF8StringEncoding];
    } @catch (NSException *exception) {
        NSDictionary *result = @{
            @"status": @"fail",
            @"resultCode": @"-101",
            @"message": @"결제 정보 오류"
        };
        
        [_delegate callback:[self parseJSONString:result] callbackId:_callbackId commandDelegate:_commandDelegate status:CDVCommandStatus_ERROR];
    }
}

- (void) onBack
{
    if ([_webView canGoBack]) {
        [_webView goBack];
    } else {
        [self onClose];
    }
}

- (void) onClose
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message: @"결제를 취소하시겠습니까?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"취소", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"확인", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSDictionary *result = @{
            @"status": @"fail",
            @"resultCode": @"-100",
            @"message": @"사용자 취소"
        };

        [self callback: result status:&((CDVCommandStatus){CDVCommandStatus_ERROR}) withRemoveWKWebView:NO];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *) decodeUnicodeString: (NSString *) string {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(%u[0-9A-Fa-f]{4})|(%[0-9A-Fa-f]{2})" options:0 error:&error];

    NSMutableString *decodedString = [string mutableCopy];
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];

    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        NSRange matchRange = [match range];
        NSString *encodedSubstring = [string substringWithRange:matchRange];
        NSString *decodedSubstring = nil;

        if ([encodedSubstring hasPrefix:@"%u"]) {
            unsigned int unicodeValue = 0;
            NSScanner *scanner = [NSScanner scannerWithString:[encodedSubstring substringFromIndex:2]];
            [scanner scanHexInt:&unicodeValue];
            decodedSubstring = [NSString stringWithFormat:@"%C", (unichar)unicodeValue];
        } else {
            decodedSubstring = [NSString stringWithFormat:@"%c", (char)strtol([[encodedSubstring substringFromIndex:1] UTF8String], NULL, 16)];
        }

        [decodedString replaceCharactersInRange:matchRange withString:decodedSubstring];
    }

    return decodedString;
}

- (void) onDidReceiveData: (NSNotification *) notification
{
    
}

- (void) callback: (NSDictionary *) result status: (CDVCommandStatus *) status withRemoveWKWebView: (BOOL) withRemoveWKWebView
{
    [_delegate callback:[self parseJSONString:result] callbackId:_callbackId commandDelegate:_commandDelegate status:*status];

    if (withRemoveWKWebView) {
        [_webView stopLoading];
        [_webView removeFromSuperview];
        _webView.UIDelegate = nil;
        _webView.navigationDelegate = nil;

        _webView = nil;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:CDVPluginHandleOpenURLNotification object:nil];

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
