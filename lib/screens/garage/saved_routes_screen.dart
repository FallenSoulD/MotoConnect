import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/saved_route_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/neumorphic_widgets.dart';
import '../../widgets/navigation_helper.dart';

class SavedRoutesScreen extends StatefulWidget {
  final MotoUser currentUser;

  const SavedRoutesScreen({super.key, required this.currentUser});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  late final Stream<List<SavedRoute>> _routesStream;

  @override
  void initState() {
    super.initState();
    _routesStream = FirestoreService().streamSavedRoutes(widget.currentUser.id);
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return "${d.inHours}s ${d.inMinutes.remainder(60)}dk";
    }
    return "${d.inMinutes}dk ${d.inSeconds.remainder(60)}sn";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SavedRoute>>(
        stream: _routesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: NeuColors.accentOrange));
          }

          final routes = snapshot.data ?? [];

          if (routes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NeuContainer(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 36,
                      depth: 4,
                      child: const Icon(Icons.edit_road, size: 64, color: NeuColors.accentOrange),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Kayıtlı rotan bulunmuyor.",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Radar üzerinden Sürüş Kaydet diyerek yeni rotalar oluşturabilirsin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];

              return NeuContainer(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                depth: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        NeuContainer(
                          padding: const EdgeInsets.all(10),
                          borderRadius: 16,
                          color: NeuColors.accentOrange.withValues(alpha: 0.2),
                          child: const Icon(Icons.route, color: NeuColors.accentOrange, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                route.routeName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                "${route.createdAt.day}/${route.createdAt.month}/${route.createdAt.year}",
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text("Mesafe", style: TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text("${route.distanceKm.toStringAsFixed(1)} km", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("Süre", style: TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(_formatDuration(route.duration), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: NeuButton(
                        text: "Tekrar Git",
                        icon: Icons.navigation,
                        isPrimary: true,
                        onPressed: () {
                          if (route.waypoints.isNotEmpty) {
                            NavigationHelper.openNavigationSheet(
                              context,
                              targetLat: route.waypoints.first.latitude,
                              targetLng: route.waypoints.first.longitude,
                              title: route.routeName,
                              subtitle: "Kayıtlı Rotanın Başlangıç Noktasına navigasyon başlat",
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Rota noktaları bulunamadı."), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
  }
}
