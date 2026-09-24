import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';
import 'package:petrolpump_flutter/app_text.dart';

/// Values the owner typed into AccountDetailsScreen, handed back via
/// onSubmit. Nothing here is ever pre-filled with demo data - the owner
/// enters their own real details.
class AccountDetails {
  final String fullName;
  final String fatherName;
  final String cnic;
  final String email;
  final String stationCount;
  final String nozzleCount;
  final String managerCount;

  const AccountDetails({
    required this.fullName,
    required this.fatherName,
    required this.cnic,
    required this.email,
    required this.stationCount,
    required this.nozzleCount,
    required this.managerCount,
  });
}

/// Opened from the "Account Details" row on ProfileScreen. Matches the
/// Figma reference exactly: Full Name, Father Name, CNIC, Email Address,
/// No. Of Stations, No. Of Nozzles, No. Of Managers, then Submit. Every
/// field starts blank - the owner fills in their own details, nothing is
/// pre-filled with demo data. No bottom nav (this is a drill-down, not a
/// tab), just a back arrow to return to Profile.
class AccountDetailsScreen extends StatefulWidget {
  final String stationName;
  final VoidCallback? onBack;
  final ValueChanged<AccountDetails>? onSubmit;

  const AccountDetailsScreen({
    super.key,
    required this.stationName,
    this.onBack,
    this.onSubmit,
  });

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final _fullNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _emailController = TextEditingController();
  final _stationCountController = TextEditingController();
  final _nozzleCountController = TextEditingController();
  final _managerCountController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _fatherNameController.dispose();
    _cnicController.dispose();
    _emailController.dispose();
    _stationCountController.dispose();
    _nozzleCountController.dispose();
    _managerCountController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmit?.call(
      AccountDetails(
        fullName: _fullNameController.text.trim(),
        fatherName: _fatherNameController.text.trim(),
        cnic: _cnicController.text.trim(),
        email: _emailController.text.trim(),
        stationCount: _stationCountController.text.trim(),
        nozzleCount: _nozzleCountController.text.trim(),
        managerCount: _managerCountController.text.trim(),
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
          const Text(
            'Account Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText),
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
            label: 'No. Of Stations',
            hint: '',
            controller: _stationCountController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'No. Of Nozzles',
            hint: '',
            controller: _nozzleCountController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'No. Of Managers',
            hint: '',
            controller: _managerCountController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
