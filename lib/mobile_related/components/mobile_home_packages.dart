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
                    priceText: '${pkg.currency} ${pkg.price}',
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
                    priceText: '${visa.currency} ${visa.price}',
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
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 11,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported),
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        priceText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
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
    );
  }
}