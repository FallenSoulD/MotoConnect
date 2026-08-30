import 'user_model.dart';

class RiderBadge {
  final String id;
  final String title;
  final String icon;
  final String description;
  final String category;
  final bool isUnlocked;
  final int currentProgress;
  final int targetProgress;

  RiderBadge({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.category,
    required this.isUnlocked,
    required this.currentProgress,
    required this.targetProgress,
  });

  double get progressPercent => (currentProgress / targetProgress).clamp(0.0, 1.0);
}

class LeaderboardEntry {
  final int rank;
  final MotoUser rider;
  final int weeklyKm;
  final int signalCount;
  final int points;

  LeaderboardEntry({
    required this.rank,
    required this.rider,
    required this.weeklyKm,
    required this.signalCount,
    required this.points,
  });
}
