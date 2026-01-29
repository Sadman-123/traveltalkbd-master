import 'package:flutter/material.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';
import 'package:traveltalkbd/mobile_related/travel_detail_screen.dart';

class MobileHomePackages extends StatelessWidget {
  const MobileHomePackages({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TravelContent>(
      future: TravelDataService.getContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Unable to load packages'));
        }

        final content = snapshot.data!;
        final tourPackages = content.tourPackages.values.toList();
        final visaPackages = content.visaPackages.values.toList();

        void _openTourDetails(BuildContext context, TourPackage pkg) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TravelDetailScreen(
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
              builder: (_) => TravelDetailScreen(
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tour Packages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildGrid(
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
              ),
              const SizedBox(height: 16),
              const Text(
                'Visa Packages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildGrid(
                itemCount: visaPackages.length,
                itemBuilder: (context, index) {
                  final visa = visaPackages[index];
                  return _PackageCard(
                    imageUrl: visa.photo,
                    title: visa.title,
                    subtitle: visa.country,
                    badge: visa.processingTime,
                    priceText: visa.discountEnabled
                        ? '${visa.currency} ${visa.discountedPrice.toStringAsFixed(0)}'
                        : '${visa.currency} ${visa.price}',
                    originalPriceText: visa.discountEnabled
                        ? '${visa.currency} ${visa.price}'
                        : null,
                    imageBadge: visa.visaType.isNotEmpty ? visa.visaType : null,
                    onTap: () => _openVisaDetails(context, visa),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

}

Widget _buildGrid({
  required int itemCount,
  required Widget Function(BuildContext, int) itemBuilder,
}) {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      // Slightly taller cards to avoid text overflow on smaller devices
      childAspectRatio: 0.7,
    ),
    itemCount: itemCount,
    itemBuilder: itemBuilder,
  );
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
    final priceColor = _hovered ? Colors.white : Colors.blue;
    final badgeBg = _hovered ? Colors.white.withOpacity(0.18) : Colors.blue.shade50;
    final badgeBorder =
        _hovered ? Border.all(color: Colors.white.withOpacity(0.25)) : null;
    final badgeTextColor = _hovered ? Colors.white : Colors.blue;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        elevation: _hovered ? 8 : 2,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
                          ? Image.network(widget.imageUrl, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                      if (widget.imageBadge != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.imageBadge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
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
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
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
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: widget.originalPriceText != null
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      widget.originalPriceText!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: (titleColor == Colors.white ? Colors.white54 : Colors.grey),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.priceText,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: priceColor,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  widget.priceText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: priceColor,
                                  ),
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
    );
  }
}