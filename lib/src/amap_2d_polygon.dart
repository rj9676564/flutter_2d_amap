import 'dart:ui';
import 'amap_2d_lat_lng.dart';

import 'amap_2d_enums.dart';

class Polygon {
  Polygon({
    String? id,
    required this.points,
    this.strokeWidth = 10,
    this.strokeColor = const Color(0xCC00BFFF),
    this.fillColor = const Color(0xC487CEFA),
    this.joinType = JoinType.bevel,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        assert(points.isNotEmpty);

  final String id;
  final List<LatLng> points;
  final double strokeWidth;
  final Color strokeColor;
  final Color fillColor;
  final JoinType joinType;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'points': points.map((e) => e.toJson()).toList(),
      'strokeWidth': strokeWidth,
      'strokeColor': strokeColor.value,
      'fillColor': fillColor.value,
      'joinType': joinType.index,
    };
  }
}
