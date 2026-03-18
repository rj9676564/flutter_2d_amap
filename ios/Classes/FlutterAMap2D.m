//
//  FlutterAMap2D.m
//  flutter_2d_amap
//
//  Created by weilu on 2019/7/1.
//

#import "FlutterAMap2D.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>
#import "MAWKWebView.h"

@implementation FlutterAMap2DFactory {
    NSObject<FlutterBinaryMessenger>* _messenger;
}
    
- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    self = [super init];
    if (self) {
        _messenger = messenger;
    }
    return self;
}
    
- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}
    
- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
    FlutterAMap2DController* aMap2DController = [[FlutterAMap2DController alloc] initWithFrame:frame
                                                                                viewIdentifier:viewId
                                                                                     arguments:args
                                                                               binaryMessenger:_messenger];
    return aMap2DController;
}
    
@end


@interface FlutterAMap2DController()<AMapLocationManagerDelegate, AMapSearchDelegate, MAMapDelegate>

    @property (strong, nonatomic) AMapLocationManager *locationManager;
    @property (strong, nonatomic) AMapSearchAPI *search;
@end

@implementation FlutterAMap2DController {
    MAWKWebView* _webViewContainer;
    MAMap* _map;
    int64_t _viewId;
    FlutterMethodChannel* _channel;
    MAPointAnnotation* _pointAnnotation;
    NSMutableDictionary<NSString*, MAPolygon*>* _polygonMap;
    NSMutableDictionary<NSString*, id<MAAnnotation>>* _markerMap;
    bool _isPoiSearch;
    bool _showClickMarker;
    bool _moveCameraOnTap;
    bool _compassEnabled;
    bool _scaleEnabled;
    bool _zoomGesturesEnabled;
    bool _scrollGesturesEnabled;
    NSDictionary* _initialCameraPosition;
    bool _onCameraChange;
    bool _onCameraChangeFinish;
}

NSString* _types = @"010000|010100|020000|030000|040000|050000|050100|060000|060100|060200|060300|060400|070000|080000|080100|080300|080500|080600|090000|090100|090200|090300|100000|100100|110000|110100|120000|120200|120300|130000|140000|141200|150000|150100|150200|160000|160100|170000|170100|170200|180000|190000|200000";
    
- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    if ([super init]) {

        _viewId = viewId;
        NSString* channelName = [NSString stringWithFormat:@"plugins.weilu/flutter_2d_amap_%lld", viewId];
        _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
        __weak __typeof__(self) weakSelf = self;
        [_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
            [weakSelf onMethodCall:call result:result];
        }];
        _polygonMap = [NSMutableDictionary dictionary];
        _markerMap = [NSMutableDictionary dictionary];
        _isPoiSearch = [args[@"isPoiSearch"] boolValue] == YES;
        _showClickMarker = [args[@"showClickMarker"] boolValue] == YES;
        _moveCameraOnTap = [args[@"moveCameraOnTap"] boolValue] == YES;
        _compassEnabled = [args[@"compassEnabled"] boolValue] == YES;
        _scaleEnabled = [args[@"scaleEnabled"] boolValue] == YES;
        _zoomGesturesEnabled = [args[@"zoomGesturesEnabled"] boolValue] == YES;
        _scrollGesturesEnabled = [args[@"scrollGesturesEnabled"] boolValue] == YES;
        _initialCameraPosition = args[@"initialCameraPosition"];

        _onCameraChange = [args[@"onCameraChange"] boolValue] == YES;
        _onCameraChangeFinish = [args[@"onCameraChangeFinish"] boolValue] == YES;
        /// 初始化地图
        _webViewContainer = [[MAWKWebView alloc] initWithFrame:frame];
        _map = [[MAMap alloc] initWithWebView:_webViewContainer];
        _map.delegate = self;
        [_map createMap];
        
        _map.zoomEnabled = _zoomGesturesEnabled;
        _map.scrollEnabled = _scrollGesturesEnabled;
        
        if (_initialCameraPosition != nil && ![_initialCameraPosition isKindOfClass:[NSNull class]]) {
            NSDictionary* target = _initialCameraPosition[@"target"];
            double zoom = [_initialCameraPosition[@"zoom"] doubleValue];
            CLLocationCoordinate2D center;
            center.latitude = [target[@"latitude"] doubleValue];
            center.longitude = [target[@"longitude"] doubleValue];
            [_map setZoomLevel:zoom animated:NO];
            [_map setCenterCoordinate:center animated:NO];
        } else {
            [_map setZoomLevel:16.5 animated:NO];
        }
    }
    return self;
}

