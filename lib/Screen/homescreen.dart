import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;
import 'event_list.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:homegenie/Screen/login.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:homegenie/Screen/history_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
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
  double _distance = 0.0;
  String _version = 'Production';
  List eventData = [];
  List<String> officeTypes = [];

  Position? _position;
  Timer? _distanceTimer;
  OverlayEntry? _overlayEntry;
  late SharedPreferences prefs;

  bool _isLoading = false;
  bool _checkedIn = false;
  bool _checkedOut = false;
  bool _isActionLoading = false;
  bool _prefsInitialized = false;

  TextEditingController _timeController = TextEditingController();
  TextEditingController _locationcontroller = TextEditingController();

  String location = "Press the button to get location";

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
      final micStatus = await Permission.microphone.request();
      final storageStatus = await Permission.storage.request();

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
    _checkPing();
  }

  Future<void> _checkPing() async {
    try {
          var connectivity = await Connectivity().checkConnectivity();

    bool noInternet = false;

    if (connectivity == ConnectivityResult.none) {
      noInternet = true;
    }

    if (connectivity is List && connectivity.contains(ConnectivityResult.none)) {
      noInternet = true;
    }
    if (noInternet) {
      Warning.show(
        context,
        'No Internet Connection! Please check your network.',
        'Error',
      );
      return;
    }

      var pingResult = await Check.pingpong();
      if (pingResult == false) {
        Warning.show(
          context,
          'ERP Site is not in working condition! Please try again later.',
          'Error',
        );
      } else {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token') ?? "";
        final email = prefs.getString('email') ?? "";

        final sessionValid = await Check.sessionActive(token, email);

        if (!sessionValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Session expired. Please log in again."),
              backgroundColor: Colors.red,
            ),
          );
          await prefs.clear();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const Login()),
            (route) => false,
          );
          return;
        }

        _init();
      }
    } catch (e) {
      print('Error during ping: $e');
    }
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
    });

    try {
      prefs = await SharedPreferences.getInstance();
      _prefsInitialized = true;
      await Future.wait([
        _setCurrentTime(),
        _getCurrentLocation(),
        _fetchEventList(),
        _fetchOfficeType(),
        _getStatusFromServer(),
        _loadVersion(),
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

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  bool isAfterMidnight() {
    final now = DateTime.now();
    return now.hour == 0 && now.minute >= 1;
  }

  Future<void> _fetchData() async {

    bool ok = await _safeCheckPing();
  if (!ok) return;

    await Future.wait([
      _setCurrentTime(),
      _getCurrentLocation(),
      _fetchEventList(),
      _fetchOfficeType(),

      _getStatusFromServer(),

      _loadVersion(),
    ]);

    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _safeCheckPing() async {
  try {
    var connectivity = await Connectivity().checkConnectivity();

    final list = connectivity is List ? connectivity : [connectivity];

    if (list.contains(ConnectivityResult.none)) {
      Warning.show(context, 'No Internet Connection! Please check your network.', 'Error');
      return false;
    }

    var pingResult = await Check.pingpong();

    if (pingResult == false) {
      Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
      return false;
    }

    return true;

  } catch (e) {
    print("Ping error: $e");
    return false;
  }
}


  bool _previousDayPendingCheckout = false;
  Future<void> _getStatusFromServer() async {
    final email = prefs.getString('email');
    if (email == null) return;

    final response = await Check.getStatus(email);

    setState(() {
      _checkedIn = response["checked_in"] ?? false;
      _checkedOut = response["checked_out"] ?? false;
      _previousDayPendingCheckout =
          response["previous_checkout_pending"] ?? false;
    });
  }

  Future<void> _fetchOfficeType() async {
    var response = await Event.office_type_list(
      prefs.getString('email') ?? '',
      context,
    );
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
                Navigator.of(
                  alertContext,
                ).pop();
              },
            ),
            TextButton(
              child: Text("Logout", style: TextStyle(color: Colors.blueAccent)),
              onPressed: () async {
                    var connectivity = await Connectivity().checkConnectivity();

    bool noInternet = false;

    if (connectivity == ConnectivityResult.none) {
      noInternet = true;
    }

    if (connectivity is List && connectivity.contains(ConnectivityResult.none)) {
      noInternet = true;
    }

    if (noInternet) {
      Warning.show(
        context,
        'No Internet Connection! Please check your network.',
        'Error',
      );
      return;
    }
                var pingResult = await Check.pingpong();

                Navigator.of(
                  alertContext,
                ).pop();

                if (pingResult == false) {
                  Warning.show(
                    context,
                    'ERP Site is not in working condition! Please try again later.',
                    'Error',
                  );
                  return;
                } else {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.clear();

                  await Future.delayed(Duration(milliseconds: 300));

                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const Login()),
                      (route) => false,
                    );
                  }
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

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return Future.value(false);
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: Colors.blue),
          backgroundColor: Colors.blue,
          title: const Text('DashBoard', style: TextStyle(fontSize: 20)),
          centerTitle: false,
          leading: IconButton(
            icon: Icon(
              Icons.menu,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
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
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Version $_version',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
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
                                onPressed:
                                    (_checkedOut &&
                                            !_checkedIn &&
                                            !_previousDayPendingCheckout)
                                        ? null
                                        : () async {
                                          

                                          await Action_Bottom.show(
                                            context: context,
                                            title: 'Choose Location',
                                            options: officeTypes,
                                            isCheckedIn:
                                                _checkedIn ||
                                                _previousDayPendingCheckout,
                                            onTrackingStarted:
                                                _showDistanceOverlay,
                                            onTrackingStopped:
                                                _removeDistanceOverlay,
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
                                            onStatusUpdate: (
                                              bool isNowCheckedIn,
                                            ) {
                                              setState(() {
                                                if (_previousDayPendingCheckout) {
                                                  _previousDayPendingCheckout =
                                                      false;
                                                  _checkedIn = false;
                                                  _checkedOut = false;
                                                } else {
                                                  _checkedIn = isNowCheckedIn;
                                                  _checkedOut = !isNowCheckedIn;
                                                }
                                              });
                                            },
                                          );

                                          await _fetchData();

                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _previousDayPendingCheckout
                                          ? Colors.red
                                          : !_checkedIn
                                          ? Colors.blue
                                          : !_checkedOut
                                          ? Colors.red
                                          : Colors.grey,
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
      ),
    );
  }
}
