import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_database/firebase_database.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final MobileScannerController controller = MobileScannerController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  bool isProcessing = false;
  String statusMessage = "وجّه الكاميرا نحو كود QR";
  String lastScannedCode = "";

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty || isProcessing) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code == lastScannedCode) return;

    setState(() {
      isProcessing = true;
      lastScannedCode = code;
      statusMessage = "جاري البحث في بيانات الكشافة...";
    });

    try {
      // 1. البحث عن الكشاف في داتا الكشافة
      final memberSnapshot = await _dbRef.child("members").child(code).get();

      String memberName = code;
      if (memberSnapshot.exists && memberSnapshot.value != null) {
        final data = Map<String, dynamic>.from(memberSnapshot.value as Map);
        memberName = data['name'] ?? code;
      }

      // 2. تسجيل الحضور بتاريخ اليوم
      final String today = DateTime.now().toIso8601String().split('T')[0];
      final String timeNow = TimeOfDay.now().format(context);

      await _dbRef.child("attendance").child(today).child(code).set({
        "name": memberName,
        "time": timeNow,
        "timestamp": ServerValue.timestamp,
        "status": "حاضر"
      });

      // 3. عرض إشعار النجاح بالاسم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم تسجيل حضور: $memberName', style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          statusMessage = "تم التسجيل: $memberName";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم المسح: $code (تعذر الربط بالسيرفر)'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // انتظر ثانية ونصف قبل السماح بمسح الكود التالي
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Om ElNour Scouts - الحضور'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                );
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                return const Icon(Icons.cameraswitch);
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // إطار تحديد الـ QR
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isProcessing ? Colors.green : Colors.blue,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // شريط معلومات الحضور في الأسفل
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget buildDispose() {
    controller.dispose();
    super.dispose();
  }
}
