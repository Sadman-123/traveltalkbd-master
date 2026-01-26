import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:traveltalkbd/admin_panel.dart';
import 'package:traveltalkbd/diy_components/adaptive_helper.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/mobile_home.dart';
import 'package:traveltalkbd/web_related/web_home.dart';
import 'package:traveltalkbd/welcome_home.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(Main());
}

class Main extends StatelessWidget {
  const Main({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      theme: Traveltalktheme.travelTheme,

     home: WelcomeHome(),
    );
  }
}


