import 'package:flutter_2d_amap/flutter_2d_amap.dart';
import 'package:flutter_2d_amap/src/amap_2d_camera_update.dart';

abstract class AMapController {
  /// city：cityName（中文或中文全拼）、cityCode均可
  Future<void> search(String keyWord, {String city = ''});

  Future<void> move(String lat, String lon);

  Future<void> location();

  Future<void> addMarker(Marker marker);

  Marker? findMarker(String id);

  Future<void> updateMarker(Marker marker);

  Future<void> removeMarker(String id);

  Future<void> addPolyline(Polyline polyline);

  Future<void> addPolygon(Polygon polygon);

  Future<void> updatePolygon(Polygon polygon);

  Future<void> removePolygon(String id);

  Future<void> clear();

  Future<void> moveCamera(CameraUpdate update);

  Future<void> animateCamera(CameraUpdate update,
      {Duration duration = const Duration(milliseconds: 250)});

  /// 获取当前位置
  Future<LatLng?> getLocation();
}
