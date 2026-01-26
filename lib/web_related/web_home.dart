import 'package:flutter/material.dart';
import 'package:traveltalkbd/web_related/components/web_home_search.dart';
import 'package:traveltalkbd/web_related/components/web_home_destinition.dart';
import 'package:traveltalkbd/web_related/components/web_home_packages.dart';
import 'package:traveltalkbd/web_related/components/web_home_about.dart';

class WebHome extends StatefulWidget {
  @override
  State<WebHome> createState() => _WebHomeState();
}

class _WebHomeState extends State<WebHome> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _destinationsKey = GlobalKey();
  final GlobalKey _packagesKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  GestureDetector(
          onTap: () {
            _scrollToSection(_homeKey);},
          child: Text(
            'Travel Talk BD',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
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
            onPressed: () => _scrollToSection(_aboutKey),
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
            // About Section
            Container(
              key: _aboutKey,
              child: const WebHomeAbout(),
            ),
          ],
        ),
      ),
    );
  }
}
