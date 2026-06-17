class Weather {
  final String id;
  final String name;
  final double lat;
  final double lon;
  double? temp;
  double? windSpeed;
  int? humidity;
  double? pressure;
  int? windDirection;

  Weather({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.temp,
    this.windSpeed,
    this.humidity,
    this.pressure,
    this.windDirection,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lon': lon,
      'temp': temp,
      'windSpeed': windSpeed,
      'humidity': humidity,
      'pressure': pressure,
      'windDirection': windDirection,
    };
  }

  factory Weather.fromMap(Map<dynamic, dynamic> map) {
    return Weather(
      id: map['id'],
      name: map['name'],
      lat: map['lat'],
      lon: map['lon'],
      temp: map['temp'],
      windSpeed: map['windSpeed'],
      humidity: map['humidity'],
      pressure: map['pressure'],
      windDirection: map['windDirection'],
    );
  }
}
