import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';
import 'package:traveltalkbd/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onRegisterTap;
  final bool returnToBooking;

  const LoginScreen({
    super.key,
    this.onSuccess,
    this.onRegisterTap,
    this.returnToBooking = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AuthService().isSignedIn) {
        if (widget.returnToBooking || Get.arguments?['returnToBooking'] == true) {
          Get.back(result: true);
        } else {
          Get.offAllNamed('/');
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService().signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        widget.onSuccess?.call();
        final returnToBooking = widget.returnToBooking || Get.arguments?['returnToBooking'] == true;
        if (returnToBooking) {
          Get.back(result: true);
        } else {
          Get.offAllNamed('/');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _authErrorMessage(e.code);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Login failed. Please try again.';
        });
      }
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // trv2.png background
          Positioned.fill(
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 0.5,
                child: Image.asset(
                  'assets/trv2.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                          Icon(
                            Icons.login_rounded,
                            size: isWeb ? 56 : 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: isWeb ? 28 : 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your email and password',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade800, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter your email';
                              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                              return null;
                            },
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter your password';
                              if (v.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Don\'t have an account? ', style: TextStyle(color: Colors.grey[700])),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Get.offNamed('/register'),
                                child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                            ],
                            ),
                          ),
                      ),
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
