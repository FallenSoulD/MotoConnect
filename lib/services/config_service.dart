import 'package:cloud_firestore/cloud_firestore.dart';

class SystemConfig {
  final String vipMonthlyPrice;
  final String vipYearlyPrice;
  final bool isGaragePhotoFeaturePaid;
  final bool isRadarBoostPaid;
  final int maxFreePhotos;
  final bool isUnlimitedSwipeFree;

  const SystemConfig({
    required this.vipMonthlyPrice,
    required this.vipYearlyPrice,
    required this.isGaragePhotoFeaturePaid,
    required this.isRadarBoostPaid,
    required this.maxFreePhotos,
    required this.isUnlimitedSwipeFree,
  });

  factory SystemConfig.fromMap(Map<String, dynamic> data) {
    return SystemConfig(
      vipMonthlyPrice: data['vipMonthlyPrice'] ?? '₺149,99 / ay',
      vipYearlyPrice: data['vipYearlyPrice'] ?? '₺999,99 / yıl',
      isGaragePhotoFeaturePaid: data['isGaragePhotoFeaturePaid'] ?? true,
      isRadarBoostPaid: data['isRadarBoostPaid'] ?? true,
      maxFreePhotos: data['maxFreePhotos'] ?? 3,
      isUnlimitedSwipeFree: data['isUnlimitedSwipeFree'] ?? false,
    );
  }
}

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final _docRef = FirebaseFirestore.instance.collection('system_settings').doc('general_config');

  Stream<SystemConfig> getConfigStream() {
    return _docRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return const SystemConfig(
          vipMonthlyPrice: '₺149,99 / ay',
          vipYearlyPrice: '₺999,99 / yıl',
          isGaragePhotoFeaturePaid: true,
          isRadarBoostPaid: true,
          maxFreePhotos: 3,
          isUnlimitedSwipeFree: false,
        );
      }
      return SystemConfig.fromMap(snapshot.data()!);
    });
  }

  Future<SystemConfig> getConfigOnce() async {
    final snapshot = await _docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      return const SystemConfig(
        vipMonthlyPrice: '₺149,99 / ay',
        vipYearlyPrice: '₺999,99 / yıl',
        isGaragePhotoFeaturePaid: true,
        isRadarBoostPaid: true,
        maxFreePhotos: 3,
        isUnlimitedSwipeFree: false,
      );
    }
    return SystemConfig.fromMap(snapshot.data()!);
  }

  Future<void> updateConfig({
    String? vipMonthlyPrice,
    String? vipYearlyPrice,
    bool? isGaragePhotoFeaturePaid,
    bool? isRadarBoostPaid,
    int? maxFreePhotos,
    bool? isUnlimitedSwipeFree,
  }) async {
    final Map<String, dynamic> updates = {};
    if (vipMonthlyPrice != null) updates['vipMonthlyPrice'] = vipMonthlyPrice;
    if (vipYearlyPrice != null) updates['vipYearlyPrice'] = vipYearlyPrice;
    if (isGaragePhotoFeaturePaid != null) updates['isGaragePhotoFeaturePaid'] = isGaragePhotoFeaturePaid;
    if (isRadarBoostPaid != null) updates['isRadarBoostPaid'] = isRadarBoostPaid;
    if (maxFreePhotos != null) updates['maxFreePhotos'] = maxFreePhotos;
    if (isUnlimitedSwipeFree != null) updates['isUnlimitedSwipeFree'] = isUnlimitedSwipeFree;

    if (updates.isEmpty) return;

    await _docRef.set(updates, SetOptions(merge: true));
  }
}
