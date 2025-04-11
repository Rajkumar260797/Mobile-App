// Code without any external package but will not work on background



// import 'dart:async';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';

// class LocationTrackerService {
//   static final List<LatLng> _locationPoints = [];
//   static bool get isTracking => _timer != null;

//   static Timer? _timer;
//   static LatLng? _startPoint;

//   static void startTracking({required LatLng start}) {
//     _startPoint = start;
//     _locationPoints.clear();

//     _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
//       Position pos = await Geolocator.getCurrentPosition();
//       _locationPoints.add(LatLng(pos.latitude, pos.longitude));
//       print("📍 Point added: ${pos.latitude}, ${pos.longitude}");
//     });
//   }

//   static void stopTracking() {
//     _timer?.cancel();
//     _timer = null;
//     print("🛑 Tracking stopped");
//   }

// // static double calculateTotalDistance() {
// //     double totalDistance = 0.0;
// //     int segment_passed = 1;
// //     for (int i = 0; i < _locationPoints.length - 1; i++) {
      
// //       print(_locationPoints[i].latitude,);
// //       print(  _locationPoints[i].longitude,);
// //       print(  _locationPoints[i + 1].latitude,);
// //       print(  _locationPoints[i + 1].longitude,);
// //       // totalDistance += Geolocator.distanceBetween(
// //       //   _locationPoints[i].latitude,
// //       //   _locationPoints[i].longitude,
// //       //   _locationPoints[i + 1].latitude,
// //       //   _locationPoints[i + 1].longitude,
// //       // );
// //       double segment = Geolocator.distanceBetween(
// //       _locationPoints[i].latitude,
// //       _locationPoints[i].longitude,
// //       _locationPoints[i + segment_passed].latitude,
// //       _locationPoints[i + segment_passed].longitude,
// //     );

// //     if (segment >= 5) { // Ignore noise
// //       totalDistance += segment;
// //       i = segment_passed -1 ;
// //       segment_passed = 1;
// //     }
// //     else{
// //       segment_passed += 1;
// //       if (_locationPoints.length <= i + segment_passed){
// //         totalDistance += segment;
// //       }
// //       else{
// //         i -= 1;
// //       }
// //     }



// //     }
// //     print("📏 Total distance: $totalDistance meters");
// //     return totalDistance;
//   // }
//   static double calculateTotalDistance() {
//     double totalDistance = 0.0;
//     for (int i = 0; i < _locationPoints.length - 1; i++) {

//       print(_locationPoints[i].latitude,);
//       print(  _locationPoints[i].longitude,);
//       print(  _locationPoints[i + 1].latitude,);
//       print(  _locationPoints[i + 1].longitude,);
//       // totalDistance += Geolocator.distanceBetween(
//       //   _locationPoints[i].latitude,
//       //   _locationPoints[i].longitude,
//       //   _locationPoints[i + 1].latitude,
//       //   _locationPoints[i + 1].longitude,
//       // );
//       double segment = Geolocator.distanceBetween(
//       _locationPoints[i].latitude,
//       _locationPoints[i].longitude,
//       _locationPoints[i + 1].latitude,
//       _locationPoints[i + 1].longitude,
//     );
//     print(segment);

//     if (segment >= 5) { // Ignore noise
//       totalDistance += segment;
//     }



//     }
//     print("📏 Total distance: $totalDistance meters");
//     return totalDistance;
//   }

//   static LatLng? getStartPoint() => _startPoint;

//   static List<LatLng> getTrackedPoints() => List.unmodifiable(_locationPoints);

//   static void clear() {
//     _locationPoints.clear();
//     _startPoint = null;
//   }
// }



// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// import 'dart:async';
// import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

// class LocationTrackerService {
//   static final List<LatLng> _locationPoints = [];
//   static bool get isTracking => _isTrackingBackground;
//   static bool _isTrackingBackground = false;
//   static LatLng? _startPoint;

//   // Start tracking location in the background
//   static void startTracking({required LatLng start}) {
//     _startPoint = start;
//     _locationPoints.clear();

//     // Initialize BackgroundGeolocation
//     if (!_isTrackingBackground) {
//       _initBackgroundGeolocation();
//       print("******* Started tracking in the background");

//       // Start background location tracking
//       _isTrackingBackground = true;
//       bg.BackgroundGeolocation.start();
//     } else {
//       print("Background geolocation is already running.");
//     }
//   }

//   // Initialize Background Geolocation for background tracking
//   static void _initBackgroundGeolocation() {
//     // Location update callback
//     bg.BackgroundGeolocation.onLocation((bg.Location location) {
//       double latitude = location.coords.latitude!;
//       double longitude = location.coords.longitude!;

//       // Add the new location to the list
//       _locationPoints.add(LatLng(latitude, longitude));

//       // Print the current location every 5 seconds
//       print("📍 Current Location: Latitude: $latitude, Longitude: $longitude");
//     });

//     // Error callback: Use BackgroundGeolocation.onError for error handling
//     // bg.BackgroundGeolocation.onError((bg.BackgroundGeolocationError error) {
//     //   print("Background Geolocation Error: ${error.message}");
//     // });

