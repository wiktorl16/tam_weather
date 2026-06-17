import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:tam_weather/screens/weather_list_screen.dart';
import '../models/weather.dart';
import 'dart:io';

// Klasa nadpisująca domyślne ustawienia sieciowe w aplikacji, ze względu na błąd/brak certyfikatu SSL.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();

  // Inicjalizacja bazy Hive.
  await Hive.initFlutter();

  // Tworzymy kontener w bazie o nazwie "weather_box".
  await Hive.openBox("weather_box");

  final box = Hive.box("weather_box");

  // Sprawdzamy, czy baza danych jest pusta.
  if (box.isEmpty) {
    var warszawa = Weather(
      id: 'war',
      name: 'Warszawa',
      lat: 52.2298,
      lon: 21.0118,
    );
    var krakow = Weather(id: 'krk', name: 'Kraków', lat: 50.0614, lon: 19.9366);

    await box.put(warszawa.id, warszawa.toMap());
    await box.put(krakow.id, krakow.toMap());
  }

  runApp(const MyApp());
}

// Główny widżet aplikacji.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAM - Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Wskazujemy, który ekran ma się wyświetlić jako pierwszy po włączeniu aplikacji.
      home: const WeatherListScreen(),
    );
  }
}
