import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';
import 'package:petrolpump_flutter/app_text.dart';

class StaffFormValues {
  final String fullName;
  final String fatherName;
  final String cnic;
  final String email;
  final String contactNumber;
  final String stationLocation;

  const StaffFormValues({
    required this.fullName,
    required this.fatherName,
    required this.cnic,
    required this.email,
    required this.contactNumber,
    required this.stationLocation,
  });
}

class StaffFormScreen extends StatefulWidget {
  final String stationName;
  final String roleLabel;
  final Widget? frontCnicImage;
  final Widget? backCnicImage;
  final VoidCallback? onBack;
  final VoidCallback? onUploadFrontCnic;
  final VoidCallback? onUploadBackCnic;
  final ValueChanged<StaffFormValues>? onSave;

  const StaffFormScreen({
    super.key,
    required this.stationName,
    this.roleLabel = 'Add Staff',
    this.frontCnicImage,
    this.backCnicImage,
    this.onBack,
    this.onUploadFrontCnic,
    this.onUploadBackCnic,
    this.onSave,
  });

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _fullNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _stationLocationController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _fatherNameController.dispose();
    _cnicController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _stationLocationController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave?.call(
      StaffFormValues(
        fullName: _fullNameController.text.trim(),
        fatherName: _fatherNameController.text.trim(),
        cnic: _cnicController.text.trim(),
        email: _emailController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        stationLocation: _stationLocationController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: Text(
          widget.stationName,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primaryText),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderDivider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            widget.roleLabel,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
          const SizedBox(height: 18),
          AppTextField(label: 'Full Name', hint: '', controller: _fullNameController),
          const SizedBox(height: 14),
          AppTextField(label: 'Father Name', hint: '', controller: _fatherNameController),
          const SizedBox(height: 14),
          AppTextField(label: 'CNIC', hint: '', controller: _cnicController, keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Email Address',
            hint: '',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Contact Number',
            hint: '',
            controller: _contactNumberController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          AppTextField(label: 'Station Location', hint: '', controller: _stationLocationController),
          const SizedBox(height: 20),
          const Text(
            'Upload Cnic',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CnicUploadBox(
                  label: 'Front Side',
                  image: widget.frontCnicImage,
                  onTap: widget.onUploadFrontCnic,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CnicUploadBox(
                  label: 'Back Side',
                  image: widget.backCnicImage,
                  onTap: widget.onUploadBackCnic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

/// One CNIC side's upload slot - shows a plus icon until an image is
/// supplied via [image], then shows that image instead.
class _CnicUploadBox extends StatelessWidget {
  final String label;
  final Widget? image;
  final VoidCallback? onTap;

  const _CnicUploadBox({required this.label, this.image, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: DottedBorderBox(
        child: AspectRatio(
          aspectRatio: 1.4,
          child: image ??
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.redLightSelected,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, size: 18, color: AppColors.brandRed),
                    ),
                    const SizedBox(height: 8),
                    Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

/// Dashed-border container - Flutter has no built-in dashed border, so this
/// paints one with a CustomPainter instead of pulling in a package for it.
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(color: AppColors.background, child: child),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderDivider
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
