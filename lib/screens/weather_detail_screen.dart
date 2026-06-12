import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../repositories/weather_repository.dart';
import '../models/weather.dart';

class WeatherDetailScreen extends StatefulWidget {
  final String cityId;
  const WeatherDetailScreen({super.key, required this.cityId});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  final WeatherRepository _repository = WeatherRepository();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final box = Hive.box("weather_box");
    final city = Weather.fromMap(box.get(widget.cityId));

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _repository.fetchDetailsForCity(city);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Szczegóły pogody")),
      body: ValueListenableBuilder(
        valueListenable: Hive.box("weather_box").listenable(),
        builder: (context, Box box, _) {
          final city = Weather.fromMap(box.get(widget.cityId));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Temperatura: ${city.temp ?? "--"}°C', style: const TextStyle(fontSize: 24)),
                const Divider(),

                Text('Prędkość wiatru: ${city.windSpeed ?? "--"} km/h', style: const TextStyle(fontSize: 18)),
                Text('Wilgotność: ${city.humidity ?? "--"}%', style: const TextStyle(fontSize: 18)),

                const SizedBox(height: 20),
                if (_isLoading) const Center(child: CircularProgressIndicator()),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ElevatedButton(onPressed: _loadDetails, child: const Text("Spróbuj ponownie"))
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}