import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:traveltalkbd/screens/booking_detail_screen.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/data/booking_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/services/auth_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final BookingService _bookingService = BookingService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final userId = AuthService().currentUserId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Not signed in';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _bookingService.getBookingsByUser(userId);
      // Enrich with images from travel data if itemImageUrl is missing
      final content = await TravelDataService.getContent();
      for (final b in list) {
        if (b['itemImageUrl'] == null || (b['itemImageUrl'] as String).isEmpty) {
          final itemId = b['itemId'] as String?;
          final itemType = b['itemType'] as String?;
          if (itemId != null && itemType != null) {
            String? photo;
            switch (itemType) {
              case 'tour':
                photo = content.tourPackages[itemId]?.photo;
                break;
              case 'visa':
                photo = content.visaPackages[itemId]?.photo;
                break;
              case 'destination':
                photo = content.destinations[itemId]?.photo;
                break;
            }
            if (photo != null && photo.isNotEmpty) {
              b['itemImageUrl'] = photo;
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _bookings = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  String _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'green';
      case 'pending':
        return 'orange';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Traveltalktheme.primaryGradient,
          ),
        ),
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // trv2.png background overlay (scaled down)
          Positioned.fill(
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 0.5,
                child: Image.asset(
                  'assets/trv2.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          // Content
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _error != null
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadBookings,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _bookings.isEmpty
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(24),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No bookings yet',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Book a tour, visa, or destination to see them here',
                                  style: TextStyle(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadBookings,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              // Match tour package card grid: same breakpoints, aspect ratio, spacing
                              int crossAxisCount;
                              double aspectRatio;
                              double spacing;
                              if (width >= 1200) {
                                crossAxisCount = 4;
                                aspectRatio = 0.88;
                                spacing = 24;
                              } else if (width >= 900) {
                                crossAxisCount = 3;
                                aspectRatio = 0.88;
                                spacing = 24;
                              } else if (width >= 600) {
                                crossAxisCount = 2;
                                aspectRatio = 0.88;
                                spacing = 24;
                              } else {
                                crossAxisCount = 2;
                                aspectRatio = 0.8;
                                spacing = 12;
                              }
                              return CustomScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: [
                                  SliverPadding(
                                    padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).padding.top + kToolbarHeight + (isWeb ? 24 : 16),
                                      left: isWeb ? 24 : 16,
                                      right: isWeb ? 24 : 16,
                                      bottom: isWeb ? 24 : 16,
                                    ),
                                    sliver: SliverGrid(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: spacing,
                                        mainAxisSpacing: spacing,
                                        childAspectRatio: aspectRatio,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final b = _bookings[index];
                                          return _BookingPackageCard(
                                            booking: b,
                                            statusColor: _statusColor,
                                            isWeb: isWeb,
                                            onTap: () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => BookingDetailScreen(booking: b),
                                              ),
                                            ),
                                          );
                                        },
                                        childCount: _bookings.length,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
        ],
      ),
    );
  }
}

/// Booking card matching tour/visa package card design exactly
class _BookingPackageCard extends StatefulWidget {
  final Map<String, dynamic> booking;
  final String Function(String) statusColor;
  final bool isWeb;
  final VoidCallback? onTap;

  const _BookingPackageCard({
    required this.booking,
    required this.statusColor,
    required this.isWeb,
    this.onTap,
  });

  @override
  State<_BookingPackageCard> createState() => _BookingPackageCardState();
}

