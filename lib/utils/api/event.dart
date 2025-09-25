import 'dart:convert';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:homegenie/utils/api/check_in_out.dart';
import 'package:homegenie/utils/widget/warning.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Event {
  static String? token;

  static late SharedPreferences prefs;
  static final URL = dotenv.env['URL'];

  static Future<List<dynamic>> eventList(String usr) async {
   final pingResult = await Check.pingpong();

    if (pingResult == null || pingResult['message'] != 'pong') {
      return [{
        "message": "ERP Site is not in working condition! Please try again later.",
        "status": "Error"
      }];
    }
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    try {
      var response = await http.get(
        Uri.parse('$URL.event_list?user=$usr'),
        headers: {
          "Authorization": token ?? "",
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['message'];
      } else {
        throw Exception("Failed to load events: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching events: $e");
    }
  }

static Future<bool> checkIfOtpRequired(String eventId, BuildContext context) async {
 final pingResult = await Check.pingpong();  
  if (pingResult == false) {
    Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    return false; 
  }

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    try {
      var response = await http.get(
        Uri.parse('$URL.is_otp_required?event_id=$eventId'),
        headers: {
          "Authorization": token ?? "",
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['message'] == true;
      } else {
        throw Exception("Failed to check OTP requirement: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error checking OTP requirement: $e");
    }
}

static Future<List<dynamic>> HistoryList(String usr, String fromDate, String toDate, BuildContext context) async {
 final pingResult = await Check.pingpong();  
  if (pingResult == false) {
    Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    return [];
  }
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  if (token == null || token.isEmpty) {
    throw Exception("Authorization token missing.");
  }

  try {
    final url = Uri.parse(
      '$URL.history_list?user=$usr&from_date=$fromDate&to_date=$toDate',
    );

    final response = await http.get(
      url,
      headers: {
        "Authorization": token,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('exc') && data['exc'] != null) {
        throw Exception("Frappe Error: ${data['exc']}");
      }
      return data['message'];
    } else {
      throw Exception("Failed to load History: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error fetching events: $e");
  }
}


  static eventdetails(String id, BuildContext context) async {
    final pingResult = await Check.pingpong();  
  if (pingResult == false) {
    Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    return [];
  }

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    try {
      var response = await http.get(
        Uri.parse('$URL.event_details?id=$id'),
        headers: {
          "Authorization": token ?? "",
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['message'];
      } else {
        throw Exception("Failed to load events: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching events: $e");
    }
  }

  static Future<List<dynamic>> office_type_list(String usr, BuildContext context) async {
 final pingResult = await Check.pingpong();  
  if (pingResult == false) {
    Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    return [];
  }
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    try {
      var response = await http.get(
        Uri.parse('$URL.officetype?user=$usr'),
        headers: {
          "Authorization": token ?? "",
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['message'];
      } else {
        throw Exception("Failed to load events: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching events: $e");
    }
  }

  static Future<List<dynamic>> head_office_list(BuildContext context) async {
 final pingResult = await Check.pingpong();  
  if (pingResult == false) {
    Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    return [];
  }
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    try {
      var response = await http.get(
        Uri.parse('$URL.head_office_list'),
        headers: {
          "Authorization": token ?? "",
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['message'];
      } else {
        throw Exception("Failed to load events: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching events: $e");
    }
  }

  static Head_office_details(String office, BuildContext context) async {
 final pingResult = await Check.pingpong();  
  if (pingResult == false) {
    Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    return [];
  }
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    try {
      var response = await http.get(
        Uri.parse('$URL.head_office_details?head_office=$office'),
        headers: {
          "Authorization": token ?? "",
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['message'];
      } else {
        throw Exception("Failed to load events: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching events: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchEventListByDate(
    String user,
    String date,
    BuildContext context,
  ) async { 
final pingResult = await Check.pingpong();  
  if (pingResult == false) {
    Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    return []; 
  }
    final prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$URL.event_list_date'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': token ?? '', // 🔐 replace with real credentials
      },
      body: jsonEncode({"user": user, "date": date}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['message'] is List) {
        return List<Map<String, dynamic>>.from(data['message']);
      } else {
        throw Exception("Unexpected response format");
      }
    } else {
      throw Exception("Failed to fetch event list: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> eventCheckin(
  String? user,
  String eventId,
  double lat,
  double lng,
  String address,
  BuildContext context,
) async {
  
  final pingResult = await Check.pingpong();  
  if (pingResult == false) {
    Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    return {}; 
  }

  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');
  
  final response = await http.post(
    Uri.parse('$URL.event_checkin'),
    body: {
      'user': user,
      'event_id': eventId,
      'lat': lat.toString(),
      'lng': lng.toString(),
      'address': address,
    },
    headers: {
      'Authorization': token ?? '', 
    },
  );

  return json.decode(response.body);
}

  static Future<Map<String, dynamic>> eventCheckout(
    String? user,
    String eventId,
    double lat,
    double lng,
    String address,
    String working_hrs,
    String distance,
    String last_lat_lng,
    String locationLogs,
    BuildContext context
  ) async {

final pingResult = await Check.pingpong();  
  if (pingResult == false) {
    Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    return {}; 
  }
    final prefs = await SharedPreferences.getInstance();


    final String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$URL.event_checkout'),
      body: {
        'user': user,
        'event_id': eventId,
        'lat': lat.toString(),
        'lng': lng.toString(),
        'address': address,
        'working_hrs': working_hrs,
        'distance': distance,
        'last_lat_lng': last_lat_lng,
        "location_logs": locationLogs,
      },
      headers: {'Authorization': token ?? ''},
    );

    return json.decode(response.body);
  }

  static Future<void> sendOtp(event_id, BuildContext context) async {

  final pingResult = await Check.pingpong();  
  if (pingResult == false) {
    Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    return;
  }
    
    final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
    Uri.parse('$URL.send_otp?event_id=$event_id'),
    headers: {
      'Authorization': token!,
    },
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to send OTP");
  }
  }

  static Future<bool> verifyOtp(String otp, String eventId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null || token.isEmpty) return false;

  try {
    final response = await http.post(
      Uri.parse('$URL.verify_otp'),
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'otp': otp,
        'event_id': eventId,
      }),
    );
    

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message']['status'] == 'success';
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}



}
