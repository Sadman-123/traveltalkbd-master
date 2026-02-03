import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';
import 'package:traveltalkbd/screens/auth/login_screen.dart';
import 'package:traveltalkbd/services/auth_service.dart';
import 'package:traveltalkbd/web_related/components/web_booking_dialog.dart';

class WebTravelDetailScreen extends StatefulWidget {
  final SearchItem item;
  final bool isAlreadyBooked;

  const WebTravelDetailScreen({super.key, required this.item, this.isAlreadyBooked = false});

  @override
  State<WebTravelDetailScreen> createState() => _WebTravelDetailScreenState();
}

class _WebTravelDetailScreenState extends State<WebTravelDetailScreen> {
  int _selectedPhotoIndex = 0;
  String _selectedVisaCategory = 'businessPerson';

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
        centerTitle: false,
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
                    // Book Now / Booked Successfully Button
                    SizedBox(
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
                            builder: (context) => WebBookingDialog(
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
                          elevation: 4,
                          backgroundColor: widget.isAlreadyBooked ? Colors.green : Colors.blue.shade700,
                          disabledBackgroundColor: Colors.green.shade300,
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
                num displayPrice = e.value.price;
                if (visa.discountEnabled && visa.discountPercent > 0) {
                  displayPrice = (e.value.price * (1 - visa.discountPercent / 100)).clamp(0, double.infinity);
                } else if (visa.discountEnabled && visa.discountAmount > 0) {
                  displayPrice = (e.value.price - visa.discountAmount).clamp(0, double.infinity);
                }
                final price = '${visa.currency} ${displayPrice.toStringAsFixed(0)}';
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
        const SizedBox(height: 32),
        _buildVisaRequirementsSection(visa),
      ],
    );
  }

  Widget _buildVisaRequirementsSection(VisaPackage visa) {
    final hasStructured = visa.generalDocuments.isNotEmpty || visa.categoryDocuments.isNotEmpty;
    final generalDocs = hasStructured ? visa.generalDocuments : const <VisaDocumentItem>[];
    final legacyDocs = !hasStructured ? visa.requiredDocuments : const <String>[];

    // If there are no documents at all, don't render the section
    if (!hasStructured && legacyDocs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visa Requirements',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.teal.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top pill - General Documents
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  gradient: Traveltalktheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'General Documents',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (hasStructured && generalDocs.isNotEmpty)
                _buildGeneralDocumentsBox(generalDocs)
              else if (legacyDocs.isNotEmpty)
                _buildLegacyDocumentsBox(legacyDocs),
              const SizedBox(height: 24),
              // Middle separator with "Documents by Visa Category"
              Stack(
                alignment: Alignment.center,
                children: [
                  Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: Traveltalktheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Documents by Visa Category',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasStructured && visa.categoryDocuments.isNotEmpty)
                _buildCategoryDocumentsBox(visa)
              else
                const Text(
                  'No category specific documents available',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralDocumentsBox(List<VisaDocumentItem> docs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 16,
            // Extra vertical space for long subtitles to avoid overflow
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            final doc = docs[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: Colors.teal.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${index + 1}. ${doc.title}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                                  fontSize: 12,
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
          },
        );
      },
    );
  }

  Widget _buildCategoryDocumentsBox(VisaPackage visa) {
    const categoryLabels = <String, String>{
      'jobHolder': 'For Job Holder',
      'businessPerson': 'For Business Person',
      'student': 'For Student',
      'other': 'Other Documents',
    };
    final categoriesOrder = categoryLabels.keys.toList();

    if (!categoriesOrder.contains(_selectedVisaCategory)) {
      _selectedVisaCategory = categoriesOrder.first;
    }

    final docs = visa.categoryDocuments[_selectedVisaCategory] ?? const <VisaDocumentItem>[];
    final currentLabel = categoryLabels[_selectedVisaCategory] ?? 'Documents';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category buttons row
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: categoriesOrder.map((key) {
            final selected = _selectedVisaCategory == key;
            final label = categoryLabels[key]!;
            final Color bg = selected ? Colors.orange : Colors.white;
            final Color fg = selected ? Colors.white : Colors.grey.shade800;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedVisaCategory = key;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? Colors.orange : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        // Selected category documents
        if (docs.isEmpty)
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.folder_special_rounded,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...docs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final doc = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${idx + 1}. ${doc.title}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (doc.subtitles.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          ...doc.subtitles.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(left: 18, bottom: 2),
                              child: Text(
                                '• $s',
                                style: const TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
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
