import 'dart:async';
import 'package:flutter_2d_amap/flutter_2d_amap.dart';

class AMap2DTool {
  /// 获取当前位置，支持超时设置
  /// [timeout] 超时时间，默认10秒
  static Future<LatLng> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Make a single request instead of polling
    // The native SDK will handle the timeout internally
    final LatLng? location = await Flutter2dAMap.getLocation()
        .timeout(timeout, onTimeout: () => null);

    if (location != null) {
      return location;
    }

    throw TimeoutException('Failed to get location: timeout');
  }
}
