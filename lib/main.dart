import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Screen/splash.dart';
import 'package:connection_notifier/connection_notifier.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:overlay_support/overlay_support.dart';

Future<void> main() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.blueAccent
  ));

  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const OverlaySupport.global(child: Myapp()));
}

class Myapp extends StatefulWidget {
  const Myapp({super.key});

  @override
  State<Myapp> createState() => _MyappState();
}

class _MyappState extends State<Myapp> {
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();

    // connectSocket("prabhu@gmail.com");
  }

  void connectSocket(String userId) {
    socket = IO.io(dotenv.env['FRAPPE_SOCKET_URL'], <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'user': userId},
    });

    socket.connect();

    socket.onConnect((_) {
      print("✅ Socket connected");
    });

    socket.on("new_notification", (data) {
      String message = data['msg'];
      showCustomNotification(message);
    });

    socket.onDisconnect((_) {
      print("❌ Socket disconnected");
    });

    socket.onConnectError((err) {
      print("⚠️ Connect Error: $err");
    });
  }

  void showCustomNotification(String message) {
    showSimpleNotification(
      Text("📩 New Message"),
      subtitle: Text(message),
      background: Colors.green[600],
      duration: Duration(seconds: 4),
      slideDismiss: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionNotifier(
      connectionNotificationOptions: ConnectionNotificationOptions(
        alignment: Alignment.bottomCenter,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,

          textTheme: GoogleFonts.poppinsTextTheme(),

          appBarTheme: AppBarTheme(
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            backgroundColor: Colors.transparent,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.normal,
              color: Colors.white,
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              textStyle: GoogleFonts.poppins(fontSize: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: Splash(),
      ),
    );
  }
}
