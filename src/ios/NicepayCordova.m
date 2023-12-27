#import <Cordova/CDV.h>
#import "NicepayCordova.h"
#import "NicepayViewController.h"

@implementation NicepayCordova { }

- (void) setup: (CDVInvokedUrlCommand*) command
{
    NSObject *params = [command.arguments objectAtIndex:0];
    NSString *options = [command.arguments objectAtIndex:1];
    
    NicepayViewController *vc = [[NicepayViewController alloc] init];
    
    NSString *systemNpLang = ({
        NSString *lang = [[[NSLocale localeWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]] languageCode] uppercaseString];
        NSString *result = @"";

        if ([lang isEqualToString:@"KO"] || [lang isEqualToString:@"CN"]) {
            result = lang;
        } else {
            result = @"EN";
        }
        
        result;
    });
    
    NSString *systemCurrencyCode = ({
        NSString *country = [[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] uppercaseString];
        NSString *result = @"";

        if ([country isEqualToString:@"KR"]) {
            result = @"KRW";
        } else if ([country isEqualToString:@"CN"]) {
            result = @"CNY";
        } else {
            result = @"USD";
        }
        
        result;
    });

    NSString *appScheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"][0][@"CFBundleURLSchemes"][0];

    [params setValue:[self getDefault:[params valueForKey:@"WapUrl"] defaultValue: appScheme] forKey:@"WapUrl"];
    [params setValue:[self getDefault:[params valueForKey:@"IspCancelUrl"] defaultValue: appScheme] forKey:@"IspCancelUrl"];
    [params setValue:[self getDefault:[params valueForKey:@"NpLang"] defaultValue: systemNpLang] forKey:@"NpLang"];
    [params setValue:[self getDefault:[params valueForKey:@"CurrencyCode"] defaultValue: systemCurrencyCode] forKey:@"CurrencyCode"];
    
    // 결제 정보
    vc.endpoint = [params valueForKey:@"Endpoint"];
    [params setValue:nil forKey:@"Endpoint"];
    vc.params = params;
    vc.header = [options valueForKey:@"withHeader"];

    // CDVInvokedUrlCommand, CDVCommandDelegate
    vc.callbackId = command.callbackId;
    vc.commandDelegate = self.commandDelegate;
    
    // Navigation Bar 표출 여부
    BOOL withNavigation = [self parseBoolean:[options valueForKey:@"withNavigation"]];
    
    if (withNavigation) {
        
        // Navigation (UINavigationController)
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:vc];
        UINavigationBar *naviBar = navi.navigationBar;
        
        // Navigation Bar Back Button 표출 여부
        BOOL withBackButton = [self parseBoolean:[options valueForKey:@"withBackButton"]];
        // Navigation Bar Close Button 표출 여부
        BOOL withCloseButton = [self parseBoolean:[options valueForKey:@"withCloseButton"]];
        // Navigation Bar Title Text (null 이면 앱 이름)
        NSString *title = [self getDefault:[options valueForKey:@"title"] defaultValue: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
        // Navigation Bar Button Color
        UIColor *buttonColor = [self colorSelector:[options valueForKey:@"buttonColor"]];
        // Navigation Bar Title Color
        UIColor *titleColor = [self colorSelector:[options valueForKey:@"titleColor"]];
        // Navigation Bar Title Color
        UIColor *backgroundColor = [self colorSelector:[options valueForKey:@"backgroundColor"] defaultColor: [UIColor whiteColor]];
        
        // Navigation Title Label (UILabel)
        UILabel *naviTitleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:vc.view.frame];
            
            label.backgroundColor = [UIColor clearColor];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = title;
            label.textColor = titleColor;
            
            label;
        });
        
        if (withBackButton) {
            naviBar.topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_np_back.png"] style:UIBarButtonItemStyleDone target:vc action:@selector(onBack)];
            naviBar.topItem.leftBarButtonItem.tintColor = buttonColor;
        }
        
        if (withCloseButton) {
            naviBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_np_close.png"] style:UIBarButtonItemStyleDone target:vc action:@selector(onClose)];
            naviBar.topItem.rightBarButtonItem.tintColor = buttonColor;
        }
        
        [naviTitleLabel sizeToFit];
        naviBar.topItem.titleView = naviTitleLabel;
        naviBar.translucent = NO;
        naviBar.barTintColor = backgroundColor;
        
        if (@available(iOS 15.0, *)) {
            UINavigationBarAppearance *naviBarAppearance = [[UINavigationBarAppearance alloc] init];
            [naviBarAppearance configureWithOpaqueBackground];
            naviBarAppearance.backgroundColor = backgroundColor;
            naviBar.standardAppearance = naviBarAppearance;
            naviBar.scrollEdgeAppearance = naviBarAppearance;
        }
        
        [self.viewController presentViewController:navi animated:YES completion:nil];
    } else {
        [self.viewController presentViewController:vc animated:YES completion:nil];
    }
}

// Utility
- (NSString *) getDefault: (id) object defaultValue: (NSString *) defaultValue
{
    NSString *stringValue = (NSString *)(object ?: @"");
    return [stringValue isEqual:@"@SYSTEM"] ? defaultValue : object;
}

- (BOOL) parseBoolean: (id) object
{
    return [object isEqualToNumber:@1] || [@[@"true", @"yes"] containsObject: [[object stringValue] lowercaseString]];
}

- (UIColor *) colorSelector: (NSString *) string
{
    return [self colorSelector:string defaultColor:[UIColor blackColor]];
}

- (UIColor *) colorSelector: (NSString *) string defaultColor: (UIColor *) defaultColor
{
    SEL colorSelector = NSSelectorFromString(string);
    
    if ([UIColor respondsToSelector:colorSelector]) {
        return [UIColor performSelector:colorSelector];
    }
    
    if ([string hasPrefix:@"#"]) {
        string = [string substringFromIndex:1];
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    unsigned int rgb;
    BOOL isValidHex = [scanner scanHexInt:&rgb];
    
    if (isValidHex) {
        return [UIColor colorWithRed:((rgb & 0xFF0000) >> 16)/255.0 green:((rgb & 0xFF00) >> 8)/255.0 blue:(rgb & 0xFF)/255.0 alpha:1.0];
    }
    
    return defaultColor;
}

- (void) setDelegate: (id<NicepayDelegate>) delegate
{
    _delegate = delegate;
}

- (void) callback: (NSString*) message callbackId: (NSString *) callbackId commandDelegate: (id<CDVCommandDelegate>) commandDelegate status: (CDVCommandStatus) status
{
    [commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:status messageAsString:message] callbackId:callbackId];
}

@end
