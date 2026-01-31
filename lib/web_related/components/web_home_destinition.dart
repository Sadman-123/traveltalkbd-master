import 'package:flutter/material.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';
import 'package:traveltalkbd/web_related/web_travel_detail_screen.dart';

class WebHomeDestinition extends StatelessWidget {
  const WebHomeDestinition({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      decoration: const BoxDecoration(
  color: Color(0xFFFBEFEF)

      ),
      child: FutureBuilder<TravelContent>(
        future: TravelDataService.getContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(80.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(80.0),
                child: Text(
                  'Unable to load destinations',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            );
          }

          final destinations = snapshot.data!.destinations.values
              .where((d) => d.available)
              .toList();

          if (destinations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(80.0),
                child: Text(
                  'No destinations available right now',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            );
          }

          return Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top Destinations',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Explore curated places to visit around the world',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 50),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    int crossAxisCount = 4;
                    if (screenWidth < 1000) {
                      crossAxisCount = 3;
                    }
                    if (screenWidth < 700) {
                      crossAxisCount = 2;
                    }
                    if (screenWidth < 500) {
                      crossAxisCount = 1;
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: destinations.length,
                      itemBuilder: (context, index) {
                        final dest = destinations[index];
                        return _DestinationCard(
                          destination: dest,
                          onTap: () => _openDetails(context, dest),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openDetails(BuildContext context, Destination dest) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebTravelDetailScreen(
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_hovered ? 0.42 : 0.3),
                  blurRadius: _hovered ? 28 : 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
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
                          Colors.black.withOpacity(0.7),
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
                    child: _badge(
                      dest.bestTimeToVisit.isNotEmpty ? dest.bestTimeToVisit : 'Anytime',
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.place, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${dest.name}, ${dest.country}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
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
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  discountedPrice,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}
