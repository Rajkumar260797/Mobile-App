// import 'dart:isolate';
// import 'dart:ui';
// import 'package:background_locator_2/location_dto.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';


// class LocationCallbackHandler {
//   static final List<LatLng> _locationPoints = [];
//   static LatLng? _startPoint;

//   @pragma('vm:entry-point')
//   static void initCallback(Map<String, dynamic> params) {
//     print("📡 Background locator initialized");
//   }
// @pragma('vm:entry-point')
// static void onNotificationTap() {
//   initCallback(<String, dynamic>{});
// }

//   @pragma('vm:entry-point')
// static void disposeCallback() {
//   print("🛑 Background locator disposed");
// }


//   @pragma('vm:entry-point')
//   static void callback(LocationDto locationDto) {
//     print('333333333333333333333333');
//     final latLng = LatLng(locationDto.latitude, locationDto.longitude);
//     _locationPoints.add(latLng);
//     print("📍 BG Point: ${latLng.latitude}, ${latLng.longitude}");
//   }

//   static List<LatLng> getTrackedPoints() => List.unmodifiable(_locationPoints);

//   static LatLng? getStartPoint() => _startPoint;

//   static void clear() {
//     _locationPoints.clear();
//     _startPoint = null;
//   }
  

//   static void setStart(LatLng point) {
//     _startPoint = point;
//   }
// }
