# TAM Weather

Aplikacja mobilna do monitorowania pogody w różnych miastach.

## Główne funkcje

* **Zarządzanie listą miast:** Dodawanie nowych miast oraz usuwanie za pomocą gestu przesunięcia.
* **Szczegółowy podgląd:** Wyświetlanie szczegółowych parametrów (temperatura, prędkość i kierunek wiatru, wilgotność, ciśnienie).
* **Obsługa offline:** Lokalny zapis danych w bazie danych urządzenia.
* **Komunikaty błędów:** Czerwone paski ostrzegawcze.

## Struktura plików

* `lib/main.dart` – inicjalizacja bazy danych i punkt startowy aplikacji.
* `lib/models/weather.dart` – model danych reprezentujący miasto.
* `lib/repositories/weather_repository.dart` – logika, zapytania HTTP i operacje na Hive.
* `lib/screens/weather_list_screen.dart` – ekran główny z listą miast i oknem dodawania.
* `lib/screens/weather_detail_screen.dart` – ekran szczegółowy.
