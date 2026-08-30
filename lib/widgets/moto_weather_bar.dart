import 'dart:async';
import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import 'neumorphic_widgets.dart';

class MotoWeatherBar extends StatefulWidget {
  final EdgeInsetsGeometry margin;
  const MotoWeatherBar({
    super.key,
    this.margin = const EdgeInsets.only(bottom: 8),
  });

  @override
  State<MotoWeatherBar> createState() => _MotoWeatherBarState();
}

class _MotoWeatherBarState extends State<MotoWeatherBar> {
  bool _isExpanded = false;
  late RidingWeather _weather;
  StreamSubscription<RidingWeather>? _weatherSubscription;
  bool _isManualRefreshing = false;

  @override
  void initState() {
    super.initState();
    _weather = MotoWeatherService().currentWeather;

    // 5 dakikada bir otomatik canlı veri çekimini başlat
    MotoWeatherService().startAutoRefresh(refreshInterval: const Duration(minutes: 5));

    _weatherSubscription = MotoWeatherService().weatherStream.listen((newWeather) {
      if (mounted) {
        setState(() {
          _weather = newWeather;
          _isManualRefreshing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _weatherSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshNow() async {
    setState(() => _isManualRefreshing = true);
    await MotoWeatherService().fetchWeather();
    if (mounted) setState(() => _isManualRefreshing = false);
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  void _showDisclaimerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeuContainer(
          padding: const EdgeInsets.all(22),
          borderRadius: 22,
          borderColor: Colors.amber.withValues(alpha: 0.5),
          borderWidth: 1.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 26),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Sorumluluk Reddi Beyanı",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                "• Bu ekranda yer alan hava durumu, tahmini asfalt sıcaklığı, rüzgar yönü ve lastik tutuş yüzdesi göstergeleri yalnızca genel bilgilendirme ve tahmin amaçlıdır.\n\n"
                "• Zemin şartları (yağ, toz, mıcır, çukur, gizli buzlanma vb.) anlık olarak bölgesel değişiklikler gösterebilir.\n\n"
                "• Sürüş hızı, yatış açısı, fren mesafesi ve can güvenliği sorumluluğu münhasıran sürücünün kendisine aittir.\n\n"
                "• MotoConnect ve geliştiricileri; bu verilere dayanılarak yapılan sürüşlerden kaynaklanabilecek kaza, maddi hasar, yaralanma veya hukuki ihtilaflardan hiçbir suretle sorumlu tutulamaz.",
                style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.45),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: NeuButton(
                  text: "Anladım ve Kabul Ediyorum",
                  isPrimary: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: NeuContainer(
        margin: widget.margin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: 14,
        color: NeuColors.surfaceDark.withValues(alpha: 0.95),
        borderColor: NeuColors.accentOrange.withValues(alpha: 0.3),
        borderWidth: 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ÜST ÖZET ŞERİT
            Row(
              children: [
                Icon(_weather.conditionIcon, color: _weather.conditionIconColor, size: 20),
                const SizedBox(width: 6),
                Text(
                  "${_weather.airTemp.toStringAsFixed(0)}°C",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 12,
                  width: 1,
                  color: Colors.white24,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.air, color: NeuColors.accentCyan, size: 16),
                const SizedBox(width: 4),
                Text(
                  "${_weather.windSpeed.toStringAsFixed(0)} km/s",
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                const Spacer(),

                // DİNAMİK TUTUŞ ROZETİ
                NeuBadge(
                  text: "Tutuş %${_weather.gripPercent}",
                  icon: Icons.speed,
                  color: _weather.gripColor,
                  fontSize: 10.5,
                ),
                const SizedBox(width: 6),

                // YENİLEME / AÇILMA OKU
                if (_isManualRefreshing)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NeuColors.accentOrange,
                    ),
                  )
                else
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white54,
                    size: 18,
                  ),
              ],
            ),

            // AÇILIR DETAY KUTUSU
            if (_isExpanded) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.water_drop_outlined,
                      label: "Yağış Durumu",
                      value: _weather.rainStatus,
                      color: Colors.blueAccent,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.navigation_outlined,
                      label: "Rüzgar Yönü",
                      value: _weather.windDirection,
                      color: NeuColors.accentCyan,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.thermostat_outlined,
                      label: "Asfalt Isısı",
                      value: "${_weather.asphaltTemp.toStringAsFixed(0)}°C (${_weather.gripStatus})",
                      color: NeuColors.accentOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // CANLI DURUM & SORUMLULUK REDDİ BUTONU
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: NeuColors.accentGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Canlı (${_formatTime(_weather.lastUpdated)} - 5 dk)",
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _showDisclaimerDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber, size: 10),
                              SizedBox(width: 3),
                              Text("Yasal Uyarı", style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _refreshNow,
                    child: const Row(
                      children: [
                        Icon(Icons.refresh, color: NeuColors.accentOrange, size: 12),
                        SizedBox(width: 3),
                        Text(
                          "Şimdi Güncelle",
                          style: TextStyle(color: NeuColors.accentOrange, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // ALT SABİT HUKUKİ SORUMLULUK REDDİ ŞERİDİ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "⚠️ Veriler tahmini ve bilgilendirme amaçlıdır. Sürüş ve hız sorumluluğu tamamen sürücüye aittir.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 9.5, height: 1.2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
