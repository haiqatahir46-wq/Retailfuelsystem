import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Labeled input matching the login/sign-up field style: off-white fill,
/// rounded border, brand-red focus ring.
///
/// A [TextFormField], so a surrounding [Form] validates it with [validator]
/// and shows the message under the box. The box has no fixed height: the
/// padding gives the usual 48dp at normal text size, and it grows for
/// larger system text or an error line instead of clipping them.
class AppTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderDivider),
    );
    final errorBorder = border.copyWith(borderSide: const BorderSide(color: AppColors.statusFault));

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
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          enabled: enabled,
          onTap: onTap,
          validator: validator,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          textInputAction: textInputAction,
          style: TextStyle(fontSize: 14, color: enabled ? AppColors.primaryText : AppColors.secondaryText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9AA5B8), fontSize: 14),
            filled: true,
            fillColor: AppColors.background,
            suffixIcon: suffixIcon,
            isDense: true,
            // 13.5 above and below a 21dp line of 14px text = the 48dp box
            // this field used to be fixed at.
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13.5),
            errorMaxLines: 2,
            border: border,
            enabledBorder: border,
            disabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: AppColors.brandRed, width: 1.4),
            ),
            errorBorder: errorBorder,
            focusedErrorBorder: errorBorder.copyWith(
              borderSide: const BorderSide(color: AppColors.statusFault, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.validator,
    this.inputFormatters,
    this.onChanged,
    this.textInputAction,
  });
}
