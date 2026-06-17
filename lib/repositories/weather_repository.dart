import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/weather.dart';

class WeatherRepository {
  final Box _box = Hive.box("weather_box");

  List<Weather> getLocalCities() {
    return _box.values.map((e) => Weather.fromMap(e)).toList();
  }

  Future<void> fetchCurrentWeatherForList() async {
    final cities = getLocalCities();
    if (cities.isEmpty) return;

    final lats = cities.map((c) => c.lat).join(',');
    final lons = cities.map((c) => c.lon).join(',');

    final url = 'https://api.open-meteo.com/v1/forecast?latitude=$lats&longitude=$lons&current_weather=true';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);

        for (int i = 0; i < cities.length; i++) {
          final city = cities[i];

          final cityData = results[i];
          final currentData = cityData['current_weather'];

          city.temp = (currentData['temperature'] as num).toDouble();

          await _box.put(city.id, city.toMap());
        }
      } else {
        throw Exception("Błąd serwera: ${response.statusCode}");
      }
    } catch (e) {
      print("Log błędu: $e");
      throw Exception("Brak połączenia z siecią - wyświetlane są archiwalne dane!");
    }
  }

  Future<void> fetchDetailsForCity(Weather city) async {
    final url = 'https://api.open-meteo.com/v1/forecast?latitude=${city.lat}&longitude=${city.lon}&hourly=relative_humidity_2m&current_weather=true';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> cityData = jsonDecode(response.body);

        final currentData = cityData['current_weather'];
        final hourlyData = cityData['hourly'];

        city.temp = (currentData['temperature'] as num).toDouble();
        city.windSpeed = (currentData['windspeed'] as num).toDouble();

        if (hourlyData != null && hourlyData['relative_humidity_2m'] is List) {
          final List<dynamic> humidities = hourlyData['relative_humidity_2m'];
          if (humidities.isNotEmpty) {
            city.humidity = (humidities.first as num).toInt();
          }
        }

        await _box.put(city.id, city.toMap());
      } else {
        throw Exception("Błąd serwera: ${response.statusCode}");
      }
    } catch (e) {
      print("Log błędu: $e");
      throw Exception("Brak połączenia z siecią - wyświetlane są archiwalne dane!");
    }
  }

  Future<void> addCity(String cityName) async {
    final url = 'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(cityName)}&count=1&language=pl';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final cityData = data['results'][0];

          final String id = '${cityName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

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
      print("Log błędu: $e");
      rethrow;
    }
  }

  Future<void> deleteCity(String cityId) async {
    try {
      await _box.delete(cityId);
    } catch (e) {
      print("Log błędu: $e");
      throw Exception("Nie udało się usunąć miasta!");
    }
  }
}