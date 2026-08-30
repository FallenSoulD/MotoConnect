import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class RidingWeather {
  final double airTemp;
  final double asphaltTemp;
  final double windSpeed;
  final String windDirection;
  final int rainProbability;
  final String rainStatus;
  final int gripPercent;
  final String gripStatus;
  final Color gripColor;
  final String conditionDescription;
  final IconData conditionIcon;
  final Color conditionIconColor;
  final DateTime lastUpdated;

  const RidingWeather({
    required this.airTemp,
    required this.asphaltTemp,
    required this.windSpeed,
    required this.windDirection,
    required this.rainProbability,
    required this.rainStatus,
    required this.gripPercent,
    required this.gripStatus,
    required this.gripColor,
    required this.conditionDescription,
    required this.conditionIcon,
    required this.conditionIconColor,
    required this.lastUpdated,
  });

  /// Varsayılan / Başlangıç İdeal Sürüş Hava Durumu
  factory RidingWeather.initial() {
    return RidingWeather(
      airTemp: 23.0,
      asphaltTemp: 28.0,
      windSpeed: 12.0,
      windDirection: "Kuzey",
      rainProbability: 0,
      rainStatus: "%0 (Kuru)",
      gripPercent: 95,
      gripStatus: "Optimal",
      gripColor: const Color(0xFF00E676),
      conditionDescription: "Açık & Güneşli",
      conditionIcon: Icons.wb_sunny_rounded,
      conditionIconColor: Colors.amber,
      lastUpdated: DateTime.now(),
    );
  }
}

class MotoWeatherService {
  static final MotoWeatherService _instance = MotoWeatherService._internal();
  factory MotoWeatherService() => _instance;
  MotoWeatherService._internal();

  Timer? _periodicTimer;
  final StreamController<RidingWeather> _weatherStreamController =
      StreamController<RidingWeather>.broadcast();

  Stream<RidingWeather> get weatherStream => _weatherStreamController.stream;

  RidingWeather _currentWeather = RidingWeather.initial();
  RidingWeather get currentWeather => _currentWeather;

  bool _isFetching = false;

  /// Servisi başlatır ve 5 dakikada bir otomatik veri yenileme kurar
  void startAutoRefresh({Duration refreshInterval = const Duration(minutes: 5)}) {
    _periodicTimer?.cancel();
    fetchWeather(); // İlk veriyi hemen çek
    _periodicTimer = Timer.periodic(refreshInterval, (_) {
      fetchWeather();
    });
  }

