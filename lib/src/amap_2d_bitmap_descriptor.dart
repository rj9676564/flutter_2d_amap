import 'dart:async' show Future;
import 'dart:typed_data' show Uint8List;
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart'
    show ImageConfiguration, AssetBundleImageKey, AssetImage, AssetBundle;

/// Bitmap工具类
class BitmapDescriptor {
  const BitmapDescriptor._(this._json);

  /// 创建默认的marker 图标的 bitmap 描述信息对象.
  static const BitmapDescriptor defaultMarker =
      BitmapDescriptor._(<dynamic>['defaultMarker']);

  /// 红色.
  static const double hueRed = 0.0;

  /// 橙色.
  static const double hueOrange = 30.0;

  /// 黄色.
  static const double hueYellow = 60.0;

  /// 绿色.
  static const double hueGreen = 120.0;

  /// 青色.
  static const double hueCyan = 180.0;

  /// 天蓝色.
  static const double hueAzure = 210.0;

  /// 蓝色.
  static const double hueBlue = 240.0;

  /// 紫色.
  static const double hueViolet = 270.0;

  /// 酒红色.
  static const double hueMagenta = 300.0;

  /// 玫瑰红.
  static const double hueRose = 330.0;

  /// 创建引用默认着色的BitmapDescriptor
  static BitmapDescriptor defaultMarkerWithHue(double hue) {
    assert(0.0 <= hue && hue < 360.0);
    return BitmapDescriptor._(<dynamic>['defaultMarker', hue]);
  }

  ///根据输入的icon路径[iconPath]创建[BitmapDescriptor]
  static BitmapDescriptor fromIconPath(String iconPath) {
    return BitmapDescriptor._(<dynamic>[
      'fromAsset',
      iconPath,
    ]);
  }

  ///从资源图像创建[BitmapDescriptor]。
  ///
  ///Flutter中的assert的资产图像按以下方式存储：
  /// https://flutter.dev/docs/development/ui/assets and images声明-分辨率感知图像资源
  ///该方法考虑了各种资产解决方案
  ///并根据dpi将图像缩放到正确的分辨率。
  ///将`mipmaps1设置为false可加载图像的精确dpi版本，默认情况下，`mipmap`为true。
  static Future<BitmapDescriptor> fromAssetImage(
    ImageConfiguration configuration,
    String assetName, {
    AssetBundle? bundle,
    String? package,
    bool mipmaps = true,
  }) async {
    if (!mipmaps && configuration.devicePixelRatio != null) {
      return BitmapDescriptor._(<dynamic>[
        'fromAssetImage',
        assetName,
        configuration.devicePixelRatio,
      ]);
    }
    final AssetImage assetImage =
        AssetImage(assetName, package: package, bundle: bundle);
    final AssetBundleImageKey assetBundleImageKey =
        await assetImage.obtainKey(configuration);
    final Size? size = configuration.size;
    return BitmapDescriptor._(<dynamic>[
      'fromAssetImage',
      assetBundleImageKey.name,
      assetBundleImageKey.scale,
      if (kIsWeb && size != null)
        [
          size.width,
          size.height,
        ],
    ]);
  }

  /// 根据将PNG图片转换后的二进制数据[byteData]创建BitmapDescriptor
  /// [size] 可选参数，指定图标的大小
  /// [scale] 可选参数，指定图标的缩放比例
  static BitmapDescriptor fromBytes(Uint8List byteData,
      {Size? size, double? scale}) {
    return BitmapDescriptor._(<dynamic>[
      'fromBytes',
      byteData,
      if (size != null) [size.width, size.height] else null,
      scale
    ]);
  }

  final dynamic _json;

  dynamic toJson() => _json;
}
