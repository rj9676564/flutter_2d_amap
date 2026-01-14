package com.weilu.flutter.flutter_2d_amap;

import androidx.annotation.NonNull;

import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;
import com.amap.api.location.AMapLocation;
import com.amap.api.services.core.ServiceSettings;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;

/**
 * Flutter2dAmapPlugin
 * @author weilu
 * */
public class Flutter2dAmapPlugin implements FlutterPlugin, ActivityAware{

  private AMap2DDelegate delegate;
  private FlutterPluginBinding pluginBinding;
  private ActivityPluginBinding activityBinding;
  private MethodChannel methodChannel;
  private MethodChannel locationMethodChannel;
  private EventChannel locationEventChannel;
  private EventChannel.EventSink locationEventSink;
  private java.util.Map<String, AMapLocationClient> locationClientMap = new java.util.HashMap<>();
  
  public Flutter2dAmapPlugin() {}
  
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    pluginBinding = binding;
    
    // Existing Map Channel
    BinaryMessenger messenger = pluginBinding.getBinaryMessenger();
    methodChannel = new MethodChannel(messenger, "plugins.weilu/flutter_2d_amap_");
    
    // New Location Channels
    locationMethodChannel = new MethodChannel(messenger, "plugins.weilu/flutter_2d_amap_location");
    locationEventChannel = new EventChannel(messenger, "plugins.weilu/flutter_2d_amap_location_stream");
    
    locationMethodChannel.setMethodCallHandler(new MethodChannel.MethodCallHandler() {
        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
            String method = call.method;
            String pluginKey = call.argument("pluginKey");
            
            switch (method) {
                case "setApiKey":
                    String androidKey = call.argument("android");
                    if (androidKey != null) {
                         AMapLocationClient.setApiKey(androidKey);
                    }
                    result.success(null);
                    break;
                case "setLocationOption":
                    if (pluginKey != null) {
                        AMapLocationClient client = getLocationClient(binding.getApplicationContext(), pluginKey);
                        AMapLocationClientOption option = new AMapLocationClientOption();
                        parseOptions(option, (java.util.Map) call.arguments);
                        client.setLocationOption(option);
                    }
                    result.success(null);
                    break;
                case "startLocation":
                    if (pluginKey != null) {
                        AMapLocationClient client = getLocationClient(binding.getApplicationContext(), pluginKey);
                        client.startLocation();
                    }
                    result.success(null);
                    break;
                case "stopLocation":
                    if (pluginKey != null) {
                         AMapLocationClient client = locationClientMap.get(pluginKey);
                         if (client != null) {
                             client.stopLocation();
                         }
                    }
                    result.success(null);
                    break;
                case "destroy":
                    if (pluginKey != null) {
                        AMapLocationClient client = locationClientMap.remove(pluginKey);
                        if (client != null) {
                            client.stopLocation();
                            client.onDestroy();
                        }
                    }
                    result.success(null);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        }
    });

    locationEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
        @Override
        public void onListen(Object arguments, EventChannel.EventSink events) {
            locationEventSink = events;
        }

