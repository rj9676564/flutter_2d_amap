import 'dart:ui';
import 'amap_2d_lat_lng.dart';
import 'amap_2d_bitmap_descriptor.dart';
import 'amap_2d_info_window.dart';

class Marker {
  Marker({
    required this.position,
    this.title,
    this.snippet,
    this.draggable = false,
    this.icon,
    this.onTap,
    this.anchor = const Offset(0.5, 1.0),
    this.infoWindowEnable = true,
    this.infoWindow = InfoWindow.noText,
    this.onDragEnd,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  final String id;
  final LatLng position;
  final String? title;
  final String? snippet;
  final bool draggable;
  final BitmapDescriptor? icon;
  final Function(String id)? onTap;
  final Offset anchor;
  final bool infoWindowEnable;
  final InfoWindow infoWindow;
  final void Function(String id, LatLng endPosition)? onDragEnd;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'position': position.toJson(),
      'title': infoWindow.title ?? title,
      'snippet': infoWindow.snippet ?? snippet,
      'draggable': draggable,
      'icon': icon?.toJson(),
      'anchorX': anchor.dx,
      'anchorY': anchor.dy,
      'infoWindowEnable': infoWindowEnable,
    };
  }

  Marker copyWith({
    LatLng? positionParam,
    String? title,
    String? snippet,
    bool? draggable,
    BitmapDescriptor? icon,
    Function(String id)? onTap,
    Offset? anchor,
    bool? infoWindowEnable,
    InfoWindow? infoWindow,
    void Function(String id, LatLng endPosition)? onDragEnd,
  }) {
    return Marker(
      id: id,
      position: positionParam ?? this.position,
      title: title ?? this.title,
      snippet: snippet ?? this.snippet,
      draggable: draggable ?? this.draggable,
      icon: icon ?? this.icon,
      onTap: onTap ?? this.onTap,
      anchor: anchor ?? this.anchor,
      infoWindowEnable: infoWindowEnable ?? this.infoWindowEnable,
      infoWindow: infoWindow ?? this.infoWindow,
      onDragEnd: onDragEnd ?? this.onDragEnd,
    );
  }
}
