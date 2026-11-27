// SCANNER entrypoint (Samsung Galaxy A15): opens the real camera
// (QrScannerPage) and scans the QR shown by the initiator device running
// acquaintance_e2e_initiator_test.dart. The role is baked into the source,
// NOT a dart-define: parallel `flutter test` processes share one kernel
// cache, so a dart-define role would leak into both runs (see
// acquaintance_e2e_body.dart header).
import 'acquaintance_e2e_body.dart';

void main() {
  runAcquaintanceE2e('scanner');
}