- (void)mapReady:(MAMap *)map {
    if (_initialCameraPosition != nil && ![_initialCameraPosition isKindOfClass:[NSNull class]]) {
        NSDictionary* target = _initialCameraPosition[@"target"];
        double zoom = [_initialCameraPosition[@"zoom"] doubleValue];
        CLLocationCoordinate2D center;
        center.latitude = [target[@"latitude"] doubleValue];
        center.longitude = [target[@"longitude"] doubleValue];
        [_map setZoomLevel:zoom animated:NO];
        [_map setCenterCoordinate:center animated:NO];
    } else {
        [_map setZoomLevel:16.5 animated:NO];
    }
    
    // 开启蓝点展示，但不要自动跟随定位回中，避免业务层手动选点后被拉回当前位置
    _map.showsUserLocation = YES;
    _map.userTrackingMode = MAUserTrackingModeNone;
    
    // 配置小蓝点样式
    // MAUserLocationRepresentation *represent = [[MAUserLocationRepresentation alloc] init];
    // represent.showsAccuracyRing = YES;
    // represent.fillColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.1];
    // represent.strokeColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.3];
    // represent.lineWidth = 1.0;
    // [_map updateUserLocationRepresentation:represent];
    
    if (!self.locationManager) {
        self.locationManager = [[AMapLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    }
    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];
    
    if (!self.search) {
        self.search = [[AMapSearchAPI alloc] init];
        self.search.delegate = self;
    }
}


- (void)map:(MAMap *)map didSingleTappedAtCoordinate:(CLLocationCoordinate2D)coordinate {
    NSDictionary* arguments = @{
            @"latitude" : @(coordinate.latitude),
            @"longitude" : @(coordinate.longitude)
        };
    [_channel invokeMethod:@"onAMapClick" arguments:arguments];
    if (_moveCameraOnTap) {
        [self->_map setCenterCoordinate:coordinate animated:YES];
    }
    if (_showClickMarker) {
        [self drawMarkers:coordinate.latitude lon:coordinate.longitude];
    }
    [self searchPOI:coordinate.latitude lon:coordinate.longitude];
}

- (MAOverlayRenderer *)map:(MAMap *)map rendererForOverlay:(id <MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolygon class]])
    {
        MAPolygonRenderer *renderer = [[MAPolygonRenderer alloc] initWithPolygon:overlay];
        
        NSNumber* strokeWidth = objc_getAssociatedObject(overlay, "strokeWidth");
        NSNumber* strokeColor = objc_getAssociatedObject(overlay, "strokeColor");
        NSNumber* fillColor = objc_getAssociatedObject(overlay, "fillColor");
        
        renderer.lineWidth = [strokeWidth doubleValue];
        renderer.strokeColor = [self colorFromNumber:strokeColor];
        renderer.fillColor = [self colorFromNumber:fillColor];
        
        NSNumber* joinType = objc_getAssociatedObject(overlay, "joinType");
        if (joinType != nil) {
            int type = [joinType intValue];
            if (type == 0) renderer.lineJoinType = kMALineJoinBevel;
            else if (type == 1) renderer.lineJoinType = kMALineJoinMiter;
            else if (type == 2) renderer.lineJoinType = kMALineJoinRound;
        }
        
        return renderer;
    } else if ([overlay isKindOfClass:[MAPolyline class]]) {
        MAPolylineRenderer *renderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        
        NSNumber* strokeWidth = objc_getAssociatedObject(overlay, "strokeWidth");
        NSNumber* strokeColor = objc_getAssociatedObject(overlay, "strokeColor");
        NSNumber* isDottedLine = objc_getAssociatedObject(overlay, "isDottedLine");
        NSNumber* visible = objc_getAssociatedObject(overlay, "visible");
        NSNumber* joinType = objc_getAssociatedObject(overlay, "joinType");

        renderer.lineWidth = [strokeWidth doubleValue];
        renderer.strokeColor = [self colorFromNumber:strokeColor];
        
        if (visible != nil && ![visible boolValue]) {
            renderer.alpha = 0.0;
        }
        
        if (joinType != nil) {
            int type = [joinType intValue];
            if (type == 0) renderer.lineJoinType = kMALineJoinBevel;
            else if (type == 1) renderer.lineJoinType = kMALineJoinMiter;
            else if (type == 2) renderer.lineJoinType = kMALineJoinRound;
        }

        if ([isDottedLine boolValue]) {
             renderer.lineDashType = kMALineDashTypeSquare;
        }
        
        return renderer;
    }
    return nil;
}

