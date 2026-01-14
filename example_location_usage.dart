import 'package:flutter_2d_amap/flutter_2d_amap.dart';
import 'package:flutter_2d_amap/src/amap_flutter_location.dart';
import 'package:flutter_2d_amap/src/amap_location_option.dart';

/// 正确使用 AMap2DLocation 的示例
class LocationExample {
  late AMap2DLocation _locationPlugin;

  void initLocation() {
    // 1. 创建定位实例
    _locationPlugin = AMap2DLocation();

    // 2. 设置定位参数（必须！）
    AMap2DLocationOption locationOption = AMap2DLocationOption();
    locationOption.onceLocation = false; // 持续定位
    locationOption.needAddress = true; // 需要地址信息
    locationOption.locationInterval = 2000; // 定位间隔 2秒

    _locationPlugin.setLocationOption(locationOption);

    // 3. 监听定位结果（必须在 startLocation 之前！）
    _locationPlugin.onLocationChanged().listen((Map<String, Object> result) {
      print('定位成功: $result');

      // 解析定位结果
      if (result.containsKey('errorCode')) {
        print('定位失败: ${result['errorCode']} - ${result['errorInfo']}');
      } else {
        double? latitude = result['latitude'] as double?;
        double? longitude = result['longitude'] as double?;
        String? address = result['address'] as String?;

        print('纬度: $latitude, 经度: $longitude');
        print('地址: $address');
      }
    });

    // 4. 开始定位
    _locationPlugin.startLocation();
  }

  void stopLocation() {
    _locationPlugin.stopLocation();
  }

  void dispose() {
    _locationPlugin.destroy();
  }
}
