package com.weilu.flutter.flutter_2d_amap;

import android.content.Context;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.View;
import android.widget.Toast;

import androidx.annotation.NonNull;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;
import com.amap.api.maps.AMap;
import com.amap.api.maps.AMapWrapper;
import com.amap.api.maps.CameraUpdateFactory;
import com.amap.api.maps.LocationSource;
import com.amap.api.maps.model.BitmapDescriptor;
import com.amap.api.maps.model.BitmapDescriptorFactory;
import com.amap.api.maps.model.CameraPosition;
import com.amap.api.maps.model.LatLng;
import com.amap.api.maps.model.Marker;
import com.amap.api.maps.model.MarkerOptions;
import com.amap.api.maps.model.MyLocationStyle;
import com.amap.api.services.core.AMapException;
import com.amap.api.services.core.LatLonPoint;
import com.amap.api.services.core.PoiItem;
import com.amap.api.services.poisearch.PoiResult;
import com.amap.api.services.poisearch.PoiSearch;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

/**
 * @author weilu
 * 2019/6/26 0026 10:18.
 */
public class AMap2DView implements PlatformView, MethodChannel.MethodCallHandler, LocationSource, AMapLocationListener,
        AMap.OnMapClickListener, PoiSearch.OnPoiSearchListener, AMap.OnMarkerClickListener, AMap.OnMarkerDragListener,AMap.OnCameraChangeListener {
    private String TAG = "AMap2DView";
    private static  final String SEARCH_CONTENT = "010000|010100|020000|030000|040000|050000|050100|060000|060100|060200|060300|060400|070000|080000|080100|080300|080500|080600|090000|090100|090200|090300|100000|100100|110000|110100|120000|120200|120300|130000|140000|141200|150000|150100|150200|160000|160100|170000|170100|170200|180000|190000|200000";
  
    private MyWebView mAMapWebView;
    private AMapWrapper aMapWrapper;
    private AMap aMap;
    private PoiSearch.Query query;
    private OnLocationChangedListener mListener;
    private AMapLocationClient mLocationClient;

    private final MethodChannel methodChannel;
    private final Handler platformThreadHandler;
    private Runnable postMessageRunnable;
    private final Context context;
    private String keyWord = "";
    private boolean isPoiSearch;
    private boolean showClickMarker;
    private boolean moveCameraOnTap;
    private boolean compassEnabled = false;
    private boolean scaleEnabled = false;
    private boolean zoomGesturesEnabled = true;
    private boolean scrollGesturesEnabled = true;
    private boolean myLocationButtonEnabled = false;
    private Map<String, Object> initialCameraPosition;
    private boolean isClick;
    private static final String IS_POI_SEARCH = "isPoiSearch";
    private String city = "";
    private Map<String, com.amap.api.maps.model.Polygon> polygonMap = new HashMap<>();
    private Map<String, Marker> markerMap = new HashMap<>();

    AMap2DView(final Context context, BinaryMessenger messenger, int id, Map<String, Object> params, AMap2DDelegate delegate) {
        this.context = context;
        platformThreadHandler = new Handler(context.getMainLooper());
        createMap(context);
        setAMap2DDelegate(delegate);
        
        methodChannel = new MethodChannel(messenger, "plugins.weilu/flutter_2d_amap_" + id);
        methodChannel.setMethodCallHandler(this);

        if (params.containsKey(IS_POI_SEARCH)) {
            isPoiSearch = (boolean) params.get(IS_POI_SEARCH);
        }
        if (params.containsKey("showClickMarker")) {
            showClickMarker = (boolean) params.get("showClickMarker");
        }
        if (params.containsKey("moveCameraOnTap")) {
            moveCameraOnTap = (boolean) params.get("moveCameraOnTap");
        }
        if (params.containsKey("compassEnabled")) {
            compassEnabled = (boolean) params.get("compassEnabled");
        }
        if (params.containsKey("scaleEnabled")) {
            scaleEnabled = (boolean) params.get("scaleEnabled");
        }
        if (params.containsKey("zoomGesturesEnabled")) {
            zoomGesturesEnabled = (boolean) params.get("zoomGesturesEnabled");
        }
        if (params.containsKey("scrollGesturesEnabled")) {
            scrollGesturesEnabled = (boolean) params.get("scrollGesturesEnabled");
        }
        if (params.containsKey("myLocationButtonEnabled")) {
            myLocationButtonEnabled = (boolean) params.get("myLocationButtonEnabled");
        }
        if (params.containsKey("initialCameraPosition") && params.get("initialCameraPosition") != null) {
            initialCameraPosition = (Map<String, Object>) params.get("initialCameraPosition");
        }
        if (params.containsKey("onCameraChange")) {
            onCameraChange = (boolean) params.get("onCameraChange");
        }
        if (params.containsKey("onCameraChangeFinish")) {
            onCameraChangeFinish = (boolean) params.get("onCameraChangeFinish");
        }
    }
    
    private boolean onCameraChange = false;
    private boolean onCameraChangeFinish = false;
    
    private boolean isMapReady = false;
    private boolean isPermissionSuccess = false;

    void setAMap2DDelegate(AMap2DDelegate delegate) {
        if (delegate != null){
            delegate.requestPermissions(new AMap2DDelegate.RequestPermission() {
                @Override
                public void onRequestPermissionSuccess() {
                    isPermissionSuccess = true;
                    if (isMapReady) {
                        setUpMap();
                    }
                }

                @Override
                public void onRequestPermissionFailure() {
                    Toast.makeText(context,"定位失败，请检查定位权限是否开启！", Toast.LENGTH_SHORT).show();
                }
            });
        }
    }
    
    private void createMap(Context context) {
        mAMapWebView = new MyWebView(context);
        MAWebViewWrapper webViewWrapper = new MAWebViewWrapper(mAMapWebView);
        aMapWrapper = new AMapWrapper(context, webViewWrapper);
        aMapWrapper.onCreate();
        aMapWrapper.onResume();
        aMapWrapper.getMapAsyn(new AMap.OnMapReadyListener() {
            @Override
            public void onMapReady(AMap map) {
                aMap = map;
                isMapReady = true;
                if (isPermissionSuccess) {
                    setUpMap();
                }
            }
        });
    }
    
    private void setUpMap() {
        if (aMap == null) return;
        if (initialCameraPosition != null) {
            Map<String, Double> target = (Map<String, Double>) initialCameraPosition.get("target");
            double zoom = toDouble(initialCameraPosition.get("zoom"));
            aMap.moveCamera(CameraUpdateFactory.newLatLngZoom(new LatLng(target.get("latitude"), target.get("longitude")), (float) zoom));
        } else {
             aMap.moveCamera(CameraUpdateFactory.zoomTo(16));
        }
        
        com.amap.api.maps.UiSettings uiSettings = aMap.getUiSettings();
//        uiSettings.setCompassEnabled(compassEnabled);
//        uiSettings.setScaleControlsEnabled(scaleEnabled);
        uiSettings.setZoomGesturesEnabled(zoomGesturesEnabled);
        uiSettings.setScrollGesturesEnabled(scrollGesturesEnabled);
        
        android.util.Log.d("Flutter2dAMap", "setUpMap: compass=" + compassEnabled + ", scale=" + scaleEnabled + ", zoom=" + zoomGesturesEnabled + ", scroll=" + scrollGesturesEnabled + ", myLocationButtonEnabled=" + myLocationButtonEnabled);
        
        aMap.setOnMapClickListener(this);
        aMap.setOnMarkerClickListener(this);
        aMap.setOnMarkerDragListener(this);
        aMap.setOnCameraChangeListener(this);
        // 设置定位监听
        aMap.setLocationSource(this);
        // 设置默认定位按钮是否显示
//        aMap.getUiSettings().setMyLocationButtonEnabled(myLocationButtonEnabled);
        MyLocationStyle myLocationStyle = new MyLocationStyle();
        myLocationStyle.strokeWidth(1f);
        myLocationStyle.strokeColor(Color.parseColor("#8052A3FF"));
        myLocationStyle.radiusFillColor(Color.parseColor("#3052A3FF"));
        myLocationStyle.showMyLocation(true);
        myLocationStyle.myLocationIcon(BitmapDescriptorFactory.fromResource(R.drawable.yd));
        myLocationStyle.myLocationType(MyLocationStyle.LOCATION_TYPE_LOCATE);
        aMap.setMyLocationStyle(myLocationStyle);
        // 设置为true表示显示定位层并可触发定位，false表示隐藏定位层并不可触发定位，默认是false
        aMap.setMyLocationEnabled(true);
    }
    
    @Override
    public void onMethodCall(MethodCall methodCall, @NonNull MethodChannel.Result result) {
        String method = methodCall.method;
        Map<String, Object> request = methodCall.arguments instanceof Map ? (Map<String, Object>) methodCall.arguments : null;
        switch(method) {
            case "search":
                keyWord = (String) request.get("keyWord");
                city = (String) request.get("city");
                search();
                break;
            case "move":
                move(toDouble((String) request.get("lat")), toDouble((String) request.get("lon")));
                break;
            case "location":
                if (mLocationClient != null) {
                    mLocationClient.startLocation();
                }
                break;
            case "addMarker":
                Map<String, Double> positionMap = (Map<String, Double>) request.get("position");
                boolean draggable = (boolean) request.get("draggable");
                String title = (String) request.get("title");
                String snippet = (String) request.get("snippet");
                Object iconObj = request.get("icon");
                String markerId = (String) request.get("id");
                double anchorX = toDouble(request.get("anchorX"));
                double anchorY = toDouble(request.get("anchorY"));
                boolean infoWindowEnable = (boolean) request.get("infoWindowEnable");

                if (positionMap != null) {
                    LatLng latLng = new LatLng(positionMap.get("latitude"), positionMap.get("longitude"));
                    MarkerOptions markerOptions = new MarkerOptions();
                    markerOptions.position(latLng);
                    if (title != null) {
                        markerOptions.title(title);
                    }
                    if (snippet != null) {
                        markerOptions.snippet(snippet);
                    }
                    markerOptions.draggable(draggable);
                    markerOptions.anchor((float) anchorX, (float) anchorY);
                    
                    BitmapDescriptor descriptor = null;
                    if (iconObj != null) {
                        descriptor = getBitmapDescriptor(iconObj);
                    }
                    if (descriptor != null) {
                        markerOptions.icon(descriptor);
                    } else {
                        markerOptions.icon(BitmapDescriptorFactory.defaultMarker());
                    }
                    
                    Marker marker = aMap.addMarker(markerOptions);
                    Map<String, Object> userData = new HashMap<>();
                    if (markerId != null) {
                        userData.put("id", markerId);
                        markerMap.put(markerId, marker);
                    }
                    userData.put("infoWindowEnable", infoWindowEnable);
                    marker.setObject(userData);
                }
                result.success(null);
                break;
            case "updateMarker":
                Map<String, Double> updatePositionMap = (Map<String, Double>) request.get("position");
                boolean updateDraggable = (boolean) request.get("draggable");
                String updateTitle = (String) request.get("title");
                String updateSnippet = (String) request.get("snippet");
                Object updateIconObj = request.get("icon");
                String updateMarkerId = (String) request.get("id");
                double updateAnchorX = toDouble(request.get("anchorX"));
                double updateAnchorY = toDouble(request.get("anchorY"));
                boolean updateInfoWindowEnable = (boolean) request.get("infoWindowEnable");

                Marker updateMarker = markerMap.get(updateMarkerId);
                if (updateMarker != null) {
                    if (updatePositionMap != null) {
                        updateMarker.setPosition(new LatLng(updatePositionMap.get("latitude"), updatePositionMap.get("longitude")));
                    }
                    if (updateTitle != null) {
                        updateMarker.setTitle(updateTitle);
                    }
                    if (updateSnippet != null) {
                        updateMarker.setSnippet(updateSnippet);
                    }
                    updateMarker.setDraggable(updateDraggable);
                    updateMarker.setAnchor((float) updateAnchorX, (float) updateAnchorY);

                    BitmapDescriptor updateDescriptor = null;
                    if (updateIconObj != null) {
                        updateDescriptor = getBitmapDescriptor(updateIconObj);
                    }
                    if (updateDescriptor != null) {
                        updateMarker.setIcon(updateDescriptor);
                    }
                    
                    // Update user data object if needed
                     Map<String, Object> updateUserData = new HashMap<>();
                     updateUserData.put("id", updateMarkerId);
                     updateUserData.put("infoWindowEnable", updateInfoWindowEnable);
                     updateMarker.setObject(updateUserData);
                }
                result.success(null);
                break;
            case "removeMarker":
                String removeMarkerId = (String) request.get("id");
                Marker removeMarker = markerMap.get(removeMarkerId);
                if (removeMarker != null) {
                    removeMarker.remove();
                    markerMap.remove(removeMarkerId);
                }
                break;
            case "addPolyline":
                List<Map<String, Double>> polylinePoints = (List<Map<String, Double>>) request.get("points");
                double polylineWidth = toDouble(request.get("width"));
                long polylineColor = ((Number) request.get("color")).longValue();
                boolean isDottedLine = (boolean) request.get("isDottedLine");
                boolean geodesic = (boolean) request.get("geodesic");
                boolean visible = (boolean) request.get("visible");
                int joinType = (int) request.get("joinType"); // 0: bevel, 1: miter, 2: round
                
                if (polylinePoints != null && polylinePoints.size() > 0) {
                    com.amap.api.maps.model.PolylineOptions polylineOptions = new com.amap.api.maps.model.PolylineOptions();
                    for (Map<String, Double> point : polylinePoints) {
                        polylineOptions.add(new LatLng(point.get("latitude"), point.get("longitude")));
                    }
                    polylineOptions.width((float) polylineWidth);
                    polylineOptions.color((int) polylineColor);
                    polylineOptions.setDottedLine(isDottedLine);
                    polylineOptions.geodesic(geodesic);
                    polylineOptions.visible(visible);
                    // AMap 2D SDK does not support setLineJoinType directly.
                    aMap.addPolyline(polylineOptions);
                }
                break;
            case "addPolygon":
                List<Map<String, Double>> points = (List<Map<String, Double>>) request.get("points");
                double strokeWidth = toDouble(request.get("strokeWidth"));
                long strokeColor = ((Number) request.get("strokeColor")).longValue();
                long fillColor = ((Number) request.get("fillColor")).longValue();
                int joinTypePolygon = (int) request.get("joinType"); // 0: bevel, 1: miter, 2: round

                if (points != null && points.size() > 0) {
                    com.amap.api.maps.model.PolygonOptions polygonOptions = new com.amap.api.maps.model.PolygonOptions();
                    for (Map<String, Double> point : points) {
                        polygonOptions.add(new LatLng(point.get("latitude"), point.get("longitude")));
                    }
                    polygonOptions.strokeWidth((float) strokeWidth);
                    polygonOptions.strokeColor((int) strokeColor);
                    polygonOptions.fillColor((int) fillColor);
                    com.amap.api.maps.model.Polygon polygon = aMap.addPolygon(polygonOptions);
                    String id = (String) request.get("id");
                    if (id != null) {
                        polygonMap.put(id, polygon);
                    }
                }
                break;
            case "updatePolygon":
                String updateId = (String) request.get("id");
                List<Map<String, Double>> updatePoints = (List<Map<String, Double>>) request.get("points");
                double updateStrokeWidth = toDouble(request.get("strokeWidth"));
                long updateStrokeColor = ((Number) request.get("strokeColor")).longValue();
                long updateFillColor = ((Number) request.get("fillColor")).longValue();

                com.amap.api.maps.model.Polygon updatePolygon = polygonMap.get(updateId);
                if (updatePolygon != null) {
                    if (updatePoints != null && updatePoints.size() > 0) {
                       List<LatLng> latLngs = new java.util.ArrayList<>();
                        for (Map<String, Double> point : updatePoints) {
                            latLngs.add(new LatLng(point.get("latitude"), point.get("longitude")));
                        }
                        updatePolygon.setPoints(latLngs);
                    }
                    updatePolygon.setStrokeWidth((float) updateStrokeWidth);
                    updatePolygon.setStrokeColor((int) updateStrokeColor);
                    updatePolygon.setFillColor((int) updateFillColor);
                    android.util.Log.d("Flutter2dAMap", "updatePolygon success: " + updateId + ", width: " + updateStrokeWidth);
                } else {
                    android.util.Log.e("Flutter2dAMap", "updatePolygon failed: " + updateId + " not found");
                }
                break;
            case "removePolygon":
                String removeId = (String) request.get("id");
                com.amap.api.maps.model.Polygon removePolygon = polygonMap.get(removeId);
                if (removePolygon != null) {
                    removePolygon.remove();
                    polygonMap.remove(removeId);
                }
                break;
            case "clear":
                if (aMap != null) {
                    aMap.clear();
                    mMarker = null;
                    polygonMap.clear();
                    markerMap.clear();
                }
                break;
            case "moveCamera":
                moveCamera(methodCall.arguments);
                break;
            case "animateCamera":
                animateCamera(methodCall.arguments);
                break;
            case "getLocation":
                if (mLocationClient != null) {
                    AMapLocation location = mLocationClient.getLastKnownLocation();
                    if (location != null) {
                        Map<String, Double> resultLocation = new HashMap<>();
                        resultLocation.put("latitude", location.getLatitude());
                        resultLocation.put("longitude", location.getLongitude());
                        result.success(resultLocation);
                        return;
                    }
                }
                result.success(null);
                break;
            default:
                break;    
        }
    }

    private double toDouble(Object obj) {
        if (obj instanceof Number) {
            return ((Number) obj).doubleValue();
        }
        try {
            return Double.parseDouble(obj.toString());
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0D;
    }
    
    @Override
    public View getView() {
        return mAMapWebView;
    }

    @Override
    public void dispose() {
        aMapWrapper.onDestroy();
        platformThreadHandler.removeCallbacks(postMessageRunnable);
        methodChannel.setMethodCallHandler(null);
    }

    @Override
    public void onLocationChanged(AMapLocation aMapLocation) {
        if (mListener != null && aMapLocation != null) {
            if (aMapLocation.getErrorCode() == 0) {
                // 显示系统小蓝点
                mListener.onLocationChanged(aMapLocation);
                aMap.moveCamera(CameraUpdateFactory.zoomTo(16));
                search(aMapLocation.getLatitude(), aMapLocation.getLongitude(), false);
            } else {
                Toast.makeText(context,"定位失败，请检查GPS是否开启！", Toast.LENGTH_SHORT).show();
            }
            if (mLocationClient != null) {
                mLocationClient.stopLocation();
            }
        }
    }

    private void search() {
        if (!isPoiSearch) {
            return;
        }
        isClick = false;
        query = new PoiSearch.Query(keyWord, SEARCH_CONTENT, city);
        // 设置每页最多返回多少条poiitem
        query.setPageSize(50);
        query.setPageNum(0);
        try {
            PoiSearch poiSearch = new PoiSearch(context, query);
            poiSearch.setOnPoiSearchListener(this);
            poiSearch.searchPOIAsyn();
        } catch (AMapException e) {
            e.printStackTrace();
        }
       
    }

    private void move(double lat, double lon) {
        LatLng latLng = new LatLng(lat, lon);
        drawMarkers(latLng, BitmapDescriptorFactory.defaultMarker());
    }

    private void search(double latitude, double longitude, boolean isClick) {
        if (!isPoiSearch) {
            return;
        }
        this.isClick = isClick;
        query = new PoiSearch.Query("", SEARCH_CONTENT, "");
        // 设置每页最多返回多少条poiitem
        query.setPageSize(1);
        query.setPageNum(0);

        try {
            PoiSearch poiSearch = new PoiSearch(context, query);
            poiSearch.setOnPoiSearchListener(this);
            LatLonPoint latLonPoint = new LatLonPoint(latitude, longitude);
            poiSearch.setBound(new PoiSearch.SearchBound(latLonPoint, 2000, true));
            poiSearch.searchPOIAsyn();
        } catch (AMapException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onMapClick(LatLng latLng) {
        if (null != methodChannel) {
            final Map<String, Object> map = new HashMap<String, Object>(2);
            map.put("latitude", latLng.latitude);
            map.put("longitude", latLng.longitude);
            methodChannel.invokeMethod("onAMapClick", map);
        }
        drawMarkers(latLng, BitmapDescriptorFactory.defaultMarker());
        search(latLng.latitude, latLng.longitude, true);
    }

    private Marker mMarker;
    
    private void drawMarkers(LatLng latLng, BitmapDescriptor bitmapDescriptor) {
        if (moveCameraOnTap) {
            aMap.moveCamera(CameraUpdateFactory.changeLatLng(new LatLng(latLng.latitude, latLng.longitude)));
        }
        if (!showClickMarker) {
             return;
        }
        if (mMarker == null) {
            mMarker = aMap.addMarker(new MarkerOptions().position(latLng).icon(bitmapDescriptor).draggable(true));
        } else {
            mMarker.setPosition(latLng);
        }
    }

    @Override
    public void activate(OnLocationChangedListener onLocationChangedListener) {
        mListener = onLocationChangedListener;
        if (mLocationClient == null) {
            try {
                mLocationClient = new AMapLocationClient(context);
                AMapLocationClientOption locationOption = new AMapLocationClientOption();
                mLocationClient.setLocationListener(this);
                //设置为高精度定位模式
                locationOption.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy);
                //设置定位参数
                mLocationClient.setLocationOption(locationOption);
                mLocationClient.startLocation();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public void deactivate() {
        mListener = null;
        if (mLocationClient != null) {
            mLocationClient.stopLocation();
            mLocationClient.onDestroy();
        }
        mLocationClient = null;
    }

    private final StringBuilder builder = new StringBuilder();

    @Override
    public void onPoiSearched(PoiResult result, int code) {

        builder.delete(0, builder.length());
        // 拼接json（避免引用gson之类的库，小插件不必要。。。）
        builder.append("[");

        if (code == AMapException.CODE_AMAP_SUCCESS) {
            // 搜索poi的结果
            if (result != null && result.getQuery() != null) {
                // 是否是同一条
                if (result.getQuery().equals(query)) {
                    final List<PoiItem> list = result.getPois();

                    if (isClick && list.size() > 0) {
                        PoiItem item = list.get(0);
                        Map<String, Object> map = new HashMap<>();
                        map.put("poiId", item.getPoiId());
                        map.put("poiName", item.getTitle());
                        map.put("latitude", item.getLatLonPoint().getLatitude());
                        map.put("longitude", item.getLatLonPoint().getLongitude());
                        methodChannel.invokeMethod("onPoiClick", map);
                    }

                    for (int i = 0; i < list.size(); i++) {
                        PoiItem item = list.get(i);
                        builder.append("{");
                        builder.append("\"cityCode\": \"");builder.append(item.getCityCode());builder.append("\",");
                        builder.append("\"cityName\": \"");builder.append(item.getCityName());builder.append("\",");
                        builder.append("\"provinceName\": \"");builder.append(item.getProvinceName());builder.append("\",");
                        builder.append("\"title\": \"");builder.append(item.getTitle());builder.append("\",");
                        builder.append("\"adName\": \"");builder.append(item.getAdName());builder.append("\",");
                        builder.append("\"provinceCode\": \"");builder.append(item.getProvinceCode());builder.append("\",");
                        builder.append("\"latitude\": \"");builder.append(item.getLatLonPoint().getLatitude());builder.append("\",");
                        builder.append("\"longitude\": \"");builder.append(item.getLatLonPoint().getLongitude());builder.append("\"");
                        builder.append("},");
                        if (i == list.size() - 1) {
                            builder.deleteCharAt(builder.length() - 1);
                        }
                    }

                    if (list.size() > 0 && !isClick) {
                        aMap.moveCamera(CameraUpdateFactory.zoomTo(16));
                        move(list.get(0).getLatLonPoint().getLatitude(), list.get(0).getLatLonPoint().getLongitude());
                    }
                }
            }
        }
        builder.append("]");
        postMessageRunnable = new Runnable() {
            @Override
            public void run() {
                Map<String, String> map = new HashMap<>(2);
                map.put("poiSearchResult", builder.toString());
                methodChannel.invokeMethod("poiSearchResult", map);
            }
        };
        if (platformThreadHandler.getLooper() == Looper.myLooper()) {
            postMessageRunnable.run();
        } else {
            platformThreadHandler.post(postMessageRunnable);
        }    }

    private void moveCamera(Object request) {
        if (aMap == null) return;
        Log.d(TAG,"moveCamera");
        com.amap.api.maps.CameraUpdate update = getCameraUpdate(request);
        if (update != null) {
            aMap.moveCamera(update);
        }
    }

    private void animateCamera(Object request) {
        if (aMap == null) return;
        Map<String, Object> params = (Map<String, Object>) request;
        Object cameraUpdateObj = params.get("cameraUpdate");
        long duration = 250;
        if (params.containsKey("duration")) {
            duration = ((Number) params.get("duration")).longValue();
        }
        
        com.amap.api.maps.CameraUpdate update = getCameraUpdate(cameraUpdateObj);
        if (update != null) {
//            aMap.animateCamera(update, duration, null);
        }
    }

    private com.amap.api.maps.CameraUpdate getCameraUpdate(Object request) {
        if (!(request instanceof List)) {
            return null;
        }
        List list = (List) request;
        if (list.isEmpty()) {
            return null;
        }
        String type = (String) list.get(0);
        
        switch (type) {
            case "newLatLng":
                Map<String, Double> latLngMap = (Map<String, Double>) list.get(1);
                return CameraUpdateFactory.newLatLng(new LatLng(latLngMap.get("latitude"), latLngMap.get("longitude")));
            case "newLatLngZoom":
                Map<String, Double> latLngZoomMap = (Map<String, Double>) list.get(1);
                double zoom = toDouble(list.get(2));
                return CameraUpdateFactory.newLatLngZoom(
                    new LatLng(latLngZoomMap.get("latitude"), latLngZoomMap.get("longitude")), 
                    (float) zoom
                );
            case "zoomIn":
                return CameraUpdateFactory.zoomIn();
            case "zoomOut":
                return CameraUpdateFactory.zoomOut();
            case "zoomTo":
                return CameraUpdateFactory.zoomTo((float) toDouble(list.get(1)));
            case "scrollBy":
//                return CameraUpdateFactory.scrollBy(
//                    (float) toDouble(list.get(1)),
//                    (float) toDouble(list.get(2))
//                );
            case "newCameraPosition":
                Map<String, Object> cameraParams = (Map<String, Object>) list.get(1);
                Map<String, Double> targetMap = (Map<String, Double>) cameraParams.get("target");
                double cZoom = toDouble(cameraParams.get("zoom"));
                double cTilt = toDouble(cameraParams.get("tilt"));
                double cBearing = toDouble(cameraParams.get("bearing"));
                
                com.amap.api.maps.model.CameraPosition cameraPosition = new com.amap.api.maps.model.CameraPosition(
                    new LatLng(targetMap.get("latitude"), targetMap.get("longitude")),
                    (float) cZoom,
                    (float) cTilt,
                    (float) cBearing
                );
                return CameraUpdateFactory.newCameraPosition(cameraPosition);
            default:
                return null;
        }
    }

    @Override
    public void onPoiItemSearched(PoiItem poiItem, int i) {

    }

    private BitmapDescriptor getBitmapDescriptor(Object iconObj) {
        if (!(iconObj instanceof List)) {
            return null;
        }
        List list = (List) iconObj;
        if (list.isEmpty()) {
            return null;
        }
        String type = (String) list.get(0);
        if ("defaultMarker".equals(type)) {
            if (list.size() > 1) {
                float hue = ((Double) toDouble(list.get(1))).floatValue();
                return BitmapDescriptorFactory.defaultMarker(hue);
            }
            return BitmapDescriptorFactory.defaultMarker();
        } else if ("fromAsset".equals(type)) {
            String assetName = (String) list.get(1);
            String assetPath = io.flutter.FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetName);
            return BitmapDescriptorFactory.fromAsset(assetPath);
        } else if ("fromAssetImage".equals(type)) {
            String assetName = (String) list.get(1);
            String assetPath = io.flutter.FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetName);
            return BitmapDescriptorFactory.fromAsset(assetPath);
        } else if ("fromBytes".equals(type)) {
            if (list.size() > 1) {
                Object data = list.get(1);
                byte[] bytes = null;
                if (data instanceof byte[]) {
                    bytes = (byte[]) data;
                }
                if (bytes != null) {
                    android.graphics.Bitmap bitmap = android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                    if (list.size() > 2) {
                        List sizeList = (List) list.get(2);
                        if (sizeList != null && sizeList.size() == 2) {
                            double width = toDouble(sizeList.get(0));
                            double height = toDouble(sizeList.get(1));
                            // Scale bitmap
                            if (width > 0 && height > 0) {
                                bitmap = android.graphics.Bitmap.createScaledBitmap(bitmap, (int)width, (int)height, true);
                            }
                        }
                    }
                    return BitmapDescriptorFactory.fromBitmap(bitmap);
                }
            }
        }
        return null;
    }

    @Override
    public boolean onMarkerClick(Marker marker) {
        Object obj = marker.getObject();
        if (obj instanceof Map) {
            Map userData = (Map) obj;
            String markerId = (String) userData.get("id");
            Boolean infoWindowEnable = (Boolean) userData.get("infoWindowEnable");
            
            if (markerId != null) {
                Map<String, String> map = new HashMap<>();
                map.put("markerId", markerId);
                methodChannel.invokeMethod("onMarkerClick", map);
            }
            
            // If infoWindowEnable is false, return true to prevent default behavior (showing info window)
            if (infoWindowEnable != null && !infoWindowEnable) {
                return true;
            }
        } else if (obj instanceof String) {
             // Fallback for types not using Map yet (if any left)
            String markerId = (String) obj;
            Map<String, String> map = new HashMap<>();
            map.put("markerId", markerId);
            methodChannel.invokeMethod("onMarkerClick", map);
            return true; // Assume consumed if we have ID but no config
        }
        return false;
    }

    @Override
    public void onMarkerDragStart(Marker marker) {
    }

    @Override
    public void onMarkerDrag(Marker marker) {
    }

    @Override
    public void onMarkerDragEnd(Marker marker) {
        Object obj = marker.getObject();
        String markerId = null;
        if (obj instanceof Map) {
             markerId = (String) ((Map) obj).get("id");
        } else if (obj instanceof String) {
             markerId = (String) obj;
        }

        if (markerId != null) {
            Map<String, Object> map = new HashMap<>();
            map.put("markerId", markerId);
            map.put("latitude", marker.getPosition().latitude);
            map.put("longitude", marker.getPosition().longitude);
            methodChannel.invokeMethod("onMarkerDragEnd", map);
        }
    }
    @Override
    public void onCameraChange(CameraPosition cameraPosition) {
        if (null != methodChannel && onCameraChange) {
            final Map<String, Object> map = new HashMap<String, Object>(2);
            map.put("latitude", cameraPosition.target.latitude);
            map.put("longitude", cameraPosition.target.longitude);
            methodChannel.invokeMethod("onCameraChange", map);
        }
    }

    @Override
    public void onCameraChangeFinish(CameraPosition cameraPosition) {
        if (null != methodChannel && onCameraChangeFinish) {
            final Map<String, Object> map = new HashMap<String, Object>(2);
            map.put("latitude", cameraPosition.target.latitude);
            map.put("longitude", cameraPosition.target.longitude);
            methodChannel.invokeMethod("onCameraChangeFinish", map);
        }
    }

//    void onCameraChange(CameraPosition var1);
//
//    void onCameraChangeFinish(CameraPosition var1);
}

