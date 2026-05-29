import 'package:flutter/material.dart';
import 'ui/screens/login_screen.dart';
import 'ui/theme/telegram_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StealthChatApp());
}

class StealthChatApp extends StatelessWidget {
  const StealthChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StealthChat',
      debugShowCheckedModeBanner: false,
      theme: TelegramTheme.lightTheme,
      darkTheme: TelegramTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
    );
  }
}
