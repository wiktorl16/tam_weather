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

  String _getWindDirectionText(int? degrees) {
    if (degrees == null) return "--";
    if (degrees >= 338 || degrees < 23) return "Północny (N)";
    if (degrees >= 23 && degrees < 68) return "Północno-Wschodni (NE)";
    if (degrees >= 68 && degrees < 113) return "Wschodni (E)";
    if (degrees >= 113 && degrees < 158) return "Południowo-Wschodni (SE)";
    if (degrees >= 158 && degrees < 203) return "Południowy (S)";
    if (degrees >= 203 && degrees < 248) return "Południowo-Zachodni (SW)";
    if (degrees >= 248 && degrees < 293) return "Zachodni (W)";
    return "Północno-Zachodni (NW)";
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
                Row(
                  children: [
                    Icon(Icons.location_city, size: 40, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(city.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),

                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Temperatura:', style: TextStyle(fontSize: 20)),
                        Text('${city.temp ?? "--"}°C', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Szczegółowe parametry:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.air, color: Colors.blue),
                  title: const Text('Prędkość wiatru'),
                  trailing: Text('${city.windSpeed ?? "--"} km/h', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                ListTile(
                  leading: const Icon(Icons.explore, color: Colors.orange),
                  title: const Text('Kierunek wiatru'),
                  trailing: Text(_getWindDirectionText(city.windDirection), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                ListTile(
                  leading: const Icon(Icons.water_drop, color: Colors.teal),
                  title: const Text('Wilgotność powietrza'),
                  trailing: Text('${city.humidity ?? "--"}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                ListTile(
                  leading: const Icon(Icons.speed, color: Colors.purple),
                  title: const Text('Ciśnienie atmosferyczne'),
                  trailing: Text('${city.pressure ?? "--"} hPa', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),

                const SizedBox(height: 20),
                if (_isLoading) const Center(child: CircularProgressIndicator()),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
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