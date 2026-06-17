import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../repositories/weather_repository.dart';
import '../models/weather.dart';
import 'weather_detail_screen.dart';

class WeatherListScreen extends StatefulWidget {
  const WeatherListScreen({super.key});

  @override
  State<WeatherListScreen> createState() => _WeatherListScreenState();
}

class _WeatherListScreenState extends State<WeatherListScreen> {
  // Inicjalizujemy instancję repozytorium do obsługi danych pogodowych i bazy Hive.
  final WeatherRepository _repository = WeatherRepository();

  // Flaga informująca, czy aplikacja w danym momencie pobiera dane z internetu.
  bool _isLoading = false;

  // Zmienna przechowująca komunikat o błędzie (np. brak sieci). Jeśli jest null, błąd się nie wyświetla.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Funkcja do automatycznego odświeżania temperatur.
    _refreshData();
  }

  Future<void> _refreshData() async {
    // Włączamy pasek ładowania i czyścimy stare błędy.
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Wywołujemy z repozytorium grupowy pobór temperatur z API Open-Meteo.
      await _repository.fetchCurrentWeatherForList();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });

      // Odliczamy 4 sekundy i czyścimy błąd.
      Future.delayed(const Duration(seconds: 4), () {
        // Sprawdzamy 'mounted', na wypadek gdyby użytkownik zamknął ekran w trakcie odliczania
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    } finally {
      // Niezależnie od tego czy pobieranie się udało, czy wystąpił błąd – wyłączamy pasek ładowania.
      setState(() => _isLoading = false);
    }
  }

  // Wyświetlamy AlertDialog służący do wpisania nowego miasta.
  void _showAddCityDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dodaj nowe miasto'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Wpisz nazwę miasta'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            // Przycisk zatwierdzenia
            ElevatedButton(
              onPressed: () async {
                // Wyciągamy tekst z pola i usuwamy z niego przypadkowe spacji z początku i końca (.trim()).
                final String text = controller.text.trim();
                if (text.isNotEmpty) {
                  // Zamykamy okienko dialogowe przed rozpoczęciem pobierania.
                  Navigator.pop(context);
                  // Włączamy wskaźnik ładowania na ekranie głównym.
                  setState(() => _isLoading = true);
                  try {
                    // Wysyłamy zapytanie o geolokalizację miasta i zapisujemy je w bazie Hive.
                    await _repository.addCity(text);
                    // Od razu dociągamy aktualną temperaturę dla nowo dodanego miasta.
                    await _repository.fetchCurrentWeatherForList();
                  } catch (e) {
                    setState(() {
                      // Obsługa błędów geolokalizacji lub duplikatów miast.
                      _errorMessage = e.toString().replaceAll(
                        "Exception: ",
                        "",
                      );
                    });

                    // Odliczamy 4 sekundy i czyścimy błąd.
                    Future.delayed(const Duration(seconds: 4), () {
                      // Sprawdzamy 'mounted', na wypadek gdyby użytkownik zamknął ekran w trakcie odliczania
                      if (mounted) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    });
                  } finally {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('Dodaj'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TAM - Weather'),
        actions: [
          // Przycisk odświeżania.
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Jeśli flaga _isLoading jest aktywna, na samej górze ekranu pojawi się poziomy pasek ładowania.
          if (_isLoading) const LinearProgressIndicator(),

          // Jeśli istnieje komunikat o błędzie, wyświetlamy czerwony pasek ostrzegawczy.
          if (_errorMessage != null)
            Container(
              color: Colors.redAccent,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),

          Expanded(
            // ValueListenableBuilder - Słucha zmian w bazie lokalnej Hive.
            child: ValueListenableBuilder(
              valueListenable: Hive.box("weather_box").listenable(),
              builder: (context, Box box, _) {
                // Pobieramy świeżą listę miast z bazy.
                final cities = _repository.getLocalCities();

                return ListView.builder(
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];

                    return Dismissible(
                      key: Key(city.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        // Kasujemy miasto trwale z lokalnej bazy danych Hive.
                        await _repository.deleteCity(city.id);
                        // Zabezpieczenie przed wywołaniem Contextu na elemencie, który mógłby już nie istnieć w drzewie.
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Usunięto miasto: ${city.name}'),
                          ),
                        );
                      },
                      child: WeatherCard(
                        city: city,
                        onTap: () {
                          // Kliknięcie w kartę przenosi użytkownika do ekranu szczegółów pogody.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WeatherDetailScreen(cityId: city.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Okrągły przycisk z plusem w prawym dolnym rogu ekranu, wywołujący okno dialogowe dodawania miasta.
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCityDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Wydzielony komponent wizualny - karta pogodowa miasta.
class WeatherCard extends StatelessWidget {
  final Weather city;
  final VoidCallback? onTap;

  const WeatherCard({super.key, required this.city, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.location_pin,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          city.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        // Sekcja po prawej stronie wiersza (Wrap układa elementy obok siebie w poziomie).
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            // Wyświetlamy temperaturę. Jeśli pole wynosi null (brak danych z API), dajemy dwie kreski '--°C'.
            Text(
              city.temp != null ? '${city.temp}°C' : '--°C',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
