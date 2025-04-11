import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginApi {
  static late SharedPreferences prefs;
  static final emploginapiURL = dotenv.env['URL'];

  static Future<Map<String, dynamic>> login(String usr, String pwd) async {
  final prefs = await SharedPreferences.getInstance();
  try {
    var response = await http.get(Uri.parse('$emploginapiURL.login?usr=$usr&pwd=$pwd'));
    var data = json.decode(response.body);

    if (response.statusCode == 401) {
      return {'error': 'Incorrect Username or Password'};
    }

    if (response.statusCode == 403) {
      return {'error': data['message']['message'] ?? 'Access Denied'};
    }

    if (response.statusCode == 200 && data['message'] == "Logged In") {
      await prefs.setString('name', data['full_name']);
      await prefs.setString('email', data['email']);
      await prefs.setString('api_key', data['api_key']);
      await prefs.setString('api_secret', data['api_secret']);
      await prefs.setString('token', data['token']);

      return {
        'name': data['full_name'],
        'employee_id': data['employee_id'],
        'token': data['token'], // don't use [0] unless you're sure it's a list
      };
    } else {

      return {'error': data['message'] ?? 'Login failed'};
    }
  } catch (e) {
    return {'error': 'Exception: $e'};
  }
}
}
