// INITIATOR entrypoint (AYya T1): shows the QR on screen at max brightness
// and polls the product accept path. The scanner device runs
// acquaintance_e2e_scanner_test.dart and reads this QR with its camera.
// The role is baked into the source, NOT a dart-define: parallel `flutter
// test` processes share one kernel cache, so a dart-define role would leak
// into both runs (see acquaintance_e2e_body.dart header).
import 'acquaintance_e2e_body.dart';

void main() {
  runAcquaintanceE2e('initiator');
}
