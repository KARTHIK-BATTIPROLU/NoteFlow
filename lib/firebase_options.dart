import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'DefaultFirebaseOptions have not been configured for your application. '
      'Run `flutterfire configure` to configure Firebase.'
    );
  }
}
