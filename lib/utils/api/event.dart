import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Event {
  static String? token;

  static late SharedPreferences prefs;
  static final URL = dotenv.env['URL'];

  static Future<List<dynamic>> eventList(String usr) async {
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

  static eventdetails(String id) async {
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

  static Future<List<dynamic>> office_type_list(String usr) async {
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

  static Future<List<dynamic>> head_office_list() async {
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

  static Head_office_details(String office) async {
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
  ) async {
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
  ) async {
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
        'Authorization': token ?? '', // if required
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
  ) async {
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
    print(response.body);
    return json.decode(response.body);
  }
}