//     // Configure BackgroundGeolocation for continuous background tracking
//     bg.BackgroundGeolocation.ready(bg.Config(
//       distanceFilter: 1, // Minimum distance between location updates (in meters)
//       stopOnTerminate: false, // Keep running after app terminates
//       startOnBoot: true, // Start tracking when the device is rebooted
//       enableHeadless: true, // Enable headless mode for background tasks
//       backgroundPermissionRationale: bg.PermissionRationale(
//         title: "We need your location",
//         message: "Please enable location services for continuous tracking.",
//         positiveAction: "OK",
//         negativeAction: "Cancel",
//       ),
//       // Set the interval for location updates to 5 seconds
//       locationUpdateInterval: 5000, // 5000 milliseconds = 5 seconds
//       fastestLocationUpdateInterval: 5000, // Fastest update interval (for efficiency)
//     )).then((bg.State state) {
//       // Start background tracking when the configuration is ready
//       bg.BackgroundGeolocation.start();
//     });
// bg.BackgroundGeolocation.onLocation((bg.Location location) {
//   print("🔥 Received location: ${location.coords.latitude}, ${location.coords.longitude}");
// });

//   }

//   static void stopTracking() {
//     _isTrackingBackground = false;
//     print("🛑 Tracking stopped");

//     // Stop background location tracking
//     bg.BackgroundGeolocation.stop();
//   }

//   static double calculateTotalDistance() {
//     double totalDistance = 0.0;
//     for (int i = 0; i < _locationPoints.length - 1; i++) {
//       double segment = Geolocator.distanceBetween(
//         _locationPoints[i].latitude,
//         _locationPoints[i].longitude,
//         _locationPoints[i + 1].latitude,
//         _locationPoints[i + 1].longitude,
//       );

//       print("Segment distance: $segment meters");

//       if (segment >= 5) { // Ignore small movements/noise
//         totalDistance += segment;
//       }
//     }
//     print("📏 Total distance: $totalDistance meters");
//     return totalDistance;
//   }

//   static LatLng? getStartPoint() => _startPoint;

//   static List<LatLng> getTrackedPoints() => List.unmodifiable(_locationPoints);

//   static void clear() {
//     _locationPoints.clear();
//     _startPoint = null;
//   }
// }




//Package -Flutter Background Geolocation [Need to Buy Licences for Release Build]
// import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationTrackerService {
  static final List<LatLng> _locationPoints = [];
  static LatLng? _startPoint;
  static bool _isTracking = false;


static bool _isInitialized = false;

// static Future<void> _configureBackgroundGeolocation() async {
//   if (_isInitialized) return;

//   await bg.BackgroundGeolocation.ready(bg.Config(
//     desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
//     distanceFilter: 0,
//     locationUpdateInterval: 5000,
//     stopOnTerminate: false,
//     startOnBoot: true,
//     scheduleUseAlarmManager: false,
//     logLevel: bg.Config.LOG_LEVEL_VERBOSE,
//     stopTimeout: 0,
//     debug: false,
//     disableMotionActivityUpdates: true,
//     isMoving: true,
//     foregroundService: true,
//     disableStopDetection: true, // <---- ✅ Important
//   autoSync: true,
//   notification: bg.Notification(
//     title: "Location Tracking",
//     text: "Tracking your movement...",
//     channelName: "tracking_channel",
    

//   )
//   ));

LatLng? _lastPoint;

// bg.BackgroundGeolocation.onLocation((bg.Location location) {
//   final coords = location.coords;
//   final point = LatLng(coords.latitude, coords.longitude);

//   if (_lastPoint == null ||
//       Geolocator.distanceBetween(
//             _lastPoint!.latitude,
//             _lastPoint!.longitude,
//             point.latitude,
//             point.longitude,
//           ) >= 5) {
//     _locationPoints.add(point);
//     _lastPoint = point;
//     print("📍 BG Point added: ${point.latitude}, ${point.longitude}");
//   } else {
//     print("⛔ Ignored (under 5m): ${point.latitude}, ${point.longitude}");
//   }
// });
//   bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
//     print("🚶 Motion Change: isMoving=${location.isMoving}");
//   });

//   _isInitialized = true;
// }


  static bool get isTracking => _isTracking;


    // Optional: error handling
//     bg.BackgroundGeolocation.onError((bg.LocationError error) {
//       print('[Location error] code: ${error.code}, message: ${error.message}');
//     });

//     bg.BackgroundGeolocation.onConnectivityChange((ConnectivityChangeEvent event) {
//   print('[onConnectivityChange] ${event}');
// });

    // bg.BackgroundGeolocation.onLocation((bg.Location location) {
    //   print('[location] - ${location}');
    // });

  

static Future<void> startTracking({required LatLng start}) async {

  _startPoint = start;
  _locationPoints.clear();

  // await _configureBackgroundGeolocation();

  // bool isEnabled = await bg.BackgroundGeolocation.state.then((s) => s.enabled);

  // if (!isEnabled) {
  //   await bg.BackgroundGeolocation.start();
  //   await bg.BackgroundGeolocation.changePace(true);
  //   print("🚀 BG Tracking started");
  // } else {
  //   print("⚠️ BG Tracking already started");
  //   await bg.BackgroundGeolocation.changePace(true); // even if already started
  // }

  // _isTracking = true;
}


  static Future<void> stopTracking() async {

    // await bg.BackgroundGeolocation.stop();
    // _isTracking = false;
    print("🛑 BG Tracking stopped");
  }

  static double calculateTotalDistance() {
    double totalDistance = 0.0;
    for (int i = 0; i < _locationPoints.length - 1; i++) {
      final segment = Geolocator.distanceBetween(
        _locationPoints[i].latitude,
        _locationPoints[i].longitude,
        _locationPoints[i + 1].latitude,
        _locationPoints[i + 1].longitude,
      );
      if (segment >= 5) {
        totalDistance += segment;
      }
    }
    print("📏 Total distance: $totalDistance meters");
    return totalDistance;
  }

  static LatLng? getStartPoint() => _startPoint;
  static List<LatLng> getTrackedPoints() => List.unmodifiable(_locationPoints);

  static void clear() {
    _locationPoints.clear();
    _startPoint = null;
  }
}
