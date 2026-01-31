import 'package:flutter/material.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';
import 'package:traveltalkbd/web_related/web_travel_detail_screen.dart';

class WebHomePackages extends StatelessWidget {
  const WebHomePackages({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      color: Colors.grey[50],
      child: FutureBuilder<TravelContent>(
        future: TravelDataService.getContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(80.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(80.0),
                child: Text(
                  'Unable to load packages',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            );
          }

          final content = snapshot.data!;
          final tourPackages = content.tourPackages.values.toList();
          final visaPackages = content.visaPackages.values
              .where((v) => v.available && (v.hasEntryTypes || v.entryTypes.isEmpty))
              .toList();

          void _openTourDetails(BuildContext context, TourPackage pkg) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WebTravelDetailScreen(
                  item: SearchItem(
                    id: pkg.id,
                    title: pkg.title,
                    subtitle: '${pkg.city}, ${pkg.country}',
                    type: 'tour',
                    imageUrl: pkg.photo,
                    payload: pkg,
                  ),
                ),
              ),
            );
          }

          void _openVisaDetails(BuildContext context, VisaPackage visa) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WebTravelDetailScreen(
                  item: SearchItem(
                    id: visa.id,
                    title: visa.title,
                    subtitle: visa.country,
                    type: 'visa',
                    imageUrl: visa.photo,
                    payload: visa,
                  ),
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
                // Tour Packages Section
                const Text(
                  'Tour Packages',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Discover amazing tour packages for your next adventure',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 50),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    int crossAxisCount = 4;
                    if (screenWidth < 1200) {
                      crossAxisCount = 3;
                    }
                    if (screenWidth < 900) {
                      crossAxisCount = 2;
                    }
                    if (screenWidth < 600) {
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
                      itemCount: tourPackages.length,
                      itemBuilder: (context, index) {
                        final pkg = tourPackages[index];
                        return _PackageCard(
                          imageUrl: pkg.photo,
                          title: pkg.title,
                          subtitle: '${pkg.city}, ${pkg.country}',
                          badge: pkg.duration,
                          priceText: pkg.discountEnabled
                              ? '${pkg.currency} ${pkg.discountedPrice.toStringAsFixed(0)}'
                              : '${pkg.currency} ${pkg.price}',
                          originalPriceText: pkg.discountEnabled
                              ? '${pkg.currency} ${pkg.price}'
                              : null,
                          imageBadge: null,
                          onTap: () => _openTourDetails(context, pkg),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 80),
                // Visa Packages Section
                const Text(
                  'Visa Packages',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Get your visa processed quickly and easily',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 50),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    int crossAxisCount = 4;
                    if (screenWidth < 1200) {
                      crossAxisCount = 3;
                    }
                    if (screenWidth < 900) {
                      crossAxisCount = 2;
                    }
                    if (screenWidth < 600) {
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
                      itemCount: visaPackages.length,
                      itemBuilder: (context, index) {
                        final visa = visaPackages[index];
                        return _PackageCard(
                          imageUrl: visa.photo,
                          title: visa.title,
                          subtitle: visa.country,
                          badge: visa.processingTime,
                          priceText: visa.priceDisplayText(visa.currency),
                          originalPriceText: visa.discountEnabled && !visa.hasEntryTypes
                              ? '${visa.currency} ${visa.price}'
                              : null,
                          imageBadge: visa.visaType.isNotEmpty ? visa.visaType : null,
                          onTap: () => _openVisaDetails(context, visa),
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
}

class _PackageCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String badge;
  final String priceText;
  final String? originalPriceText;
  final String? imageBadge;
  final VoidCallback? onTap;

  const _PackageCard({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.priceText,
    this.originalPriceText,
    this.imageBadge,
    this.onTap,
  });

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
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
    final titleColor = _hovered ? Colors.white : Colors.black87;
    final subtitleColor = _hovered ? Colors.white70 : Colors.grey.shade600;
    final priceColor = _hovered ? Colors.white : Colors.blue.shade700;
    final badgeBg = _hovered ? Colors.white.withOpacity(0.18) : Colors.blue.shade50;
    final badgeBorder =
        _hovered ? Border.all(color: Colors.white.withOpacity(0.25)) : null;
    final badgeTextColor = _hovered ? Colors.white : Colors.blue.shade700;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Material(
          elevation: _hovered ? 10 : 4,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: _hovered ? _hoverGradient : null,
                color: _hovered ? null : Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 11,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                        if (widget.imageBadge != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.imageBadge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(8),
                              border: badgeBorder,
                            ),
                            child: Text(
                              widget.badge,
                              style: TextStyle(
                                fontSize: 12,
                                color: badgeTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Flexible(
                            child: Text(
                              widget.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              widget.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (widget.originalPriceText != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  widget.originalPriceText!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: (titleColor == Colors.white ? Colors.white54 : Colors.grey),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.priceText,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: priceColor,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              widget.priceText,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: priceColor,
                              ),
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
}
