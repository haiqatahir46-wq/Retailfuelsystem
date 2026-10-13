import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/station.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/station_photo.dart';
import '../widgets/wave_clipper.dart';

/// Sign-up screen. Same wave-clipped station-photo header family as
/// [SplashScreen] / [LoginScreen] (same WaveClipper, same white-backdrop
/// fix), shorter still (5 fields need more room than the 2-field login).
///
/// Create Account only goes ahead once the form is valid: a username or
/// Gmail, a password of 6+ characters, a date of birth, a station name and
/// a whole number of stations from 1 to [Station.maxSignupStations].
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
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  /// Off until the first Create Account, then on, so errors only appear
  /// once the owner has tried to submit and then clear as each is fixed.
  var _autovalidate = AutovalidateMode.disabled;

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
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    widget.onCreateAccount(
      usernameOrGmail: _userController.text.trim(),
      password: _passwordController.text,
      dateOfBirth: _dobController.text,
      stationName: _stationController.text.trim(),
      stationCount: parseWholeNumber(_countController.text)!,
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
                        child: widget.stationImage ?? const StationPhoto(),
                      ),
                    ),
                    // Inside the safe area, so a notch or the status bar
                    // never covers it.
                    Positioned(
                      top: 0,
                      left: 0,
                      child: SafeArea(
                        right: false,
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 0, 0),
                          child: _BackButton(onTap: widget.onBack),
                        ),
                      ),
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
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidate,
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
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: Validators.requiredText('Enter a username or Gmail address'),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Password',
                        hint: 'Create a password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        validator: Validators.minLength(6, message: 'Use at least 6 characters'),
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
                        validator: Validators.requiredText('Pick your date of birth'),
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
                        textInputAction: TextInputAction.next,
                        validator: Validators.requiredText('Enter the station name'),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'No. of Stations',
                        hint: '1',
                        controller: _countController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        // Bounded, so a huge number can't make the app build
                        // millions of stations.
                        validator: Validators.intInRange(1, Station.maxSignupStations),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submit,
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: widget.onSignIn,
                        // Text.rich, unlike RichText, follows the system
                        // text size.
                        child: const Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
