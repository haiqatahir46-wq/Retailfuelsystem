import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/station_photo.dart';
import '../widgets/wave_clipper.dart';

/// Sign-in screen. Reuses the exact same station-photo + fixed-wave header
/// as [SplashScreen] (same WaveClipper, same white-backdrop fix so there's
/// no gap color), just with a shorter image panel to leave room for the
/// form below. Sign In only goes ahead once both fields are filled in.
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
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  /// Off until the first Sign In, then on, so errors only appear once the
  /// owner has tried to sign in and then clear as each field is fixed.
  var _autovalidate = AutovalidateMode.disabled;

  // Image panel height as a fraction of the screen - shorter than the
  // splash screen's 0.6161 so the form has room to breathe.
  static const double _sceneHeightFactor = 0.3541;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    widget.onSignIn(_emailController.text.trim(), _passwordController.text);
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
                    child: widget.stationImage ?? const StationPhoto(),
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
                formKey: _formKey,
                autovalidateMode: _autovalidate,
                emailController: _emailController,
                passwordController: _passwordController,
                rememberMe: _rememberMe,
                obscurePassword: _obscurePassword,
                onRememberChanged: (v) => setState(() => _rememberMe = v),
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onForgotPassword: widget.onForgotPassword,
                onCreateAccount: widget.onCreateAccount,
                onSignIn: _signIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final AutovalidateMode autovalidateMode;
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
    required this.formKey,
    required this.autovalidateMode,
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
      child: Form(
        key: formKey,
        autovalidateMode: autovalidateMode,
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
            AppTextField(
              label: 'Email / Username',
              controller: emailController,
              hint: 'Enter your email or username',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.requiredText('Enter your email or username'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              controller: passwordController,
              hint: 'Enter your password',
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              validator: Validators.requiredText('Enter your password'),
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
            // A Wrap, not a Row: when a narrow screen or large text leaves
            // no room for both, "Forgot Password?" moves to its own line
            // instead of overflowing.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
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
            ElevatedButton(
              onPressed: onSignIn,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.brandRed,
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: AppColors.brandRed.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
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
            OutlinedButton(
              onPressed: onCreateAccount,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
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
          ],
        ),
      ),
    );
  }
}
