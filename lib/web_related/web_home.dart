import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:traveltalkbd/diy_components/user_avatar.dart';
import 'package:traveltalkbd/app_splash_gate.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/services/auth_service.dart';
import 'package:traveltalkbd/web_related/components/web_home_search.dart';
import 'package:traveltalkbd/web_related/components/web_home_destinition.dart';
import 'package:traveltalkbd/web_related/components/web_home_packages.dart';
import 'package:traveltalkbd/web_related/components/web_about_us_page.dart';
import 'package:traveltalkbd/diy_components/chat_floating_button.dart';
import 'package:traveltalkbd/diy_components/home_footer.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class WebHome extends StatefulWidget {
  @override
  State<WebHome> createState() => _WebHomeState();
}

class _WebHomeState extends State<WebHome> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _destinationsKey = GlobalKey();
  final GlobalKey _packagesKey = GlobalKey();
  final AuthService _auth = AuthService();
  StreamSubscription? _authSubscription;

  late final Future<void> _preloadFuture =
      TravelDataService.getContent().then((_) {});

  @override
  void initState() {
    super.initState();
    _authSubscription = _auth.authStateChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToAboutUs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WebAboutUsPage()),
    );
  }

  void _navigateToLogin() {
    Get.toNamed('/login')?.then((_) => setState(() {}));
  }

  void _navigateToMyBookings() {
    if (!_auth.isSignedIn) {
      _navigateToLogin();
      return;
    }
    if (_auth.isEmailPasswordUser && !_auth.isEmailVerified) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verify your email'),
          content: const Text(
            'Please verify your email address to view your bookings. Check your inbox for the verification link, or go to Profile to resend it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Get.toNamed('/profile')?.then((_) => setState(() {}));
              },
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      );
      return;
    }
    Get.toNamed('/bookings')?.then((_) => setState(() {}));
  }

  void _navigateToMyProfile() {
    if (!_auth.isSignedIn) {
      _navigateToLogin();
      return;
    }
    Get.toNamed('/profile')?.then((_) => setState(() {}));
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _auth.signOut();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSplashGate(
      loadFuture: _preloadFuture,
      child: Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
    decoration:  BoxDecoration(
     gradient: Traveltalktheme.primaryGradient
    ),
  ),
        title:  GestureDetector(
          onTap: () {
            _scrollToSection(_homeKey);},
          // child: Text(
          //   'Travel Talk BD',
          //   style: TextStyle(
          //     color: Colors.white,
          //     fontWeight: FontWeight.bold,
          //     fontSize: 24,
          //   ),
          // ),
          child: SvgPicture.asset('assets/logo.svg',height: 100,width: 150,color: Colors.white,)
        ),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _scrollToSection(_homeKey),
            child: const Text(
              'Home',
              style: TextStyle(fontSize: 16,color: Colors.white,fontFamily: 'traveltalk'),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _scrollToSection(_destinationsKey),
            child: const Text(
              'Destinations',
              style: TextStyle(fontSize: 16,color: Colors.white,fontFamily: 'traveltalk'),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _scrollToSection(_packagesKey),
            child: const Text(
              'Packages',
              style: TextStyle(fontSize: 16,color: Colors.white,fontFamily: 'traveltalk'),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _navigateToAboutUs,
            child: const Text(
              'About Us',
              style: TextStyle(fontSize: 16,color: Colors.white,fontFamily: 'traveltalk'),
            ),
          ),
          const SizedBox(width: 8),
          _auth.isSignedIn
              ? PopupMenuButton<String>(
                  offset: const Offset(0, 48),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        _navigateToMyProfile();
                        break;
                      case 'bookings':
                        _navigateToMyBookings();
                        break;
                      case 'logout':
                        _signOut();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.person_outline),
                        title: Text('Profile'),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'bookings',
                      child: ListTile(
                        leading: Icon(Icons.bookmark_border),
                        title: Text('Manage Booking'),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: _auth.getCurrentUserProfile(),
                    builder: (context, snapshot) {
                      final photoUrl = snapshot.data?['photoUrl'] as String? ?? _auth.currentUser?.photoURL;
                      final name = snapshot.data?['displayName'] as String? ?? _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? '';
                      final initials = name.trim().isNotEmpty ? name.trim().substring(0, 1) : null;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: UserAvatar(
                          photoUrl: photoUrl,
                          initials: initials,
                          size: 36,
                        ),
                      );
                    },
                  ),
                )
              : TextButton(
                  onPressed: _navigateToLogin,
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: const ChatFloatingButton(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Home/Search Section
            Container(
              key: _homeKey,
              child: const WebHomeSearch(),
            ),
            // Destinations Section
            Container(
              key: _destinationsKey,
              child: const WebHomeDestinition(),
            ),
            // Packages Section
            Container(
              key: _packagesKey,
              child: const WebHomePackages(),
            ),
            // Footer
            HomeFooter(
              onNavigate: (section) {
                switch (section) {
                  case 'home':
                    _scrollToSection(_homeKey);
                    break;
                  case 'destinations':
                    _scrollToSection(_destinationsKey);
                    break;
                  case 'packages':
                    _scrollToSection(_packagesKey);
                    break;
                  case 'about':
                    _navigateToAboutUs();
                    break;
                }
              },
            ),
          ],
        ),
      ),
    ),
    );
  }
}
