import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';

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
///
/// Nothing is required, but Submit checks what was typed: a valid email
/// and 13-digit CNIC if given, and whole numbers from 0 for the counts.
class AccountDetailsScreen extends StatefulWidget {
  final String stationName;
  final VoidCallback? onBack;
  final ValueChanged<AccountDetails>? onSubmit;

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();

  const AccountDetailsScreen({
    super.key,
    required this.stationName,
    this.onBack,
    this.onSubmit,
  });
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final _fullNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _emailController = TextEditingController();
  final _stationCountController = TextEditingController();
  final _nozzleCountController = TextEditingController();
  final _managerCountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// Off until the first Submit, then on, so errors only appear once the
  /// owner has tried to submit and then clear as each field is fixed.
  var _autovalidate = AutovalidateMode.disabled;

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
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
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
      // A Column in a scroll view rather than a ListView: a ListView only
      // builds the rows on screen, and Form.validate can't check a field
      // that has been scrolled away and disposed.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Account Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText),
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Full Name',
                hint: '',
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Father Name',
                hint: '',
                controller: _fatherNameController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'CNIC',
                hint: '35202-1234567-1',
                controller: _cnicController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: Validators.cnic(),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Email Address',
                hint: '',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.email(),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'No. Of Stations',
                hint: '',
                controller: _stationCountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: Validators.wholeNumber(required: false),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'No. Of Nozzles',
                hint: '',
                controller: _nozzleCountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: Validators.wholeNumber(required: false),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'No. Of Managers',
                hint: '',
                controller: _managerCountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: Validators.wholeNumber(required: false),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.brandRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
