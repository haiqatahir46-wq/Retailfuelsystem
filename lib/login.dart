import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';
import 'package:petrolpump_flutter/wave_clipper.dart';

/// Sign-in screen. Reuses the exact same station-photo + fixed-wave header
/// as [SplashScreen] (same WaveClipper, same white-backdrop fix so there's
/// no gap color), just with a shorter image panel to leave room for the
/// form below.
class LoginScreen extends StatefulWidget {
  final Widget? stationImage;
  final void Function(String email, String password) onSignIn;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onCreateAccount;

  const LoginScreen({
    super.key,
    required this.onSignIn,
    this.stationImage,
    this.onForgotPassword,
    this.onCreateAccount,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  // Image panel height as a fraction of the screen - shorter than the
  // splash screen's 0.6161 so the form has room to breathe.
  static const double _sceneHeightFactor = 0.3541;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Stack(
        children: [
          // --- Station image panel with the same fixed wave edge ---
          Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: _sceneHeightFactor,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: AppColors.cardBackground),
                child: ClipPath(
                  clipper: const WaveClipper(),
                  child: SizedBox.expand(
                    child: widget.stationImage ?? const _StationPlaceholder(),
                  ),
                ),
              ),
            ),
          ),

          // --- Sign-in form ---
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 1 - _sceneHeightFactor,
              widthFactor: 1,
              child: _SignInForm(
                emailController: _emailController,
                passwordController: _passwordController,
                rememberMe: _rememberMe,
                obscurePassword: _obscurePassword,
                onRememberChanged: (v) => setState(() => _rememberMe = v),
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onForgotPassword: widget.onForgotPassword,
                onCreateAccount: widget.onCreateAccount,
                onSignIn: () => widget.onSignIn(
                  _emailController.text,
                  _passwordController.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onToggleObscure;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onCreateAccount;
  final VoidCallback onSignIn;

  const _SignInForm({
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.onRememberChanged,
    required this.onToggleObscure,
    required this.onForgotPassword,
    required this.onCreateAccount,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Column(
            children: [
              Text(
                'FUEL OPS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Fuel Management System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Column(
            children: [
              Text(
                'Sign In',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Access your station operations account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _FormField(
            label: 'Email / Username',
            controller: emailController,
            hint: 'Enter your email or username',
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Password',
            controller: passwordController,
            hint: 'Enter your password',
            obscureText: obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.secondaryText,
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => onRememberChanged(!rememberMe),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: rememberMe,
                        onChanged: (v) => onRememberChanged(v ?? false),
                        activeColor: AppColors.brandRed,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Remember me',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onForgotPassword,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: onSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandRed,
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: AppColors.brandRed.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.borderDivider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.borderDivider)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: onCreateAccount,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandRed,
                side: const BorderSide(color: AppColors.brandRed, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;

  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 50,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 14, color: AppColors.primaryText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9AA5B8), fontSize: 14),
              filled: true,
              fillColor: AppColors.background,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderDivider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderDivider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.brandRed, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StationPlaceholder extends StatelessWidget {
  const _StationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB0141A), AppColors.brandRed],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_gas_station,
          size: 72,
          color: Colors.white.withOpacity(0.25),
        ),
      ),
    );
  }
}
