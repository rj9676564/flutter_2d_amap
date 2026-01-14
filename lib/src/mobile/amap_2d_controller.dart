import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_2d_amap/flutter_2d_amap.dart';
import 'package:flutter_2d_amap/src/amap_2d_camera_update.dart';

class AMapMobileController extends AMapController {
  AMapMobileController(
    int id,
    this._widget,
  ) : _channel = MethodChannel('plugins.weilu/flutter_2d_amap_$id') {
    _channel.setMethodCallHandler(_handleMethod);
  }
  final MethodChannel _channel;

  final AMapView _widget;

  final Map<String, Marker> _markers = <String, Marker>{};

  Future<dynamic> _handleMethod(MethodCall call) async {
    final String method = call.method;
    switch (method) {
      case 'poiSearchResult':
        {
          if (_widget.onPoiSearched != null) {
            final Map<dynamic, dynamic> args =
                call.arguments as Map<dynamic, dynamic>;
            final List<PoiSearch> list = [];
            for (final value
                in json.decode(args['poiSearchResult'] as String) as List) {
              list.add(PoiSearch.fromJsonMap(value as Map<String, dynamic>));
            }
            _widget.onPoiSearched!(list);
            _widget.onPoiSearched!(list);
          }
          return Future<dynamic>.value('');
        }
      case 'onPoiClick':
        {
          if (_widget.onPoiClick != null) {
            final Map<dynamic, dynamic> args =
                call.arguments as Map<dynamic, dynamic>;
            final Poi poi = Poi(
              id: args['poiId'] as String,
              name: args['poiName'] as String,
              latLng: LatLng(
                (args['latitude'] as num).toDouble(),
                (args['longitude'] as num).toDouble(),
              ),
            );
            _widget.onPoiClick!(poi);
          }
          return Future<dynamic>.value('');
        }
      case 'onAMapClick':
        {
          if (_widget.onAMapClick != null) {
            final Map<dynamic, dynamic> args =
                call.arguments as Map<dynamic, dynamic>;
            final LatLng latLng = LatLng(
              (args['latitude'] as num).toDouble(),
              (args['longitude'] as num).toDouble(),
            );
            _widget.onAMapClick!(latLng);
          }
          return Future<dynamic>.value('');
        }
      case 'onMarkerClick':
        {
          final Map<dynamic, dynamic> args =
              call.arguments as Map<dynamic, dynamic>;
          final String markerId = args['markerId'] as String;
          final Marker? marker = _markers[markerId];
          if (marker != null && marker.onTap != null) {
            marker.onTap!(markerId);
          }
          return Future<dynamic>.value('');
        }
      case 'onMarkerDragEnd':
        {
          final Map<dynamic, dynamic> args =
              call.arguments as Map<dynamic, dynamic>;
          final String markerId = args['markerId'] as String;
          final double latitude = (args['latitude'] as num).toDouble();
          final double longitude = (args['longitude'] as num).toDouble();
          final Marker? marker = _markers[markerId];
          if (marker != null && marker.onDragEnd != null) {
            marker.onDragEnd!(markerId, LatLng(latitude, longitude));
          }
          return Future<dynamic>.value('');
        }
      case 'onCameraChange':
        {
          if (_widget.onCameraChange != null) {
            final Map<dynamic, dynamic> args =
                call.arguments as Map<dynamic, dynamic>;
            final CameraPosition cameraPosition = CameraPosition(
              target: LatLng(
                (args['latitude'] as num).toDouble(),
                (args['longitude'] as num).toDouble(),
              ),
            );
            _widget.onCameraChange!(cameraPosition);
          }
          return Future<dynamic>.value('');
        }
      case 'onCameraChangeFinish':
        {
          if (_widget.onCameraChangeFinish != null) {
            final Map<dynamic, dynamic> args =
                call.arguments as Map<dynamic, dynamic>;
            final CameraPosition cameraPosition = CameraPosition(
              target: LatLng(
                (args['latitude'] as num).toDouble(),
                (args['longitude'] as num).toDouble(),
              ),
            );
            _widget.onCameraChangeFinish!(cameraPosition);
          }
          return Future<dynamic>.value('');
        }
    }
    return Future<dynamic>.value('');
  }

  /// city：cityName（中文或中文全拼）、cityCode均可
  @override
  Future<void> search(String keyWord, {String city = ''}) async {
    return _channel.invokeMethod('search', <String, dynamic>{
      'keyWord': keyWord,
      'city': city,
    });
  }

  @override
  Future<void> move(String lat, String lon) async {
    return _channel
        .invokeMethod('move', <String, dynamic>{'lat': lat, 'lon': lon});
  }

  @override
  Future<void> location() async {
    return _channel.invokeMethod('location');
  }

  @override
  Future<void> addMarker(Marker marker) async {
    _markers[marker.id] = marker;
    return _channel.invokeMethod('addMarker', marker.toMap());
  }

  @override
  Marker? findMarker(String id) {
    return _markers[id];
  }

  @override
  Future<void> updateMarker(Marker marker) async {
    _markers[marker.id] = marker;
    return _channel.invokeMethod('updateMarker', marker.toMap());
  }

  @override
  Future<void> removeMarker(String id) async {
    _markers.remove(id);
    return _channel.invokeMethod('removeMarker', {'id': id});
  }

  @override
  Future<void> addPolyline(Polyline polyline) async {
    return _channel.invokeMethod('addPolyline', polyline.toJson());
  }

  @override
  Future<void> addPolygon(Polygon polygon) async {
    return _channel.invokeMethod('addPolygon', polygon.toMap());
  }

  @override
  Future<void> updatePolygon(Polygon polygon) async {
    return _channel.invokeMethod('updatePolygon', polygon.toMap());
  }

  @override
  Future<void> removePolygon(String id) async {
    return _channel.invokeMethod('removePolygon', {'id': id});
  }

  @override
  Future<void> clear() async {
    _markers.clear();
    return _channel.invokeMethod('clear');
  }

  @override
  Future<void> moveCamera(CameraUpdate update) async {
    return _channel.invokeMethod('moveCamera', update.toJson());
  }

  @override
  Future<void> animateCamera(CameraUpdate update,
      {Duration duration = const Duration(milliseconds: 250)}) async {
    final Map<String, dynamic> params = {
      'cameraUpdate': update.toJson(),
      'duration': duration.inMilliseconds,
    };
    return _channel.invokeMethod('animateCamera', params);
  }

  @override
  Future<LatLng?> getLocation() async {
    final Map<dynamic, dynamic>? result =
        await _channel.invokeMethod('getLocation');
    if (result == null) return null;
    return LatLng(
      (result['latitude'] as num).toDouble(),
      (result['longitude'] as num).toDouble(),
    );
  }
}
