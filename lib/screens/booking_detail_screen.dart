import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';
import 'package:traveltalkbd/mobile_related/travel_detail_screen.dart';
import 'package:traveltalkbd/web_related/web_travel_detail_screen.dart';

class BookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    final itemTitle = booking['itemTitle'] as String? ?? 'Unknown';
    final itemType = booking['itemType'] as String? ?? 'booking';
    final status = booking['status'] as String? ?? 'pending';
    final dateStr = booking['date'] as String? ?? '-';
    final people = booking['numberOfPeople'] as int? ?? 0;
    final name = booking['name'] as String? ?? '';
    final email = booking['email'] as String? ?? '';
    final phone = booking['phone'] as String? ?? '';
    final notes = booking['notes'] as String? ?? '';
    final imageUrl = booking['itemImageUrl'] as String?;
    final itemId = booking['itemId'] as String?;
    final visaPhotoUrl = booking['visaPhotoUrl'] as String?;
    final visaEntryTypeLabel = booking['visaEntryTypeLabel'] as String?;
    final ts = booking['timestamp'] as String?;
    String bookedOn = '';
    if (ts != null) {
      try {
        final dt = DateTime.parse(ts);
        bookedOn = DateFormat('MMM dd, yyyy • h:mm a').format(dt);
      } catch (_) {}
    }

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
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
          'Booking Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: isWeb ? _buildWebLayout(
          context,
          itemTitle: itemTitle,
          itemType: itemType,
          status: status,
          statusColor: statusColor,
          dateStr: dateStr,
          people: people,
          name: name,
          email: email,
          phone: phone,
          notes: notes,
          imageUrl: imageUrl,
          itemId: itemId,
          visaPhotoUrl: visaPhotoUrl,
          visaEntryTypeLabel: visaEntryTypeLabel,
          bookedOn: bookedOn,
        ) : _buildMobileLayout(
          context,
          itemTitle: itemTitle,
          itemType: itemType,
          status: status,
          statusColor: statusColor,
          dateStr: dateStr,
          people: people,
          name: name,
          email: email,
          phone: phone,
          notes: notes,
          imageUrl: imageUrl,
          itemId: itemId,
          visaPhotoUrl: visaPhotoUrl,
          visaEntryTypeLabel: visaEntryTypeLabel,
          bookedOn: bookedOn,
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context, {
    required String itemTitle,
    required String itemType,
    required String status,
    required Color statusColor,
    required String dateStr,
    required int people,
    required String name,
    required String email,
    required String phone,
    required String notes,
    String? imageUrl,
    String? itemId,
    String? visaPhotoUrl,
    String? visaEntryTypeLabel,
    required String bookedOn,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildImageSection(context, imageUrl: imageUrl, itemTitle: itemTitle, status: status, statusColor: statusColor),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBadge(status, statusColor),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.category_outlined, 'Type', itemType),
              _buildDetailRow(Icons.calendar_today, 'Date', dateStr),
              _buildDetailRow(Icons.people_outline, 'Travelers', '$people ${people == 1 ? 'person' : 'people'}'),
              if (bookedOn.isNotEmpty) _buildDetailRow(Icons.schedule, 'Booked on', bookedOn),
              const Divider(height: 32),
              Text('Contact Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (name.isNotEmpty) _buildDetailRow(Icons.person_outline, 'Name', name),
              if (email.isNotEmpty) _buildDetailRow(Icons.email_outlined, 'Email', email),
              if (phone.isNotEmpty) _buildDetailRow(Icons.phone_outlined, 'Phone', phone),
              if (notes.isNotEmpty) ...[
                const Divider(height: 32),
                Text('Notes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(notes, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
              ],
              if (visaEntryTypeLabel != null && visaEntryTypeLabel.isNotEmpty)
                _buildDetailRow(Icons.verified_user, 'Visa Entry', visaEntryTypeLabel),
              if (visaPhotoUrl != null && visaPhotoUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Passport Photo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(visaPhotoUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey[300], child: const Icon(Icons.image_not_supported, size: 48))),
                ),
              ],
              const SizedBox(height: 24),
              if (itemId != null) _buildViewPackageButton(context, itemId: itemId, itemType: itemType),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebLayout(
    BuildContext context, {
    required String itemTitle,
    required String itemType,
    required String status,
    required Color statusColor,
    required String dateStr,
    required int people,
    required String name,
    required String email,
    required String phone,
    required String notes,
    String? imageUrl,
    String? itemId,
    String? visaPhotoUrl,
    String? visaEntryTypeLabel,
    required String bookedOn,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: _buildImageSection(context, imageUrl: imageUrl, itemTitle: itemTitle, status: status, statusColor: statusColor),
          ),
          const SizedBox(width: 40),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itemTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildStatusBadge(status, statusColor),
                const SizedBox(height: 24),
                _buildDetailRow(Icons.category_outlined, 'Type', itemType),
                _buildDetailRow(Icons.calendar_today, 'Date', dateStr),
                _buildDetailRow(Icons.people_outline, 'Travelers', '$people ${people == 1 ? 'person' : 'people'}'),
                if (bookedOn.isNotEmpty) _buildDetailRow(Icons.schedule, 'Booked on', bookedOn),
                const Divider(height: 32),
                Text('Contact Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (name.isNotEmpty) _buildDetailRow(Icons.person_outline, 'Name', name),
                if (email.isNotEmpty) _buildDetailRow(Icons.email_outlined, 'Email', email),
                if (phone.isNotEmpty) _buildDetailRow(Icons.phone_outlined, 'Phone', phone),
                if (notes.isNotEmpty) ...[
                  const Divider(height: 32),
                  Text('Notes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(notes, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
                ],
                if (visaEntryTypeLabel != null && visaEntryTypeLabel.isNotEmpty)
                  _buildDetailRow(Icons.verified_user, 'Visa Entry', visaEntryTypeLabel),
                if (visaPhotoUrl != null && visaPhotoUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Passport Photo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(visaPhotoUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey[300], child: const Icon(Icons.image_not_supported, size: 48))),
                  ),
                ],
                const SizedBox(height: 32),
                if (itemId != null) _buildViewPackageButton(context, itemId: itemId, itemType: itemType),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(
    BuildContext context, {
    String? imageUrl,
    required String itemTitle,
    required String status,
    required Color statusColor,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(280),
                )
              : _buildPlaceholder(280),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              itemTitle,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6B4E9A).withOpacity(0.4),
            const Color(0xFFE10098).withOpacity(0.3),
          ],
        ),
      ),
      child: Center(child: Icon(Icons.image_outlined, size: 64, color: Colors.white.withOpacity(0.6))),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewPackageButton(BuildContext context, {required String itemId, required String itemType}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _navigateToPackage(context, itemId: itemId, itemType: itemType),
        icon: const Icon(Icons.open_in_new),
        label: const Text('View Original Package'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.primary),
          foregroundColor: AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _navigateToPackage(BuildContext context, {required String itemId, required String itemType}) async {
    try {
      final content = await TravelDataService.getContent();
      SearchItem? item;
      switch (itemType) {
        case 'tour':
          final pkg = content.tourPackages[itemId];
          if (pkg != null) {
            item = SearchItem(id: pkg.id, title: pkg.title, subtitle: '${pkg.city}, ${pkg.country}', type: 'tour', imageUrl: pkg.photo, payload: pkg);
          }
          break;
        case 'visa':
          final visa = content.visaPackages[itemId];
          if (visa != null) {
            item = SearchItem(id: visa.id, title: visa.title, subtitle: visa.country, type: 'visa', imageUrl: visa.photo, payload: visa);
          }
          break;
        case 'destination':
          final dest = content.destinations[itemId];
          if (dest != null) {
            item = SearchItem(id: dest.id, title: dest.name, subtitle: dest.country, type: 'destination', imageUrl: dest.photo, payload: dest);
          }
          break;
      }
      if (item != null && context.mounted) {
        final isWeb = MediaQuery.of(context).size.width > 600;
        if (isWeb) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WebTravelDetailScreen(item: item!, isAlreadyBooked: true),
          ));
        } else {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TravelDetailScreen(item: item!, isAlreadyBooked: true),
          ));
        }
      }
    } catch (_) {}
  }
}
