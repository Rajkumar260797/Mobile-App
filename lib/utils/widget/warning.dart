import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

class Warning extends StatelessWidget {
  final String message;

  const Warning(context, {Key? key, required this.message, required type})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink(); // Return an empty widget
  }

  static show(BuildContext context, String message, String type) {
    Flushbar(
            borderRadius: BorderRadius.circular(5),
            duration: Duration(seconds: 5),
            margin: EdgeInsets.all(15),
            flushbarPosition: FlushbarPosition.TOP,
            message: message,
            backgroundColor: type == "Warning"
                ? Colors.orange
                : type == "Error"
                    ? Colors.red
                    : type == "Success"
                        ? Colors.green
                        : Colors.blue,
            icon: (type == "Warning" || type == 'Error')
                ? const Icon(
                    Icons.warning,
                    color: Colors.white,
                  )
                : const Icon(
                    Icons.done,
                    color: Colors.white,
                  ))
        .show(context);
  }
}
