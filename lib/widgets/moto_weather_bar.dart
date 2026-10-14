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

class _MotoWeatherBarState extends State<MotoWeatherBar> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late RidingWeather _weather;
  StreamSubscription<RidingWeather>? _weatherSubscription;
  bool _isManualRefreshing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _weather = MotoWeatherService().currentWeather;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_weather.isBanRisk) {
      _pulseController.repeat(reverse: true);
    }

    // 5 dakikada bir otomatik canlı veri çekimini başlat
    MotoWeatherService().startAutoRefresh(refreshInterval: const Duration(minutes: 5));

    _weatherSubscription = MotoWeatherService().weatherStream.listen((newWeather) {
      if (mounted) {
        setState(() {
          _weather = newWeather;
          _isManualRefreshing = false;
        });

        if (newWeather.isBanRisk) {
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          _pulseController.stop();
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
                "• Bu ekranda yer alan hava durumu, tahmini asfalt sıcaklığı, rüzgar hamleleri ve lastik tutuş yüzdesi göstergeleri genel meteorolojik modellerden alınan anlık tahminlerdir.\n\n"
                "• Yağış, rüzgar fırtınası, su birikintileri, gizli buzlanma ve yağlanmış asfalt zemin tutuşunu aniden sıfırlayabilir.\n\n"
                "• Şiddetli fırtına veya olumsuz hava koşullarında Valilik ve Emniyet tarafından motosiklet ve motokuryelerin trafiğe çıkışı yasaklanabilir. Bu yasaklara uymak sürücünün yasal ve can güvenliği sorumluluğundadır.\n\n"
                "• MotoConnect ve geliştiricileri; bu verilere dayanılarak yapılan sürüşlerden kaynaklanabilecek kaza, maddi hasar, yaralanma veya cezai işlemlerden hiçbir suretle sorumlu tutulamaz.",
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
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        Color borderColor = NeuColors.accentOrange.withValues(alpha: 0.3);
        double borderWidth = 1.0;

        if (_weather.isBanRisk) {
          borderColor = Colors.redAccent.withValues(alpha: _pulseAnimation.value);
          borderWidth = 1.8;
        } else if (_weather.isDangerous) {
          borderColor = Colors.deepOrangeAccent.withValues(alpha: 0.8);
          borderWidth = 1.4;
        }

        return GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: NeuContainer(
            margin: widget.margin,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            borderRadius: 14,
            color: _weather.isBanRisk
                ? const Color(0xFF1E0E12)
                : NeuColors.surfaceDark.withValues(alpha: 0.95),
            borderColor: borderColor,
            borderWidth: borderWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. KRİTİK VALİLİK YASAĞI / FIRTINA ÜST BANNER (Sadece kritik durumda gösterilir)
                if (_weather.isBanRisk) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: _pulseAnimation.value),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gavel, color: Colors.redAccent, size: 15),
                        const SizedBox(width: 7),
                        const Expanded(
                          child: Text(
                            "VALİLİK YASAĞI RİSKİ • SÜRÜŞE UYGUN DEĞİL!",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "⛔ YASAK",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_weather.isDangerous) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.deepOrangeAccent.withValues(alpha: 0.6),
                        width: 1.0,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.deepOrangeAccent, size: 15),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "DİKKAT: Zorlu Hava & Aşırı Kaygan Zemin!",
                            style: TextStyle(
                              color: Colors.deepOrangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 2. ANA ÖZET ŞERİT
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
                    Icon(
                      _weather.windGusts >= 55 ? Icons.storm : Icons.air,
                      color: _weather.windGusts >= 55 ? Colors.redAccent : NeuColors.accentCyan,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _weather.windGusts > _weather.windSpeed + 5
                          ? "${_weather.windSpeed.toStringAsFixed(0)} km/s (Hamle: ${_weather.windGusts.toStringAsFixed(0)})"
                          : "${_weather.windSpeed.toStringAsFixed(0)} km/s",
                      style: TextStyle(
                        color: _weather.windGusts >= 55 ? Colors.redAccent : Colors.white70,
                        fontSize: 11.5,
                        fontWeight: _weather.windGusts >= 55 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),

                    // DİNAMİK TUTUŞ ROZETİ
                    NeuBadge(
                      text: "Tutuş %${_weather.gripPercent}",
                      icon: _weather.isBanRisk ? Icons.block : Icons.speed,
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

                // 3. AÇILIR DETAY KUTUSU
                if (_isExpanded) ...[
                  const Divider(height: 16),

                  // EĞER TEHLİKE VEYA YASAK VARSA AÇIKLAMA KUTUSU
                  if (_weather.isBanRisk || _weather.isDangerous) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _weather.isBanRisk
                            ? Colors.red.withValues(alpha: 0.16)
                            : Colors.deepOrange.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _weather.isBanRisk ? Colors.redAccent : Colors.deepOrangeAccent,
                          width: 1.1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _weather.isBanRisk ? Icons.emergency : Icons.warning_rounded,
                                color: _weather.isBanRisk ? Colors.redAccent : Colors.deepOrangeAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _weather.isBanRisk
                                      ? "FIRTINA & MOTOSİKLET YASAĞI UYARISI"
                                      : "YOL VE SÜRÜŞ GÜVENLİĞİ UYARISI",
                                  style: TextStyle(
                                    color: _weather.isBanRisk ? Colors.redAccent : Colors.deepOrangeAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _weather.safetyWarning,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.4),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.amber, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _weather.isBanRisk
                                      ? "İstanbul Boğaz köprülerinde, viyadüklerde ve sahil yollarında ani şiddetli hamleler devrilmeye sebep olabilir. Valilik yasaklarına uyunuz."
                                      : "Islak asfalt üzerinde beyaz yol çizgileri ve metal mazgallar sıfır tutuşa düşer. Yatış açısından kaçının.",
                                  style: const TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // DETAYLI ÖLÇÜM KARTLARI
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
                          label: "Rüzgar & Yön",
                          value: "${_weather.windDirection}\n(Hamle: ${_weather.windGusts.toStringAsFixed(0)} km/s)",
                          color: _weather.windGusts >= 55 ? Colors.redAccent : NeuColors.accentCyan,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.thermostat_outlined,
                          label: "Asfalt & Tutuş",
                          value: "${_weather.asphaltTemp.toStringAsFixed(0)}°C\n${_weather.gripStatus}",
                          color: _weather.gripColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // CANLI DURUM & SORUMLULUK REDDİ BUTONU
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _weather.isBanRisk ? Colors.redAccent : NeuColors.accentGreen,
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
                                  Text(
                                    "Yasal Uyarı",
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                              style: TextStyle(
                                color: NeuColors.accentOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
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
                      "⚠️ Meteorolojik tahminlerdir. Sürüş kararı ve yol güvenliği tamamen sürücüye aittir.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 9.5, height: 1.2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
