import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homegenie/Screen/history_list.dart';
import 'package:homegenie/Screen/login.dart';
import 'event_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:geofence_service/geofence_service.dart' as geofence;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'test.dart';
import '../utils/widget/action_bottom.dart';
import '../utils/widget/event_list.dart';
import '../utils/widget/warning.dart';
import '../utils/api/check_in_out.dart';
import '../utils/api/event.dart';
import '../utils/api/location_api.dart';
import '../utils/widget/floating_widget.dart';
import '../utils/widget/location_tracker.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isTracking = false;
  double _distance = 0.0;
  OverlayEntry? _overlayEntry;
  List eventData = [];
  List<String> officeTypes = [];
  TextEditingController _timeController = TextEditingController();
  TextEditingController _locationcontroller = TextEditingController();
  late SharedPreferences prefs;
  bool _isLoading = false;
  bool _checkedIn = false;
  bool _checkedOut = false;
  bool _prefsInitialized = false;
  Timer? _distanceTimer;
  bool _isActionLoading = false;

  String location = "Press the button to get location";
  Position? _position;


  Future<void> _get_checkin_status() async {
    bool checkin = await Check.check_in_status(prefs.getString('email'));
    setState(() {
      _checkedIn = checkin;
    });
  }

  Future<void> _get_checkout_status() async {
    bool checkout = await Check.check_out_status(prefs.getString('email'));
    setState(() {
      _checkedOut = checkout;
    });
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

  void _showDistanceOverlay() {
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 0,
            right: 10,
            child: FloatingDistanceWidget(distance: _distance),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    _distanceTimer = Timer.periodic(Duration(seconds: 5), (_) {
      double dist = LocationTrackerService.calculateTotalDistance();
      setState(() {
        _distance = dist;
      });
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _removeDistanceOverlay() {
    _distanceTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _getCurrentLocation() async {
    bool hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    try {
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _getAddressFromLatLng(_position!.latitude, _position!.longitude);
    } catch (e) {
      setState(() {
        location = "Failed to get current location.";
      });
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lon) async {
    String result = await LocationHelper.getAddressFromCoordinates(lat, lon);

    setState(() {
      location = result;
      _locationcontroller.text = result;
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
    });

    try {
      prefs = await SharedPreferences.getInstance();
      _prefsInitialized = true;

      await Future.wait([
        _get_checkin_status(),
        _get_checkout_status(),
        _setCurrentTime(),
        _getCurrentLocation(),
        _fetchEventList(),
        _fetchOfficeType(),
        _getStatusFromServer(),

      ]);
    } catch (e) {
      print("Initialization error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool isAfterMidnight() {
    final now = DateTime.now();
    return now.hour == 0 && now.minute >= 1;
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _setCurrentTime(),
      _getCurrentLocation(),
      _fetchEventList(),
      _fetchOfficeType(),
      // _get_checkin_status(),
      // _get_checkout_status(),

        _getStatusFromServer(),
    ]);

    if (mounted) {
      setState(() {}); // just trigger rebuild
    }
    print(_checkedOut);
        print(!_checkedOut);
  }

  bool _previousDayPendingCheckout = false;
  Future<void> _getStatusFromServer() async {
  final email = prefs.getString('email');
  if (email == null) return;

  final response = await Check.getStatus(email); // Custom API call

  setState(() {
    _checkedIn = response["checked_in"] ?? false;
    _checkedOut = response["checked_out"] ?? false;
    _previousDayPendingCheckout = response["previous_checkout_pending"] ?? false;
  });
}


  Future<void> _fetchOfficeType() async {
    var response = await Event.office_type_list(prefs.getString('email') ?? '');
    if (response is List) {
      officeTypes = response.map((e) => e.toString()).toList();
    }
  }

  Future<void> _fetchEventList() async {
    var response = await Event.eventList(prefs.getString('email') ?? '');
    if (response is List) {
      eventData = response;
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return "";
    DateTime dt = DateTime.parse(dateTime);
    return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year.toString().substring(2)}";
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return "";
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

  Future<void> _setCurrentTime() async {
    String formattedTime = DateFormat('hh:mm a').format(DateTime.now());
    _timeController.text = formattedTime;
  }

  void _initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext alertContext) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Logout", style: TextStyle(color: Colors.blueAccent)),
              onPressed: () async {
                Navigator.of(alertContext).pop(); // Close dialog

                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                await Future.delayed(Duration(milliseconds: 300));

                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const Login()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List<Widget> getEventWidgets() {
      return eventData.expand<Widget>((event) {
        String initials =
            event['subject'] != null && event['name'].isNotEmpty
                ? event['name'][0]
                : '';
        String title = event['subject'] ?? "No Title";
        String eventType = event['event_type'] ?? '';
        String location = event['custom_location'] ?? '';
        String date = _formatDate(event['starts_on'] ?? '');
        String time = _formatTime(event['starts_on'] ?? '');
        String name = event['name'] ?? '';

        return [
          EventCard(
            name: name,
            initials: initials,
            title: title,
            eventType: eventType,
            location: location,
            date: date,
            time: time,
          ),
          SizedBox(height: 5),
        ];
      }).toList();
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.blueAccent,
        ),
        backgroundColor: Colors.blue,
        title: const Text('DashBoard', style: TextStyle(fontSize: 20)),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: 30), // Custom icon
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open drawer manually
          },
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Row(
                  children: [
                    Icon(Icons.account_circle, color: Colors.white, size: 50),
                    SizedBox(width: 10),
                    Text(
                      prefs.getString('name') ?? '',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.blueAccent),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.event, color: Colors.blueAccent),
              title: Text('Events'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.blueAccent),
              title: Text('History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryList()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.blueAccent),
              title: Text('Logout'),
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  await _fetchData();
                },
                color: Colors.blueAccent,
                child: ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(color: Colors.blue),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_circle,
                            color: Colors.white,
                            size: 70,
                          ),

                          SizedBox(width: 10),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Hello,',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                prefs.getString('name') ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10),

                    Container(
                      padding: EdgeInsets.all(12.0),
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Colors.blueAccent,
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(3, 5),
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Lets Go To Work",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _timeController.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 10),

                          Row(
                            children: [
                              Icon(Icons.location_pin, color: Colors.blue),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _locationcontroller.text,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:  (_checkedOut && !_checkedIn && !_previousDayPendingCheckout)
    ? null
    : () async {
        // setState(() {
        //   _isActionLoading = true;
        // });

        await Action_Bottom.show(
          context: context,
          title: 'Choose Location',
          options: officeTypes,
          isCheckedIn: _checkedIn || _previousDayPendingCheckout, // treat as IN
          onTrackingStarted: _showDistanceOverlay,
          onTrackingStopped: _removeDistanceOverlay,
          onApiStart: () {
    setState(() {
      _isActionLoading = true;
    });
  },
  onApiEnd: () async {
    await _fetchData();
    setState(() {
      _isActionLoading = false;
    });
  },
          onStatusUpdate: (bool isNowCheckedIn) {
            setState(() {
              // If we just checked out previous day
              if (_previousDayPendingCheckout) {
                _previousDayPendingCheckout = false;
                _checkedIn = false;
                _checkedOut = false;
              } else {
                _checkedIn = isNowCheckedIn;
                _checkedOut = !isNowCheckedIn;
              }
            });
          },
        );

        // await Future.delayed(Duration(seconds: 5));
        await _fetchData();

        // setState(() {
        //   _isActionLoading = false;
        // });

        
      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _previousDayPendingCheckout
                                        ? Colors.red
                                        : !_checkedIn
                                          ? Colors.blue
                                          : !_checkedOut
                                            ? Colors.red
                                              : Colors.grey

                                        
                              ),
                              child:
                                  _isActionLoading
                                      ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
  _previousDayPendingCheckout
      ? "Check Out (Previous Day)"
      : !_checkedIn
          ? "Check In"
          : !_checkedOut
              ? "Check Out"
              : "Completed",

              
  style: TextStyle(color: Colors.white),
),

                            ),
                          ),
                        ],
                      ),
                    ),

                    // SizedBox(height: 10),
                    // Padding(padding: EdgeInsets.all(10),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: [
                    //       Text("Today Mettings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    //       ElevatedButton(onPressed: (){}, child:
                    //       Text("See all", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.grey)),
                    //       style: ElevatedButton.styleFrom(backgroundColor: Colors.white,padding:EdgeInsets.all(1)),
                    //       )
                    //     ]
                    //   ),
                    // ),

                    // Container(
                    //   padding: EdgeInsets.all(12.0),
                    //   margin: EdgeInsets.symmetric(horizontal: 10),
                    //   decoration: BoxDecoration(
                    //     color: Colors.blueAccent,
                    //     borderRadius: BorderRadius.circular(12.0),
                    //     border: Border.all(
                    //       color: Colors.white,
                    //       width: 0.5,
                    //     ),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.black.withOpacity(0.3),
                    //         blurRadius: 10,
                    //         spreadRadius: 2,
                    //         offset: Offset(3, 5),
                    //       ),
                    //     ],
                    //   ),
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       SizedBox(height: 10),
                    //       Row(
                    //         children: [
                    //           SizedBox(width: 10),
                    //           Expanded(
                    //             child: Text(
                    //               "No Mettings Today",
                    //               style: TextStyle(fontSize: 16,color: Colors.white),

                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Appointment",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventsPage(),
                                ),
                              );
                            },
                            child: Text(
                              "See all",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.all(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...getEventWidgets(),
                  ],
                ),
              ),
    );
  }
}