        @Override
        public void onCancel(Object arguments) {
            locationEventSink = null;
        }
    });
  }

  private AMapLocationClient getLocationClient(android.content.Context context, String pluginKey) {
      if (locationClientMap.containsKey(pluginKey)) {
          return locationClientMap.get(pluginKey);
      }
      try {
          AMapLocationClient client = new AMapLocationClient(context);
          client.setLocationListener(aMapLocation -> {
              if (locationEventSink != null && aMapLocation != null) {
                  java.util.Map<String, Object> data = new java.util.HashMap<>();
                  data.put("pluginKey", pluginKey);
                  data.put("callbackTime", new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.getDefault()).format(new java.util.Date()));
                  if (aMapLocation.getErrorCode() == 0) {
                      data.put("latitude", aMapLocation.getLatitude());
                      data.put("longitude", aMapLocation.getLongitude());
                      data.put("accuracy", aMapLocation.getAccuracy());
                      data.put("altitude", aMapLocation.getAltitude());
                      data.put("bearing", aMapLocation.getBearing());
                      data.put("speed", aMapLocation.getSpeed());
                      data.put("address", aMapLocation.getAddress());
                      data.put("description", aMapLocation.getDescription());
                      data.put("adCode", aMapLocation.getAdCode());
                      data.put("cityCode", aMapLocation.getCityCode());
                      data.put("city", aMapLocation.getCity());
                      data.put("district", aMapLocation.getDistrict());
                      data.put("province", aMapLocation.getProvince());
                      data.put("street", aMapLocation.getStreet());
                      data.put("streetNumber", aMapLocation.getStreetNum());
                      data.put("locationType", aMapLocation.getLocationType());
                      data.put("locationTime", aMapLocation.getTime());
                  } else {
                      data.put("errorCode", aMapLocation.getErrorCode());
                      data.put("errorInfo", aMapLocation.getErrorInfo());
                  }
                  locationEventSink.success(data);
              }
          });
          locationClientMap.put(pluginKey, client);
          return client;
      } catch (Exception e) {
          e.printStackTrace();
      }
      return null;
  }
  
  private void parseOptions(AMapLocationClientOption option, java.util.Map args) {
      if (args == null) return;
      if (args.containsKey("locationInterval")) {
          option.setInterval(((Number)args.get("locationInterval")).longValue());
      }
      if (args.containsKey("needAddress")) {
          option.setNeedAddress((boolean)args.get("needAddress"));
      }
      if (args.containsKey("onceLocation")) {
          option.setOnceLocation((boolean)args.get("onceLocation"));
      }
      if (args.containsKey("locationMode")) {
          int mode = (int) args.get("locationMode");
          switch (mode) {
              case 0: option.setLocationMode(AMapLocationClientOption.AMapLocationMode.Battery_Saving); break;
              case 1: option.setLocationMode(AMapLocationClientOption.AMapLocationMode.Device_Sensors); break;
              case 2: option.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy); break;
          }
      }
      // Added other option parsing as needed...
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    pluginBinding = null;
    locationMethodChannel.setMethodCallHandler(null);
    locationEventChannel.setStreamHandler(null);
    for (AMapLocationClient client : locationClientMap.values()) {
        client.stopLocation();
        client.onDestroy();
    }
    locationClientMap.clear();
  }

  @Override
  public void onAttachedToActivity(@NonNull final ActivityPluginBinding binding) {
    activityBinding = binding;
    
    BinaryMessenger messenger = pluginBinding.getBinaryMessenger();
    AMap2DFactory mFactory = new AMap2DFactory(messenger, null);
    pluginBinding.getPlatformViewRegistry().registerViewFactory("plugins.weilu/flutter_2d_amap", mFactory);

    delegate = new AMap2DDelegate(binding.getActivity());
    binding.addRequestPermissionsResultListener(delegate);
    mFactory.setDelegate(delegate);

    methodChannel = new MethodChannel(messenger, "plugins.weilu/flutter_2d_amap_");
    methodChannel.setMethodCallHandler(new MethodChannel.MethodCallHandler() {
      @Override
      public void onMethodCall(@NonNull MethodCall methodCall, @NonNull MethodChannel.Result result) {
        String method = methodCall.method;
        switch(method) {
          case "updatePrivacy":
            boolean isAgree = "true".equals(methodCall.arguments);
            ServiceSettings.updatePrivacyShow(binding.getActivity(), isAgree, isAgree);
            ServiceSettings.updatePrivacyAgree(binding.getActivity(), isAgree);
            AMapLocationClient.updatePrivacyShow(binding.getActivity(), isAgree, isAgree);
            AMapLocationClient.updatePrivacyAgree(binding.getActivity(), isAgree);
            break;
          case "getLocation":
            try {
                final AMapLocationClient client = new AMapLocationClient(pluginBinding.getApplicationContext());
                AMapLocationClientOption option = new AMapLocationClientOption();
                option.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy);
                option.setOnceLocation(true);
                client.setLocationOption(option);
                client.setLocationListener(new AMapLocationListener() {
                  @Override
                  public void onLocationChanged(AMapLocation aMapLocation) {
                    if (aMapLocation != null) {
                      if (aMapLocation.getErrorCode() == 0) {
                        java.util.Map<String, Double> loc = new java.util.HashMap<>();
                        loc.put("latitude", aMapLocation.getLatitude());
                        loc.put("longitude", aMapLocation.getLongitude());
                        result.success(loc);
                      } else {
                        result.error("LOCATION_ERROR", "ErrCode:" + aMapLocation.getErrorCode() + ", errInfo:" + aMapLocation.getErrorInfo(), null);
                      }
                    } else {
                      result.error("LOCATION_ERROR", "Location is null", null);
                    }
                    client.stopLocation();
                    client.onDestroy();
                  }
                });
                client.startLocation();
            } catch (Exception e) {
                result.error("LOCATION_ERROR", e.getMessage(), null);
                e.printStackTrace();
            }
            break;
          default:
            break;
        }
      }
    });

  }

  @Override
  public void onDetachedFromActivity() {
    tearDown();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  private void tearDown() {
    activityBinding.removeRequestPermissionsResultListener(delegate);
    activityBinding = null;
    delegate = null;
    methodChannel.setMethodCallHandler(null);
  }
}
