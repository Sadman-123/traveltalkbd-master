import 'package:flutter/material.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';

/// Our Services grid: 2 boxes in row 1, 3 boxes in row 2.
/// Each box: icon top-left, title, subtitle, faint background icon top-right.
class WebServicesGrid extends StatelessWidget {
  final List<ServiceItem> services;

  const WebServicesGrid({super.key, required this.services});

  Widget _buildServiceCard(ServiceItem item) {
    return _HoverableServiceCard(item: item);
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

class _HoverableServiceCard extends StatefulWidget {
  final ServiceItem item;

  const _HoverableServiceCard({required this.item});

  @override
  State<_HoverableServiceCard> createState() => _HoverableServiceCardState();
}

class _HoverableServiceCardState extends State<_HoverableServiceCard> {
  bool _isHovered = false;

  static IconData _iconForService(String title) {
    final t = title.toLowerCase();
    if (t.contains('visa')) return Icons.description_outlined;
    if (t.contains('tour') || t.contains('package')) return Icons.luggage_outlined;
    if (t.contains('hotel')) return Icons.hotel_outlined;
    if (t.contains('air') || t.contains('flight') || t.contains('ticket')) return Icons.flight_outlined;
    if (t.contains('transfer') || t.contains('car') || t.contains('transport')) return Icons.directions_car_outlined;
    return Icons.work_outline;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconForService(widget.item.title);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 200,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.primary : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? Colors.white.withOpacity(0.5) : Colors.blue.shade100,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.04),
              blurRadius: _isHovered ? 12 : 8,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                icon,
                size: 72,
                color: _isHovered ? Colors.white.withOpacity(0.3) : Colors.grey.shade300.withOpacity(0.6),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: _isHovered ? Colors.white : Colors.blue.shade800, size: 28),
                const SizedBox(height: 12),
                Text(
                  widget.item.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isHovered ? Colors.white : Colors.blue.shade900,
                  ),
                ),
                if (widget.item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.item.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: _isHovered ? Colors.white.withOpacity(0.9) : Colors.grey.shade700,
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
      ),
    );
  }
}
