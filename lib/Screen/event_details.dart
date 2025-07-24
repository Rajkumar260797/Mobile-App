import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homegenie/utils/api/check_in_out.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api/event.dart';
import '../utils/widget/location_tracker.dart';
import '../utils/widget/warning.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/api/location_api.dart';

class EventDetails extends StatefulWidget {
  final String eventid;

  const EventDetails({super.key, required this.eventid});

  @override
  State<EventDetails> createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  Map<String, dynamic> eventData = {};

  bool _isLoading = false;
  bool _isActionInProgress = false;

  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    print('event initState called');
    _checkPing();
  }

  Future<void> _checkPing() async {
  try {
    var pingResult = await Check.pingpong(); 

    if (pingResult == false) {
      Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    } else {
      _init();  
    }
  } catch (e) {
    print('Error during ping: $e');
  }
}


  Future<void> _init() async {
    prefs = await SharedPreferences.getInstance();
    await _fetchData();
    setState(() {});
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _fetchEventDetails()
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return "--:--";

    DateTime dt = DateTime.parse(dateTime);
    return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year.toString().substring(2)}";
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return "--:--";
    DateTime dt = DateTime.parse(dateTime);
    String period = dt.hour >= 12 ? "pm" : "am";
    int hour =
        dt.hour > 12
            ? dt.hour - 12
            : dt.hour == 0
            ? 12
            : dt.hour;
    String minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute$period";
  }

  String _calculateWorkingHours(String? checkIn, String? checkOut) {
    if (checkIn == null || checkOut == null) return "--:--";

    try {
      DateTime inTime = DateTime.parse(checkIn);
      DateTime outTime = DateTime.parse(checkOut);

      Duration difference = outTime.difference(inTime);

      int hours = difference.inHours;
      int minutes = difference.inMinutes.remainder(60);

      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
    } catch (e) {
      return "--:--";
    }
  }

  Future<void> _fetchEventDetails() async {
    final response = await Event.eventdetails(widget.eventid, context);
    if (response != Null) {
      setState(() {
        eventData = response;
      });
    }
  }

  String _getParticipantsTitles() {
    final participants = eventData['reference_details'];
    if (participants == null || participants is! List) return '';

    List<String> titles =
        participants
            .map<String>((p) => "${p['opportunity_from']}-${p['party_name']}")
            .toList();

    return titles.join(', ');
  }

  Future<String> _getCurrentLocationAddress() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final address = await LocationHelper.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (address.isNotEmpty) {
        return address;
      } else {
        return "Unknown location";
      }
    } catch (e) {
      print("Error fetching location: $e");
      return "Error fetching location";
    }
  }

  Future<bool> _handleLocationPermission() async {
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
        'Location permission permanently denied. Please enable it from settings.',
        'Error',
      );
      return false;
    }

    return true;
  }

  // void launchDialer(String phoneNumber) async {
  //   final Uri dialUri = Uri(scheme: 'tel', path: phoneNumber);
  //   if (await canLaunchUrl(dialUri)) {
  //     await launchUrl(dialUri,mode: LaunchMode.externalApplication,);
  //   } else {
  //     throw 'Could not launch $dialUri';
  //   }
  // }

  void launchDialer(String phoneNumber) async {
  final Uri dialUri = Uri(scheme: 'tel', path: phoneNumber);
  print('Trying to launch: $dialUri');
  if (await canLaunchUrl(dialUri)) {
    print('Can launch, trying...');
    await launchUrl(
      dialUri,
      mode: LaunchMode.externalApplication,
    );
    print('Dialer launched');
  } else {
    print('Cannot launch $dialUri');
  }
}


  void openWhatsAppChat(String phoneNumber) async {
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final formattedNumber =
        cleanedNumber.startsWith('91') ? cleanedNumber : '91$cleanedNumber';

    final uri = Uri.parse('whatsapp://send?phone=$formattedNumber');

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp not installed or cannot open.')),
      );
    }
  }

  bool _isTodayEvent() {
    if (eventData['event']['starts_on'] == null) return false;

    DateTime eventDate = DateTime.parse(eventData['event']['starts_on']);
    DateTime now = DateTime.now();

    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
  }
