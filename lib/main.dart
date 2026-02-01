import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'url_strategy_stub.dart'
    if (dart.library.html) 'package:flutter_web_plugins/url_strategy.dart' as url_strategy;
import 'package:traveltalkbd/screens/admin/admin_gate.dart';
import 'package:traveltalkbd/diy_components/adaptive_helper.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/mobile_related/mobile_home.dart';
import 'package:traveltalkbd/screens/auth/login_screen.dart';
import 'package:traveltalkbd/screens/auth/register_screen.dart';
import 'package:traveltalkbd/screens/my_bookings_screen.dart';
import 'package:traveltalkbd/screens/my_profile_screen.dart';
import 'package:traveltalkbd/web_related/web_home.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kIsWeb) {
    url_strategy.usePathUrlStrategy();
  }
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  String get _initialRoute {
    if (kIsWeb) {
      final path = Uri.base.path.toLowerCase();
      final fragment = Uri.base.fragment.toLowerCase();
      if (path.contains('admin') || fragment.contains('admin')) {
        return '/admin';
      }
    }
    return '/';
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Traveltalktheme.travelTheme,
      initialRoute: _initialRoute,
      getPages: [
        GetPage(
          name: '/',
          page: () => AdaptiveHelper(mobile: MobileHome(), web: WebHome()),
        ),
        GetPage(
          name: '/admin',
          page: () => const AdminGate(),
        ),
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
        ),
        GetPage(
          name: '/register',
          page: () => const RegisterScreen(),
        ),
        GetPage(
          name: '/profile',
          page: () => const MyProfileScreen(),
        ),
        GetPage(
          name: '/bookings',
          page: () => const MyBookingsScreen(),
        ),
      ],
    );
  }
}
