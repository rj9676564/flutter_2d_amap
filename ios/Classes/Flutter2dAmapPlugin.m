#import "Flutter2dAmapPlugin.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import "FlutterAMap2D.h"
#import "AMapSearchAPI.h"

// Define a subclass to hold extra state
@interface AMap2DLocationManager : AMapLocationManager
@property (nonatomic, strong) NSString *pluginKey;
@property (nonatomic, copy) NSString *fullAccuracyPurposeKey;
@property (nonatomic, copy) FlutterResult flutterResult; // For onceLocation callbacks if needed
@property (nonatomic, assign) BOOL isLocating; // Track if a location request is in progress
@property (nonatomic, assign) BOOL isOnceLocation; // Track if this is a onceLocation request
@end

@implementation AMap2DLocationManager
@end

@interface Flutter2dAmapPlugin () <FlutterStreamHandler, AMapLocationManagerDelegate>
@property (nonatomic, strong) FlutterEventSink eventSink;
@property (nonatomic, strong) NSMutableDictionary<NSString*, AMap2DLocationManager*> *locationManagerMap;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSDictionary*> *locationOptionMap;
@end

@implementation Flutter2dAmapPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  // Existing Map Channel
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"plugins.weilu/flutter_2d_amap_"
            binaryMessenger:[registrar messenger]];
  Flutter2dAmapPlugin* instance = [[Flutter2dAmapPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];

  FlutterAMap2DFactory* aMap2DFactory =
  [[FlutterAMap2DFactory alloc] initWithMessenger:registrar.messenger];
  [registrar registerViewFactory:aMap2DFactory withId:@"plugins.weilu/flutter_2d_amap"];
    
  // New Location Method Channel
  FlutterMethodChannel* locationChannel = [FlutterMethodChannel
      methodChannelWithName:@"plugins.weilu/flutter_2d_amap_location"
            binaryMessenger:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:locationChannel];
    
  // New Location Event Channel
  FlutterEventChannel* eventChannel = [FlutterEventChannel
      eventChannelWithName:@"plugins.weilu/flutter_2d_amap_location_stream"
           binaryMessenger:[registrar messenger]];
  [eventChannel setStreamHandler:instance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _locationManagerMap = [NSMutableDictionary dictionary];
        _locationOptionMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
   // NSLog(@"call.method %@",call.method);
  if ([@"setKey" isEqualToString:call.method]) {
    NSString *key = call.arguments;
    [AMapServices sharedServices].enableHTTPS = YES;
    [AMapServices sharedServices].apiKey = key;
    result(@YES);
  } else if ([@"updatePrivacy" isEqualToString:call.method]) {
      [self updatePrivacyStatement:call.arguments];
      result(@YES);
  } else if ([@"getLocation" isEqualToString:call.method]) { // Simple one-shot location
      [self handleSimpleGetLocation:call result:result];
  } else if ([@"setApiKey" isEqualToString:call.method]) {
      NSDictionary *args = call.arguments;
      NSString *iosKey = args[@"ios"];
      if (iosKey) {
          [AMapServices sharedServices].apiKey = iosKey;
      }
      result(nil);
  } else if ([@"setLocationOption" isEqualToString:call.method]) {
      NSDictionary *args = call.arguments;
      NSString *pluginKey = args[@"pluginKey"];
      if (pluginKey) {
          self.locationOptionMap[pluginKey] = args;
          AMap2DLocationManager *manager = [self getLocationManager:pluginKey];
          [self parseOptions:args forManager:manager];
      }
      result(nil);
  } else if ([@"startLocation" isEqualToString:call.method]) {
      [self startLocation:call result:result];
  } else if ([@"stopLocation" isEqualToString:call.method]) {
      [self stopLocation:call];
      result(nil);
  } else if ([@"destroy" isEqualToString:call.method]) {
      [self destroyLocation:call];
      result(nil);
  } else if ([@"getSystemAccuracyAuthorization" isEqualToString:call.method]) {
      [self getSystemAccuracyAuthorization:call result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

// Logic for simple one-shot location (outside of the continuously managed instances)
- (void)handleSimpleGetLocation:(FlutterMethodCall*)call result:(FlutterResult)result {
      // Use a shared key for simple getLocation calls
      NSString *tempKey = @"simple_location_manager";
      AMap2DLocationManager *locationManager = self.locationManagerMap[tempKey];
      
      // Check if already locating
      if (locationManager && locationManager.isLocating) {
          result([FlutterError errorWithCode:@"LOCATION_IN_PROGRESS" 
                                     message:@"A location request is already in progress" 
                                     details:nil]);
          return;
      }
      
      // Create or reuse manager
      if (!locationManager) {
          locationManager = [[AMap2DLocationManager alloc] init];
          locationManager.delegate = self;
          [locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
          [locationManager setLocationTimeout:10];
          [locationManager setReGeocodeTimeout:5];
          self.locationManagerMap[tempKey] = locationManager;
      }
      
      locationManager.isLocating = YES;
      [locationManager requestLocationWithReGeocode:NO completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
          locationManager.isLocating = NO;
          if (error) {
               result([FlutterError errorWithCode:@"LOCATION_ERROR" 
                                          message:error.localizedDescription 
                                          details:@(error.code)]);
          } else {
               if (location) {
                   result(@{@"latitude": @(location.coordinate.latitude), 
                           @"longitude": @(location.coordinate.longitude)});
               } else {
                   result([FlutterError errorWithCode:@"LOCATION_ERROR" 
                                              message:@"Location is null" 
                                              details:nil]);
               }
          }
          [locationManager stopUpdatingLocation];
      }];
}

- (void)updatePrivacyStatement:(id)arguments {
    if ([arguments isKindOfClass:[NSString class]]) {
        // Old Logic compatibility
        if ([@"true" isEqualToString:arguments]) {
             [AMapSearchAPI updatePrivacyShow:AMapPrivacyShowStatusDidShow privacyInfo:AMapPrivacyInfoStatusDidContain];
            [AMapSearchAPI updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];
             [AMapLocationManager updatePrivacyShow:AMapPrivacyShowStatusDidShow privacyInfo:AMapPrivacyInfoStatusDidContain];
             [AMapLocationManager updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];
        } else {
             [AMapSearchAPI updatePrivacyShow:AMapPrivacyShowStatusNotShow privacyInfo:AMapPrivacyInfoStatusNotContain];
            [AMapSearchAPI updatePrivacyAgree:AMapPrivacyAgreeStatusNotAgree];
             [AMapLocationManager updatePrivacyShow:AMapPrivacyShowStatusNotShow privacyInfo:AMapPrivacyInfoStatusNotContain];
             [AMapLocationManager updatePrivacyAgree:AMapPrivacyAgreeStatusNotAgree];
        }
    } else if ([arguments isKindOfClass:[NSDictionary class]]) {
        // New Logic
        NSDictionary *args = (NSDictionary *)arguments;
        if ((AMapLocationVersionNumber) < 20800) {
            NSLog(@"当前定位SDK版本没有隐私合规接口，请升级定位SDK到2.8.0及以上版本");
            return;
        }
        if (args[@"hasContains"] != nil && args[@"hasShow"] != nil) {
            [AMapLocationManager updatePrivacyShow:[args[@"hasShow"] integerValue] privacyInfo:[args[@"hasContains"] integerValue]];
        }
        if (args[@"hasAgree"] != nil) {
            [AMapLocationManager updatePrivacyAgree:[args[@"hasAgree"] integerValue]];
        }
    }
}

- (AMap2DLocationManager*)getLocationManager:(NSString*)pluginKey {
    if (!pluginKey) return nil;
    AMap2DLocationManager *manager = self.locationManagerMap[pluginKey];
    if (!manager) {
        manager = [[AMap2DLocationManager alloc] init];
        manager.pluginKey = pluginKey;
        manager.locatingWithReGeocode = YES;
        manager.delegate = self;
        self.locationManagerMap[pluginKey] = manager;
    }
    return manager;
}

- (void)parseOptions:(NSDictionary*)options forManager:(AMap2DLocationManager*)manager {
    if (!options || !manager) return;
    
    if (options[@"allowsBackgroundLocationUpdates"]) {
        manager.allowsBackgroundLocationUpdates = [options[@"allowsBackgroundLocationUpdates"] boolValue];
    }
    
    if (options[@"needAddress"]) {
        manager.locatingWithReGeocode = [options[@"needAddress"] boolValue];
    }
    
    if (options[@"geoLanguage"]) {
        NSInteger val = [options[@"geoLanguage"] integerValue];
        if (val == 0) manager.reGeocodeLanguage = AMapLocationReGeocodeLanguageDefault;
        else if (val == 1) manager.reGeocodeLanguage = AMapLocationReGeocodeLanguageChinse;
        else if (val == 2) manager.reGeocodeLanguage = AMapLocationReGeocodeLanguageEnglish;
    }
    
    if (options[@"pausesLocationUpdatesAutomatically"]) {
        manager.pausesLocationUpdatesAutomatically = [options[@"pausesLocationUpdatesAutomatically"] boolValue];
    }
    
    if (options[@"desiredAccuracy"]) {
        NSInteger val = [options[@"desiredAccuracy"] integerValue];
        switch (val) {
            case 0: manager.desiredAccuracy = kCLLocationAccuracyBest; break;
            case 1: manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation; break;
            case 2: manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters; break;
            case 3: manager.desiredAccuracy = kCLLocationAccuracyHundredMeters; break;
            case 4: manager.desiredAccuracy = kCLLocationAccuracyKilometer; break;
            case 5: manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers; break;
            default: manager.desiredAccuracy = kCLLocationAccuracyBest; break;
        }
    }
    
    if (options[@"distanceFilter"]) {
        double val = [options[@"distanceFilter"] doubleValue];
        if (val == -1) manager.distanceFilter = kCLDistanceFilterNone;
        else if (val > 0) manager.distanceFilter = val;
    }
    
    if (@available(iOS 14.0, *)) {
        if (options[@"locationAccuracyAuthorizationMode"]) {
            NSInteger mode = [options[@"locationAccuracyAuthorizationMode"] integerValue];
            if (mode == 0) [manager setLocationAccuracyMode:AMapLocationFullAndReduceAccuracy];
            else if (mode == 1) [manager setLocationAccuracyMode:AMapLocationFullAccuracy];
            else if (mode == 2) [manager setLocationAccuracyMode:AMapLocationReduceAccuracy];
        }
        
        if (options[@"fullAccuracyPurposeKey"]) {
            manager.fullAccuracyPurposeKey = options[@"fullAccuracyPurposeKey"];
        }
    }
    
    if (options[@"locationTimeout"]) {
        manager.locationTimeout = [options[@"locationTimeout"] integerValue];
    }
     if (options[@"reGeocodeTimeout"]) {
        manager.reGeocodeTimeout = [options[@"reGeocodeTimeout"] integerValue];
    }
}

- (void)startLocation:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *pluginKey = call.arguments[@"pluginKey"];
    if (!pluginKey) return;
    
    AMap2DLocationManager *manager = [self getLocationManager:pluginKey];
    if (!manager) return;
    
    NSDictionary *options = self.locationOptionMap[pluginKey];
    BOOL onceLocation = NO;
    if (options && options[@"onceLocation"]) {
        onceLocation = [options[@"onceLocation"] boolValue];
    }
    
    if (onceLocation) {
        // Check if already locating
        if (manager.isLocating) {
            result([FlutterError errorWithCode:@"LOCATION_IN_PROGRESS" 
                                       message:@"A location request is already in progress" 
                                       details:nil]);
            return;
        }
        
        // Single location request
        manager.isLocating = YES;
        manager.isOnceLocation = YES;
        [manager requestLocationWithReGeocode:manager.locatingWithReGeocode completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
             manager.isLocating = NO;
             manager.isOnceLocation = NO;
             [self handleLocationCallback:location regeocode:regeocode error:error pluginKey:pluginKey];
        }];
    } else {
        // Continuous location updates
        manager.isOnceLocation = NO;
        manager.flutterResult = result; // not typically used for continuous, but consistent with pattern
        [manager startUpdatingLocation];
    }
    result(nil);
}

- (void)stopLocation:(FlutterMethodCall*)call {
    NSString *pluginKey = call.arguments[@"pluginKey"];
    if (!pluginKey) return;
    AMap2DLocationManager *manager = self.locationManagerMap[pluginKey];
    if (manager) {
        // Don't stop if a onceLocation request is in progress
        // The SDK will handle stopping automatically
        if (manager.isOnceLocation) {
            NSLog(@"[AMap2D] Skipping stopLocation - onceLocation request in progress");
            return;
        }
        manager.flutterResult = nil;
        [manager stopUpdatingLocation];
        NSLog(@"[AMap2D] stopLocation called for pluginKey: %@", pluginKey);
    }
}

- (void)destroyLocation:(FlutterMethodCall*)call {
    NSString *pluginKey = call.arguments[@"pluginKey"];
     if (!pluginKey) return;
     AMap2DLocationManager *manager = self.locationManagerMap[pluginKey];
     if (manager) {
         [manager stopUpdatingLocation];
         manager.delegate = nil;
         [self.locationManagerMap removeObjectForKey:pluginKey];
         [self.locationOptionMap removeObjectForKey:pluginKey];
     }
}

- (void)getSystemAccuracyAuthorization:(FlutterMethodCall*)call result:(FlutterResult)result {
     if (@available(iOS 14.0, *)) {
         NSString *pluginKey = call.arguments[@"pluginKey"];
         AMap2DLocationManager *manager = [self getLocationManager:pluginKey];
         // Need a manager instance to check this on iOS 14 effectively if using SDK wrappers?
         // Actually standard CLLocationManager can check it too, but SDK provides `currentAuthorization`?
         // SDK 2.6.5+ provides properties.
         // Let's use standard check if manager isn't strictly needed for this.
         // But the user code used `[manager currentAuthorization]`.
         // We'll stick to our previous implementation or try to match reference.
         // Reference: CLAccuracyAuthorization curacyAuthorization = [manager currentAuthorization];
         // Assuming manager is AMapLocationManager. checking header...
         // AMapLocationManager does NOT seem to have `currentAuthorization` exposed in all versions unless it's a category?
         // Use CLLocationManager directly as fallback which is safer.
         
          CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
          if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
              CLLocationManager *tempManager = [[CLLocationManager alloc] init];
              CLAccuracyAuthorization accuracy = tempManager.accuracyAuthorization;
              result(@(accuracy)); // 0: Full, 1: Reduced
          } else {
              result(@(-1));
          }
     } else {
         result(@(0));
     }
}

#pragma mark - FlutterStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    NSLog(@"[AMap2D] EventChannel onListen called - eventSink registered");
    self.eventSink = events;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    NSLog(@"[AMap2D] EventChannel onCancel called - eventSink cleared");
    self.eventSink = nil;
    return nil;
}