Future<bool> showOTPDialog(BuildContext context) async {
  TextEditingController otpController = TextEditingController();
  int timerSeconds = 30;
  Timer? resendTimer;

  Future<void> sendOtp() async {
    await Event.sendOtp(widget.eventid, context);
  }

  await sendOtp(); // Initial OTP send

  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Start the timer inside the builder so we have access to setState
          void startTimer() {
            resendTimer?.cancel();
            resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
              if (timerSeconds == 0) {
                timer.cancel();
              } else {
                setState(() {
                  timerSeconds--;
                });
              }
            });
          }

          // Start timer on first build only
          if (resendTimer == null) {
            startTimer();
          }

          return AlertDialog(
            title: const Text('Enter OTP to Confirm'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'OTP'),
                ),
                const SizedBox(height: 10),
                Text(
                  timerSeconds > 0
                      ? 'Resend OTP in $timerSeconds sec'
                      : 'Didn’t receive it?',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                TextButton(
                  onPressed: timerSeconds == 0
                      ? () async {
                          await sendOtp();
                          setState(() {
                            timerSeconds = 30;
                          });
                          startTimer(); // restart timer
                        }
                      : null,
                  child: const Text('Resend OTP'),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  resendTimer?.cancel();
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final isValid = await Event.verifyOtp(
                      otpController.text, widget.eventid);
                  if (isValid) {
                    resendTimer?.cancel();
                    Navigator.of(dialogContext).pop(true);  // close dialog first

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('OTP Verified')),
);

                  } else {

                    Warning.show(
                                                    context,
                                                    'Invalid OTP',
                                                    'Error',
                                                  );
                    
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  ).then((value) => value ?? false);
}



  @override
  Widget build(BuildContext context) {
    Color getActionColor() {
      final checkIn = eventData['event']['custom_check_in'];
      final checkOut = eventData['event']['custom_check_out'];

      if ((checkIn == null || checkIn.isEmpty) &&
          (checkOut == null || checkOut.isEmpty)) {
        return Colors.green; // Check In state
      } else if ((checkIn != null && checkIn.isNotEmpty) &&
          (checkOut == null || checkOut.isEmpty)) {
        return Colors.red; // Check Out state
      }
      return const Color.fromARGB(231, 175, 173, 173); // Already done
    }

    String getButtonLabel() {
      // _checkPing();
      final checkIn = eventData['event']['custom_check_in'];
      final checkOut = eventData['event']['custom_check_out'];

      if ((checkIn == null || checkIn.isEmpty) &&
          (checkOut == null || checkOut.isEmpty)) {
        return 'Click Here to Check In';
      } else if ((checkIn != null && checkIn.isNotEmpty) &&
          (checkOut == null || checkOut.isEmpty)) {
        return 'Click Here to Check Out';
      }
      return 'Checked In and Out';
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Event Details', style: TextStyle(fontSize: 20)),
          backgroundColor: Colors.blueAccent,
        ),
        body:
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: Colors.blueAccent,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              radius: 40,
                              child: Text(
                                (eventData['reference_details'] != null &&
                                        eventData['reference_details']
                                            .isNotEmpty)
                                    ? (eventData['reference_details'][0]['party_name']
                                                ?.isNotEmpty ??
                                            false
                                        ? eventData['reference_details'][0]['party_name'][0]
                                        : '')
                                    : (eventData['event']?['name']
                                                ?.isNotEmpty ??
                                            false
                                        ? eventData['event']['name'][0] // Removed extra `?`
                                        : ''),
                                style: TextStyle(fontSize: 18),
                              ),
                            ),

                            SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (eventData['reference_details'] != null &&
                                            eventData['reference_details']
                                                .isNotEmpty)
                                        ? eventData['reference_details'][0]['party_name'] ??
                                            "No Party Name"
                                        : eventData['event']?['name'] ??
                                            "No Event Name",
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.location_pin,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 5),
                                      Flexible(
                                        child:
                                        //         Text(eventData['event']['subject']??'',
                                        // style: TextStyle(fontSize: 14),
                                        // maxLines: 2,
                                        //           overflow: TextOverflow.ellipsis,
                                        //         ),
                                        FutureBuilder<String>(
                                          future: _getCurrentLocationAddress(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Text(
                                                "Fetching location...",
                                                style: TextStyle(fontSize: 14),
                                              );
                                            } else if (snapshot.hasError) {
                                              return Text(
                                                "Location error",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.red,
                                                ),
                                              );
                                            } else {
                                              return Text(
                                                snapshot.data ??
                                                    "Location not found",
                                                style: TextStyle(fontSize: 14),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        Container(
                          child: TabBar(
                            tabs: [Tab(text: 'Check In'), Tab(text: 'Details')],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              RefreshIndicator(

                                onRefresh: _fetchData,
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  child: Container(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                
                                          children: [
                                            SizedBox(height: 250),
                                
                                            GestureDetector(
                                              onTap: () async {
                                                setState(() {
                                                  _isActionInProgress = true;
                                                });
                                                if (!_isTodayEvent()) {
                                                  Warning.show(
                                                    context,
                                                    'You can only check in/out on the event day.',
                                                    'Invalid Date',
                                                  );
                                                  return;
                                                }
                                
                                                final userEmail = prefs.getString(
                                                  'email',
                                                ); // or userId
                                                final eventId = widget.eventid;
                                                String? checkIn =
                                                    eventData['event']['custom_check_in'];
                                                String? checkOut =
                                                    eventData['event']['custom_check_out'];
                                
                                                Position position;
                                                try {
                                                  bool serviceEnabled =
                                                      await Geolocator.isLocationServiceEnabled();
                                                  if (!serviceEnabled) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "Location services are disabled.",
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                
                                                  LocationPermission permission =
                                                      await Geolocator.checkPermission();
                                                  if (permission ==
                                                      LocationPermission.denied) {
                                                    permission =
                                                        await Geolocator.requestPermission();
                                                    if (permission ==
                                                        LocationPermission
                                                            .denied) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            "Location permission denied.",
                                                          ),
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                  }
                                
                                                  if (permission ==
                                                      LocationPermission
                                                          .deniedForever) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "Location permission permanently denied.",
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  bool hasPermission =
                                                      await _handleLocationPermission();
                                                  if (!hasPermission) return;
                                
                                                  position =
                                                      await Geolocator.getCurrentPosition(
                                                        desiredAccuracy:
                                                            LocationAccuracy.high,
                                                      );
                                                  double lat = position.latitude;
                                                  double lng = position.longitude;
                                                  final address =
                                                      await LocationHelper.getAddressFromCoordinates(
                                                        lat,
                                                        lng,
                                                      );
                                
                                                  final working_hrs =
                                                      _calculateWorkingHours(
                                                        eventData['event']['custom_check_in'],
                                                        DateTime.now().toString(),
                                                      );
                                                  if ((checkIn == null ||
                                                          checkIn.isEmpty) &&
                                                      (checkOut == null ||
                                                          checkOut.isEmpty)) {
                                                    final response =
                                                        await Event.eventCheckin(
                                                          userEmail,
                                                          eventId,
                                                          lat,
                                                          lng,
                                                          address,
                                                          context,
                                                        );
                                    
                                                    if (response['message'] != null)  {
                                                    if (response['message']['status'] ==
                                                        "success") {
                                                      Warning.show(
                                                        context,
                                                        response['message']['message'],
                                                        "Success",
                                                      );
                                                      await prefs.setBool(
                                                        'with_event',
                                                        true,
                                                      );
                                                      _fetchData(); // refresh
                                                    } else if (response['message']['status'] ==
                                                        "error") {
                                                      Warning.show(
                                                        context,
                                                        response['message']['message'],
                                                        "Error",
                                                      );
                                                    }
                                                          }
                                                  } 
                                                  else if ((checkIn != null &&
                                                          checkIn.isNotEmpty) &&
                                                      (checkOut == null ||
                                                          checkOut.isEmpty)) {

                                                            bool isOtpRequired = await Event.checkIfOtpRequired(widget.eventid, context);
                                                            print(isOtpRequired);

  if (isOtpRequired) {
    bool confirmed = await showOTPDialog(context);

    if (!confirmed) {
      Warning.show(context, "OTP verification failed. Cannot proceed.", "Error");
      return;
    }
  }
                                
                                                    
                                
                                
                                                    LocationTrackerService.stopTracking();
                                                    double distance =
                                                        LocationTrackerService.calculateTotalDistance();
                                
                                                    String
                                                    formattedDistanceWithUnit;
                                
                                                    if (distance >= 1000) {
                                                      double km = distance / 1000;
                                                      formattedDistanceWithUnit =
                                                          '${km.toStringAsFixed(2)} km';
                                                    } else {
                                                      formattedDistanceWithUnit =
                                                          '${distance.toStringAsFixed(2)} m';
                                                    }
                                
                                                    List<LatLng> path =
                                                        LocationTrackerService.getTrackedPoints();
                                
                                                    // 3. Convert to JSON-friendly format
                                                    List<Map<String, dynamic>>
                                                    locationLogs =
                                                        path
                                                            .map(
                                                              (latLng) => {
                                                                'latitude':
                                                                    latLng
                                                                        .latitude,
                                                                'longitude':
                                                                    latLng
                                                                        .longitude,
                                                              },
                                                            )
                                                            .toList();
                                
                                                    final last_lat_lng =
                                                        prefs.getString(
                                                          'last_lat_lng',
                                                        ) ??
                                                        '';
                                
                                                    final response =
                                                        await Event.eventCheckout(
                                                          userEmail,
                                                          eventId,
                                                          lat,
                                                          lng,
                                                          address,
                                                          working_hrs,
                                                          formattedDistanceWithUnit,
                                                          last_lat_lng,
                                                          jsonEncode(
                                                            locationLogs,
                                                          ),
                                                          context,
                                                        );
                                                    if (response['message'] != null) {

                                                      if (response['message']['status'] ==
                                                          "success") {
                                                        LocationTrackerService.startTracking(
                                                        start: LatLng(
                                                          position.latitude,
                                                          position.longitude,
                                                        ),
                                                      );
                                
                                                      Warning.show(
                                                        context,
                                                        response['message']['message'],
                                                        "Success",
                                                      );
                                                      await prefs.setString(
                                                        'last_checkout_address',
                                                        address,
                                                      );
                                
                                                      await prefs.setString(
                                                        'last_lat_lng',
                                
                                                        '$lat,$lng',
                                                      );
                                
                                                      _fetchData(); // refresh
                                                    }
                                                   else {
                                                    Warning.show(
                                                      context,
                                                      "Already checked in and out",
                                                      "",
                                                    );
                                                  }
                                                }
                                                  }
                                                } catch (e) {
                                                  print("Location error: $e");
                                                  Warning.show(
                                                    context,
                                                    "$e",
                                                    "Error",
                                                  );
                                                } finally {
                                                  setState(() {
                                                    _isActionInProgress = false;
                                                  });
                                                }
                                              },
                                
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 80,
                                                    backgroundColor:
                                                        getActionColor(),
                                                    child: CircleAvatar(
                                                      radius: 60,
                                                      backgroundColor:
                                                          const Color.fromARGB(
                                                            255,
                                                            221,
                                                            217,
                                                            217,
                                                          ),
                                                      child: CircleAvatar(
                                                        radius: 40,
                                                        backgroundColor:
                                                            const Color.fromARGB(
                                                              231,
                                                              175,
                                                              173,
                                                              173,
                                                            ),
                                                        child: Icon(
                                                          Icons.touch_app,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (_isActionInProgress)
                                                    SizedBox(
                                                      height: 40,
                                                      width: 40,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 3,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(getButtonLabel()),
                                        SizedBox(height: 20),
                                        Container(
                                          padding: EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                                // offset: Offset(3, 5),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                children: [
                                                  Icon(Icons.timer),
                                                  Text(
                                                    _formatTime(
                                                      eventData['event']['custom_check_in'],
                                                    ),
                                                  ),
                                                  Text("Check In"),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  Icon(Icons.timer),
                                                  Text(
                                                    _formatTime(
                                                      eventData['event']['custom_check_out'],
                                                    ),
                                                  ),
                                                  Text("Check Out"),
                                                ],
                                              ),
                                              Container(
                                                width: 90,
                                                child: Column(
                                                  children: [
                                                    Icon(Icons.timer),
                                                    Text(
                                                      _calculateWorkingHours(
                                                        eventData['event']['custom_check_in'],
                                                        eventData['event']['custom_check_out'],
                                                      ),
                                                    ),
                                
                                                    Text("Working Hrs"),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              RefreshIndicator(

                                onRefresh: _fetchData,
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  child: Container(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 20),
                                
                                        Text(
                                          'Name:${eventData['event']['name']}',
                                        ),
                                        SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                (eventData['reference_details'] !=
                                                            null &&
                                                        eventData['reference_details']
                                                            .isNotEmpty &&
                                                        eventData['reference_details'][0]['contact_mobile'] !=
                                                            null &&
                                                        eventData['reference_details'][0]['contact_mobile']
                                                            .toString()
                                                            .isNotEmpty)
                                                    ? 'Mobile Number: ${eventData['reference_details'][0]['contact_mobile']}'
                                                    : 'Mobile Number: null',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (eventData['reference_details'] !=
                                                    null &&
                                                eventData['reference_details']
                                                    .isNotEmpty &&
                                                eventData['reference_details'][0]['contact_mobile'] !=
                                                    null &&
                                                eventData['reference_details'][0]['contact_mobile']
                                                    .toString()
                                                    .isNotEmpty)
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.call),
                                                    onPressed: () {
                                                      final phone =
                                                          eventData['reference_details'][0]['contact_mobile'];
                                                      launchDialer(phone);
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: FaIcon(
                                                      FontAwesomeIcons.whatsapp,
                                                      color: Colors.green,
                                                    ),
                                
                                                    onPressed: () {
                                                      final phone =
                                                          eventData['reference_details'][0]['contact_mobile'];
                                                      openWhatsAppChat(phone);
                                                    },
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                
                                        SizedBox(height: 20),
                                
                                        Text('Title:${_getParticipantsTitles()}'),
                                        SizedBox(height: 20),
                                        Text(
                                          (eventData['reference_details'] !=
                                                      null &&
                                                  eventData['reference_details']
                                                      .isNotEmpty)
                                              ? 'Product Enquired:${eventData['reference_details'][0]['custom_product_enquired']}'
                                              : 'Product Enquired:null',
                                        ),
                                        SizedBox(height: 20),
                                
                                        Text(
                                          'Event Type:${eventData['event']['event_type']}',
                                        ),
                                        SizedBox(height: 20),
                                
                                        Text(
                                          'Subject:${eventData['event']['subject']}',
                                        ),
                                        SizedBox(height: 20),
                                
                                        Text(
                                          'Owner:${eventData['event']['owner']}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
