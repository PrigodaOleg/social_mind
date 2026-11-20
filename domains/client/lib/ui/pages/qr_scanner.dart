// Полноэкранная страница сканирования QR-кода (mobile_scanner).
// Возвращает отсканированную строку через Navigator.pop(context, rawValue).
// Камера недоступна (нет разрешения/нет камеры): показываем подсказку
// вместо падения - страница остается тонкой оберткой над MobileScanner.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../ui.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  // autoStart: false - стартуем вручную с проглатыванием ошибки (в тестах и
  // на платформах без камеры start() бросает MissingPluginException).
  final _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.qrCode],
  );

  // Дебаунс: повторные обнаружения в течение секунды игнорируются.
  DateTime _lastDetection = DateTime.fromMillisecondsSinceEpoch(0);
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      await _controller.start();
    } catch (_) {
      // Ошибка стартует errorBuilder/подсказку через состояние контроллера.
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final now = DateTime.now();
    if (now.difference(_lastDetection) < const Duration(seconds: 1)) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      _lastDetection = now;
      if (_popped) return;
      _popped = true;
      Navigator.of(context).pop(raw);
      return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: t.colorScheme.inversePrimary,
        title: Text(l.qrScannerTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.qrScannerHint),
          ),
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l.qrScannerPermissionDenied,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.colorScheme.error),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
