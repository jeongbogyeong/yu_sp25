import 'package:flutter/material.dart';

class CommonDialog {
  static void show(BuildContext context, {required String title, required String content, required bool isSuccess, Function()? onConfirmed}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: isSuccess ? Color(0xFF4CAF50) : Colors.red)),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (onConfirmed != null) {
                onConfirmed();
              }
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }
}