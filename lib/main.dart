import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'qr_scan_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة الفايربيس (يتم وضع إعدادات المشروع المجاني هنا)
  await Firebase.initializeApp();
  runApp(const ScoutApp());
}

class ScoutApp extends StatelessWidget {
  const ScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كشافة أم النور ⚜️',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''), // دعم كامل للغة العربية
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
        ),
        useMaterial3: true,
        fontFamily: 'Tajawal',
      ),
      home: const QRScanPage(),
    );
  }
}
