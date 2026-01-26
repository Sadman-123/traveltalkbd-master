import 'package:flutter/material.dart';
import 'package:traveltalkbd/web_related/components/web_home_search.dart';
import 'package:traveltalkbd/web_related/components/web_home_destinition.dart';
import 'package:traveltalkbd/web_related/components/web_home_packages.dart';
import 'package:traveltalkbd/web_related/components/web_about_us_page.dart';

class WebHome extends StatefulWidget {
  @override
  State<WebHome> createState() => _WebHomeState();
}

class _WebHomeState extends State<WebHome> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _destinationsKey = GlobalKey();
  final GlobalKey _packagesKey = GlobalKey();

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF4A1E6A), // purple
          Color(0xFFE10098), // pink
        ],
      ),
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
          child: Image.asset('assets/logo.png',height: 150,width: 150,),
        ),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _scrollToSection(_homeKey),
            child: const Text(
              'Home',
              style: TextStyle(fontSize: 16,color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _scrollToSection(_destinationsKey),
            child: const Text(
              'Destinations',
              style: TextStyle(fontSize: 16,color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _scrollToSection(_packagesKey),
            child: const Text(
              'Packages',
              style: TextStyle(fontSize: 16,color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _navigateToAboutUs,
            child: const Text(
              'About Us',
              style: TextStyle(fontSize: 16,color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
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
          ],
        ),
      ),
    );
  }
}
