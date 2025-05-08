import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Check{
  static final methodapiUrl = dotenv.env['URL'];
  static String? token;

  static checkin(id, lat, lng,String address,String type) async {

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    token = prefs.getString('token');
    try {
      var response = await http.get(
        Uri.parse('$methodapiUrl.checkin?user=$id&lat=$lat&lng=$lng&address=${Uri.encodeComponent(address)}&office_type=$type'),
        headers: {
          "Authorization": token ?? "",
        },
      );
      var data = json.decode(response.body);
      print(data);
      print("########");

      if (response.statusCode == 200) {
        return {
          "message": data['message'],
          "status": data['message'] == "Check-In Created Successfully"
              ? "Success"
              : "Error"
        };
      }
    } catch (e) {
      print(['error $e']);
    }
  }

  static checkout(id, lat, lng,String address,lastCheckoutAddress,distance,String type,List<Map<String, dynamic>> locationLogs) async {

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      token = prefs.getString('token');
      print(await prefs.getBool('with_event'));
      print(await prefs.getString('last_lat_lng'));
      final with_event = await prefs.getBool('with_event');
      final last_lat_lng = await prefs.getString('last_lat_lng');

      var response = await http.get(
        Uri.parse('$methodapiUrl.checkout?user=$id&lat=$lat&lng=$lng&address=${Uri.encodeComponent(address)}&lastCheckoutAddress=$lastCheckoutAddress&distance=$distance&office_type=$type&"location_logs": locationLogs&with_event=$with_event&last_lat_lng=$last_lat_lng'),
        headers: {
          "Authorization": token ?? "",
        },
      );
      final data = json.decode(response.body);
      String message = data['message'].toString();
    String status = "Success"; // default

    if (response.statusCode == 403) {
      status = "Warning"; // permission-related or validation issue
    } else if (response.statusCode == 400 || response.statusCode == 500) {
      status = "Error"; // bad request or server error
    } else if (message.contains("Already checked out")) {
      status = "Warning";
    } else if (message.contains("CheckIn Already Exists")) {
      status = "Warning";
    }

    return {
      "message": message,
      "status": status,
    };
  } catch (e) {
    print(['error $e']);
    return {
      "message": "Something went wrong: $e",
      "status": "Error"
    };
  }
  }

  static check_in_status(user) async {

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      token = prefs.getString('token');
      var response = await http.get(
        Uri.parse('$methodapiUrl.checkin_status?user=$user'),
        headers: {
          "Authorization": token ?? "",
        },
      );
      var data = json.decode(response.body);

      if (response.statusCode == 200) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        // prefs.setString("outtime", Utils.getTime());
        if(data['message']==true){
          return true;
        }
        else{
          return false;
        }

      }
    } catch (e) {
      print(['error $e']);
    }
  }

    static check_out_status(user) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      token = prefs.getString('token');
      var response = await http.get(
        Uri.parse('$methodapiUrl.checkout_status?user=$user'),
        headers: {
          "Authorization": token ?? "",
        },
      );
      var data = json.decode(response.body);

      if (response.statusCode == 200) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        // prefs.setString("outtime", Utils.getTime());
        if(data['message']==true){
          return true;
        }
        else{
          return false;
        }

      }
    } catch (e) {
      print(['error $e']);
    }
  }




}