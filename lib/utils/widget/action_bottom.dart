import 'package:flutter/material.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homegenie/utils/api/check_in_out.dart';
import 'package:homegenie/utils/api/event.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:shared_preferences/shared_preferences.dart';
import 'warning.dart';
import '../widget/location_tracker.dart';
import '../api/location_api.dart';

class Action_Bottom {
  static Future<String> _getAddressFromLatLng(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
    } catch (e) {
      print("Address fetch error: $e");
    }
    return "Unknown Location";
  }

  static Future<bool> _handleLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Warning.show(context, 'Location services are disabled.', 'Error');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Warning.show(context, 'Location permission denied.', 'Error');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Warning.show(
        context,
        'Location permissions are permanently denied. Please enable them in settings.',
        'Error',
      );
      return false;
    }

    return true;
  }

  static Future<dynamic> show({
    required BuildContext context,
    required String title,
    required List<String> options,
    required bool isCheckedIn,
    VoidCallback? onTrackingStarted,
    VoidCallback? onTrackingStopped,
    Function(bool isNowCheckedIn)? onStatusUpdate,
  }) {
    return showAdaptiveActionSheet(
      context: context,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.blueAccent),
          ),
        ],
      ),
      actions:
          options
              .map(
                (option) => BottomSheetAction(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(option, style: TextStyle(fontSize: 20)),
                      const Icon(Icons.chevron_right, color: Colors.blueAccent),
                    ],
                  ),
                  onPressed: (_) async {
                    Navigator.pop(context);
                    if (option == "Head Office") {
                      List<dynamic> officeList = await Event.head_office_list();

                      List<String> officeNames =
                          officeList.map((e) => e.toString()).toList();

                      Action_Bottom_Secondary(
                        context: context,
                        title: option,
                        options: officeNames,
                        isCheckedIn: isCheckedIn,
                        onTrackingStarted: onTrackingStarted,
                        onTrackingStopped: onTrackingStopped,
                      );
                    } else {
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      final email = prefs.getString('email');

                      bool hasPermission = await _handleLocationPermission(
                        context,
                      );
                      if (!hasPermission) return;

                      Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      final address =
                          await LocationHelper.getAddressFromCoordinates(
                            position.latitude,
                            position.longitude,
                          );

                      final lastCheckoutAddress =
                          prefs.getString('last_checkout_address') ?? '';

                      var response;
                      if (isCheckedIn) {
                        LocationTrackerService.stopTracking();
                        double returnDistance =
                            LocationTrackerService.calculateTotalDistance();
                        onTrackingStopped?.call();
                        String formattedDistanceWithUnit;

                        if (returnDistance >= 1000) {
                          double km = returnDistance / 1000;
                          formattedDistanceWithUnit =
                              '${km.toStringAsFixed(2)} km';
                        } else {
                          formattedDistanceWithUnit =
                              '${returnDistance.toStringAsFixed(2)} m';
                        }
                        List<LatLng> path =
                            LocationTrackerService.getTrackedPoints();
                        List<Map<String, dynamic>> locationLogs =
                            path
                                .map(
                                  (latLng) => {
                                    'latitude': latLng.latitude,
                                    'longitude': latLng.longitude,
                                  },
                                )
                                .toList();

                        response = await Check.checkout(
                          email,
                          position.latitude,
                          position.longitude,
                          address,
                          lastCheckoutAddress.isNotEmpty
                              ? lastCheckoutAddress
                              : "",
                          formattedDistanceWithUnit,
                          option,
                          locationLogs,
                        );
                      } else {
                        response = await Check.checkin(
                          email,
                          position.latitude,
                          position.longitude,
                          address,
                          option,
                        );
                      }

                      if (response?['status'] == "Success") {
                        Warning.show(context, response['message'], 'Success');
                        // if (!isCheckedIn) {
                        //   LocationTrackerService.startTracking(
                        //     start: LatLng(
                        //       position.latitude,
                        //       position.longitude,
                        //     ),
                        //   );
                        //   onTrackingStarted?.call();
                        // }
                        await prefs.setString('last_checkout_address', '');
                        await prefs.setString('last_lat_lng', '');
                        await prefs.setBool('with_event', false);

                        await prefs.setString(
                          'last_lat_lng',
                          '${position.latitude},${position.longitude}',
                        );
                        // if (!isCheckedIn) {
                        //   onStatusUpdate?.call(true);
                        // } else {
                        //   onStatusUpdate?.call(false);
                        // }
                      } else {
                        print(response);
                        print("@@@@");
                        print(response['message']);
                        Warning.show(context, response['message'], 'Warning');
                      }
                    }
                  },
                ),
              )
              .toList(),
    );
  }

  static Future<dynamic> Action_Bottom_Secondary({
    required BuildContext context,
    required String title,
    required List<String> options,
    required bool isCheckedIn,
    VoidCallback? onTrackingStarted,
    VoidCallback? onTrackingStopped,
  }) {
    return showAdaptiveActionSheet(
      context: context,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.blueAccent),
          ),
        ],
      ),
      actions:
          options
              .map(
                (option) => BottomSheetAction(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(option),
                      const Icon(Icons.chevron_right, color: Colors.blueAccent),
                    ],
                  ),
                  onPressed: (_) async {
                    Navigator.pop(context);
                    try {
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();

                      Map<String, dynamic> office_details =
                          await Event.Head_office_details(option);

                      double _geofenceRadius =
                          office_details['allowd_distance_meters'];

                      maps.LatLng _geofenceCenter = maps.LatLng(
                        double.parse(office_details['latitude']),
                        double.parse(office_details['longitude']),
                      );

                      bool hasPermission = await _handleLocationPermission(
                        context,
                      );
                      if (!hasPermission) return;

                      Position? _position;
                      _position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      if (_position != null) {
                        double distance = Geolocator.distanceBetween(
                          _position!.latitude,
                          _position!.longitude,
                          _geofenceCenter.latitude,
                          _geofenceCenter.longitude,
                        );

                        if (distance <= _geofenceRadius) {
                          final email = prefs.getString('email');
                          final address =
                              await LocationHelper.getAddressFromCoordinates(
                                _position.latitude,
                                _position.longitude,
                              );

                          final lastCheckoutAddress =
                              prefs.getString('last_checkout_address') ?? '';

                          var response;
                          if (isCheckedIn) {
                            // LocationTrackerService.stopTracking();
                            // onTrackingStopped?.call();

                            double returnDistance =
                                LocationTrackerService.calculateTotalDistance();
                            String formattedDistanceWithUnit;

                            if (returnDistance >= 1000) {
                              double km = returnDistance / 1000;
                              formattedDistanceWithUnit =
                                  '${km.toStringAsFixed(2)} km';
                            } else {
                              formattedDistanceWithUnit =
                                  '${returnDistance.toStringAsFixed(2)} m';
                            }
                            List<LatLng> path =
                                LocationTrackerService.getTrackedPoints();
                            List<Map<String, dynamic>> locationLogs =
                                path
                                    .map(
                                      (latLng) => {
                                        'latitude': latLng.latitude,
                                        'longitude': latLng.longitude,
                                      },
                                    )
                                    .toList();
                            response = await Check.checkout(
                              email,
                              _position.latitude,
                              _position.longitude,
                              address,
                              lastCheckoutAddress.isNotEmpty
                                  ? lastCheckoutAddress
                                  : "",
                              formattedDistanceWithUnit,
                              option,
                              locationLogs,
                            );
                          } else {
                            response = await Check.checkin(
                              email,
                              _position.latitude,
                              _position.longitude,
                              address,
                              option,
                            );
                          }

                          if (response?['status'] == "Success") {
                            Warning.show(
                              context,
                              response['message'],
                              'Success',
                            );
                            // if (!isCheckedIn) {
                            //   LocationTrackerService.startTracking(
                            //     start: LatLng(
                            //       _position.latitude,
                            //       _position.longitude,
                            //     ),
                            //   );
                            //   onTrackingStarted?.call();
                            // }
                            await prefs.setString('last_checkout_address', '');
                            await prefs.setBool('with_event', false);

                            await prefs.setString(
                              'last_lat_lng',
                              '${_position.latitude},${_position.longitude}',
                            );
                          } else {
                            Warning.show(
                              context,
                              response['message'],
                              'Warning',
                            );
                          }

                          // setState(() => _checkedIn = !_checkedIn);
                        } else {
                          Warning.show(
                            context,
                            'You are outside the geofence!',
                            'Error',
                          );
                        }
                      }
                    } catch (e) {
                      Warning.show(context, 'Error: ${e.toString()}', 'Error');
                    }
                  },
                ),
              )
              .toList(),
    );
  }
}
