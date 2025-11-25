import 'package:connectivity_plus/connectivity_plus.dart';

import '../utils/api/login_api.dart';
import '../utils/widget/warning.dart';
import 'package:flutter/material.dart';
import 'package:homegenie/Screen/homescreen.dart';
import 'package:homegenie/utils/api/check_in_out.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

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
      Warning.show(context, 'ERP Site is not in working condition! Please try again later.', 'Error');
    } else {
      _emailFocusNode.addListener(() {
        setState(() {});
      });
    }
  } catch (e) {
    print('Error during ping: $e');
  }
}

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  login() async {
    setState(() {
      _isLoading = true;
    });
    _checkPing() ;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String email = _emailController.text.toString().trim();
    String passwordValue = _passwordController.text.toString().trim();

    bool isValidEmail(String email) {
      final RegExp emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      return emailRegex.hasMatch(email);
    }

    if (!isValidEmail(email)) {
      setState(() => _isLoading = false);
      Warning.show(context, 'Invalid Email Address!', "Warning");
      return;
    }

    if (passwordValue.isEmpty) {
      setState(() => _isLoading = false);
      Warning.show(context, 'Password cannot be empty.', "Warning");
      return;
    }

    try {
      Map<String, dynamic> user = await LoginApi.login(email, passwordValue);
      setState(() => _isLoading = false);
      if (user.containsKey('error')) {
        Warning.show(context, user['error'], "Warning");
        return;
      }
      Warning.show(context, 'Login Successful', "Success");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Homescreen()),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Warning.show(context, 'Login error. Please try again.', "Warning");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            title: Text("Login Failed"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK", style: TextStyle(color: Color(0xFFE75124))),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 150),
                      Image.asset(
                        'assets/images/loginlogo.jpeg',
                        width: 500,
                        height: 100,
                      ),
                      SizedBox(height: 30),
                      Text(
                        "Login to Continue Your Account",
                        style: TextStyle(
                          color: Color.fromARGB(255, 7, 7, 7),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      _BuildEmailField(),
                      SizedBox(height: 20),
                      _buildPasswordField(),
                      SizedBox(height: 30),
                      _buildLoginButton(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  TextFormField _BuildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
        labelText: 'Email Address',
        labelStyle: TextStyle(color: Colors.black),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),

      validator: (value) {
        if (value == null || value.isEmpty) {
          // return Warning.show(
          //     context, 'Please enter your mobile number', "Error");
        }
        // if (value.length != 10) {
        //   // return Warning.show(
        //   //     context, 'Please enter a valid 10-digit mobile number', "Error");
        // }
        return null;
      },
    );
  }

  TextFormField _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.black),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.blueAccent,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: () => login(),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blueAccent,
        ),
        alignment: Alignment.center,
        child: Text(
          "Login",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
