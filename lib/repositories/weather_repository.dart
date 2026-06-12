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
}