class _BookingPackageCardState extends State<_BookingPackageCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final status = b['status'] as String? ?? 'pending';
    final dateStr = b['date'] as String? ?? '-';
    final people = b['numberOfPeople'] as int? ?? 0;
    final imageUrl = b['itemImageUrl'] as String?;
    final itemType = b['itemType'] as String? ?? 'booking';
    final ts = b['timestamp'] as String?;
    String timeAgo = '';
    if (ts != null) {
      try {
        final dt = DateTime.parse(ts);
        timeAgo = DateFormat('MMM dd, yyyy').format(dt);
      } catch (_) {}
    }
    final title = b['itemTitle'] as String? ?? 'Unknown';
    final durationText = dateStr;
    final subtitle = '$people ${people == 1 ? 'person' : 'people'}${timeAgo.isNotEmpty ? ' • Booked $timeAgo' : ''}';
    final statusText = status.toUpperCase();

    final collapsedBarHeight = widget.isWeb ? 100.0 : 80.0;
    final borderRadius = widget.isWeb ? 16.0 : 12.0;
    final elevation = widget.isWeb ? (_hovered ? 10.0 : 4.0) : (_hovered ? 6.0 : 2.0);
    final blurSigma = widget.isWeb ? 16.0 : 12.0;
    final padding = widget.isWeb ? 16.0 : 10.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        elevation: elevation,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = constraints.maxHeight;
            final collapsedTop = cardHeight - collapsedBarHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                // Image background - same as tour/visa cards
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                else
                  _buildPlaceholder(),
                // Gradient overlay - same as tour/visa cards
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: widget.isWeb ? 120 : 80,
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
                // AnimatedPositioned glass bar - same as tour/visa cards
                AnimatedPositioned(
                  duration: Duration(milliseconds: widget.isWeb ? 350 : 300),
                  curve: Curves.easeOutCubic,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  top: _hovered ? 0 : collapsedTop,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                      child: Container(
                        padding: EdgeInsets.all(padding),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(borderRadius),
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
                                  padding: EdgeInsets.symmetric(vertical: widget.isWeb ? 8 : 6),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: widget.isWeb ? 18 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: const [
                                            Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                                          ],
                                        ),
                                      ),
                                      if (durationText.isNotEmpty) ...[
                                        SizedBox(height: widget.isWeb ? 8 : 6),
                                        Text(
                                          'Date: $durationText',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: widget.isWeb ? 14 : 12,
                                            color: Colors.white.withOpacity(0.95),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                      if (subtitle.isNotEmpty) ...[
                                        SizedBox(height: widget.isWeb ? 4 : 4),
                                        Text(
                                          subtitle,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: widget.isWeb ? 13 : 11,
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: widget.isWeb ? 8 : 6),
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: widget.isWeb ? 20 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: const [
                                            Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: widget.isWeb ? 12 : 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.visibility, size: widget.isWeb ? 18 : 16, color: Colors.white.withOpacity(0.95)),
                                          SizedBox(width: widget.isWeb ? 6 : 6),
                                          Text(
                                            'Booking details',
                                            style: TextStyle(
                                              fontSize: widget.isWeb ? 15 : 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white.withOpacity(0.95),
                                              shadows: const [
                                                Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
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
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: widget.isWeb ? 18 : 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: widget.isWeb ? 12 : 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (durationText.isNotEmpty)
                                          Text(
                                            durationText,
                                            style: TextStyle(
                                              fontSize: widget.isWeb ? 13 : 11,
                                              color: Colors.white.withOpacity(0.95),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        if (durationText.isNotEmpty) SizedBox(height: widget.isWeb ? 4 : 2),
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            fontSize: widget.isWeb ? 18 : 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: const [
                                              Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
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
                // Item type badge (top-left) - like durationBadge
                Positioned(
                  top: widget.isWeb ? 12 : 8,
                  left: widget.isWeb ? 12 : 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isWeb ? 10 : 8,
                      vertical: widget.isWeb ? 6 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(widget.isWeb ? 8 : 6),
                    ),
                    child: Text(
                      itemType.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.isWeb ? 12 : 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Status badge (top-right) - like discountBadge
                Positioned(
                  top: widget.isWeb ? 12 : 8,
                  right: widget.isWeb ? 12 : 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isWeb ? 12 : 10,
                      vertical: widget.isWeb ? 7 : 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.statusColor(status) == 'green'
                            ? [Colors.green.shade700, Colors.green.shade500]
                            : widget.statusColor(status) == 'orange'
                                ? [Colors.orange.shade700, Colors.orange.shade500]
                                : widget.statusColor(status) == 'red'
                                    ? [Colors.red.shade700, Colors.red.shade500]
                                    : [const Color(0xFF6B4E9A), const Color(0xFFE10098)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(widget.isWeb ? 10 : 8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.isWeb ? 12 : 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
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

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(
        Icons.image_not_supported,
        size: widget.isWeb ? 48 : 40,
        color: Colors.grey,
      ),
    );
  }
}
