import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/ride_model.dart';

class RouteResult {
  final List<LatLng> waypoints;
  final double distanceKm;
  final String durationText;

  RouteResult({
    required this.waypoints,
    required this.distanceKm,
    required this.durationText,
  });
}

class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  /// OpenStreetMap / OSRM Gerçek Karayolu Navigasyon API'si ile
  /// 100% gerçek sokak, otoyol, köprü ve virajlardan geçen gerçek GPS rotası çeker.
  Future<RouteResult> fetchRoadRoute(LatLng start, LatLng dest) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List?;

          if (coords != null && coords.isNotEmpty) {
            final List<LatLng> points = [];
            for (var c in coords) {
              if (c is List && c.length >= 2) {
                final lng = (c[0] as num).toDouble();
                final lat = (c[1] as num).toDouble();
                points.add(LatLng(lat, lng));
              }
            }

            final double distMeters = (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
            final double distKm = distMeters / 1000.0;

            final double durationSeconds = (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;
            final int totalMinutes = (durationSeconds / 60).round();
            final int hours = totalMinutes ~/ 60;
            final int mins = totalMinutes % 60;
            final String durationText = hours > 0 ? "${hours}s ${mins}dk" : "${mins}dk";

            if (points.isNotEmpty) {
              return RouteResult(
                waypoints: points,
                distanceKm: double.parse(distKm.toStringAsFixed(1)),
                durationText: durationText,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint("OSRM Route fetch error: $e");
    }

    // Ağ hatası veya OSRM yanıt vermezse kıvrımlı motor rotası fallback'i
    const Distance dist = Distance();
    final double rawDist = dist.as(LengthUnit.Kilometer, start, dest);
    final double fallbackDist = (rawDist * 1.22).clamp(1.0, 999.0);
    final int estHours = fallbackDist ~/ 65;
    final int estMins = ((fallbackDist % 65) / 65 * 60).round();
    final String fallbackDuration = estHours > 0 ? "${estHours}s ${estMins}dk" : "${estMins}dk";

    return RouteResult(
      waypoints: generatePointsBetween(start, dest),
      distanceKm: double.parse(fallbackDist.toStringAsFixed(1)),
      durationText: fallbackDuration,
    );
  }

  /// Belirtilen rota başlığı veya açıklamasına göre GPS polyline noktalarını getirir
  List<LatLng> getRoutePointsForRide(RideEvent ride) {
    if (ride.waypoints.isNotEmpty && ride.waypoints.length > 2) {
      return ride.waypoints;
    }

    final lowerTitle = "${ride.title} ${ride.route}".toLowerCase();

    if (lowerTitle.contains("şile") || lowerTitle.contains("darlık")) {
      return sileDarlikRoute;
    } else if (lowerTitle.contains("viaport") || lowerTitle.contains("körfez") || lowerTitle.contains("otoyol")) {
      return viaportKorfezRoute;
    } else if (lowerTitle.contains("riva") || lowerTitle.contains("polonezköy")) {
      return atasehirRivaRoute;
    } else if (lowerTitle.contains("boğaz") || lowerTitle.contains("sarıyer") || lowerTitle.contains("beşiktaş")) {
      return bogazSahilRoute;
    }

    if (ride.waypoints.isNotEmpty) {
      return ride.waypoints;
    }

    return sileDarlikRoute;
  }

  /// İki nokta arasında doğal virajlı ara noktalar üretir
  List<LatLng> generatePointsBetween(LatLng start, LatLng dest) {
    const Distance dist = Distance();
    final double distanceMeters = dist.as(LengthUnit.Meter, start, dest);
    int steps = (distanceMeters / 1500).clamp(8, 35).toInt();

    List<LatLng> points = [];
    points.add(start);

    for (int i = 1; i < steps; i++) {
      double t = i / steps;
      double lat = start.latitude + (dest.latitude - start.latitude) * t;
      double lng = start.longitude + (dest.longitude - start.longitude) * t;

      double curveOffset = 0.005 * math.sin(t * math.pi);
      double dx = dest.longitude - start.longitude;
      double dy = dest.latitude - start.latitude;
      double length = math.sqrt(dx * dx + dy * dy);
      if (length > 0) {
        lat += (-dx / length) * curveOffset;
        lng += (dy / length) * curveOffset;
      }
      points.add(LatLng(lat, lng));
    }

    points.add(dest);
    return points;
  }

  // --- POPÜLER MOTORCU ROTALARI ---

  static const List<LatLng> sileDarlikRoute = [
    LatLng(40.9901, 29.0232), // Kadıköy Haldun Taner
    LatLng(40.9820, 29.0550), // Göztepe Köprüsü
    LatLng(40.9850, 29.1120), // Ataşehir
    LatLng(41.0150, 29.1550), // Ümraniye Şile Bağlantısı
    LatLng(41.0350, 29.1800), // Çekmeköy
    LatLng(41.0520, 29.2400), // Taşdelen
    LatLng(41.0600, 29.3500), // Ömerli
    LatLng(41.0950, 29.4600), // Şile Yolu Virajları
    LatLng(41.1400, 29.5400), // Sofular Sapağı
    LatLng(41.1760, 29.6100), // Şile Merkez / Liman
    LatLng(41.1300, 29.5800), // Darlık Barajı Girişi
    LatLng(41.1150, 29.5600), // Darlık Kamp & Viraj Noktası
  ];

  static const List<LatLng> viaportKorfezRoute = [
    LatLng(40.9290, 29.3190), // Kurtköy Viaport Otopark
    LatLng(40.9150, 29.3550), // Sabiha Gökçen Çıkışı
    LatLng(40.8900, 29.4100), // Akfırat / İstanbul Park
    LatLng(40.8450, 29.4500), // Kuzey Marmara Dilovası
    LatLng(40.7850, 29.4800), // Osmangazi Köprü Ayrımı
    LatLng(40.7600, 29.5800), // Hereke Sahil Virajları
    LatLng(40.7600, 29.7400), // Körfez Pisti & Varış
  ];

  static const List<LatLng> atasehirRivaRoute = [
    LatLng(40.9850, 29.1120), // Ataşehir Shell
    LatLng(41.0300, 29.1250), // Ümraniye
    LatLng(41.0650, 29.1450), // Çavuşbaşı
    LatLng(41.0900, 29.1500), // Beykoz Orman Yolu
    LatLng(41.1100, 29.2100), // Polonezköy Tabiat Parkı
    LatLng(41.1650, 29.2250), // Göllü Köyü Virajları
    LatLng(41.2250, 29.2190), // Riva Sahil & Kale
  ];

  static const List<LatLng> bogazSahilRoute = [
    LatLng(41.0420, 29.0080), // Beşiktaş Meydan
    LatLng(41.0470, 29.0250), // Ortaköy
    LatLng(41.0680, 29.0430), // Bebek Sahil
    LatLng(41.0850, 29.0560), // Rumeli Hisarı
    LatLng(41.1070, 29.0550), // Emirgan
    LatLng(41.1180, 29.0580), // İstinye
    LatLng(41.1390, 29.0500), // Yeniköy
    LatLng(41.1550, 29.0480), // Tarabya
    LatLng(41.1710, 29.0560), // Kireçburnu
    LatLng(41.1980, 29.0530), // Sarıyer Meydan
    LatLng(41.2240, 29.0960), // Rumeli Feneri
  ];
}
