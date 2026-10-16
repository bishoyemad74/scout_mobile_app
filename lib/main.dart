import 'package:flutter/material.dart';
import 'qr_scan_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScoutApp());
}

class ScoutApp extends StatelessWidget {
  const ScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Om ElNour Scouts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const QRScanPage(),
    );
  }
}
