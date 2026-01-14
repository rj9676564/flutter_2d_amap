import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'amap_location_option.dart';

/// iOS 14中系统的定位类型信息
enum AMap2DAccuracyAuthorization {
  /// 系统的精确定位类型
  AMapAccuracyAuthorizationFullAccuracy,

  /// 系统的模糊定位类型
  AMapAccuracyAuthorizationReducedAccuracy,

  /// 未知类型
  AMapAccuracyAuthorizationInvalid
}

/// 高德定位Flutter插件入口类
class AMap2DLocation {
  static const String _CHANNEL_METHOD_LOCATION =
      "plugins.weilu/flutter_2d_amap_location";
  static const String _CHANNEL_STREAM_LOCATION =
      "plugins.weilu/flutter_2d_amap_location_stream";

  static const MethodChannel _methodChannel =
      const MethodChannel(_CHANNEL_METHOD_LOCATION);

  static const EventChannel _eventChannel =
      const EventChannel(_CHANNEL_STREAM_LOCATION);

  static Stream<Map<String, Object>> _onLocationChanged = _eventChannel
      .receiveBroadcastStream()
      .asBroadcastStream()
      .map<Map<String, Object>>((element) => element.cast<String, Object>());

  StreamController<Map<String, Object>>? _receiveStream;
  StreamSubscription<Map<String, Object>>? _subscription;
  String? _pluginKey;

  /// 适配iOS 14定位新特性，只在iOS平台有效
  Future<AMap2DAccuracyAuthorization> getSystemAccuracyAuthorization() async {
    int result = -1;
    if (Platform.isIOS) {
      result = await _methodChannel.invokeMethod(
          "getSystemAccuracyAuthorization", {'pluginKey': _pluginKey});
    }
    if (result == 0) {
      return AMap2DAccuracyAuthorization.AMapAccuracyAuthorizationFullAccuracy;
    } else if (result == 1) {
      return AMap2DAccuracyAuthorization
          .AMapAccuracyAuthorizationReducedAccuracy;
    }
    return AMap2DAccuracyAuthorization.AMapAccuracyAuthorizationInvalid;
  }

  /// 初始化
  AMap2DLocation() {
    _pluginKey = DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 开始定位
  void startLocation() {
    _methodChannel.invokeMethod('startLocation', {'pluginKey': _pluginKey});
    return;
  }

  /// 停止定位
  void stopLocation() {
    _methodChannel.invokeMethod('stopLocation', {'pluginKey': _pluginKey});
    return;
  }

  /// 设置Android和iOS的apikey，建议在weigdet初始化时设置<br>
  /// apiKey的申请请参考高德开放平台官网<br>
  /// Android端: https://lbs.amap.com/api/android-location-sdk/guide/create-project/get-key<br>
  /// iOS端: https://lbs.amap.com/api/ios-location-sdk/guide/create-project/get-key<br>
  /// [androidKey] Android平台的key<br>
  /// [iosKey] ios平台的key<br>
  static void setApiKey(String androidKey, String iosKey) {
    _methodChannel
        .invokeMethod('setApiKey', {'android': androidKey, 'ios': iosKey});
  }

  /// 设置定位参数
  void setLocationOption(AMap2DLocationOption locationOption) {
    Map option = locationOption.getOptionsMap();
    option['pluginKey'] = _pluginKey;
    _methodChannel.invokeMethod('setLocationOption', option);
  }

  /// 销毁定位
  void destroy() {
    _methodChannel.invokeListMethod('destroy', {'pluginKey': _pluginKey});
    if (_subscription != null) {
      _receiveStream?.close();
      _subscription?.cancel();
      _receiveStream = null;
      _subscription = null;
    }
  }

  /// 定位结果回调
  Stream<Map<String, Object>> onLocationChanged() {
    if (_receiveStream == null) {
      _receiveStream = StreamController();
      _subscription = _onLocationChanged.listen((Map<String, Object> event) {
        if (event['pluginKey'] == _pluginKey) {
          Map<String, Object> newEvent = Map<String, Object>.of(event);
          newEvent.remove('pluginKey');
          _receiveStream?.add(newEvent);
        }
      });
    }
    return _receiveStream!.stream;
  }

  /// 获取单次定位 result is [Map]
  ///
  /// 默认超时时间 10秒
  Future<Map<String, Object>> getLocation(AMap2DLocationOption option,
      {Duration timeout = const Duration(seconds: 10)}) async {
    option.onceLocation = true;
    setLocationOption(option);

    final Completer<Map<String, Object>> completer = Completer();
    StreamSubscription<Map<String, Object>>? subscription;

    // Listen directly to the global stream, not the filtered one
    // This avoids interfering with the shared _receiveStream
    subscription = _onLocationChanged.listen((Map<String, Object> event) {
      // Filter by pluginKey
      if (event['pluginKey'] == _pluginKey) {
        if (!completer.isCompleted) {
          Map<String, Object> newEvent = Map<String, Object>.of(event);
          newEvent.remove('pluginKey');
          completer.complete(newEvent);
        }
        subscription?.cancel();
        // Don't call stopLocation() for onceLocation - SDK handles it automatically
      }
    }, onError: (Object error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
      subscription?.cancel();
      // Don't call stopLocation() here either
    });

    startLocation();

    return completer.future.timeout(timeout, onTimeout: () {
      subscription?.cancel();
      stopLocation(); // Only stop on timeout
      throw TimeoutException("Location timeout");
    });
  }
}
