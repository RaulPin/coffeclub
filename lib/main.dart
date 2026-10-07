import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/firebase/seed.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase si usamos datos reales (cafés/menús/pedidos) o backend
  // completo. Requiere lib/firebase_options.dart (flutterfire configure).
  if (AppConfig.dataFromFirestore) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Siembra la base en desarrollo si está vacía.
    if (AppConfig.useFirestoreData) {
      try {
        await seedFirestoreIfEmpty();
      } catch (e) {
        debugPrint('Seed de Firestore omitido: $e');
      }
    }
  }

  if (!AppConfig.useMockBackend) {
    // Stripe: la publishable key es pública; la secret key vive solo en el
    // servidor (Cloud Functions).
    Stripe.publishableKey = AppConfig.stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  runApp(const ProviderScope(child: CoffeClubApp()));
}
