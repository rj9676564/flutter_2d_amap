
class LatLng {
  const LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  Map<String, double> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static LatLng fromJson(dynamic json) {
    if (json is Map) {
      return LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );
    }
    // Handle edge cases or throw? For now assume valid map or list if we supported [lat, lng]
    return const LatLng(0, 0);
  }

  @override
  String toString() {
    return 'LatLng($latitude, $longitude)';
  }
}