- (MAAnnotationView *)map:(MAMap *)map viewForAnnotation:(id <MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAUserLocation class]]) {
        return nil; // 定位点使用默认样式（小蓝点）
    }
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        MAPinAnnotationView* annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation];
        NSNumber* infoWindowEnable = objc_getAssociatedObject(annotation, "infoWindowEnable");
        BOOL canShowCallout = (infoWindowEnable != nil) ? [infoWindowEnable boolValue] : YES; // Default true
        
        annotationView.canShowCallout= canShowCallout;
        annotationView.draggable = YES;        //设置标注可以拖动，默认为NO
        
        NSNumber* anchorX = objc_getAssociatedObject(annotation, "anchorX");
        NSNumber* anchorY = objc_getAssociatedObject(annotation, "anchorY");

        NSArray* iconConfig = objc_getAssociatedObject(annotation, "iconConfig");
            if (iconConfig != nil && iconConfig.count > 0) {
                NSString* type = iconConfig[0];
                UIImage* image = nil;
                if ([type isEqualToString:@"fromAssetImage"] || [type isEqualToString:@"fromAsset"]) {
                    NSString* assetName = iconConfig[1];
                    NSString* key = [FlutterDartProject lookupKeyForAsset:assetName];
                    NSString* path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
                    image = [UIImage imageWithContentsOfFile:path];
                    // handle scale if needed, usually handled by Flutter's asset resolution logic or providing already scaled name.
                    // For simplicity, we load the file.
                } else if ([type isEqualToString:@"fromBytes"]) {
                    FlutterStandardTypedData* byteData = iconConfig[1];
                    double scale = 1.0;
                    if (iconConfig.count > 3 && ![iconConfig[3] isKindOfClass:[NSNull class]]) {
                        scale = [iconConfig[3] doubleValue];
                    }
                    image = [UIImage imageWithData:byteData.data scale:scale];
                    
                    if (iconConfig.count > 2) {
                        NSArray* sizeList = iconConfig[2];
                        if ([sizeList isKindOfClass:[NSArray class]] && sizeList.count == 2) {
                             double width = [sizeList[0] doubleValue];
                             double height = [sizeList[1] doubleValue];
                             if (width > 0 && height > 0) {
                                 // NSLog(@"Resizing image to: %f x %f", width, height);
                                 UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 0.0);
                                 [image drawInRect:CGRectMake(0, 0, width, height)];
                                 image = UIGraphicsGetImageFromCurrentImageContext();
                                 UIGraphicsEndImageContext();
                             }
                        }
                    }
                }
                
                // If we have a custom image config, we should use MAAnnotationView instead of MAPinAnnotationView
                // Even if image is nil (failed), we return this to avoid showing the default purple pin.
                 MAAnnotationView* customView = [[MAAnnotationView alloc] initWithAnnotation:annotation];
                 if (image != nil) {
                    customView.image = image;
                 }
                 customView.canShowCallout = canShowCallout;
                 customView.draggable = YES;
                 
                 // Apply anchor
                 if (anchorX != nil && anchorY != nil) {
                     double u = [anchorX doubleValue];
                     double v = [anchorY doubleValue];
                     if (image != nil) {
                        customView.centerOffset = CGPointMake((0.5 - u) * image.size.width, (0.5 - v) * image.size.height);
                     }
                 } else {
                     // Default behavior if no anchor specified: usually center or bottom-center.
                     // Legacy code assumed bottom center:
                     if (image != nil) {
                        customView.centerOffset = CGPointMake(0, -image.size.height / 2);
                     }
                 }
                 return customView;
            }
            
            // For default pin, we might still want to apply anchor if customized, but usually pin anchor is fixed.
            // We only modify canShowCallout here for default pin.
            
            return annotationView;
    }
    return nil;
}

