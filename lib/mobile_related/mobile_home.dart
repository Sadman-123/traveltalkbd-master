import 'package:flutter/material.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_about.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_destinition.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_packages.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_search.dart';
class MobileHome extends StatefulWidget{
  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> {
  int ind=0;
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
        title: Image.asset('assets/logo.png',height: 135,width: 135,),
      ),
      body: IndexedStack(
        index: ind,
        children: [
          MobileHomeSearch(),
          MobileHomeDestinition(),
          MobileHomePackages(),
          MobileHomeAbout()
        ],
      ),
     bottomNavigationBar: Container(
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
  child: NavigationBar(
    backgroundColor: Colors.transparent, // IMPORTANT
    elevation: 0,
    selectedIndex: ind,
    onDestinationSelected: (value) {
      setState(() {
        ind = value;
      });
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home),
        label: "Home",
      ),
      NavigationDestination(
        icon: Icon(Icons.place_outlined),
        label: "Destination",
      ),
      NavigationDestination(
        icon: Icon(Icons.wallet_giftcard_outlined),
        label: "Packages",
      ),
      NavigationDestination(
        icon: Icon(Icons.info_outline_rounded),
        label: "About us",
      ),
    ],
  ),
),
    );
  }
}