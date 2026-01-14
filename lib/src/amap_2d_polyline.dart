import 'dart:ui';
import 'amap_2d_lat_lng.dart';

import 'amap_2d_enums.dart';

class Polyline {
  Polyline({
    required this.points,
    this.width = 10,
    this.color = const Color(0xCC00BFFF),
    this.isDottedLine = false,
    this.geodesic = false,
    this.visible = true,
    this.joinType = JoinType.bevel,
  });

  final List<LatLng> points;
  final double width;
  final Color color;
  final bool isDottedLine;
  final bool geodesic;
  final bool visible;
  final JoinType joinType;

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((e) => e.toJson()).toList(),
      'width': width,
      'color': color.value,
      'isDottedLine': isDottedLine,
      'geodesic': geodesic,
      'visible': visible,
      'joinType': joinType.index,
    };
  }
}
