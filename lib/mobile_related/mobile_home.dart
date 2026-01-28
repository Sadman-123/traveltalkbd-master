import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:traveltalkbd/app_splash_gate.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_about.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_destinition.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_packages.dart';
import 'package:traveltalkbd/mobile_related/components/mobile_home_search.dart';
import 'package:traveltalkbd/mobile_related/data/travel_data_service.dart';
class MobileHome extends StatefulWidget{
  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> {
  int ind=0;
  @override
  Widget build(BuildContext context) {
    return AppSplashGate(
      loadFuture: TravelDataService.getContent().then((_) {}),
      child: Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
    decoration:  BoxDecoration(
      gradient:Traveltalktheme.primaryGradient
    ),
  ),
          //child: SvgPicture.asset('assets/logo.svg',height: 100,width: 150,color: Colors.white,)

        title: SvgPicture.asset('assets/logo.svg',height: 90,width: 150,color: Colors.white,),
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
        decoration:  BoxDecoration(
          gradient: Traveltalktheme.primaryGradient
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
    ),
    );
  }
}