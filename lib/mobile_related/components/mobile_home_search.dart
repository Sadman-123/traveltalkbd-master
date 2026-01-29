import 'dart:async';
import 'package:flutter/material.dart';
import 'package:traveltalkbd/diy_components/spark_banner_overlay.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/components/package_search_screen.dart';
import 'package:traveltalkbd/services/banner_service.dart' as banner_service;
import 'package:traveltalkbd/services/home_settings_service.dart';

class MobileHomeSearch extends StatefulWidget {
  /// When true, renders as a fixed-height section for embedding in a scroll view.
  final bool asSection;

  const MobileHomeSearch({
    Key? key,
    this.asSection = false,
  }) : super(key: key);

  @override
  State<MobileHomeSearch> createState() => _MobileHomeSearchState();
}

class _MobileHomeSearchState extends State<MobileHomeSearch> {
  int _currentSloganIndex = 0;
  bool _isTourPackages = true;
  Timer? _sloganTimer;
  List<banner_service.Banner> _banners = [];
  bool _showPromotions = true;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  final PageController _bannerPageController = PageController();

  List<String> _slogans = [
    "Discover Your Next Adventure",
    "Travel Beyond Imagination",
    "Create Memories That Last Forever",
    "Your Journey Starts Here",
    "Explore the World with Us",
  ];
  String _backgroundImage = 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800';

  @override
  void initState() {
    super.initState();
    _loadHomeSettings();
    _loadBanners();
  }

  Future<void> _loadHomeSettings() async {
    try {
      final slogans = await HomeSettingsService.getSlogans();
      final backgroundImage = await HomeSettingsService.getBackgroundImage();
      if (mounted) {
        setState(() {
          _slogans = slogans;
          _backgroundImage = backgroundImage;
        });
        if (_slogans.isNotEmpty) {
          _startSloganRotation();
        }
      }
    } catch (e) {
      // Use default values on error
      if (mounted && _slogans.isNotEmpty) {
        _startSloganRotation();
      }
    }
  }

  void _startSloganRotation() {
    if (_slogans.isEmpty) return;
    _sloganTimer?.cancel();
    _sloganTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _slogans.isNotEmpty) {
        setState(() {
          _currentSloganIndex = (_currentSloganIndex + 1) % _slogans.length;
        });
      }
    });
  }

  Future<void> _loadBanners() async {
    try {
      final shouldShow = await banner_service.BannerService.shouldShowPromotions();
      final banners = await banner_service.BannerService.getBanners();
      if (mounted) {
        setState(() {
          _showPromotions = shouldShow;
          _banners = banners;
        });
        if (_banners.length > 1) {
          _startBannerRotation();
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _startBannerRotation() {
    _bannerTimer?.cancel();
    if (_banners.length > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted && _bannerPageController.hasClients) {
          final nextIndex = (_currentBannerIndex + 1) % _banners.length;
          _bannerPageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _sloganTimer?.cancel();
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(_backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Logo/Brand Name
                const Text(
                  'Travel Talk BD',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Animated Slogan
                if (_slogans.isNotEmpty)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Padding(
                      key: ValueKey<int>(_currentSloganIndex),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _slogans[_currentSloganIndex % _slogans.length],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 50),
                
                // Search Box Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Toggle Button (only controls what will be searched on next screen)
                        Container(
  margin: const EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(15),
  ),
  child: Row(
    children: [
      /// TOUR PACKAGES
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isTourPackages = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: _isTourPackages
                  ? Traveltalktheme.primaryGradient
                  : null,
              color: !_isTourPackages ? Colors.transparent : null,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              'Tour Packages',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isTourPackages ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),

      /// VISA
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isTourPackages = false;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: !_isTourPackages
                  ? Traveltalktheme.primaryGradient
                  : null,
              color: _isTourPackages ? Colors.transparent : null,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              'Visa',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: !_isTourPackages ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),

                        
                        // Search Field (read-only, navigates to dedicated search page)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            readOnly: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PackageSearchScreen(
                                    initialIsTourPackages: _isTourPackages,
                                  ),
                                ),
                              );
                            },
                            decoration: InputDecoration(
                              hintText: _isTourPackages
                                  ? 'Where do you want to go?'
                                  : 'Search visa information...',
                              prefixIcon: const Icon(Icons.search, color: Colors.blue),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Promotional Banners
                if (_showPromotions && _banners.isNotEmpty) ...[
                  SizedBox(
                    height: 120,
                    child: _banners.length > 1
                        ? PageView.builder(
                            controller: _bannerPageController,
                            itemCount: _banners.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentBannerIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildBannerWidget(_banners[index]),
                              );
                            },
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildBannerWidget(_banners[0]),
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
    );
    if (widget.asSection) {
      return SizedBox(
        height: 520,
        child: content,
      );
    }
    return Scaffold(body: content);
  }

  Widget _buildBannerWidget(banner_service.Banner banner) {
    if (banner.type == 'image') {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: banner.imageUrl != null && banner.imageUrl!.isNotEmpty
              ? Image.network(
                  banner.imageUrl!,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: Traveltalktheme.primaryGradient
                      ),
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 32),
                      ),
                    );
                  },
                )
              : Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: Traveltalktheme.primaryGradient
                  ),
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.white, size: 32),
                  ),
                ),
        ),
      );
    } else {
      return SparkBannerOverlay(
        duration: const Duration(milliseconds: 2500),
        sparkColor: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: Traveltalktheme.primaryGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_offer,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.heading ?? 'Special Offer!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    banner.subtext ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
            ),
          ],
        ),
        ),
      );
    }
  }
}