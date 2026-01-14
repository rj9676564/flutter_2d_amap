import 'package:flutter/material.dart';
import 'package:flutter_2d_amap/src/interface/amap_2d_controller.dart';
import 'package:flutter_2d_amap/src/amap_2d_camera_position.dart';

import 'amap_2d_view_state.dart'
    if (dart.library.html) 'web/amap_2d_view_state.dart'
    if (dart.library.io) 'mobile/amap_2d_view_state.dart';

import 'amap_2d_poi.dart';
import 'poi_search_model.dart';
import 'amap_2d_lat_lng.dart';

typedef AMapViewCreatedCallback = void Function(AMapController controller);

class AMapView extends StatefulWidget {
  const AMapView({
    super.key,
    this.isPoiSearch = true,
    this.showClickMarker = true,
    this.moveCameraOnTap = true,
    this.compassEnabled = false,
    this.scaleEnabled = false,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.initialCameraPosition,
    this.onPoiSearched,
    this.onPoiClick,
    this.onAMapClick,
    this.onCameraChange,
    this.onCameraChangeFinish,
    this.onAMapViewCreated,
  });

  final bool isPoiSearch;
  final bool showClickMarker;
  final bool moveCameraOnTap;
  final bool compassEnabled;
  final bool scaleEnabled;
  final bool zoomGesturesEnabled;
  final bool scrollGesturesEnabled;
  final CameraPosition? initialCameraPosition;
  final AMapViewCreatedCallback? onAMapViewCreated;
  final Function(List<PoiSearch>)? onPoiSearched;
  final Function(Poi)? onPoiClick;
  final Function(LatLng)? onAMapClick;
  final Function(CameraPosition)? onCameraChange;
  final Function(CameraPosition)? onCameraChangeFinish;

  @override
  AMapViewState createState() => AMapViewState();
}
