import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class RidingWeather {
  final double airTemp;
  final double asphaltTemp;
  final double windSpeed;
  final double windGusts;
  final String windDirection;
  final int rainProbability;
  final double precipitationMm;
  final String rainStatus;
  final int gripPercent;
  final String gripStatus;
  final Color gripColor;
  final String conditionDescription;
  final IconData conditionIcon;
  final Color conditionIconColor;
  final DateTime lastUpdated;

  // Güvenlik & Valilik Yasağı Göstergeleri
  final bool isDangerous;
  final bool isBanRisk;
  final String safetyWarning;
  final int weatherCode;
  final String riskLevel; // 'GUVENLI', 'DIKKAT', 'TEHLIKELI', 'YASAK_RISKI'

  const RidingWeather({
    required this.airTemp,
    required this.asphaltTemp,
    required this.windSpeed,
    required this.windGusts,
    required this.windDirection,
    required this.rainProbability,
    required this.precipitationMm,
    required this.rainStatus,
    required this.gripPercent,
    required this.gripStatus,
    required this.gripColor,
    required this.conditionDescription,
    required this.conditionIcon,
    required this.conditionIconColor,
    required this.lastUpdated,
    required this.isDangerous,
    required this.isBanRisk,
    required this.safetyWarning,
    required this.weatherCode,
    required this.riskLevel,
  });

  /// Varsayılan / Başlangıç İdeal Sürüş Hava Durumu
  factory RidingWeather.initial() {
    return RidingWeather(
      airTemp: 23.0,
      asphaltTemp: 28.0,
      windSpeed: 12.0,
      windGusts: 16.0,
      windDirection: "Kuzey",
      rainProbability: 0,
      precipitationMm: 0.0,
      rainStatus: "%0 (Kuru)",
      gripPercent: 95,
      gripStatus: "Optimal",
      gripColor: const Color(0xFF00E676),
      conditionDescription: "Açık & Güneşli",
      conditionIcon: Icons.wb_sunny_rounded,
      conditionIconColor: Colors.amber,
      lastUpdated: DateTime.now(),
      isDangerous: false,
      isBanRisk: false,
      safetyWarning: "Sürüş şartları elverişli. İyi yolculuklar!",
      weatherCode: 0,
      riskLevel: "GUVENLI",
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
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,rain,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m"
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
          final double windGusts = (current['wind_gusts_10m'] as num?)?.toDouble() ?? windSpeed;
          final double windDeg = (current['wind_direction_10m'] as num?)?.toDouble() ?? 0.0;
          final double precip = (current['precipitation'] as num?)?.toDouble() ?? 0.0;
          final int weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;

          // Asfalt ısısı: Gündüz güneş ışığı ve ortam ısısına göre asfalt 5-8°C daha sıcaktır; yağmurda ise soğur
          final int currentHour = DateTime.now().hour;
          final bool isDaytime = currentHour >= 7 && currentHour <= 19;
          double asphaltTemp = temp;
          if (precip > 0.1) {
            asphaltTemp = temp - 2.0; // Yağmurda ıslanan asfalt hızlıca soğur
          } else if (isDaytime && weatherCode <= 2) {
            asphaltTemp = temp + 5.5; // Güneşli kuru asfalt ısınır
          } else {
            asphaltTemp = temp + 1.0;
          }

          // Rüzgar yönü
          final String windDirStr = _getWindDirectionName(windDeg);

          // Yağış olasılığı ve detaylı durumu
          int rainProb = (precip > 0) ? (precip * 35).clamp(20, 100).toInt() : 0;
          String rainStatus = "%0 (Kuru)";
          if (precip >= 4.0 || weatherCode == 65 || weatherCode == 82) {
            rainStatus = "Şiddetli Sağanak (${precip.toStringAsFixed(1)} mm)";
            rainProb = 100;
          } else if (precip >= 1.5 || weatherCode == 63 || weatherCode == 81) {
            rainStatus = "Kuvvetli Yağmur (${precip.toStringAsFixed(1)} mm)";
            rainProb = 95;
          } else if (precip >= 0.3 || weatherCode == 61 || weatherCode == 80) {
            rainStatus = "Islak Asfalt (${precip.toStringAsFixed(1)} mm)";
            rainProb = 80;
          } else if (precip > 0.0 || (weatherCode >= 51 && weatherCode <= 55)) {
            rainStatus = "Çiseleme (${precip.toStringAsFixed(1)} mm)";
            rainProb = 50;
          }

          // ==============================================================
          // GERÇEKÇİ ÇOK FAKTÖRLÜ MOTOSİKLET LASTİK TUTUŞ MODELİ
          // ==============================================================
          int grip = 100;

          // 1. Zemin Islaklığı ve Yağış Kaybı
          if ((weatherCode >= 71 && weatherCode <= 77) || weatherCode == 85 || weatherCode == 86) {
            grip -= 75; // Kar / Yoğun kar
          } else if (weatherCode == 56 || weatherCode == 57 || weatherCode == 66 || weatherCode == 67) {
            grip -= 80; // Dondurucu yağmur / Gizli buzlanma
          } else if (precip >= 4.0 || weatherCode == 65 || weatherCode == 82) {
            grip -= 52; // Şiddetli sağanak / Su birikintisi / Aquaplaning
          } else if (precip >= 1.5 || weatherCode == 63 || weatherCode == 81) {
            grip -= 38; // Kuvvetli yağmur / Islak kaygan asfalt
          } else if (precip >= 0.3 || weatherCode == 61 || weatherCode == 80) {
            grip -= 28; // Yağmurlu zemin
          } else if (precip > 0.0 || (weatherCode >= 51 && weatherCode <= 55)) {
            // Yağış başlangıcı ve çiseleme asfalttaki yağ ve tozu köpürtür (en tehlikeli sabunsu tabaka)
            grip -= 22;
          }

          // 2. Şiddetli Hava Olayları (WMO Ekstrem Durumlar)
          if (weatherCode >= 95 && weatherCode <= 99) {
            grip -= 20; // Gök gürültülü fırtına / Dolu
          }

          // 3. Rüzgar Hamlesi & Yan Rüzgar (Motosikleti şeritten savurur, viraj tutuş rezervini yok eder)
          if (windGusts >= 70.0 || windSpeed >= 50.0) {
            grip -= 32; // Şiddetli fırtına - devrilme ve savrulma riski
          } else if (windGusts >= 55.0 || windSpeed >= 38.0) {
            grip -= 24; // Fırtına hamlesi - köprü ve viyadüklerde ani savrulma
          } else if (windGusts >= 40.0 || windSpeed >= 28.0) {
            grip -= 14; // Sert yan rüzgar
          } else if (windGusts >= 25.0 || windSpeed >= 18.0) {
            grip -= 6;  // Hafif/orta esinti
          }

          // 4. Sıcaklık ve Kauçuk Sertliği (Soğuk lastik tutuş kaybı)
          if (asphaltTemp <= 1.0 || temp <= 1.0) {
            grip -= 35; // Gizli donma / cam gibi asfalt
          } else if (asphaltTemp <= 5.0 || temp <= 5.0) {
            grip -= 16; // Lastik kauçuğu çalışma sıcaklığına ulaşamaz
          } else if (asphaltTemp <= 10.0 || temp <= 10.0) {
            grip -= 8;
          }

          grip = grip.clamp(10, 98);

          // ==============================================================
          // VALİLİK / AFAD MOTOSİKLET YASAĞI VE KRİTİK TEHLİKE TESPİTİ
          // ==============================================================
          bool isBanRisk = false;
          bool isDangerous = false;
          String safetyWarning = "";
          String riskLevel = "GUVENLI";
          String gripStatus = "Optimal";
          Color gripColor = const Color(0xFF00E676); // Yeşil

          final bool isSnowOrIce = (weatherCode >= 71 && weatherCode <= 77) ||
              (weatherCode == 56 || weatherCode == 57 || weatherCode == 66 || weatherCode == 67) ||
              (temp <= 1.0 && precip > 0.0);

          final bool isStormGale = (windGusts >= 58.0) || (windSpeed >= 44.0);
          final bool isSevereThunderstorm = (weatherCode >= 95 && weatherCode <= 99);

          if (isSnowOrIce) {
            isBanRisk = true;
            isDangerous = true;
            riskLevel = "YASAK_RISKI";
            gripStatus = "Buzlanma / Kar (Yasak Riski)";
            gripColor = const Color(0xFFE040FB); // Mor
            safetyWarning = "Kar ve gizli buzlanma nedeniyle motosikletlerin trafiğe çıkışı hayati tehlike taşır! Valilik yasağı uygulanmaktadır.";
          } else if (isStormGale || (isSevereThunderstorm && windGusts >= 45.0) || grip <= 38) {
            isBanRisk = true;
            isDangerous = true;
            riskLevel = "YASAK_RISKI";
            gripStatus = "Fırtına (Sürüşe Kesinlikle Uygun Değil)";
            gripColor = const Color(0xFFFF3B30); // Neon Tehlike Kırmızısı
            safetyWarning = "Şiddetli fırtına hamleleri (${windGusts.toStringAsFixed(0)} km/s) ve sağanak nedeniyle Valilik motosiklet trafiğe çıkış yasağı riski ve köprü/viyadük devrilme tehlikesi mevcuttur!";
          } else if (grip <= 58 || windGusts >= 42.0 || precip >= 1.5) {
            isDangerous = true;
            riskLevel = "TEHLIKELI";
            gripStatus = "Aşırı Kaygan & Rüzgar";
            gripColor = Colors.deepOrangeAccent;
            safetyWarning = "Zemin ıslak ve rüzgar sert (${windGusts.toStringAsFixed(0)} km/s hamle). Beyaz yol çizgileri ve mazgallar sıfır tutuşa düşer.";
          } else if (grip <= 75 || precip > 0.0 || windSpeed >= 25.0) {
            isDangerous = false;
            riskLevel = "DIKKAT";
            gripStatus = "Dikkat (Islak / Rüzgar)";
            gripColor = Colors.amber;
            safetyWarning = "Zemin ıslak veya rüzgarlı. Ani frenajdan kaçının ve takip mesafesini iki katına çıkarın.";
          } else {
            isDangerous = false;
            riskLevel = "GUVENLI";
            gripStatus = "Optimal";
            gripColor = const Color(0xFF00E676);
            safetyWarning = "Sürüş şartları elverişli. İyi yolculuklar!";
          }

          // Hava Durumu İkon ve Açıklaması
          final condition = _getWeatherCondition(weatherCode, isDaytime);

          _currentWeather = RidingWeather(
            airTemp: temp,
            asphaltTemp: asphaltTemp,
            windSpeed: windSpeed,
            windGusts: windGusts,
            windDirection: windDirStr,
            rainProbability: rainProb,
            precipitationMm: precip,
            rainStatus: rainStatus,
            gripPercent: grip,
            gripStatus: gripStatus,
            gripColor: gripColor,
            conditionDescription: condition.description,
            conditionIcon: condition.icon,
            conditionIconColor: condition.iconColor,
            lastUpdated: DateTime.now(),
            isDangerous: isDangerous,
            isBanRisk: isBanRisk,
            safetyWarning: safetyWarning,
            weatherCode: weatherCode,
            riskLevel: riskLevel,
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
          description: "Sisli (Görüş Kısıtlı)",
          icon: Icons.foggy,
          iconColor: Colors.white54,
        );
      case 51:
      case 53:
      case 55:
        return (
          description: "Çiseleme (Kaygan)",
          icon: Icons.water_drop_outlined,
          iconColor: Colors.lightBlueAccent,
        );
      case 56:
      case 57:
        return (
          description: "Dondurucu Çiseleme (Buzlanma!)",
          icon: Icons.ac_unit,
          iconColor: Colors.purpleAccent,
        );
      case 61:
        return (
          description: "Hafif Yağmurlu",
          icon: Icons.water_drop,
          iconColor: Colors.blueAccent,
        );
      case 63:
        return (
          description: "Kuvvetli Yağmur",
          icon: Icons.water_drop,
          iconColor: Colors.blue,
        );
      case 65:
        return (
          description: "Şiddetli Sağanak",
          icon: Icons.thunderstorm,
          iconColor: Colors.deepOrangeAccent,
        );
      case 66:
      case 67:
        return (
          description: "Donan Yağmur (Gizli Buzlanma!)",
          icon: Icons.severe_cold,
          iconColor: Colors.purpleAccent,
        );
      case 71:
      case 73:
      case 75:
      case 77:
        return (
          description: "Karlı Zemin",
          icon: Icons.ac_unit,
          iconColor: Colors.lightBlueAccent,
        );
      case 80:
      case 81:
      case 82:
        return (
          description: "Sağanak Yağış",
          icon: Icons.thunderstorm,
          iconColor: Colors.cyanAccent,
        );
      case 85:
      case 86:
        return (
          description: "Yoğun Kar Sağanağı",
          icon: Icons.snowing,
          iconColor: Colors.lightBlueAccent,
        );
      case 95:
        return (
          description: "Gök Gürültülü Fırtına",
          icon: Icons.bolt,
          iconColor: Colors.deepOrange,
        );
      case 96:
      case 99:
        return (
          description: "Dolu ve Şiddetli Fırtına",
          icon: Icons.crisis_alert,
          iconColor: Colors.redAccent,
        );
      default:
        return (
          description: "Bulutlu",
          icon: Icons.cloud,
          iconColor: Colors.white70,
        );
    }
  }
}
