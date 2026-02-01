import 'package:flutter/material.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';

/// Our Services grid: 2 boxes in row 1, 3 boxes in row 2.
/// Each box: icon top-left, title, subtitle, faint background icon top-right.
class WebServicesGrid extends StatelessWidget {
  final List<ServiceItem> services;

  const WebServicesGrid({super.key, required this.services});

  static IconData _iconForService(String title) {
    final t = title.toLowerCase();
    if (t.contains('visa')) return Icons.description_outlined;
    if (t.contains('tour') || t.contains('package')) return Icons.luggage_outlined;
    if (t.contains('hotel')) return Icons.hotel_outlined;
    if (t.contains('air') || t.contains('flight') || t.contains('ticket')) return Icons.flight_outlined;
    if (t.contains('transfer') || t.contains('car') || t.contains('transport')) return Icons.directions_car_outlined;
    return Icons.work_outline;
  }

  Widget _buildServiceCard(ServiceItem item) {
    final icon = _iconForService(item.title);
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Faint background icon (top right corner)
          Positioned(
            top: 8,
            right: 8,
            child: Icon(
              icon,
              size: 72,
              color: Colors.grey.shade300.withOpacity(0.6),
            ),
          ),
          // Card content - icon, title, subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.blue.shade800, size: 28),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              if (item.subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final row1 = services.take(2).toList();
    final row2 = services.skip(2).take(3).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          if (row1.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < 2; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 0 ? 10 : 0, left: i == 1 ? 10 : 0),
                      child: i < row1.length ? _buildServiceCard(row1[i]) : const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          if (row2.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < 3; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < 2 ? 7 : 0,
                        left: i > 0 ? 7 : 0,
                      ),
                      child: i < row2.length ? _buildServiceCard(row2[i]) : const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ],
        ],
    );
  }
}
