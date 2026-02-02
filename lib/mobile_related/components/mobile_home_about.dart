import 'package:flutter/material.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';

class MobileHomeAbout extends StatelessWidget {
  /// When true, renders without SingleChildScrollView for embedding in a parent scroll.
  final bool embedded;

  const MobileHomeAbout({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final isEmbedded = embedded;
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
        final employeesList = about.employees.values.toList()
          ..sort((a, b) => a.rank.compareTo(b.rank));

        final column = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'About Us',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Learn more about our company',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          about.tagline,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (about.rating > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 24,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                about.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Rating',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              // Description
              Text(
                about.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              // Mission and Vision
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flag,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Mission',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      about.mission,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Vision',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      about.vision,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Employees Section
              if (employeesList.isNotEmpty) ...[
                const Text(
                  'Our Team',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...employeesList.map((employee) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo on left - Modern rectangular design
                          Container(
                            width: 120,
                            height: 120,
                            constraints: const BoxConstraints(
                              minWidth: 120,
                              minHeight: 120,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: employee.pictureUrl.isNotEmpty
                                  ? Image.network(
                                      employee.pictureUrl,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.person, size: 50, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.person, size: 50, color: Colors.grey),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Details on right
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  employee.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  employee.designation,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (employee.experience.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.work_outline, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          employee.experience,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.format_quote,
                                        color: Colors.blue.shade300,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          employee.quote,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[800],
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
              // Why Choose Us
              const Text(
                'Why Choose Us',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _WhyChooseUsGrid(items: about.whyChooseUs),
              const SizedBox(height: 24),
              // Services
              const Text(
                'Our Services',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _ServicesGrid(services: about.services),
              const SizedBox(height: 24),
              // Documents Section
              if (about.documents.isNotEmpty) ...[
                const Text(
                  'Documents',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...about.documents.map((doc) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            doc,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ],
          );
        if (isEmbedded) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: column,
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: column,
        );
      },
    );
  }
}

class _WhyChooseUsGrid extends StatelessWidget {
  final List<String> items;

  const _WhyChooseUsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final row1 = items.take(2).toList();
    final row2 = items.skip(2).take(3).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (row1.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 2; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 0 ? 6 : 0, left: i == 1 ? 6 : 0),
                    child: i < row1.length ? _WhyChooseUsCard(item: row1[i]) : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        if (row2.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i < 2 ? 4 : 0,
                      left: i > 0 ? 4 : 0,
                    ),
                    child: i < row2.length ? _WhyChooseUsCard(item: row2[i]) : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WhyChooseUsCard extends StatefulWidget {
  final String item;

  const _WhyChooseUsCard({required this.item});

  @override
  State<_WhyChooseUsCard> createState() => _WhyChooseUsCardState();
}

class _WhyChooseUsCardState extends State<_WhyChooseUsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.primary : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered ? Colors.white.withOpacity(0.5) : Colors.blue.shade100,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.04),
              blurRadius: _isHovered ? 10 : 6,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.check_circle_outline,
                size: 56,
                color: _isHovered ? Colors.white.withOpacity(0.3) : Colors.green.shade200.withOpacity(0.6),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.item,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _isHovered ? Colors.white : Colors.blue.shade900,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  final List<ServiceItem> services;

  const _ServicesGrid({required this.services});

  @override
  Widget build(BuildContext context) {
    final row1 = services.take(2).toList();
    final row2 = services.skip(2).take(3).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (row1.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 2; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 0 ? 6 : 0, left: i == 1 ? 6 : 0),
                    child: i < row1.length ? _ServiceCard(service: row1[i]) : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        if (row2.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i < 2 ? 4 : 0,
                      left: i > 0 ? 4 : 0,
                    ),
                    child: i < row2.length ? _ServiceCard(service: row2[i]) : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final ServiceItem service;

  const _ServiceCard({required this.service});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isHovered = false;

  static IconData _iconForService(String title) {
    final t = title.toLowerCase();
    if (t.contains('visa')) return Icons.description_outlined;
    if (t.contains('tour') || t.contains('package')) return Icons.luggage_outlined;
    if (t.contains('hotel')) return Icons.hotel_outlined;
    if (t.contains('air') || t.contains('flight') || t.contains('ticket')) return Icons.flight_outlined;
    if (t.contains('transfer') || t.contains('car') || t.contains('transport')) return Icons.directions_car_outlined;
    return Icons.work_outline;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconForService(widget.service.title);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.primary : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered ? Colors.white.withOpacity(0.5) : Colors.blue.shade100,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.04),
              blurRadius: _isHovered ? 10 : 6,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(
                    icon,
                    size: 56,
                    color: _isHovered ? Colors.white.withOpacity(0.3) : Colors.grey.shade300.withOpacity(0.6),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: _isHovered ? Colors.white : Colors.blue.shade800, size: 24),
                      const SizedBox(height: 10),
                      Text(
                        widget.service.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isHovered ? Colors.white : Colors.blue.shade900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.service.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.service.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: _isHovered ? Colors.white.withOpacity(0.9) : Colors.grey.shade700,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

