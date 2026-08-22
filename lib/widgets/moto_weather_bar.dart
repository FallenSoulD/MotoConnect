import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: widget.margin,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.4), width: 1.2),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ÜST ÖZET ŞERİT
            Row(
              children: [
                const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                const Text(
                  "23°C",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 12,
                  width: 1,
                  color: Colors.white24,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.air, color: Colors.cyanAccent, size: 16),
                const SizedBox(width: 4),
                const Text(
                  "12 km/s",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed, color: Colors.greenAccent, size: 13),
                      SizedBox(width: 3),
                      Text(
                        "Tutuş %95",
                        style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white54,
                  size: 18,
                ),
              ],
            ),

            // AÇILIR DETAY KUTUSU
            if (_isExpanded) ...[
              const Divider(color: Colors.white12, height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.water_drop_outlined,
                      label: "Yağış",
                      value: "%0 (Kuru)",
                      color: Colors.blueAccent,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.navigation_outlined,
                      label: "Rüzgar",
                      value: "Güvenli (Kuzey)",
                      color: Colors.cyanAccent,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.thermostat_outlined,
                      label: "Asfalt Isısı",
                      value: "28°C (Optimal)",
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
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
