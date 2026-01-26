import 'package:flutter/material.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';

class MobileHomeAbout extends StatelessWidget {
  const MobileHomeAbout({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TravelContent>(
      future: TravelDataService.getContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.aboutInfo == null) {
          return const Center(child: Text('Unable to load about info'));
        }

        final about = snapshot.data!.aboutInfo!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                about.companyName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(about.tagline),
              const SizedBox(height: 12),
              Text(about.description),
              const SizedBox(height: 12),
              Text('Mission: ${about.mission}'),
              Text('Vision: ${about.vision}'),
              const SizedBox(height: 12),
              const Text('Why choose us', style: TextStyle(fontWeight: FontWeight.bold)),
              ...about.whyChooseUs.map((item) => Text('• $item')),
              const SizedBox(height: 12),
              const Text('Services', style: TextStyle(fontWeight: FontWeight.bold)),
              ...about.services.map((item) => Text('• $item')),
              const SizedBox(height: 12),
              const Text('Contact', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Phone: ${about.contact['phone'] ?? ''}'),
              Text('Email: ${about.contact['email'] ?? ''}'),
              Text('Address: ${about.contact['address'] ?? ''}'),
            ],
          ),
        );
      },
    );
  }
}