import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'src/amap_2d_lat_lng.dart';

export 'src/amap_2d_view.dart';
export 'src/interface/amap_2d_controller.dart';
export 'src/poi_search_model.dart';
export 'src/amap_2d_marker.dart';
export 'src/amap_2d_polygon.dart';
export 'src/amap_2d_lat_lng.dart';
export 'src/amap_2d_lat_lng_bounds.dart';
export 'src/amap_2d_poi.dart';
export 'src/amap_2d_camera_update.dart';
export 'src/amap_2d_camera_position.dart';
export 'src/amap_2d_bitmap_descriptor.dart';
export 'src/amap_2d_polyline.dart';
export 'src/amap_2d_enums.dart';
export 'src/amap_2d_info_window.dart';
export 'src/amap_2d_tool.dart';
export 'src/amap_location_option.dart';
export 'src/amap_flutter_location.dart';

class Flutter2dAMap {
  static const MethodChannel _channel =
      MethodChannel('plugins.weilu/flutter_2d_amap_');

  static String _webKey = '';
  static String get webKey => _webKey;

  static Future<bool?> setApiKey(
      {String iOSKey = '', String webKey = ''}) async {
    if (kIsWeb) {
      _webKey = webKey;
    } else {
      if (Platform.isIOS) {
        return _channel.invokeMethod<bool>('setKey', iOSKey);
      }
    }
    return Future.value(true);
  }

  static Future<LatLng?> getLocation() async {
    final Map<dynamic, dynamic>? result =
        await _channel.invokeMethod('getLocation');
    if (result == null) return null;
    return LatLng(
      (result['latitude'] as num).toDouble(),
      (result['longitude'] as num).toDouble(),
    );
  }

  /// 更新同意隐私状态,需要在初始化地图之前完成
  static Future<void> updatePrivacy(bool isAgree) async {
    if (kIsWeb) {
    } else {
      if (Platform.isIOS || Platform.isAndroid) {
        await _channel.invokeMethod<bool>('updatePrivacy', isAgree.toString());
      }
    }
  }
}
