import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';
import 'package:traveltalkbd/mobile_related/travel_detail_screen.dart';

class MobileHomePackages extends StatelessWidget {
  /// When true, renders without SingleChildScrollView for embedding in a parent scroll.
  final bool embedded;

  const MobileHomePackages({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final isEmbedded = embedded;
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
        final visaPackages = content.visaPackages.values
            .where((v) => v.available && (v.hasEntryTypes || v.entryTypes.isEmpty))
            .toList();

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

        final column = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Tour Packages',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Explore our curated tour packages',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              _buildGrid(
                itemCount: tourPackages.length,
                childAspectRatio: 0.8,
                itemBuilder: (context, index) {
                  final pkg = tourPackages[index];
                  return _TourPackageCard(
                    imageUrl: pkg.photo,
                    title: pkg.title,
                    durationText: pkg.duration,
                    subtitle: '${pkg.city}, ${pkg.country}',
                    priceText: pkg.discountEnabled
                        ? '${pkg.currency} ${pkg.discountedPrice.toStringAsFixed(0)}'
                        : '${pkg.currency} ${pkg.price}',
                    durationBadge: pkg.duration.isNotEmpty ? pkg.duration : null,
                    discountBadge: pkg.discountEnabled && (pkg.discountPercent > 0 || pkg.discountAmount > 0)
                        ? (pkg.discountPercent > 0
                            ? '${pkg.discountPercent.toStringAsFixed(0)}% Off'
                            : '${pkg.discountAmount.toStringAsFixed(0)} ${pkg.currency} Off')
                        : null,
                    onTap: () => _openTourDetails(context, pkg),
                  );
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Visa Packages',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Visa assistance and processing services',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              _buildGrid(
                itemCount: visaPackages.length,
                childAspectRatio: 0.8,
                itemBuilder: (context, index) {
                  final visa = visaPackages[index];
                  return _VisaPackageCard(
                    imageUrl: visa.photo,
                    title: visa.title,
                    durationText: visa.processingTime,
                    priceText: visa.priceDisplayText(visa.currency),
                    visaTypeBadge: visa.visaType.isNotEmpty ? visa.visaType : null,
                    discountBadge: visa.discountEnabled && (visa.discountPercent > 0 || visa.discountAmount > 0)
                        ? (visa.discountPercent > 0
                            ? '${visa.discountPercent.toStringAsFixed(0)}% Off'
                            : '${visa.discountAmount.toStringAsFixed(0)} ${visa.currency} Off')
                        : null,
                    onTap: () => _openVisaDetails(context, visa),
                  );
                },
              ),
            ],
          );
        if (isEmbedded) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: column,
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: column,
        );
      },
    );
  }

}

Widget _buildGrid({
  required int itemCount,
  required Widget Function(BuildContext, int) itemBuilder,
  double childAspectRatio = 0.7,
}) {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: childAspectRatio,
    ),
    itemCount: itemCount,
    itemBuilder: itemBuilder,
  );
}

class _TourPackageCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String durationText;
  final String subtitle;
  final String priceText;
  final String? durationBadge;
  final String? discountBadge;
  final VoidCallback? onTap;

  const _TourPackageCard({
    required this.imageUrl,
    required this.title,
    required this.durationText,
    required this.subtitle,
    required this.priceText,
    this.durationBadge,
    this.discountBadge,
    this.onTap,
  });

  @override
  State<_TourPackageCard> createState() => _TourPackageCardState();
}

class _TourPackageCardState extends State<_TourPackageCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        elevation: _hovered ? 6 : 2,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardHeight = constraints.maxHeight;
              const collapsedBarHeight = 80.0;
              final collapsedTop = cardHeight - collapsedBarHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.imageUrl.isNotEmpty)
                    Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.35),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    top: _hovered ? 0 : collapsedTop,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF6B4E9A).withOpacity(0.12),
                                const Color(0xFF5A3D8A).withOpacity(0.22),
                                const Color(0xFF4A2E7A).withOpacity(0.28),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                            border: Border.all(
                              color: const Color(0xFF7B5EAA).withOpacity(0.15),
                              width: 0.5,
                            ),
                          ),
                          child: _hovered
                              ? Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          widget.title,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                                            ],
                                          ),
                                        ),
                                        if (widget.durationText.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            widget.durationText,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withOpacity(0.95),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        if (widget.subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.subtitle,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white.withOpacity(0.9),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          widget.priceText,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.visibility, size: 16, color: Colors.white.withOpacity(0.95)),
                                            const SizedBox(width: 6),
                                            Text(
                                              'View details',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withOpacity(0.95),
                                                shadows: const [
                                                  Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (widget.durationText.isNotEmpty)
                                            Text(
                                              widget.durationText,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white.withOpacity(0.95),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (widget.durationText.isNotEmpty) const SizedBox(height: 2),
                                          Text(
                                            widget.priceText,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                                              ],
                                            ),
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
                  if (widget.durationBadge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.durationBadge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (widget.discountBadge != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B4E9A), Color(0xFFE10098)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                        ),
                        child: Text(
                          widget.discountBadge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VisaPackageCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String durationText;
  final String priceText;
  final String? visaTypeBadge;
  final String? discountBadge;
  final VoidCallback? onTap;

  const _VisaPackageCard({
    required this.imageUrl,
    required this.title,
    required this.durationText,
    required this.priceText,
    this.visaTypeBadge,
    this.discountBadge,
    this.onTap,
  });

  @override
  State<_VisaPackageCard> createState() => _VisaPackageCardState();
}

class _VisaPackageCardState extends State<_VisaPackageCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        elevation: _hovered ? 6 : 2,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardHeight = constraints.maxHeight;
              const collapsedBarHeight = 80.0;
              final collapsedTop = cardHeight - collapsedBarHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Full image background - clear, no blur
                  if (widget.imageUrl.isNotEmpty)
                    Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                    ),
                  // Subtle gradient at bottom only
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.35),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Glass bottomsheet - pulls up on hover (like web)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    top: _hovered ? 0 : collapsedTop,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF6B4E9A).withOpacity(0.12),
                                const Color(0xFF5A3D8A).withOpacity(0.22),
                                const Color(0xFF4A2E7A).withOpacity(0.28),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                            border: Border.all(
                              color: const Color(0xFF7B5EAA).withOpacity(0.15),
                              width: 0.5,
                            ),
                          ),
                          child: _hovered
                              ? Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          widget.title,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                                            ],
                                          ),
                                        ),
                                        if (widget.durationText.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            widget.durationText,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withOpacity(0.95),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          widget.priceText,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.visibility, size: 16, color: Colors.white.withOpacity(0.95)),
                                            const SizedBox(width: 6),
                                            Text(
                                              'View details',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withOpacity(0.95),
                                                shadows: const [
                                                  Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (widget.durationText.isNotEmpty)
                                            Text(
                                              widget.durationText,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white.withOpacity(0.95),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (widget.durationText.isNotEmpty) const SizedBox(height: 2),
                                          Text(
                                            widget.priceText,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                                              ],
                                            ),
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
                  // Badges on top of glass so they stay visible
                  if (widget.visaTypeBadge != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.visaTypeBadge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
                  if (widget.discountBadge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B4E9A), Color(0xFFE10098)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                  ),
                  child: Text(
                    widget.discountBadge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
