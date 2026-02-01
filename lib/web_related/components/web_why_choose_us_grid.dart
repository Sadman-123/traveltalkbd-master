import 'package:flutter/material.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';

/// Why Choose Us grid: 2 boxes in row 1, 3 boxes in row 2.
/// Same box style as Our Services - light grey, light blue border, icon top-left, faint background icon.
/// Each item is a single string (no subtitle).
class WebWhyChooseUsGrid extends StatelessWidget {
  final List<String> items;

  const WebWhyChooseUsGrid({super.key, required this.items});

  Widget _buildItemCard(String item) {
    return _HoverableWhyChooseUsCard(item: item);
  }

  @override
  Widget build(BuildContext context) {
    final row1 = items.take(2).toList();
    final row2 = items.skip(2).take(3).toList();
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
                    child: i < row1.length ? _buildItemCard(row1[i]) : const SizedBox.shrink(),
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
                    child: i < row2.length ? _buildItemCard(row2[i]) : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HoverableWhyChooseUsCard extends StatefulWidget {
  final String item;

  const _HoverableWhyChooseUsCard({required this.item});

  @override
  State<_HoverableWhyChooseUsCard> createState() => _HoverableWhyChooseUsCardState();
}

class _HoverableWhyChooseUsCardState extends State<_HoverableWhyChooseUsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
                Icons.check_circle_outline,
                size: 72,
                color: _isHovered ? Colors.white.withOpacity(0.3) : Colors.green.shade200.withOpacity(0.6),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isHovered ? Colors.white : Colors.blue.shade900,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
