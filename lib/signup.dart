import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';
import 'package:petrolpump_flutter/app_text.dart';
import 'package:petrolpump_flutter/wave_clipper.dart';
import 'package:petrolpump_flutter/add_station.dart';

/// Sign-up screen. Same wave-clipped station-photo header family as
/// [SplashScreen] / [LoginScreen] (same WaveClipper, same white-backdrop
/// fix), shorter still (5 fields need more room than the 2-field login).
class SignupScreen extends StatefulWidget {
  final Widget? stationImage;
  final VoidCallback? onBack;
  final VoidCallback? onSignIn;
  final void Function({
    required String usernameOrGmail,
    required String password,
    required String dateOfBirth,
    required String stationName,
    required int stationCount,
  }) onCreateAccount;

  const SignupScreen({
    super.key,
    required this.onCreateAccount,
    this.stationImage,
    this.onBack,
    this.onSignIn,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  final _stationController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  bool _obscurePassword = true;

  // Shorter than the login screen's 0.3541 - five fields need more room.
  static const double _sceneHeightFactor = 0.3004;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _stationController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) {
      _dobController.text =
          '${picked.day.toString().padLeft(2, '0')} / ${picked.month.toString().padLeft(2, '0')} / ${picked.year}';
    }
  }

  void _submit() {
    widget.onCreateAccount(
      usernameOrGmail: _userController.text,
      password: _passwordController.text,
      dateOfBirth: _dobController.text,
      stationName: _stationController.text,
      stationCount: int.tryParse(_countController.text) ?? 1,
    );
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
                child: Stack(
                  children: [
                    ClipPath(
                      clipper: const WaveClipper(),
                      child: SizedBox.expand(
                        child: widget.stationImage ?? const _StationPlaceholder(),
                      ),
                    ),
                    Positioned(
                      top: 22,
                      left: 20,
                      child: _BackButton(onTap: widget.onBack),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Sign-up form ---
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 1 - _sceneHeightFactor,
              widthFactor: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Column(
                      children: [
                        Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Set up your station operations account',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    AppTextField(
                      label: 'Username or Gmail',
                      hint: 'Enter username or Gmail',
                      controller: _userController,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Password',
                      hint: 'Create a password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.secondaryText,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Date of Birth',
                      hint: 'DD / MM / YYYY',
                      controller: _dobController,
                      readOnly: true,
                      onTap: _pickDateOfBirth,
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.secondaryText,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Name of Station',
                      hint: 'e.g. Amir Filling, Pattoki',
                      controller: _stationController,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'No. of Stations',
                      hint: '1',
                      controller: _countController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submit,
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: widget.onSignIn,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                          children: [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted circular back button over the photo, same pill treatment as the
/// logo mark used earlier - a solid-ish backdrop so it reads as a UI chip
/// against the photo rather than a plain icon floating on it.
class _BackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Material(
          color: const Color(0x73170F0F),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            ),
          ),
        ),
      ),
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
          size: 64,
          color: Colors.white.withOpacity(0.25),
        ),
      ),
    );
  }
}
