
import 'amap_2d_lat_lng.dart';

class Poi {
  const Poi({
    required this.id,
    required this.name,
    required this.latLng,
  });

  final String id;
  final String name;
  final LatLng latLng;

  @override
  String toString() {
    return 'Poi{id: $id, name: $name, latLng: $latLng}';
  }
}
