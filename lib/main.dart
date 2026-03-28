import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/pricing/pricing_engine.dart';
import 'data/repositories/trip_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (kDebugMode) {
    PricingEngine.inViDuRaConsole();
  }
  runApp(
    MultiProvider(
      providers: [
        Provider<TripRepository>(create: (_) => TripRepository()),
      ],
      child: const RideBookingApp(),
    ),
  );
}
