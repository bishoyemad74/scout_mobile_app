import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_database/firebase_database.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  String? scannedCode;
  String? memberName;
  String? memberTeam;
  bool isLoading = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // فحص كود العضو فور التقاطه تلقائياً
  void _onCodeDetected(BarcodeCapture capture) async {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!.trim();
      
      setState(() {
        isScanning = false; // إيقاف المسح مؤقتاً عند التقاط أول كود
        scannedCode = code;
        isLoading = true;
      });

      // إيقاف الكاميرا مؤقتاً
      await cameraController.stop();

      // البحث عن بيانات الكشاف في Firebase
      await _fetchMemberDetails(code);
    }
  }

  Future<void> _fetchMemberDetails(String code) async {
    try {
      final snapshot = await _dbRef.child('members/$code').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          memberName = data['name'] ?? 'كشاف معروف';
          memberTeam = data['team'] ?? 'الفريق الأول';
          isLoading = false;
        });
      } else {
        setState(() {
          memberName = 'عضو جديد (الكود: $code)';
          memberTeam = 'غير محدد';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        memberName = 'كشاف (الكود: $code)';
        memberTeam = 'غير محدد';
        isLoading = false;
      });
    }
  }

  // تسجيل الحضور بعد الضغط على زر التأكيد
  Future<void> _confirmAttendance() async {
    if (scannedCode == null) return;

    final String todayDate = DateTime.now().toString().split(' ')[0];
    final String timeNow = TimeOfDay.now().format(context);

    await _dbRef.child('drafts/team_1/$scannedCode').set({
      'code': scannedCode,
      'name': memberName,
      'team': memberTeam,
      'time': timeNow,
      'score': 10.0,
      'date': todayDate,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 تم تسجيل حضور الكشاف ($memberName) بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    _resetScanner();
  }

  // إعادة فتح الكاميرا لمسح كود جديد
  void _resetScanner() async {
    setState(() {
      isScanning = true;
      scannedCode = null;
      memberName = null;
      memberTeam = null;
      isLoading = false;
    });
    await cameraController.start();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كشافة أم النور ⚜️ - المسح التلقائي'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // منطقة الكاميرا الحية
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: _onCodeDetected,
                ),
                // إطار توجيه الـ QR
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isScanning ? Colors.green : Colors.yellow,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // منطقة النتيجة والتأكيد اليدوي
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : scannedCode == null
                      ? const Center(
                          child: Text(
                            '📷 وجه الكاميرا نحو كود الـ QR وسيتم التثبيت والتأكيد تلقائياً',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '👤 $memberName',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '🏷️ الفريق: $memberTeam | الكود: $scannedCode',
                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _confirmAttendance,
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('✅ تأكيد وتسجيل الحضور'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: _resetScanner,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  ),
                                  child: const Text('إلغاء'),
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
