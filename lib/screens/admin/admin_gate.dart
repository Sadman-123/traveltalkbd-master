import 'package:flutter/material.dart';
import 'package:traveltalkbd/admin_panel.dart';
import 'package:traveltalkbd/services/auth_service.dart';
import 'package:traveltalkbd/screens/admin/admin_login_screen.dart';

/// Admin route gate.
///
/// - If Firebase is still restoring the auth state, shows a loading spinner.
/// - If user is logged in, shows `AdminPanel`.
/// - If user is not logged in, shows `AdminLoginScreen`.
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        // While Firebase is restoring the persisted session, show a loader.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Once the auth state is known, decide which screen to show.
        if (snapshot.data != null) {
          return const AdminPanel();
        }

        return const AdminLoginScreen();
      },
    );
  }
}
