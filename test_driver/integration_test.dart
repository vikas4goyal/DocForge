// Host side of `flutter drive` for integration tests that need to own the
// test binding, such as integration_test/store_assets/app_review_video_test.dart.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
