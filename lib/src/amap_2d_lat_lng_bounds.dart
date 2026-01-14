
import 'amap_2d_lat_lng.dart';

class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;

  const LatLngBounds({
    required this.southwest,
    required this.northeast,
  });

  Map<String, dynamic> toJson() {
    return {
      'southwest': southwest.toJson(),
      'northeast': northeast.toJson(),
    };
  }

  static LatLngBounds? fromJson(dynamic json) {
    if (json == null || json is! Map) {
        return null;
    }
    return LatLngBounds(
      southwest: LatLng.fromJson(json['southwest']),
      northeast: LatLng.fromJson(json['northeast']),
    );
  }
}
