import 'dart:async';
import 'package:flutter/material.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/mobile_related/data/travel_models.dart';
import 'package:traveltalkbd/web_related/web_travel_detail_screen.dart';
import 'package:traveltalkbd/services/banner_service.dart' as banner_service;
import 'package:traveltalkbd/services/home_settings_service.dart';

class WebHomeSearch extends StatefulWidget {
  const WebHomeSearch({super.key});

  @override
  State<WebHomeSearch> createState() => _WebHomeSearchState();
}

class _WebHomeSearchState extends State<WebHomeSearch> {
  int _currentSloganIndex = 0;
  bool _isTourPackages = true;
  Timer? _sloganTimer;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<SearchItem> _allItems = [];
  List<SearchItem> _filteredItems = [];
  Timer? _debounce;
  bool _showResults = false;
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
  String _backgroundImage = 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=1920';

  @override
  void initState() {
    super.initState();
    _loadHomeSettings();
    _loadData();
    _loadBanners();
    _searchController.addListener(_onSearchChanged);
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
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _filterResults(_searchController.text);
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final content = await TravelDataService.getContent();
      if (!mounted) return;
      final items = TravelDataService.buildSearchItems(content);
      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
        _filterResults(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterResults(String query) {
    if (!mounted) return;
    final lowerQuery = query.toLowerCase().trim();
    final source = _allItems.where((item) {
      return _isTourPackages ? item.type == 'tour' : item.type == 'visa';
    });

    setState(() {
      if (lowerQuery.isEmpty) {
        _filteredItems = [];
        _showResults = false;
      } else {
        _filteredItems = source.where((item) {
          return item.title.toLowerCase().contains(lowerQuery) ||
              item.subtitle.toLowerCase().contains(lowerQuery);
        }).toList();
        _showResults = true;
      }
    });
  }

  void _openDetails(SearchItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebTravelDetailScreen(item: item),
      ),
    );
  }

  @override
  void dispose() {
    _sloganTimer?.cancel();
    _debounce?.cancel();
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;

    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(_backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
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
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Logo/Brand Name
                const Text(
                  'Travel Talk BD',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 30),
                // Animated Slogan
                if (_slogans.isNotEmpty)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _slogans[_currentSloganIndex % _slogans.length],
                      key: ValueKey<int>(_currentSloganIndex),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
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
                const SizedBox(height: 60),
                // Search Box Container
                Container(
                  width: isWideScreen ? 800 : double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Toggle Button
                      Container(
  margin: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(18),
  ),
  child: Row(
    children: [
      /// TOUR PACKAGES
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isTourPackages = true;
              _filterResults(_searchController.text);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: _isTourPackages
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF4A1E6A), // purple
                        Color(0xFFE10098), // pink
                      ],
                    )
                  : null,
              color: !_isTourPackages ? Colors.transparent : null,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Tour Packages',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isTourPackages ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
              _filterResults(_searchController.text);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: !_isTourPackages
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF4A1E6A), // purple
                        Color(0xFFE10098), // pink
                      ],
                    )
                  : null,
              color: _isTourPackages ? Colors.transparent : null,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Visa',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: !_isTourPackages ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),

                      // Search Field
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: _isTourPackages
                                ? 'Where do you want to go?'
                                : 'Search visa information...',
                            prefixIcon: const Icon(Icons.search, color: Colors.blue, size: 28),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            hintStyle: const TextStyle(fontSize: 18),
                          ),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search Results - Fixed height container
                const SizedBox(height: 30),
                SizedBox(
                  height: 300,
                  width: isWideScreen ? 800 : double.infinity,
                  child: _showResults
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              : _filteredItems.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(40),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.search_off,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No matches found',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(20),
                                      itemCount: _filteredItems.length,
                                      itemBuilder: (context, index) {
                                  final item = _filteredItems[index];
                                  return InkWell(
                                    onTap: () => _openDetails(item),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          if (item.imageUrl != null &&
                                              item.imageUrl!.isNotEmpty)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                item.imageUrl!,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) {
                                                  return Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                size: 32,
                                              ),
                                            ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.title,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.subtitle,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: item.type == 'tour'
                                                        ? Colors.blue.shade50
                                                        : Colors.green.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    item.type.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: item.type == 'tour'
                                                          ? Colors.blue.shade700
                                                          : Colors.green.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.grey[400],
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Promotional Banners
                if (_showPromotions && _banners.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  SizedBox(
                    width: isWideScreen ? 800 : double.infinity,
                    height: 200,
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
                              return _buildBannerWidget(_banners[index], isWideScreen);
                            },
                          )
                        : _buildBannerWidget(_banners[0], isWideScreen),
                  ),
                  if (_banners.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _banners.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentBannerIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerWidget(banner_service.Banner banner, bool isWideScreen) {
    if (banner.type == 'image') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: banner.imageUrl != null && banner.imageUrl!.isNotEmpty
              ? Image.network(
                  banner.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF4A1E6A), // purple
          Color(0xFFE10098), // pink
        ],
      ),
                      ),
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 48),
                      ),
                    );
                  },
                )
              : Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF4A1E6A), // purple
          Color(0xFFE10098), // pink
        ],
      ),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.white, size: 48),
                  ),
                ),
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF4A1E6A), // purple
          Color(0xFFE10098), // pink
        ],
      ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_offer,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.heading ?? 'Special Offer!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    banner.subtext ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      );
    }
  }
}
