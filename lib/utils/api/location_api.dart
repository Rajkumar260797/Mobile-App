import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationHelper {
  static const String _googleApiKey = 'AIzaSyCEkjoOnXRf6c9Xzml2QPNvZoq2LuG06JI'; // Replace this with your actual key

  static Future<String> getAddressFromCoordinates(double lat, double lon) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lon&key=$_googleApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        } else {
          return "No address found";
        }
      } else {
        return "Error fetching address";
      }
    } catch (e) {
      print("Google API exception: $e");
      return "Error getting address";
    }
  }
}
