import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';
import 'package:traveltalkbd/mobile_related/travel_detail_screen.dart';

class MobileHomeDestinition extends StatelessWidget {
  const MobileHomeDestinition({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBEFEF)
      ),
      child: SafeArea(
        child: FutureBuilder<TravelContent>(
          future: TravelDataService.getContent(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Unable to load destinations'));
            }

            final destinations = snapshot.data!.destinations.values
                .where((d) => d.available)
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));

            if (destinations.isEmpty) {
              return const Center(child: Text('No destinations available right now'));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Top Destinations',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Swipe to explore curated places to visit',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CardSwiper(
                    cardsCount: destinations.length,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    isLoop: true,
                    onSwipe: (prevIndex, currentIndex, direction) => true,
                    cardBuilder: (context, index, percentX, percentY) {
                      final dest = destinations[index];
                      return _DestinationCard(
                        destination: dest,
                        onTap: () => _openDetails(context, dest),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, Destination dest) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TravelDetailScreen(
          item: SearchItem(
            id: dest.id,
            title: dest.name,
            subtitle: dest.country,
            type: 'destination',
            imageUrl: dest.photo,
            payload: dest,
          ),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatefulWidget {
  final Destination destination;
  final VoidCallback onTap;

  const _DestinationCard({
    required this.destination,
    required this.onTap,
  });

  @override
  State<_DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<_DestinationCard> {
  static const _hoverGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF4A1E6A), // purple
      Color(0xFFE10098), // pink
    ],
  );

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dest = widget.destination;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_hovered ? 0.32 : 0.25),
                  blurRadius: _hovered ? 26 : 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildBackgroundImage(dest.photo),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        opacity: _hovered ? 0.55 : 0.0,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: _hoverGradient,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _priceChip(),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _badge(dest.bestTimeToVisit.isNotEmpty
                        ? dest.bestTimeToVisit
                        : 'Anytime'),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.place, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${dest.name}, ${dest.country}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dest.shortDescription,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: dest.popularFor.take(3).map((tag) {
                            return _badge(tag, subtle: true);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImage(String url) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFF1C2B50),
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.white54, size: 48),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFF1C2B50),
          child: const Center(
            child: Icon(Icons.image_not_supported, color: Colors.white54, size: 48),
          ),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFF1C2B50),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _badge(String label, {bool subtle = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: subtle ? Colors.white.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: subtle ? Colors.white.withOpacity(0.25) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: subtle ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _priceChip() {
    final destination = widget.destination;
    final hasDiscount = destination.discountEnabled;
    final originalPrice =
        '${destination.currency} ${destination.startingPrice.toStringAsFixed(0)}';
    final discountedPrice =
        '${destination.currency} ${destination.discountedStartingPrice.toStringAsFixed(0)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flight_takeoff, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          if (hasDiscount)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  originalPrice,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  discountedPrice,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            )
          else
            Text(
              originalPrice,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}