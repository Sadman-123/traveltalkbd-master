import 'package:flutter/material.dart';
import 'package:traveltalkbd/admin_panel.dart';
import 'package:traveltalkbd/services/auth_service.dart';
import 'package:traveltalkbd/screens/admin/admin_login_screen.dart';

/// Shows AdminLoginScreen when not logged in, AdminPanel when logged in.
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (AuthService().isSignedIn) {
      return const AdminPanel();
    }
    return const AdminLoginScreen();
  }
}
