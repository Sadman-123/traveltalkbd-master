import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:traveltalkbd/diy_components/user_avatar.dart';
import 'package:traveltalkbd/app_splash_gate.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_about.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_destinition.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_packages.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_search.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
import 'package:traveltalkbd/services/auth_service.dart';
import 'package:traveltalkbd/diy_components/chat_floating_button.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class MobileHome extends StatefulWidget {
  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> {
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _destinationsKey = GlobalKey();
  final GlobalKey _packagesKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final AuthService _auth = AuthService();
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = _auth.authStateChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    Navigator.pop(context); // Close drawer
    // Wait for drawer to close, then scroll to section
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0,
        );
      }
    });
  }

  void _navigateToLogin({bool closeDrawer = true}) {
    if (closeDrawer) Navigator.pop(context);
    Get.toNamed('/login')?.then((_) => setState(() {}));
  }

  void _navigateToMyBookings() {
    Navigator.pop(context);
    if (!_auth.isSignedIn) {
      _navigateToLogin(closeDrawer: false);
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
                Get.toNamed('/profile');
              },
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      );
      return;
    }
    Get.toNamed('/bookings');
  }

  void _navigateToMyProfile() {
    Navigator.pop(context);
    if (!_auth.isSignedIn) {
      _navigateToLogin(closeDrawer: false);
      return;
    }
    Get.toNamed('/profile')?.then((_) => setState(() {}));
  }

  Future<void> _signOut() async {
    Navigator.pop(context);
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
  Widget build(BuildContext context) {
    return AppSplashGate(
      loadFuture: TravelDataService.getContent().then((_) {}),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: Traveltalktheme.primaryGradient,
            ),
          ),
          title: GestureDetector(
            onTap: ()=>_scrollToSection(_homeKey),
            child: SvgPicture.asset(
            'assets/logo.svg',
            height: 90,
            width: 150,
            color: Colors.white,
          ),
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4A1E6A).withOpacity(0.95),
                  const Color(0xFFE10098).withOpacity(0.9),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: ()=>_scrollToSection(_homeKey),
                      child: SvgPicture.asset(
                        'assets/logo.svg',
                        height: 90,
                        width: 150,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_auth.isSignedIn) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: _navigateToMyProfile,
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _auth.getCurrentUserProfile(),
                          builder: (context, snapshot) {
                            final photoUrl = snapshot.data?['photoUrl'] as String? ?? _auth.currentUser?.photoURL;
                            return Row(
                              children: [
                                UserAvatar(photoUrl: photoUrl, size: 56, showBorder: true),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'My Profile',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _auth.currentUser?.email ?? '',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () => _scrollToSection(_homeKey),
                  ),
                  _DrawerItem(
                    icon: Icons.place_outlined,
                    label: 'Destinations',
                    onTap: () => _scrollToSection(_destinationsKey),
                  ),
                  _DrawerItem(
                    icon: Icons.wallet_giftcard_outlined,
                    label: 'Packages',
                    onTap: () => _scrollToSection(_packagesKey),
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About Us',
                    onTap: () => _scrollToSection(_aboutKey),
                  ),
                  const Divider(color: Colors.white54, height: 24),
                  _DrawerItem(
                    icon: Icons.bookmark_border,
                    label: 'My Bookings',
                    onTap: _navigateToMyBookings,
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: 'My Profile',
                    onTap: _navigateToMyProfile,
                  ),
                  _auth.isSignedIn
                      ? _DrawerItem(
                          icon: Icons.logout,
                          label: 'Logout',
                          onTap: _signOut,
                        )
                      : _DrawerItem(
                          icon: Icons.login,
                          label: 'Login',
                          onTap: _navigateToLogin,
                        ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: ExpandableFab.location,
        floatingActionButton: const ChatFloatingButton(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Section(sectionKey: _homeKey, child: MobileHomeSearch(asSection: true)),
              _Section(
                sectionKey: _destinationsKey,
                child: SizedBox(
                  height: 420,
                  child: MobileHomeDestinition(),
                ),
              ),
              _Section(
                sectionKey: _packagesKey,
                child: MobileHomePackages(embedded: true),
              ),
              _Section(
                sectionKey: _aboutKey,
                child: MobileHomeAbout(embedded: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final GlobalKey sectionKey;
  final Widget child;

  const _Section({required this.sectionKey, required this.child})
      : super(key: sectionKey);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 26),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
