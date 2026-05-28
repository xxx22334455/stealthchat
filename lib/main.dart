import 'package:flutter/material.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/chat_list_screen.dart';

void main() {
  runApp(const StealthChatApp());
}

class StealthChatApp extends StatelessWidget {
  const StealthChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StealthChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