  void stopAutoRefresh() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Canlı Açık Hava API'sinden (Open-Meteo) anlık sürüş verilerini çeker
  Future<RidingWeather> fetchWeather({double? lat, double? lng}) async {
    if (_isFetching) return _currentWeather;
    _isFetching = true;

    double targetLat = lat ?? 41.0082; // Varsayılan İstanbul
    double targetLng = lng ?? 28.9784;

    try {
      // Eğer koordinat verilmediyse cihazın anlık GPS konumunu almayı dene
      if (lat == null || lng == null) {
        final position = await _getCurrentPosition();
        if (position != null) {
          targetLat = position.latitude;
          targetLng = position.longitude;
        }
      }

      final url = Uri.parse(
        "https://api.open-meteo.com/v1/forecast"
        "?latitude=$targetLat&longitude=$targetLng"
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,rain,weather_code,wind_speed_10m,wind_direction_10m"
        "&wind_speed_unit=kmh"
        "&timezone=auto",
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'] as Map<String, dynamic>?;

        if (current != null) {
          final double temp = (current['temperature_2m'] as num?)?.toDouble() ?? 22.0;
          final double windSpeed = (current['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;
          final double windDeg = (current['wind_direction_10m'] as num?)?.toDouble() ?? 0.0;
          final double precip = (current['precipitation'] as num?)?.toDouble() ?? 0.0;
          final int weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;

          // Asfalt ısısı formülü: Gündüz güneş ışığı ve ortam ısısına göre asfalt 5-8°C daha sıcaktır
          final int currentHour = DateTime.now().hour;
          final bool isDaytime = currentHour >= 7 && currentHour <= 19;
          double asphaltTemp = temp;
          if (isDaytime && weatherCode <= 2) {
            asphaltTemp = temp + 5.5; // Güneşli kuru asfalt ısınır
          } else if (precip > 0.1) {
            asphaltTemp = temp - 1.5; // Yağmurda asfalt soğur ve ıslanır
          } else {
            asphaltTemp = temp + 2.0;
          }

          // Rüzgar yönü
          final String windDirStr = _getWindDirectionName(windDeg);

          // Yağış olasılığı ve durumu
          int rainProb = (precip > 0) ? (precip * 30).clamp(10, 100).toInt() : 0;
          String rainStatus = "%0 (Kuru)";
          if (precip > 2.0) {
            rainStatus = "Şiddetli Yağmur";
            rainProb = 95;
          } else if (precip > 0.3) {
            rainStatus = "Islak Asfalt";
            rainProb = 75;
          } else if (precip > 0) {
            rainStatus = "Çiseleme";
            rainProb = 40;
          }

          // Lastik Tutuş Yüzdesi (% Hesaplaması)
          int grip = 95;
          String gripStatus = "Optimal";
          Color gripColor = const Color(0xFF00E676); // Yeşil

          if (temp < 3.0) {
            grip = 45;
            gripStatus = "Buzlanma Riski!";
            gripColor = Colors.purpleAccent;
          } else if (precip > 1.0) {
            grip = 62;
            gripStatus = "Islak Kaygan";
            gripColor = Colors.orangeAccent;
          } else if (precip > 0.0) {
            grip = 74;
            gripStatus = "Dikkat";
            gripColor = Colors.amber;
          } else if (temp < 10.0) {
            grip = 82;
            gripStatus = "Soğuk Lastik";
            gripColor = Colors.cyanAccent;
          } else if (windSpeed > 40.0) {
            grip = 80;
            gripStatus = "Sert Yan Rüzgar";
            gripColor = Colors.amber;
          } else {
            grip = 96;
            gripStatus = "Mükemmel";
            gripColor = const Color(0xFF00E676);
          }

          // Hava Durumu İkon ve Açıklaması
          final condition = _getWeatherCondition(weatherCode, isDaytime);

          _currentWeather = RidingWeather(
            airTemp: temp,
            asphaltTemp: asphaltTemp,
            windSpeed: windSpeed,
            windDirection: windDirStr,
            rainProbability: rainProb,
            rainStatus: rainStatus,
            gripPercent: grip,
            gripStatus: gripStatus,
            gripColor: gripColor,
            conditionDescription: condition.description,
            conditionIcon: condition.icon,
            conditionIconColor: condition.iconColor,
            lastUpdated: DateTime.now(),
          );

          _weatherStreamController.add(_currentWeather);
          return _currentWeather;
        }
      }
    } catch (e) {
      debugPrint("MotoWeatherService error: $e");
    } finally {
      _isFetching = false;
    }

    return _currentWeather;
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 3),
            ),
          );
    } catch (_) {
      return null;
    }
  }

  String _getWindDirectionName(double deg) {
    if (deg >= 337.5 || deg < 22.5) return "Kuzey (Yıldız)";
    if (deg >= 22.5 && deg < 67.5) return "Kuzeydoğu (Poyraz)";
    if (deg >= 67.5 && deg < 112.5) return "Doğu (Gündoğusu)";
    if (deg >= 112.5 && deg < 157.5) return "Güneydoğu (Keşişleme)";
    if (deg >= 157.5 && deg < 202.5) return "Güney (Kıble)";
    if (deg >= 202.5 && deg < 247.5) return "Güneybatı (Lodos)";
    if (deg >= 247.5 && deg < 292.5) return "Batı (Günbatısı)";
    return "Kuzeybatı (Karayel)";
  }

  ({String description, IconData icon, Color iconColor}) _getWeatherCondition(int code, bool isDaytime) {
    switch (code) {
      case 0:
        return (
          description: isDaytime ? "Açık & Güneşli" : "Açık Gece",
          icon: isDaytime ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          iconColor: isDaytime ? Colors.amber : Colors.blueAccent,
        );
      case 1:
      case 2:
        return (
          description: "Parçalı Bulutlu",
          icon: Icons.cloud_queue,
          iconColor: Colors.amberAccent,
        );
      case 3:
        return (
          description: "Kapalı & Bulutlu",
          icon: Icons.cloud,
          iconColor: Colors.white70,
        );
      case 45:
      case 48:
        return (
          description: "Sisli (Görüş Düşük)",
          icon: Icons.foggy,
          iconColor: Colors.white54,
        );
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
        return (
          description: "Yağmurlu",
          icon: Icons.water_drop,
          iconColor: Colors.blueAccent,
        );
      case 65:
      case 80:
      case 81:
      case 82:
        return (
          description: "Sağanak Yağış",
          icon: Icons.thunderstorm,
          iconColor: Colors.cyanAccent,
        );
      case 71:
      case 73:
      case 75:
        return (
          description: "Karlı",
          icon: Icons.ac_unit,
          iconColor: Colors.lightBlueAccent,
        );
      case 95:
      case 96:
      case 99:
        return (
          description: "Gök Gürültülü Fırtına",
          icon: Icons.bolt,
          iconColor: Colors.deepOrange,
        );
      default:
        return (
          description: "Sürüşe Uygun",
          icon: Icons.wb_sunny_rounded,
          iconColor: Colors.amber,
        );
    }
  }
}
