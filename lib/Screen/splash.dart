import 'package:flutter/material.dart';
import 'package:homegenie/utils/api/check_in_out.dart';
import 'package:homegenie/utils/widget/warning.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'homescreen.dart';
import 'history_list.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  initState() {
    super.initState();
    _checkPing();
  }

  Future<void> _checkPing() async {
  try {
    var pingResult = await Check.pingpong(); 

    if (pingResult == false) {
      Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    } else {
    _redirect();
    }
  } catch (e) {
    print('Error during ping: $e');
  }
}


  void _redirect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    await Future.delayed(Duration(seconds: 3)); // Optional splash duration

    if (email != null && email.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Homescreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    }
  }

  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: height * 0.38),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 100,
                  width: 300,
                  child: Image.asset('assets/images/logo.png'),
                ),
              ),
            ),
            SizedBox(height: height * 0.35),
            // Text(
            //   "Thirvu Soft Pvt Ltd",
            //   style: TextStyle(
            //       color: Color.fromARGB(255, 0, 0, 0),
            //       fontSize: 15,
            //       fontWeight: FontWeight.bold),
            // ),
          ],
        ),
      ),
    );
  }
}
