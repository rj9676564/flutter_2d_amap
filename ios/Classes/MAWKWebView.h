//
//  MAWKWebView.h
//  flutter_2d_amap
//

#import <UIKit/UIKit.h>
#import <MAMapKit/MAMapKit.h>
#import <MAMapKit/MAMapWebViewProcotol.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MAWKWebView : NSObject<MAMapWebViewProcotol>

@property(nonatomic, strong, readonly) WKWebView *webView;

- (instancetype)initWithFrame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
