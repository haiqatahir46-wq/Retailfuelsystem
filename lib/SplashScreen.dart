import 'dart:async';
import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';
import 'package:petrolpump_flutter/wave_clipper.dart';


class SplashScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  final Widget? stationImage;

  const SplashScreen({
    super.key,
    required this.onGetStarted,
    this.stationImage,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _cardSlide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    // One-shot entrance: card slides up + fades in on launch.
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _introController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _introController.forward();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  // The image panel's own height, as a fraction of the screen. The wave's
  // deepest dip (see WaveClipper) stays inside this panel, and the panel
  // has a white backdrop behind the clipped photo — so the sliver between
  // the dip and the panel's bottom edge is white, not the Scaffold's red,
  // and it lines up seamlessly with the white card that starts right below.
  static const double _sceneHeightFactor = 0.6161;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandRed,
      body: Stack(
        children: [
          // --- Station image panel with a fixed wave bottom edge ---
          Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: _sceneHeightFactor,
              widthFactor: 1,
              child: DecoratedBox(
                // White backdrop: covers the gap between the wave's deepest
                // point and this panel's own bottom edge.
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

          // --- White welcome card ---
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 1 - _sceneHeightFactor,
              widthFactor: 1,
              child: AnimatedBuilder(
                animation: _introController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _cardSlide.value),
                    child: Opacity(opacity: _fade.value, child: child),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  decoration: const BoxDecoration(
                    color: AppColors.cardBackground,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to PARCO',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Monitor every pump, tank and sale across\nyour station in real time.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(3, (i) {
                              final active = i == 0;
                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                width: active ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.brandRed
                                      : AppColors.borderDivider,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                          _GetStartedButton(onTap: widget.onGetStarted),
                        ],
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

class _GetStartedButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GetStartedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brandRed,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Placeholder forecourt scene used until a real station photo is wired in.
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
          size: 96,
          color: Colors.white.withOpacity(0.25),
        ),
      ),
    );
  }
}