#pragma mark - AMapLocationManagerDelegate

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode {
    if ([manager isKindOfClass:[AMap2DLocationManager class]]) {
        [self handleLocationCallback:location regeocode:reGeocode error:nil pluginKey:((AMap2DLocationManager*)manager).pluginKey];
    }
}

- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error {
    if ([manager isKindOfClass:[AMap2DLocationManager class]]) {
         [self handleLocationCallback:nil regeocode:nil error:error pluginKey:((AMap2DLocationManager*)manager).pluginKey];
    }
}

- (void)amapLocationManager:(AMapLocationManager *)manager doRequireLocationAuth:(CLLocationManager*)locationManager {
    [locationManager requestWhenInUseAuthorization];
}

- (void)amapLocationManager:(AMapLocationManager *)manager doRequireTemporaryFullAccuracyAuth:(CLLocationManager*)locationManager completion:(void(^)(NSError *error))completion {
    if (@available(iOS 14.0, *)) {
        if ([manager isKindOfClass:[AMap2DLocationManager class]]) {
             AMap2DLocationManager *myManager = (AMap2DLocationManager*)manager;
             if (myManager.fullAccuracyPurposeKey && myManager.fullAccuracyPurposeKey.length > 0) {
                 [locationManager requestTemporaryFullAccuracyAuthorizationWithPurposeKey:myManager.fullAccuracyPurposeKey completion:^(NSError * _Nullable error) {
                     if (completion) completion(error);
                 }];
             } else {
                 // Log error or fallback
             }
        }
    }
}

