/// Android端定位模式
enum AMap2DLocationMode {
  /// 低功耗模式
  Battery_Saving,

  /// 仅设备模式,不支持室内环境的定位
  Device_Sensors,

  /// 高精度模式
  Hight_Accuracy
}

/// 逆地理信息语言
enum AMap2DGeoLanguage {
  /// 默认，自动适配
  DEFAULT,

  /// 汉语，无论在国内还是国外都返回英文
  ZH,

  /// 英语，无论在国内还是国外都返回中文
  EN
}

/// iOS中期望的定位精度
enum AMap2DDesiredAccuracy {
  /// 最高精度
  Best,

  /// 适用于导航场景的高精度
  BestForNavigation,

  /// 10米
  NearestTenMeters,

  /// 100米
  HundredMeters,

  /// 1000米
  Kilometer,

  /// 3000米
  ThreeKilometers,
}

/// iOS 14中期望的定位精度,只有在iOS 14的设备上才能生效
enum AMap2DLocationAccuracyAuthorizationMode {
  /// 精确和模糊定位
  FullAndReduceAccuracy,

  /// 精确定位
  FullAccuracy,

  /// 模糊定位
  ReduceAccuracy
}

/// 定位参数设置
class AMap2DLocationOption {
  /// 是否需要地址信息，默认true
  bool needAddress = true;

  /// 逆地理信息语言类型<br>
  /// 默认[AMap2DGeoLanguage.DEFAULT] 自动适配<br>
  /// 可选值：<br>
  /// <li>[AMap2DGeoLanguage.DEFAULT] 自动适配</li>
  /// <li>[AMap2DGeoLanguage.EN] 英文</li>
  /// <li>[AMap2DGeoLanguage.ZH] 中文</li>
  AMap2DGeoLanguage geoLanguage;

  /// 是否单次定位
  /// 默认值：false
  bool onceLocation = false;

  /// 是否允许后台定位
  /// 是否允许后台定位。只在iOS 9.0及之后起作用。设置为YES的时候必须保证 Background Modes 中的 Location updates 处于选中状态，否则会抛出异常。
  /// 由于iOS系统限制，需要在定位未开始之前或定位停止之后，修改该属性的值才会有效果。
  /// 默认值：false
  bool allowsBackgroundLocationUpdates = false;

  /// Android端定位模式, 只在Android系统上有效<br>
  /// 默认值：[AMap2DLocationMode.Hight_Accuracy]<br>
  /// 可选值：<br>
  /// <li>[AMap2DLocationMode.Battery_Saving]</li>
  /// <li>[AMap2DLocationMode.Device_Sensors]</li>
  /// <li>[AMap2DLocationMode.Hight_Accuracy]</li>
  AMap2DLocationMode locationMode;

  /// Android端定位间隔<br>
  /// 单位：毫秒<br>
  /// 默认：2000毫秒<br>
  int locationInterval = 2000;

  /// iOS端是否允许系统暂停定位<br>
  /// 默认：false
  bool pausesLocationUpdatesAutomatically = false;

  /// iOS端期望的定位精度， 只在iOS端有效<br>
  /// 默认值：最高精度<br>
  /// 可选值：<br>
  /// <li>[AMap2DDesiredAccuracy.Best] 最高精度</li>
  /// <li>[AMap2DDesiredAccuracy.BestForNavigation] 适用于导航场景的高精度 </li>
  /// <li>[AMap2DDesiredAccuracy.NearestTenMeters] 10米 </li>
  /// <li>[AMap2DDesiredAccuracy.Kilometer] 1000米</li>
  /// <li>[AMap2DDesiredAccuracy.ThreeKilometers] 3000米</li>
  AMap2DDesiredAccuracy desiredAccuracy =
      AMap2DDesiredAccuracy.NearestTenMeters;

  /// iOS端定位最小更新距离<br>
  /// 单位：米<br>
  /// 默认值：-1，不做限制<br>
  double distanceFilter = -1;

  /// iOS 14中设置期望的定位精度权限
  AMap2DLocationAccuracyAuthorizationMode
      desiredLocationAccuracyAuthorizationMode =
      AMap2DLocationAccuracyAuthorizationMode.FullAccuracy;

  /// iOS 14中定位精度权限由模糊定位升级到精确定位时，需要用到的场景key fullAccuracyPurposeKey 这个key要和plist中的配置一样
  String fullAccuracyPurposeKey = "";

  AMap2DLocationOption(
      {this.locationInterval = 2000,
      this.needAddress = true,
      this.locationMode = AMap2DLocationMode.Hight_Accuracy,
      this.geoLanguage = AMap2DGeoLanguage.DEFAULT,
      this.onceLocation = false,
      this.allowsBackgroundLocationUpdates = false,
      this.pausesLocationUpdatesAutomatically = false,
      this.desiredAccuracy = AMap2DDesiredAccuracy.NearestTenMeters,
      this.distanceFilter = -1,
      this.desiredLocationAccuracyAuthorizationMode =
          AMap2DLocationAccuracyAuthorizationMode.FullAccuracy});

  /// 获取设置的定位参数对应的Map
  Map getOptionsMap() {
    return {
      "locationInterval": this.locationInterval,
      "needAddress": needAddress,
      "locationMode": locationMode.index,
      "geoLanguage": geoLanguage.index,
      "onceLocation": onceLocation,
      "allowsBackgroundLocationUpdates": allowsBackgroundLocationUpdates,
      "pausesLocationUpdatesAutomatically": pausesLocationUpdatesAutomatically,
      "desiredAccuracy": desiredAccuracy.index,
      'distanceFilter': distanceFilter,
      "locationAccuracyAuthorizationMode":
          desiredLocationAccuracyAuthorizationMode.index,
      "fullAccuracyPurposeKey": fullAccuracyPurposeKey
    };
  }
}
