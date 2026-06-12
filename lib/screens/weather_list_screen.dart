import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../repositories/weather_repository.dart';

class WeatherListScreen extends StatefulWidget {
  const WeatherListScreen({super.key});

  @override
  State<WeatherListScreen> createState() => _WeatherListScreenState();
}

class _WeatherListScreenState extends State<WeatherListScreen> {
  final WeatherRepository _repository = WeatherRepository();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _repository.fetchCurrentWeatherForList();
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
      appBar: AppBar(
        title: const Text('TAM - Weather'),
        actions: [
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),

          if (_errorMessage != null)
            Container(
              color: Colors.redAccent,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            ),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box("weather_box").listenable(),
              builder: (context, Box box, _) {
                final cities = _repository.getLocalCities();

                return ListView.builder(
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    return ListTile(
                      title: Text(city.name),
                      trailing: Text(city.temp != null ? '${city.temp}°C' : '--°C', style: const TextStyle(fontSize: 18)),
                      onTap: () {
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}