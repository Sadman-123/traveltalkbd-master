import 'dart:async';
import 'package:flutter/material.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';

class WebHomeAbout extends StatefulWidget {
  const WebHomeAbout({super.key});

  @override
  State<WebHomeAbout> createState() => _WebHomeAboutState();
}

class _WebHomeAboutState extends State<WebHomeAbout> {
  Timer? _carouselTimer;
  int _currentReviewIndex = 0;

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentReviewIndex = (_currentReviewIndex + 1) % reviews.length;
        });
      }
    });
  }

  void _goToReview(int index) {
    setState(() {
      _currentReviewIndex = index;
    });
    _carouselTimer?.cancel();
    _startCarousel();
  }

  final List<Map<String, dynamic>> reviews = [
    {
      "name": "Rahim Ahmed",
      "gender": "male",
      "photo": "https://randomuser.me/api/portraits/men/32.jpg",
      "location": "Dhaka, Bangladesh",
      "rating": 5,
      "review":
          "Serviceটা honestly amazing! Tour guide was very friendly. পুরো tripটা stress free ছিল। Highly recommended!"
    },
    {
      "name": "Nusrat Jahan",
      "gender": "female",
      "photo": "https://randomuser.me/api/portraits/women/45.jpg",
      "location": "Chittagong, Bangladesh",
      "rating": 4,
      "review":
          "Hotel and transport ভালো ছিল। Pickup-এ একটু delay হয়েছিল, but overall experience pretty good."
    },
    {
      "name": "Tanvir Hasan",
      "gender": "male",
      "photo": "https://randomuser.me/api/portraits/men/18.jpg",
      "location": "Sylhet, Bangladesh",
      "rating": 5,
      "review":
          "Visa processingটা super fast! কোন hassle ছাড়াই হয়ে গেছে। Trusted service 👍"
    },
    {
      "name": "Ayesha Rahman",
      "gender": "female",
      "photo": "https://randomuser.me/api/portraits/women/29.jpg",
      "location": "Khulna, Bangladesh",
      "rating": 4,
      "review":
          "Family tour এর জন্য perfect arrangement ছিল। Hotel quality ভালো লেগেছে।"
    },
    {
      "name": "Fahim Chowdhury",
      "gender": "male",
      "photo": "https://randomuser.me/api/portraits/men/40.jpg",
      "location": "Dhaka, Bangladesh",
      "rating": 5,
      "review":
          "Best travel agency so far! Communication খুব clear ছিল এবং সব কিছু on time পেয়েছি।"
    },
    {
      "name": "Arif Hossain",
      "gender": "male",
      "photo": "https://randomuser.me/api/portraits/men/55.jpg",
      "location": "Kuala Lumpur, Malaysia",
      "rating": 5,
      "review":
          "Amazing experience! Airport pickup smooth ছিল। Totally satisfied."
    },
    {
      "name": "Sadia Karim",
      "gender": "female",
      "photo": "https://randomuser.me/api/portraits/women/61.jpg",
      "location": "Selangor, Malaysia",
      "rating": 4,
      "review":
          "Tour scheduleটা well planned ছিল। একটু busy লাগছিল, but really enjoyed."
    },
    {
      "name": "Imran Mahmud",
      "gender": "male",
      "photo": "https://randomuser.me/api/portraits/men/67.jpg",
      "location": "Penang, Malaysia",
      "rating": 5,
      "review":
          "Very professional team. সব details আগে থেকেই explain করা হয়েছিল। No hidden cost!"
    },
    {
      "name": "Nabila Sultana",
      "gender": "female",
      "photo": "https://randomuser.me/api/portraits/women/73.jpg",
      "location": "Johor Bahru, Malaysia",
      "rating": 4,
      "review":
          "Good service and friendly behavior। Hotel locationটা especially ভালো ছিল।"
    },
    {
      "name": "Hasan Ali",
      "gender": "male",
      "photo": "https://randomuser.me/api/portraits/men/80.jpg",
      "location": "Kuala Lumpur, Malaysia",
      "rating": 5,
      "review":
          "Everything was perfect from booking to return. Highly recommended 🇧🇩➡🇲🇾"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      color: Colors.white,
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
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.aboutInfo == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(80.0),
                child: Text(
                  'Unable to load about info',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            );
          }

          final about = snapshot.data!.aboutInfo!;
          return Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            about.companyName,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            about.tagline,
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (about.rating > 0)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  about.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Rating',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 40),
                // Description
                Text(
                  about.description,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 50),
                // Mission and Vision
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.flag,
                                  color: Colors.blue.shade700,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Mission',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              about.mission,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.visibility,
                                  color: Colors.green.shade700,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Vision',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              about.vision,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                // Why Choose Us
                const Text(
                  'Why Choose Us',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: about.whyChooseUs.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 50),
                // Services
                const Text(
                  'Our Services',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: about.services.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.work_outline,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 50),
                // Reviews Section
                const Text(
                  'What Our Customers Say',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _ReviewsCarousel(
                  reviews: reviews,
                  currentIndex: _currentReviewIndex,
                  onPageChanged: _goToReview,
                ),
                const SizedBox(height: 50),
                // Contact Information
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Us',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (about.contact['phone'] != null)
                        _ContactItem(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: about.contact['phone'].toString(),
                        ),
                      if (about.contact['email'] != null) ...[
                        const SizedBox(height: 16),
                        _ContactItem(
                          icon: Icons.email,
                          label: 'Email',
                          value: about.contact['email'].toString(),
                        ),
                      ],
                      if (about.contact['address'] != null) ...[
                        const SizedBox(height: 16),
                        _ContactItem(
                          icon: Icons.location_on,
                          label: 'Address',
                          value: about.contact['address'].toString(),
                        ),
                      ],
                      if (about.establishedYear > 0) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Established in ${about.establishedYear}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReviewsCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;
  final int currentIndex;
  final Function(int) onPageChanged;

  const _ReviewsCarousel({
    required this.reviews,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final review = reviews[currentIndex];
    final rating = review['rating'] as int;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Review Card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Rating Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 28,
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Review Text
                Text(
                  review['review'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Reviewer Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile Photo
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                        review['photo'] as String,
                      ),
                      onBackgroundImageError: (_, __) {},
                    ),
                    const SizedBox(width: 16),
                    // Name and Location
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['name'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              review['location'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Carousel Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(reviews.length, (index) {
              return GestureDetector(
                onTap: () => onPageChanged(index),
                child: Container(
                  width: currentIndex == index ? 32 : 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? Colors.blue.shade600
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
