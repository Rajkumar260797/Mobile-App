// // // import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
// // // import 'package:flutter/material.dart';


// // // class MyApp extends StatelessWidget {
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return MaterialApp(
// // //       title: 'Adaptive action sheet Demo',
// // //       theme: ThemeData(
// // //         primarySwatch: Colors.blue,
// // //         visualDensity: VisualDensity.adaptivePlatformDensity,
// // //       ),
// // //       home: const MyHomePage(),
// // //     );
// // //   }
// // // }

// // // class MyHomePage extends StatefulWidget {
// // //   const MyHomePage({Key? key}) : super(key: key);

// // //   @override
// // //   _MyHomePageState createState() => _MyHomePageState();
// // // }

// // // class _MyHomePageState extends State<MyHomePage> {
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text('Adaptive action sheet example'),
// // //       ),
// // //       body: Center(
// // //         child: Column(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           children: [
// // //             ElevatedButton(
// // //               onPressed: () {
// // //                 showAdaptiveActionSheet(
// // //                   context: context,
// // //                   actions: <BottomSheetAction>[
// // //                     BottomSheetAction(
// // //                       title: const Text('Item 1'),
// // //                       onPressed: (_) {},
// // //                     ),
// // //                     BottomSheetAction(
// // //                       title: const Text('Item 2'),
// // //                       onPressed: (_) {},
// // //                     ),
// // //                     BottomSheetAction(
// // //                       title: const Text('Item 3'),
// // //                       onPressed: (_) {},
// // //                     ),
// // //                   ],
// // //                   cancelAction: CancelAction(title: const Text('Cancel')),
// // //                 );
// // //               },
// // //               child: const Text('Show action sheet'),
// // //             ),
// // //             ElevatedButton(
// // //               onPressed: () {
// // //                 Action_Bottom(context,'Choose Test',['hello','hai']);
// // //               },
// // //               child: const Text('Show action sheet with title'),
// // //             ),
// // //             ElevatedButton(
// // //               onPressed: () {
// // //                 showAdaptiveActionSheet(
// // //                   context: context,
// // //                   actions: <BottomSheetAction>[
// // //                     BottomSheetAction(
// // //                       title: const Text(
// // //                         'Add',
// // //                         style: TextStyle(
// // //                           fontSize: 18,
// // //                           fontWeight: FontWeight.w500,
// // //                         ),
// // //                       ),
// // //                       onPressed: (_) {},
// // //                       leading: const Icon(Icons.add, size: 25),
// // //                     ),
// // //                     BottomSheetAction(
// // //                       title: const Text(
// // //                         'Delete',
// // //                         style: TextStyle(
// // //                           fontSize: 18,
// // //                           fontWeight: FontWeight.w500,
// // //                           color: Colors.red,
// // //                         ),
// // //                       ),
// // //                       onPressed: (_) {},
// // //                       leading: const Icon(
// // //                         Icons.delete,
// // //                         size: 25,
// // //                         color: Colors.red,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                   cancelAction: CancelAction(title: const Text('Cancel')),
// // //                 );
// // //               },
// // //               child: const Text('Show action sheet with icons'),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   Future<dynamic> Action_Bottom(BuildContext context,String title, List<String> options) {
// // //     return showAdaptiveActionSheet(
// // //                 context: context,
// // //                 title: Row(
// // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                 children: [
// // //                   Text(title, style: const TextStyle(fontSize: 24,fontWeight: FontWeight.w500),),
// // //                   GestureDetector(
// // //                     onTap: () => Navigator.pop(context),
// // //                     child: const Icon(Icons.close,color: Colors.blueAccent),
// // //                   )
                  
// // //                 ]

// // //                 ),
// // //                 actions: options
// // //                 .map(
// // //                   (option) => BottomSheetAction(
// // //                     title: Row(
// // //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                       children: [
// // //                         Text(option),
// // //                         const Icon(Icons.chevron_right,color: Colors.blueAccent)
// // //                       ],
// // //                     ),
// // //                     onPressed: (_) {
// // //                       Action_Bottom_Secondary(context, option, ['hai1','hai2','hai3']);
// // //                     },
                    
// // //                   ),
                
// // //                   ) .toList(),

// // //               );
// // //   }

// // //   Future<dynamic> Action_Bottom_Secondary(BuildContext context,String title, List<String> options) {
// // //     return showAdaptiveActionSheet(
// // //                 context: context,
// // //                 title: Row(
// // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                 children: [
// // //                   Text(title, style: const TextStyle(fontSize: 24,fontWeight: FontWeight.w500),),
// // //                   GestureDetector(
// // //                     onTap: () => Navigator.pop(context),
// // //                     child: const Icon(Icons.close,color: Colors.blueAccent),
// // //                   )
                  
// // //                 ]

// // //                 ),
// // //                 actions: options
// // //                 .map(
// // //                   (option) => BottomSheetAction(
// // //                     title: Row(
// // //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                       children: [
// // //                         Text(option),
// // //                         const Icon(Icons.chevron_right,color: Colors.blueAccent)
// // //                       ],
// // //                     ),
// // //                     onPressed: (_) {},
                    
// // //                   ),
                
// // //                   ) .toList(),

// // //               );
// // //   }

// // // }


// // import 'package:flutter/material.dart';
// // import 'package:battery_plus/battery_plus.dart';
// // import 'package:connection_notifier/connection_notifier.dart';

// // class BatteryConnectivityCheckScreen extends StatefulWidget {
// //   @override
// //   _BatteryConnectivityCheckScreenState createState() =>
// //       _BatteryConnectivityCheckScreenState();
// // }

// // class _BatteryConnectivityCheckScreenState extends State<BatteryConnectivityCheckScreen> {
// //   final Battery _battery = Battery();
// //   int _batteryLevel = 100; // Default battery level

// //   @override
// //   void initState() {
// //     super.initState();
// //     _getBatteryLevel();
// //   }

// //   Future<void> _getBatteryLevel() async {
// //     final level = await _battery.batteryLevel;
// //     setState(() {
// //       _batteryLevel = level;
// //     });
// //   }

// //   void _performAction(bool isConnected) {
// //     if (_batteryLevel < 20) {
// //       // Restrict action if battery is below 20%
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Battery too low! Action not allowed.")),
// //       );
// //       return;
// //     }

// //     if (!isConnected) {
// //       // Restrict action if no internet connection
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("No internet connection! Action not allowed.")),
// //       );
// //       return;
// //     }

