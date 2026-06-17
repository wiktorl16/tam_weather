import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/weather.dart';

class WeatherRepository {
  // Pobieramy referencję do otwartego w main.dart kontenera Hive.
  final Box _box = Hive.box("weather_box");

  // Funkcja pobierająca listę wszystkich miast zapisanych lokalnie w bazie danych.
  List<Weather> getLocalCities() {
    return _box.values.map((e) => Weather.fromMap(e)).toList();
  }

  // Funkcja odpowiedzialna za pobranie aktualnej temperatury dla wszystkich miast na liście głównej.
  Future<void> fetchCurrentWeatherForList() async {
    final cities = getLocalCities();

    // Jeśli lista jest pusta – przerywamy działanie funkcji.
    if (cities.isEmpty) return;

    // Łączymy współrzędne wszystkich miast w jeden ciąg tekstowy oddzielony przecinkami.
    // Np. dla Warszawy i Krakowa 'lats' przyjmie postać: "52.2298,50.0614".
    final lats = cities.map((c) => c.lat).join(',');
    final lons = cities.map((c) => c.lon).join(',');

    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=$lats&longitude=$lons&current_weather=true';

    try {
      final response = await http.get(Uri.parse(url));

      // Sprawdzamy, czy serwer odpowiedział poprawnie (kod 200 oznacza sukces).
      if (response.statusCode == 200) {
        // API Open-Meteo zwraca nam Listę (Array).
        final List<dynamic> results = jsonDecode(response.body);

        for (int i = 0; i < cities.length; i++) {
          final city = cities[i];

          // API zwraca wyniki w dokładnie takiej samej kolejności, w jakiej wysłaliśmy współrzędne.
          final cityData = results[i];
          final currentData = cityData['current_weather'];

          // Wyciągamy temperaturę i rzutujemy ją na typ double.
          city.temp = (currentData['temperature'] as num).toDouble();

          await _box.put(city.id, city.toMap());
        }
      } else {
        throw Exception("Błąd serwera: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception(
        "Brak połączenia z siecią - wyświetlane są archiwalne dane!",
      );
    }
  }

  // Funkcja pobiera komplet szczegółowych danych (wiatr, wilgotność, ciśnienie) dla jednego konkretnego miasta.
  Future<void> fetchDetailsForCity(Weather city) async {
    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=${city.lat}&longitude=${city.lon}&current=temperature_2m,wind_speed_10m,wind_direction_10m,surface_pressure&hourly=relative_humidity_2m';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Serwer dla pojedynczego zapytania zwraca Mapę {} (obiekt), a nie listę [].
        final Map<String, dynamic> cityData = jsonDecode(response.body);

        final currentData = cityData['current'];
        final hourlyData = cityData['hourly'];

        // Jeśli currentData nie jest null, przypisujemy wartości.
        if (currentData != null) {
          city.temp = (currentData['temperature_2m'] as num?)?.toDouble();
          city.windSpeed = (currentData['wind_speed_10m'] as num?)?.toDouble();
          city.pressure = (currentData['surface_pressure'] as num?)?.toDouble();
          city.windDirection = (currentData['wind_direction_10m'] as num?)
              ?.toInt();
        }

        final humidities = hourlyData?['relative_humidity_2m'];
        if (humidities is List && humidities.isNotEmpty) {
          city.humidity = (humidities.first as num?)?.toInt();
        }

        await _box.put(city.id, city.toMap());
      } else {
        throw Exception("Błąd serwera: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception(
        "Brak połączenia z siecią - wyświetlane są archiwalne dane!",
      );
    }
  }

  // Funkcja odpowiedzialna za dodawanie nowego miasta.
  Future<void> addCity(String cityName) async {
    // Walidacja duplikatów: pobieramy zapisane miasta z bazy.
    final existingCities = getLocalCities();

    // Sprawdzamy metodą .any(), czy w bazie jest już miasto o identycznej nazwie (ignorując wielkość liter i spacje).
    final alreadyExists = existingCities.any(
      (city) => city.name.toLowerCase().trim() == cityName.toLowerCase().trim(),
    );

    // Jeśli miasto już istnieje na liście, przerywamy działanie i zgłaszamy błąd.
    if (alreadyExists) {
      throw Exception("To miasto znajduje się już na Twojej liście!");
    }

    // Zapytanie do API Geolokalizacji: zamieniamy nazwę tekstową miasta na współrzędne geograficzne.
    // Uri.encodeComponent pilnuje poprawnego kodowania znaków specjalnych i spacji w adresie URL.
    final url =
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(cityName)}&count=1&language=pl';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Sprawdzamy, czy tablica 'results' istnieje i nie jest pusta (czy znaleziono takie miejsce na świecie).
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final cityData = data['results'][0];

          // Generujemy unikalny identyfikator na podstawie nazwy oraz aktualnego znacznika czasu w milisekundach.
          final String id =
              '${cityName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

          final newCity = Weather(
            id: id,
            name: cityData['name'],
            lat: (cityData['latitude'] as num).toDouble(),
            lon: (cityData['longitude'] as num).toDouble(),
          );

          await _box.put(newCity.id, newCity.toMap());
        } else {
          throw Exception("Nie znaleziono miasta o podanej nazwie!");
        }
      } else {
        throw Exception("Błąd serwera: ${response.statusCode}");
      }
    } catch (e) {
      // 'rethrow' przekazuje złapany błąd do interfejsu użytkownika (UI),
      // aby okno dialogowe w widoku mogło go przechwycić i wyświetlić komunikat na ekranie.
      rethrow;
    }
  }

  // Metoda usuwająca miasto z bazy lokalnej na podstawie jego unikalnego identyfikatora ID.
  Future<void> deleteCity(String cityId) async {
    try {
      await _box.delete(cityId);
    } catch (e) {
      throw Exception("Nie udało się usunąć miasta!");
    }
  }
}
