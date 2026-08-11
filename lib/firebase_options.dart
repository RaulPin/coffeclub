// PLACEHOLDER — reemplaza este archivo ejecutando:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Ese comando genera este mismo archivo con la configuración real de tu
// proyecto Firebase para cada plataforma (Android, iOS, etc.). Mientras
// `AppConfig.useMockBackend` sea true, este placeholder nunca se usa.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase no está configurado. Ejecuta `flutterfire configure` para '
      'generar lib/firebase_options.dart, o mantén AppConfig.useMockBackend '
      'en true para usar el modo demo.',
    );
  }
}
