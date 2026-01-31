import 'package:flutter/material.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';
import 'package:traveltalkbd/web_related/components/web_booking_dialog.dart';

class WebTravelDetailScreen extends StatefulWidget {
  final SearchItem item;

  const WebTravelDetailScreen({super.key, required this.item});

  @override
  State<WebTravelDetailScreen> createState() => _WebTravelDetailScreenState();
}

class _WebTravelDetailScreenState extends State<WebTravelDetailScreen> {
  int _selectedPhotoIndex = 0;

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
      backgroundColor: Colors.white,
      appBar: AppBar(
         flexibleSpace: Container(
    decoration:  BoxDecoration(
      gradient: Traveltalktheme.primaryGradient
    ),
  ),
        title: Text(
          widget.item.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side - Images Gallery
              Expanded(
                flex: 1,
                child: _buildPhotoGallery(widget.item),
              ),
              const SizedBox(width: 40),
              // Right Side - Content
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.grey[600], size: 18),
                        const SizedBox(width: 6),
                        Text(
                          widget.item.subtitle,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Details Section
                    details,
                    const SizedBox(height: 32),
                    // Book Now Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => WebBookingDialog(
                              itemId: widget.item.id,
                              itemTitle: widget.item.title,
                              itemType: widget.item.type,
                              visaPackage: widget.item.type == 'visa' ? widget.item.payload as VisaPackage? : null,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          backgroundColor: Colors.blue.shade700,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.book_online, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Book Now',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        height: 600,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    // Reset index if out of bounds
    if (_selectedPhotoIndex >= photos.length) {
      _selectedPhotoIndex = 0;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Image Display
        Container(
          height: 500,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Main Image
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Image.network(
                    photos[_selectedPhotoIndex],
                    key: ValueKey(photos[_selectedPhotoIndex]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Navigation Arrows (if multiple photos)
                if (photos.length > 1) ...[
                  // Left Arrow
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPhotoIndex = (_selectedPhotoIndex - 1 + photos.length) % photos.length;
                            });
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.chevron_left, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Right Arrow
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPhotoIndex = (_selectedPhotoIndex + 1) % photos.length;
                            });
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.chevron_right, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                        '${_selectedPhotoIndex + 1} / ${photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Thumbnail Grid (if multiple photos)
        if (photos.length > 1) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedPhotoIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPhotoIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: index < photos.length - 1 ? 12 : 0),
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
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
                                  child: Icon(Icons.image_not_supported, size: 24),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.attach_money, color: Colors.blue.shade700, size: 28),
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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Package Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(Icons.access_time, 'Duration', pkg.duration),
        const SizedBox(height: 16),
        _buildDetailRow(
          Icons.star,
          'Rating',
          '${pkg.rating.toStringAsFixed(1)} / 5.0',
        ),
        const SizedBox(height: 16),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
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
                final price = '${visa.currency} ${e.value.price.toStringAsFixed(0)}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 18,
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_money, color: Colors.blue.shade700, size: 28),
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
                        fontSize: 22,
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
        const SizedBox(height: 24),
        const Text(
          'Visa Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (visa.visaType.isNotEmpty)
          _buildDetailRow(Icons.article, 'Visa Type', visa.visaType),
        if (visa.visaType.isNotEmpty) const SizedBox(height: 16),
        if (visa.validity.isNotEmpty)
          _buildDetailRow(Icons.calendar_today, 'Validity', visa.validity),
        if (visa.validity.isNotEmpty) const SizedBox(height: 16),
        if (visa.processingTime.isNotEmpty)
          _buildDetailRow(
            Icons.schedule,
            'Processing Time',
            visa.processingTime,
          ),
        if (visa.requiredDocuments.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Required Documents',
            style: TextStyle(
              fontSize: 20,
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
              children: visa.requiredDocuments.map((doc) {
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
          ),
        ],
      ],
    );
  }

  Widget _buildDestinationDetails(Destination dest) {
    String price = '${dest.currency} ${dest.startingPrice}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price Highlight
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.attach_money, color: Colors.blue.shade700, size: 28),
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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'About This Destination',
          style: TextStyle(
            fontSize: 20,
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
        const SizedBox(height: 24),
        const Text(
          'Travel Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          Icons.calendar_today,
          'Best Time to Visit',
          dest.bestTimeToVisit.isNotEmpty
              ? dest.bestTimeToVisit
              : 'Anytime',
        ),
        if (dest.popularFor.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Popular For',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: dest.popularFor.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Colors.blue.shade50,
                labelStyle: TextStyle(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
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
                    fontSize: 16,
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
