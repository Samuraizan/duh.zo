import 'package:flutter/material.dart';
import 'presentation/screens/device/device_connection_screen.dart';
import 'presentation/screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DuhZoApp());
}

class DuhZoApp extends StatelessWidget {
  const DuhZoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'duh.zo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/connect': (context) => DeviceConnectionScreen(),
      },
    );
  }
} 