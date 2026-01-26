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
          final visaPackages = content.visaPackages.values.toList();

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
                          priceText: '${pkg.currency} ${pkg.price}',
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
                          priceText: '${visa.currency} ${visa.price}',
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

class _PackageCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String badge;
  final String priceText;
  final VoidCallback? onTap;

  const _PackageCard({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.priceText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 11,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      priceText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
