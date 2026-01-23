import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_2d_amap/flutter_2d_amap.dart';
import 'package:flutter_2d_amap/src/mobile/amap_2d_controller.dart';

class AMapViewState extends State<AMapView> {
  final Completer<AMapMobileController> _controller =
      Completer<AMapMobileController>();

  void _onPlatformViewCreated(int id) {
    final AMapMobileController controller = AMapMobileController(id, widget);
    _controller.complete(controller);
    if (widget.onAMapViewCreated != null) {
      widget.onAMapViewCreated!(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'plugins.weilu/flutter_2d_amap',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: _CreationParams.fromWidget(widget).toMap(),
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'plugins.weilu/flutter_2d_amap',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: _CreationParams.fromWidget(widget).toMap(),
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return Text(
        '$defaultTargetPlatform is not yet supported by the flutter_2d_amap plugin');
  }
}

/// 需要更多的初始化配置，可以在此处添加
class _CreationParams {
  _CreationParams({
    this.isPoiSearch = true,
    this.showClickMarker = true,
    this.moveCameraOnTap = true,
    this.compassEnabled = false,
    this.scaleEnabled = false,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.myLocationButtonEnabled = false,
    this.initialCameraPosition,
    this.onCameraChange = false,
    this.onCameraChangeFinish = false,
  });

  static _CreationParams fromWidget(AMapView widget) {
    return _CreationParams(
      isPoiSearch: widget.isPoiSearch,
      showClickMarker: widget.showClickMarker,
      moveCameraOnTap: widget.moveCameraOnTap,
      compassEnabled: widget.compassEnabled,
      scaleEnabled: widget.scaleEnabled,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      scrollGesturesEnabled: widget.scrollGesturesEnabled,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      initialCameraPosition: widget.initialCameraPosition,
      onCameraChange: widget.onCameraChange != null,
      onCameraChangeFinish: widget.onCameraChangeFinish != null,
    );
  }

  final bool isPoiSearch;
  final bool showClickMarker;
  final bool moveCameraOnTap;
  final bool compassEnabled;
  final bool scaleEnabled;
  final bool zoomGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool myLocationButtonEnabled;
  final CameraPosition? initialCameraPosition;
  final bool onCameraChange;
  final bool onCameraChangeFinish;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isPoiSearch': isPoiSearch,
      'showClickMarker': showClickMarker,
      'moveCameraOnTap': moveCameraOnTap,
      'compassEnabled': compassEnabled,
      'scaleEnabled': scaleEnabled,
      'zoomGesturesEnabled': zoomGesturesEnabled,
      'scrollGesturesEnabled': scrollGesturesEnabled,
      'myLocationButtonEnabled': myLocationButtonEnabled,
      'initialCameraPosition': initialCameraPosition?.toMap(),
      'onCameraChange': onCameraChange,
      'onCameraChangeFinish': onCameraChangeFinish,
    };
  }
}