#pragma mark - Helper

- (void)handleLocationCallback:(CLLocation*)location regeocode:(AMapLocationReGeocode*)reGeocode error:(NSError*)error pluginKey:(NSString*)pluginKey {
    NSLog(@"[AMap2D] handleLocationCallback called - pluginKey: %@, eventSink: %@, location: %@, error: %@", 
          pluginKey, self.eventSink ? @"YES" : @"NO", location, error);
    
    if (!self.eventSink || !pluginKey) {
        NSLog(@"[AMap2D] Callback skipped - eventSink: %@, pluginKey: %@", 
              self.eventSink ? @"exists" : @"nil", pluginKey ?: @"nil");
        return;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"pluginKey"] = pluginKey;
    dict[@"callbackTime"] = [self getFormatTime:[NSDate date]];
    
    if (error) {
        dict[@"errorCode"] = @(error.code);
        dict[@"errorInfo"] = error.localizedDescription;
    } else {
        if (location) {
            dict[@"latitude"] = @(location.coordinate.latitude);
            dict[@"longitude"] = @(location.coordinate.longitude);
            dict[@"accuracy"] = @(location.horizontalAccuracy);
            dict[@"altitude"] = @(location.altitude);
            dict[@"bearing"] = @(location.course);
            dict[@"speed"] = @(location.speed);
            dict[@"locationTime"] = [self getFormatTime:location.timestamp];
            dict[@"locationType"] = @(1);
        }
        if (reGeocode) {
            dict[@"address"] = reGeocode.formattedAddress;
            dict[@"country"] = reGeocode.country;
            dict[@"province"] = reGeocode.province;
            dict[@"city"] = reGeocode.city;
            dict[@"district"] = reGeocode.district;
            dict[@"cityCode"] = reGeocode.citycode;
            dict[@"adCode"] = reGeocode.adcode;
            dict[@"street"] = reGeocode.street;
            dict[@"streetNumber"] = reGeocode.number;
            dict[@"description"] = reGeocode.formattedAddress;
        }
    }
    
    NSLog(@"[AMap2D] Sending location data to Dart: %@", dict);
    self.eventSink(dict);
}


- (NSString *)getFormatTime:(NSDate*)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [formatter stringFromDate:date];
}

@end