- (void)map:(MAMap *)map didSelectAnnotationView:(MAAnnotationView *)view
{
    id<MAAnnotation> annotation = view.annotation;
    NSString *markerId = objc_getAssociatedObject(annotation, "markerId");
    if (markerId != nil) {
         [self->_channel invokeMethod:@"onMarkerClick" arguments:@{@"markerId" : markerId}];
    }
}

- (void)map:(MAMap *)map annotationView:(MAAnnotationView *)view didChangeDragState:(MAAnnotationViewDragState)newState fromOldState:(MAAnnotationViewDragState)oldState {
    if (newState == MAAnnotationViewDragStateEnding) {
        id<MAAnnotation> annotation = view.annotation;
        NSString *markerId = objc_getAssociatedObject(annotation, "markerId");
        if (markerId != nil) {
            NSDictionary* arguments = @{
                @"markerId" : markerId,
                @"latitude" : @(annotation.coordinate.latitude),
                @"longitude" : @(annotation.coordinate.longitude)
            };
            [self->_channel invokeMethod:@"onMarkerDragEnd" arguments:arguments];
        }
    }
}

- (UIColor *)colorFromNumber:(NSNumber *)number {
    unsigned long value = [number unsignedLongValue];
    CGFloat alpha = ((value >> 24) & 0xFF) / 255.0f;
    CGFloat red   = ((value >> 16) & 0xFF) / 255.0f;
    CGFloat green = ((value >> 8)  & 0xFF) / 255.0f;
    CGFloat blue  = (value         & 0xFF) / 255.0f;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

//接收位置更新,实现AMapLocationManagerDelegate代理的amapLocationManager:didUpdateLocation方法，处理位置更新
- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode{
    if (!CLLocationCoordinate2DIsValid(location.coordinate)) {
        return;
    }
    
    // 同步给Lite SDK地图以更新蓝点
    [_map setUserLocation:location coordinateType:AMapCoordinateTypeAMap];
    
    [self searchPOI:location.coordinate.latitude lon:location.coordinate.longitude];
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    [_map setUserHeading:newHeading];
}

/* POI 搜索回调. */
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response{
    if (response.pois.count == 0) {
        NSDictionary* arguments = @{@"poiSearchResult" : @"[]"};
        [_channel invokeMethod:@"poiSearchResult" arguments:arguments];
        return;
    }
    
    //1. 初始化可变字符串，存放最终生成json字串
    NSMutableString *jsonString = [[NSMutableString alloc] initWithString:@"["];
    
    [response.pois enumerateObjectsUsingBlock:^(AMapPOI *obj, NSUInteger idx, BOOL *stop) {
        
        if (idx == 0) {
            CLLocationCoordinate2D center;
            center.latitude = obj.location.latitude;
            center.longitude = obj.location.longitude;
            [self->_map setZoomLevel:17 animated: YES];
            [self->_map setCenterCoordinate:center animated:YES];
            if (self->_showClickMarker) {
                [self drawMarkers:obj.location.latitude lon:obj.location.longitude];
            }
        }
        //2. 遍历数组，取出键值对并按json格式存放
        NSString *string  = [NSString stringWithFormat:@"{\"cityCode\":\"%@\",\"cityName\":\"%@\",\"provinceName\":\"%@\",\"title\":\"%@\",\"adName\":\"%@\",\"provinceCode\":\"%@\",\"latitude\":\"%f\",\"longitude\":\"%f\"},", obj.citycode, obj.city, obj.province, obj.name, obj.district, obj.pcode, obj.location.latitude, obj.location.longitude];
        [jsonString appendString:string];
        
    }];
    
    // 3. 获取末尾逗号所在位置
    NSUInteger location = [jsonString length] - 1;
    
    NSRange range = NSMakeRange(location, 1);
    
    // 4. 将末尾逗号换成结束的]
    [jsonString replaceCharactersInRange:range withString:@"]"];
    
    NSDictionary* arguments = @{
                                @"poiSearchResult" : jsonString
                                };
    [_channel invokeMethod:@"poiSearchResult" arguments:arguments];
    
}

//字典转Json
- (NSString*)dictionaryToJson:(NSDictionary *)dic {
    NSError *parseError = nil;
    NSData  *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (UIView*)view {
    return _webViewContainer.webView;
}
    
//检查是否授予定位权限
- (bool)hasPermission{
    CLAuthorizationStatus locationStatus =  [CLLocationManager authorizationStatus];
    return (bool)(locationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || locationStatus == kCLAuthorizationStatusAuthorizedAlways);
}

- (void)drawMarkers:(CGFloat)lat lon:(CGFloat)lon {
    if (self->_pointAnnotation == NULL) {
        self->_pointAnnotation = [[MAPointAnnotation alloc] init];
        self->_pointAnnotation.coordinate = CLLocationCoordinate2DMake(lat, lon);
        [self->_map addAnnotation:self->_pointAnnotation];
    } else {
        self->_pointAnnotation.coordinate = CLLocationCoordinate2DMake(lat, lon);
    }
}

- (void)searchPOI:(CGFloat)lat lon:(CGFloat)lon{
    
    if (_isPoiSearch) {
        AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
        request.types               = _types;
        request.requireExtension    = YES;
        request.offset              = 50;
        request.location            = [AMapGeoPoint locationWithLatitude:lat longitude:lon];
        [self.search AMapPOIAroundSearch:request];
    }
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([[call method] isEqualToString:@"search"]) {
        if (_isPoiSearch) {
            AMapPOIKeywordsSearchRequest *request = [[AMapPOIKeywordsSearchRequest alloc] init];
            request.types               = _types;
            request.requireExtension    = YES;
            request.offset              = 50;
            request.keywords            = [call arguments][@"keyWord"];
            request.city                = [call arguments][@"city"];
            [self.search AMapPOIKeywordsSearch:request];
        }
    } else if ([[call method] isEqualToString:@"move"]) {
        NSString* lat = [call arguments][@"lat"];
        NSString* lon = [call arguments][@"lon"];
        CLLocationCoordinate2D center;
        center.latitude = [lat doubleValue];
        center.longitude = [lon doubleValue];
        [self->_map setCenterCoordinate:center animated:YES];
        [self drawMarkers:[lat doubleValue] lon:[lon doubleValue]];
    } else if ([[call method] isEqualToString:@"location"]) {
        [self.locationManager startUpdatingLocation]; 
    } else if ([[call method] isEqualToString:@"addMarker"]) {
        NSDictionary* positionArgs = [call arguments][@"position"];
        NSString* title = [call arguments][@"title"];
        NSString* snippet = [call arguments][@"snippet"];
        NSString* markerId = [call arguments][@"id"];
        NSNumber* anchorX = [call arguments][@"anchorX"];
        NSNumber* anchorY = [call arguments][@"anchorY"];
        NSNumber* infoWindowEnable = [call arguments][@"infoWindowEnable"];
        
        MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
        
        if (positionArgs != nil) {
             annotation.coordinate = CLLocationCoordinate2DMake([positionArgs[@"latitude"] doubleValue], [positionArgs[@"longitude"] doubleValue]);
        }
        
        if (title != nil) {
            annotation.title = title;
        }
        if (snippet != nil) {
            annotation.subtitle = snippet;
        }
        
        if (markerId != nil) {
             objc_setAssociatedObject(annotation, "markerId", markerId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
             [self->_markerMap setObject:annotation forKey:markerId];
        }
        if (anchorX != nil) {
             objc_setAssociatedObject(annotation, "anchorX", anchorX, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (anchorY != nil) {
             objc_setAssociatedObject(annotation, "anchorY", anchorY, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (infoWindowEnable != nil) {
             objc_setAssociatedObject(annotation, "infoWindowEnable", infoWindowEnable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        id iconObj = [call arguments][@"icon"];
        if (iconObj != nil && [iconObj isKindOfClass:[NSArray class]]) {
            // If custom icon is present, we need to store it to use in `viewForAnnotation` delegate.
            // However, MAPointAnnotation is a data object. We need to associate the icon config with it.
            objc_setAssociatedObject(annotation, "iconConfig", iconObj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        [self->_map addAnnotation:annotation];
        result(nil);
    } else if ([[call method] isEqualToString:@"updateMarker"]) {
        NSDictionary* positionArgs = [call arguments][@"position"];
        NSString* title = [call arguments][@"title"];
        NSString* snippet = [call arguments][@"snippet"];
        NSString* markerId = [call arguments][@"id"];
        NSNumber* anchorX = [call arguments][@"anchorX"];
        NSNumber* anchorY = [call arguments][@"anchorY"];
        NSNumber* infoWindowEnable = [call arguments][@"infoWindowEnable"];
        id iconObj = [call arguments][@"icon"];
        
        MAPointAnnotation* annotation = [self->_markerMap objectForKey:markerId];
        if (annotation != nil) {
            if (positionArgs != nil) {
                annotation.coordinate = CLLocationCoordinate2DMake([positionArgs[@"latitude"] doubleValue], [positionArgs[@"longitude"] doubleValue]);
            }
            if (title != nil) {
                annotation.title = title;
            }
            if (snippet != nil) {
                annotation.subtitle = snippet;
            }
            
            // For other properties, we update associated objects.
            // If they affect visual appearance (icon, anchor), we might need to refresh view.
            
            if (anchorX != nil) {
                 objc_setAssociatedObject(annotation, "anchorX", anchorX, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            if (anchorY != nil) {
                 objc_setAssociatedObject(annotation, "anchorY", anchorY, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            if (infoWindowEnable != nil) {
                 objc_setAssociatedObject(annotation, "infoWindowEnable", infoWindowEnable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            if (iconObj != nil && [iconObj isKindOfClass:[NSArray class]]) {
                 objc_setAssociatedObject(annotation, "iconConfig", iconObj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            
            // To ensure UI updates for custom view properties (icon, anchor), we get the view and update it, 
            // or re-add annotation.
            // Re-adding is simplest to ensure full state consistency via viewForAnnotation.
            [self->_map removeAnnotation:annotation];
            [self->_map addAnnotation:annotation];
        }
        result(nil);
    } else if ([[call method] isEqualToString:@"removeMarker"]) {
        NSString* markerId = [call arguments][@"id"];
        MAPointAnnotation* annotation = [self->_markerMap objectForKey:markerId];
        if (annotation != nil) {
            [self->_map removeAnnotation:annotation];
            [self->_markerMap removeObjectForKey:markerId];
        }
    } else if ([[call method] isEqualToString:@"addPolyline"]) {
        NSArray* points = [call arguments][@"points"];
        NSNumber* width = [call arguments][@"width"];
        NSNumber* color = [call arguments][@"color"];
        // isDottedLine and geodesic might need custom renderer handling or verified 2D SDK support.
        // Standard MAPolylineRenderer has lineDashPattern for dotted lines.

        if (points != nil && points.count > 0) {
            CLLocationCoordinate2D commonPolylineCoords[points.count];
            for (int i = 0; i < points.count; i++) {
                NSDictionary* point = points[i];
                commonPolylineCoords[i].latitude = [point[@"latitude"] doubleValue];
                commonPolylineCoords[i].longitude = [point[@"longitude"] doubleValue];
            }
            
            MAPolyline *polyline = [MAPolyline polylineWithCoordinates:commonPolylineCoords count:points.count];
            
            objc_setAssociatedObject(polyline, "strokeWidth", width, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(polyline, "strokeColor", color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            // Storing dotted line config if needed
            NSNumber *isDottedLine = [call arguments][@"isDottedLine"];
            objc_setAssociatedObject(polyline, "isDottedLine", isDottedLine, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            NSNumber *visible = [call arguments][@"visible"];
            objc_setAssociatedObject(polyline, "visible", visible, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            NSNumber *joinType = [call arguments][@"joinType"];
            objc_setAssociatedObject(polyline, "joinType", joinType, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            [self->_map addOverlay:polyline];
        }
    } else if ([[call method] isEqualToString:@"addPolygon"]) {
        NSArray* points = [call arguments][@"points"];
        NSNumber* strokeWidth = [call arguments][@"strokeWidth"];
        NSNumber* strokeColor = [call arguments][@"strokeColor"];
        NSNumber* fillColor = [call arguments][@"fillColor"];

        if (points != nil && points.count > 0) {
            CLLocationCoordinate2D commonPolylineCoords[points.count];
            for (int i = 0; i < points.count; i++) {
                NSDictionary* point = points[i];
                commonPolylineCoords[i].latitude = [point[@"latitude"] doubleValue];
                commonPolylineCoords[i].longitude = [point[@"longitude"] doubleValue];
            }
            
            MAPolygon *polygon = [MAPolygon polygonWithCoordinates:commonPolylineCoords count:points.count];
            // We need to store these properties to use them in rendererForOverlay
            // Since MAPolygon doesn't hold style info directly, we might need a custom subclass or associate object.
            // For simplicity in this step, I'll rely on rendererForOverlay hook which I need to implement.
            // However, the standard MAPolygon doesn't carry color info.
            // I will use objc_setAssociatedObject to attach style info to the polygon instance.
            
            objc_setAssociatedObject(polygon, "strokeWidth", strokeWidth, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(polygon, "strokeColor", strokeColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(polygon, "fillColor", fillColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

            objc_setAssociatedObject(polygon, "fillColor", fillColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

            [self->_map addOverlay:polygon];
            NSString* id = [call arguments][@"id"];
            if (id != nil) {
                [self->_polygonMap setObject:polygon forKey:id];
            }
        }
    } else if ([[call method] isEqualToString:@"updatePolygon"]) {
        NSString* id = [call arguments][@"id"];
        MAPolygon* oldPolygon = [self->_polygonMap objectForKey:id];
        if (oldPolygon != nil) {
            [self->_map removeOverlay:oldPolygon];
            
            // Re-add new polygon (since MAPolygon geometry is immutable)
             NSArray* points = [call arguments][@"points"];
            NSNumber* strokeWidth = [call arguments][@"strokeWidth"];
            NSNumber* strokeColor = [call arguments][@"strokeColor"];
            NSNumber* fillColor = [call arguments][@"fillColor"];

            if (points != nil && points.count > 0) {
                CLLocationCoordinate2D commonPolylineCoords[points.count];
                for (int i = 0; i < points.count; i++) {
                    NSDictionary* point = points[i];
                    commonPolylineCoords[i].latitude = [point[@"latitude"] doubleValue];
                    commonPolylineCoords[i].longitude = [point[@"longitude"] doubleValue];
                }
                MAPolygon *polygon = [MAPolygon polygonWithCoordinates:commonPolylineCoords count:points.count];
                objc_setAssociatedObject(polygon, "strokeWidth", strokeWidth, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(polygon, "strokeColor", strokeColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(polygon, "fillColor", fillColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                
                [self->_map addOverlay:polygon];
                [self->_polygonMap setObject:polygon forKey:id];
            }
        }
    } else if ([[call method] isEqualToString:@"removePolygon"]) {
        NSString* id = [call arguments][@"id"];
        MAPolygon* polygon = [self->_polygonMap objectForKey:id];
        if (polygon != nil) {
            [self->_map removeOverlay:polygon];
            [self->_polygonMap removeObjectForKey:id];
        }
    } else if ([[call method] isEqualToString:@"clear"]) {
        [self->_map removeAnnotations:self->_map.annotations];
        [self->_map removeOverlays:self->_map.overlays];
        [self->_polygonMap removeAllObjects];
        [self->_markerMap removeAllObjects];
        self->_pointAnnotation = nil;
    } else if ([[call method] isEqualToString:@"moveCamera"]) {
        [self moveCamera:[call arguments]];
    } else if ([[call method] isEqualToString:@"animateCamera"]) {
        [self animateCamera:[call arguments]];
    } else if ([[call method] isEqualToString:@"getLocation"]) {
        CLLocation* location = self->_map.userLocation.location;
        if (location != nil && CLLocationCoordinate2DIsValid(location.coordinate)) {
            result(@{
                @"latitude" : @(location.coordinate.latitude),
                @"longitude" : @(location.coordinate.longitude)
            });
        } else {
            result(nil);
        }
    }
}

- (void)moveCamera:(id)arguments {
    [self updateCamera:arguments animated:NO];
}

- (void)animateCamera:(NSDictionary*)arguments {
    id cameraUpdate = arguments[@"cameraUpdate"];
    [self updateCamera:cameraUpdate animated:YES];
}

- (void)updateCamera:(NSArray*)arguments animated:(BOOL)animated {
    if (arguments.count == 0 || _map == nil) return;
    NSString* type = arguments[0];
    
    if ([type isEqualToString:@"newLatLng"]) {
        NSDictionary* latLng = arguments[1];
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake([latLng[@"latitude"] doubleValue], [latLng[@"longitude"] doubleValue]);
        [self->_map setCenterCoordinate:center animated:animated];
    } else if ([type isEqualToString:@"newLatLngZoom"]) {
        NSDictionary* latLng = arguments[1];
        double zoom = [arguments[2] doubleValue];
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake([latLng[@"latitude"] doubleValue], [latLng[@"longitude"] doubleValue]);
        [self->_map setZoomLevel:zoom animated:animated];
        [self->_map setCenterCoordinate:center animated:animated];
    } else if ([type isEqualToString:@"zoomIn"]) {
        [self->_map setZoomLevel:self->_map.zoomLevel + 1 animated:animated];
    } else if ([type isEqualToString:@"zoomOut"]) {
        [self->_map setZoomLevel:self->_map.zoomLevel - 1 animated:animated];
    } else if ([type isEqualToString:@"zoomTo"]) {
        double zoom = [arguments[1] doubleValue];
        [self->_map setZoomLevel:zoom animated:animated];
    } else if ([type isEqualToString:@"scrollBy"]) {
        double x = [arguments[1] doubleValue];
        double y = [arguments[2] doubleValue];
        
        __weak __typeof__(self) weakSelf = self;
        [self->_map convertCoordinate:self->_map.centerCoordinate completeCallback:^(CGPoint centerPoint) {
            __strong __typeof__(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            CGPoint newPoint = CGPointMake(centerPoint.x + x, centerPoint.y + y);
            [strongSelf->_map convertPoint:newPoint completeCallback:^(CLLocationCoordinate2D newCenter) {
                __strong __typeof__(weakSelf) strongSelf2 = weakSelf;
                if (!strongSelf2) return;
                [strongSelf2->_map setCenterCoordinate:newCenter animated:animated];
            }];
        }];
    } else if ([type isEqualToString:@"newCameraPosition"]) {
        NSDictionary* cameraParams = arguments[1];
        NSDictionary* targetMap = cameraParams[@"target"];
        double zoom = [cameraParams[@"zoom"] doubleValue];
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake([targetMap[@"latitude"] doubleValue], [targetMap[@"longitude"] doubleValue]);
        [self->_map setZoomLevel:zoom animated:animated];
        [self->_map setCenterCoordinate:center animated:animated];
    }
}
- (void)mapRegionChanged:(MAMap *)map {
    if (_onCameraChange) {
        NSDictionary* arguments = @{
            @"latitude" : @(map.centerCoordinate.latitude),
            @"longitude" : @(map.centerCoordinate.longitude)
        };
        [_channel invokeMethod:@"onCameraChange" arguments:arguments];
    }
}

- (void)mapRegionDidChanged:(MAMap *)map {
    if (_onCameraChangeFinish) {
        NSDictionary* arguments = @{
            @"latitude" : @(map.centerCoordinate.latitude),
            @"longitude" : @(map.centerCoordinate.longitude)
        };
        [_channel invokeMethod:@"onCameraChangeFinish" arguments:arguments];
    }
}
@end
