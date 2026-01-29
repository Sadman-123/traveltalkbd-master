import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:traveltalkbd/app_splash_gate.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_about.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_destinition.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_packages.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_search.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';

class MobileHome extends StatefulWidget {
  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> {
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _destinationsKey = GlobalKey();
  final GlobalKey _packagesKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

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
                ],
              ),
            ),
          ),
        ),
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
        //floatingActionButton: FloatingActionButton(onPressed: (){}),
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
