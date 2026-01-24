//
//  MAWKWebView.m
//  flutter_2d_amap
//

#import "MAWKWebView.h"
#import <MAMapKit/MAMapKit.h>

@implementation MAWKWebView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super init];
    if (self) {
        [self initWebViewWithFrame:frame];
    }
    return self;
}

- (void)initWebViewWithFrame:(CGRect)frame {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *content = [[WKUserContentController alloc] init];
    configuration.userContentController = content;
    
    if (@available(iOS 11.0, *)) {
        // 注册轻量版地图SDK网络拦截监听
        // Note: customSchemeArray is provided by the Lite SDK version of MAMapKit
        Class amapClass = NSClassFromString(@"MAMap");
        SEL customSchemeSelector = NSSelectorFromString(@"customSchemeArray");
        if (amapClass && [amapClass respondsToSelector:customSchemeSelector]) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSArray *array = [amapClass performSelector:customSchemeSelector];
            #pragma clang diagnostic pop
            
            for (id model in array) {
                // model is MACustomSchemeModel
                SEL handlerSelector = NSSelectorFromString(@"urlSchemeHandler");
                SEL schemeSelector = NSSelectorFromString(@"urlScheme");
                if ([model respondsToSelector:handlerSelector] && [model respondsToSelector:schemeSelector]) {
                    #pragma clang diagnostic push
                    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    id<WKURLSchemeHandler> handler = [model performSelector:handlerSelector];
                    NSString *scheme = [model performSelector:schemeSelector];
                    #pragma clang diagnostic pop
                    [configuration setURLSchemeHandler:handler forURLScheme:scheme];
                }
            }
        }
    }
    
    _webView = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
}

- (WKWebViewConfiguration *)configuration {
    return self.webView.configuration;
}

- (nullable WKNavigation *)loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL {
    return [self.webView loadHTMLString:string baseURL:baseURL];
}

- (nullable WKNavigation *)loadRequest:(NSURLRequest *)request {
    return [self.webView loadRequest:request];
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler {
    [self.webView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}

- (void)setFrame:(CGRect)frame {
    self.webView.frame = frame;
}

- (void)addSubView:(UIView *)view {
    [self.webView addSubview:view];
}

- (void)dealloc {
    // NSLog(@"MAWKWebView --- dealloc");
}

@end
