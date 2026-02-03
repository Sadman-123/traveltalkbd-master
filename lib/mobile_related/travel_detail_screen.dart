import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/screens/auth/login_screen.dart';
import 'package:traveltalkbd/services/auth_service.dart';
import 'data/travel_models.dart';
import 'components/booking_dialog.dart';

class TravelDetailScreen extends StatefulWidget {
  final SearchItem item;
  final bool isAlreadyBooked;

  const TravelDetailScreen({super.key, required this.item, this.isAlreadyBooked = false});

  @override
  State<TravelDetailScreen> createState() => _TravelDetailScreenState();
}

class _TravelDetailScreenState extends State<TravelDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;
  String _selectedVisaCategory = 'businessPerson';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget details;
    switch (widget.item.type) {
      case 'tour':
        details = _buildTourDetails(widget.item.payload as TourPackage);
        break;
      case 'visa':
        details = _buildVisaDetails(widget.item.payload as VisaPackage);
        break;
      case 'destination':
        details = _buildDestinationDetails(widget.item.payload as Destination);
        break;
      default:
        details = const Text('Details unavailable');
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Traveltalktheme.primaryGradient,
          ),
        ),
        title: Text(
          widget.item.title,
          style: const TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoGallery(widget.item),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.grey[600], size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.item.subtitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Details Section
                        details,
                        const SizedBox(height: 80), // Space for the bottom button
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fixed Book Now / Booked Successfully Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.isAlreadyBooked ? null : () async {
                    if (!AuthService().isSignedIn) {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(returnToBooking: true),
                        ),
                      );
                      if (!mounted || result != true) return;
                    }
                    if (!mounted) return;
                    if (AuthService().isEmailPasswordUser && !AuthService().isEmailVerified) {
                      final go = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Verify your email'),
                          content: const Text(
                            'Please verify your email address before making a booking. Check your inbox for the verification link, or go to Profile to resend it.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Go to Profile'),
                            ),
                          ],
                        ),
                      );
                      if (mounted && go == true) Get.toNamed('/profile');
                      return;
                    }
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (context) => BookingDialog(
                        itemId: widget.item.id,
                        itemTitle: widget.item.title,
                        itemType: widget.item.type,
                        visaPackage: widget.item.type == 'visa' ? widget.item.payload as VisaPackage? : null,
                        itemImageUrl: widget.item.imageUrl,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: widget.isAlreadyBooked ? Colors.green : Colors.purple,
                    disabledBackgroundColor: Colors.green.shade300,
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.isAlreadyBooked ? Icons.check_circle : Icons.book_online, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        widget.isAlreadyBooked ? 'Booked Successfully' : 'Book Now',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(SearchItem item) {
    List<String> photos = [];
    
    // Get photos from payload based on type
    if (item.payload is Destination) {
      photos = (item.payload as Destination).photos;
    } else if (item.payload is TourPackage) {
      photos = (item.payload as TourPackage).photos;
    } else if (item.payload is VisaPackage) {
      photos = (item.payload as VisaPackage).photos;
    } else if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      photos = [item.imageUrl!];
    }
    
    if (photos.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 48,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Image Carousel
        SizedBox(
          height: 300,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: photos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPhotoIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    photos[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // Photo Counter (if multiple photos)
              if (photos.length > 1)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPhotoIndex + 1} / ${photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Page Indicators
              if (photos.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(photos.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPhotoIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
        // Thumbnail Strip (if multiple photos)
        if (photos.length > 1) ...[
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentPhotoIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: index < photos.length - 1 ? 12 : 0),
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Stack(
                        children: [
                          Image.network(
                            photos[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, size: 20),
                                ),
                              );
                            },
                          ),
                          if (isSelected)
                            Container(
                              color: Colors.blue.withOpacity(0.2),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTourDetails(TourPackage pkg) {
    String price = '${pkg.currency} ${pkg.price}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price Highlight
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.attach_money, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Package Price',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Package Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(Icons.access_time, 'Duration', pkg.duration),
        const SizedBox(height: 12),
        _buildDetailRow(
          Icons.star,
          'Rating',
          '${pkg.rating.toStringAsFixed(1)} / 5.0',
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          Icons.check_circle,
          'Availability',
          pkg.available ? 'Available' : 'Not Available',
          color: pkg.available ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  String _formatEntryTypeLabel(String key) {
    switch (key) {
      case 'singleEntry': return 'Single Entry';
      case 'doubleEntry': return 'Double Entry';
      case 'multipleEntry': return 'Multiple Entry';
      default: return key;
    }
  }

  Widget _buildVisaDetails(VisaPackage visa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price / Entry Types
        if (visa.hasEntryTypes) ...[
          const Text(
            'Visa Prices by Entry Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: visa.sortedEnabledEntryTypes.map((e) {
                final label = _formatEntryTypeLabel(e.key);
                num displayPrice = e.value.price;
                if (visa.discountEnabled && visa.discountPercent > 0) {
                  displayPrice = (e.value.price * (1 - visa.discountPercent / 100)).clamp(0, double.infinity);
                } else if (visa.discountEnabled && visa.discountAmount > 0) {
                  displayPrice = (e.value.price - visa.discountAmount).clamp(0, double.infinity);
                }
                final price = '${visa.currency} ${displayPrice.toStringAsFixed(0)}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_money, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visa Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${visa.currency} ${visa.discountEnabled ? visa.discountedPrice.toStringAsFixed(0) : visa.price}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        const Text(
          'Visa Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (visa.visaType.isNotEmpty)
          _buildDetailRow(Icons.article, 'Visa Type', visa.visaType),
        if (visa.visaType.isNotEmpty) const SizedBox(height: 12),
        if (visa.validity.isNotEmpty)
          _buildDetailRow(Icons.calendar_today, 'Validity', visa.validity),
        if (visa.validity.isNotEmpty) const SizedBox(height: 12),
        if (visa.processingTime.isNotEmpty)
          _buildDetailRow(
            Icons.schedule,
            'Processing Time',
            visa.processingTime,
          ),
        const SizedBox(height: 20),
        // Documents sections
        if (visa.generalDocuments.isNotEmpty || visa.categoryDocuments.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (visa.generalDocuments.isNotEmpty) ...[
                const Text(
                  'General Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGeneralDocumentsBox(visa.generalDocuments),
                const SizedBox(height: 20),
              ],
              if (visa.categoryDocuments.isNotEmpty)
                _buildCategoryDocumentsBox(visa),
            ],
          )
        else if (visa.requiredDocuments.isNotEmpty) ...[
          const Text(
            'Required Documents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildLegacyDocumentsBox(visa.requiredDocuments),
        ],
      ],
    );
  }

  Widget _buildGeneralDocumentsBox(List<VisaDocumentItem> docs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: docs.map((doc) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (doc.subtitles.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...doc.subtitles.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '• $s',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryDocumentsBox(VisaPackage visa) {
    const categoryLabels = <String, String>{
      'businessPerson': 'Business person',
      'student': 'Student',
      'jobHolder': 'Job holder',
    };
    final categoriesOrder = categoryLabels.keys.toList();
    if (!categoriesOrder.contains(_selectedVisaCategory)) {
      _selectedVisaCategory = categoriesOrder.first;
    }
    final selectedDocs = visa.categoryDocuments[_selectedVisaCategory] ?? const <VisaDocumentItem>[];
    final otherDocs = visa.categoryDocuments['other'] ?? const <VisaDocumentItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documents by visa category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle-like buttons
              Wrap(
                spacing: 8,
                children: categoriesOrder.map((key) {
                  final label = categoryLabels[key]!;
                  final selected = _selectedVisaCategory == key;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedVisaCategory = key;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (selectedDocs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No documents found for this category',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                _buildGeneralDocumentsBox(selectedDocs),
              if (otherDocs.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Other documents (if applicable)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildGeneralDocumentsBox(otherDocs),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegacyDocumentsBox(List<String> docs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: docs.map((doc) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    doc,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDestinationDetails(Destination dest) {
    String price = '${dest.currency} ${dest.startingPrice}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price Highlight
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.attach_money, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Starting Price',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'About This Destination',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          dest.shortDescription,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Travel Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          Icons.calendar_today,
          'Best Time to Visit',
          dest.bestTimeToVisit.isNotEmpty
              ? dest.bestTimeToVisit
              : 'Anytime',
        ),
        if (dest.popularFor.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Popular For',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dest.popularFor.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Colors.blue.shade50,
                labelStyle: TextStyle(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