// //     // Perform your action here
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text("Action performed successfully!")),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return ConnectionNotifierToggler(
// //       onConnectionStatusChanged: (connected) {
// //         // Handle real-time connection status updates if needed
// //       },
// //       connected: Scaffold(
// //         appBar: AppBar(title: Text("Battery & Internet Check")),
// //         body: Center(
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               Text("Battery Level: $_batteryLevel%"),
// //               Text("Internet: Connected"),
// //               SizedBox(height: 20),
// //               ElevatedButton(
// //                 onPressed: () => _performAction(true),
// //                 child: Text("Perform Action"),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //       disconnected: Scaffold(
// //         appBar: AppBar(title: Text("Battery & Internet Check")),
// //         body: Center(
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               Text("Battery Level: $_batteryLevel%"),
// //               Text("Internet: Not Connected"),
// //               SizedBox(height: 20),
// //               ElevatedButton(
// //                 onPressed: null, // Disabled when no internet
// //                 child: Text("Perform Action (Offline)"),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
      
// //     );
// //   }
// // }


// import 'package:web_socket_channel/io.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class WebSocketService {
//   static final WebSocketService _instance = WebSocketService._internal();
//   factory WebSocketService() => _instance;
//   WebSocketService._internal();

//   late WebSocketChannel _channel;
//   Function(String)? onMessageReceived; // Callback function to update UI

//   void connect() {
//     _channel = IOWebSocketChannel.connect("wss://your-frappe-site/ws");

//     _channel.stream.listen((message) {
//       print("New Notification: $message");
//       if (onMessageReceived != null) {
//         onMessageReceived!(message);
//       }
//     }, onDone: () {
//       print("WebSocket Disconnected. Reconnecting...");
//       connect(); // Auto-reconnect
//     }, onError: (error) {
//       print("WebSocket Error: $error");
//     });
//   }

//   void sendMessage(String message) {
//     _channel.sink.add(message);
//   }

//   void closeConnection() {
//     _channel.sink.close();
//   }
// }

