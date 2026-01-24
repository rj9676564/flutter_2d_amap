import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_2d_amap/flutter_2d_amap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flutter2dAMap.updatePrivacy(true);
  Flutter2dAMap.setApiKey(
    iOSKey: '1a8f6a489483534a9f2ca96e4eeeb9b3',
    webKey: '4e479545913a3a180b3cffc267dad646',
    androidKey: 'f7ce066dbebef774b3d6dc96434daade',
  ).then((value) => runApp(const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<PoiSearch> _list = [];
  int _index = 0;
  final ScrollController _controller = ScrollController();
  late AMapController? _aMapController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('flutter_2d_amap'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 9,
              child: AMapView(
                isPoiSearch: false,
                showClickMarker: false,
                moveCameraOnTap: false,
                onPoiSearched: (List<PoiSearch> result) {
                  setState(() {
                    _list = result;
                  });
                },
                onPoiClick: (Poi poi) {
                  print(
                      'User clicked POI: ${poi.name} (ID: ${poi.id}) at ${poi.latLng}');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Clicked POI: ${poi.name}'),
                    duration: const Duration(seconds: 1),
                  ));
                },
                onAMapViewCreated: (controller) {
                  _aMapController = controller;
                },
                initialCameraPosition: const CameraPosition(
                  target: LatLng(22.543099, 114.057868), // 设一个默认位置，比如深圳
                  zoom: 16,
                ),
              ),
            ),
            Expanded(
              flex: 11,
              child: ListView.separated(
                  controller: _controller,
                  shrinkWrap: true,
                  itemCount: _list.length,
                  separatorBuilder: (_, index) {
                    return const Divider(height: 0.6);
                  },
                  itemBuilder: (_, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _index = index;
                          if (_aMapController != null) {
                            final lat =
                                double.tryParse(_list[index].latitude ?? '') ??
                                    0;
                            final lon =
                                double.tryParse(_list[index].longitude ?? '') ??
                                    0;
                            _aMapController?.moveCamera(
                              CameraUpdate.newLatLng(LatLng(lat, lon)),
                            );
                          }
                        });
                      },
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        height: 50.0,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                '${_list[index].provinceName!} ${_list[index].cityName!} ${_list[index].adName!} ${_list[index].title!}',
                              ),
                            ),
                            Opacity(
                                opacity: _index == index ? 1 : 0,
                                child:
                                    const Icon(Icons.done, color: Colors.blue))
                          ],
                        ),
                      ),
                    );
                  }),
            )
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'clear',
            onPressed: () {
              _aMapController?.clear();
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () {
              _aMapController?.addMarker(Marker(
                position: const LatLng(39.909187, 116.397451),
                title: 'Tiananmen',
                snippet: 'Beijing, China',
                draggable: true,
                icon: BitmapDescriptor.defaultMarker,
                anchor: const Offset(0.5, 0.5), // User requested (0.5, 0.5)
                infoWindowEnable: false, // User requested disable
                onTap: (id) {
                  print('Marker tapped: $id');
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Marker tapped: $id')));
                },
                onDragEnd: (id, position) {
                  print('Marker drag end: $id, at $position');
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Drag end: $position')));
                },
              ));
              _aMapController?.addPolygon(Polygon(
                id: 'polygon_1',
                points: [
                  const LatLng(22.574005, 113.942954),
                  const LatLng(22.574005, 113.942004),
                  const LatLng(22.570005, 113.942004),
                ],
                strokeWidth: 2,
                strokeColor: Colors.red,
                fillColor: Colors.red.withOpacity(0.3),
              ));
              _aMapController?.addPolyline(Polyline(
                points: [
                  const LatLng(22.574005, 113.942954),
                  const LatLng(22.574005, 113.945000),
                ],
                width: 5,
                color: Colors.blue,
                isDottedLine: true,
              ));
            },
            child: const Icon(Icons.add_location),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'update',
            onPressed: () {
              _aMapController?.updatePolygon(Polygon(
                id: 'polygon_1',
                points: [
                  const LatLng(22.574005, 113.942954),
                  const LatLng(22.574005, 113.942004),
                  const LatLng(22.570005, 113.942004),
                  const LatLng(22.570005, 113.942954),
                ],
                strokeWidth: 4,
                strokeColor: Colors.red,
                fillColor: Colors.green.withOpacity(0.3),
              ));
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.edit),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'camera',
            onPressed: () {
              _aMapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  const CameraPosition(
                    target: LatLng(39.909187, 116.397451),
                    zoom: 15.0,
                  ),
                ),
                duration: const Duration(milliseconds: 1000),
              );
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    ));
  }
}
