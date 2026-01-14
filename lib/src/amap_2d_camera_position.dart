
import 'amap_2d_lat_lng.dart';

/// 相机位置，包含可视区域的位置参数。
class CameraPosition {
  /// 构造一个CameraPosition 对象
  ///
  /// 如果[bearing], [target], [tilt], 或者 [zoom] 为null时会返回[AssertionError]
  const CameraPosition({
    this.bearing = 0.0,
    required this.target,
    this.tilt = 0.0,
    this.zoom = 10,
  });

  /// 可视区域指向的方向，以角度为单位，从正北向逆时针方向计算，从0 度到360 度。
  final double bearing;

  /// 目标位置的屏幕中心点经纬度坐标。
  final LatLng target;

  /// 目标可视区域的倾斜度，以角度为单位。范围从0到360度
  final double tilt;

  /// 目标可视区域的缩放级别
  final double zoom;

  /// 将[CameraPosition]装换成Map
  ///
  /// 主要在插件内部使用
  Map<String, dynamic> toMap() => {
        'bearing': bearing,
        'target': target.toJson(),
        'tilt': tilt,
        'zoom': zoom,
      };

  /// 从Map转换成[CameraPosition]
  ///
  /// 主要在插件内部使用
  static CameraPosition? fromMap(dynamic json) {
    if (json == null || json is! Map) {
      return null;
    }
    final LatLng target = LatLng.fromJson(json['target']);
    return CameraPosition(
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
      target: target,
      tilt: (json['tilt'] as num?)?.toDouble() ?? 0.0,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 10.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final CameraPosition typedOther = other as CameraPosition;
    return bearing == typedOther.bearing &&
        target == typedOther.target &&
        tilt == typedOther.tilt &&
        zoom == typedOther.zoom;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[bearing, target, tilt, zoom]);

  @override
  String toString() =>
      'CameraPosition(bearing: $bearing, target: $target, tilt: $tilt, zoom: $zoom)';
}
