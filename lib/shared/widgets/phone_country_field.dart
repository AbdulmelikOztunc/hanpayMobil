import 'package:flutter/material.dart';
import 'package:hanpay_mobil/shared/utils/receiver_phone_format.dart';

class PhoneCountryField extends StatelessWidget {
  const PhoneCountryField({
    super.key,
    required this.country,
    required this.phoneController,
    required this.onCountryChanged,
    required this.countryLabel,
    required this.phoneLabel,
    required this.countryTmLabel,
    required this.countryTrLabel,
    required this.phonePlaceholder,
    this.countryError,
    this.phoneValidator,
    this.disabled = false,
  });

  final ReceiverPhoneCountry country;
  final TextEditingController phoneController;
  final ValueChanged<ReceiverPhoneCountry> onCountryChanged;
  final String countryLabel;
  final String phoneLabel;
  final String countryTmLabel;
  final String countryTrLabel;
  final String phonePlaceholder;
  final String? countryError;
  final FormFieldValidator<String>? phoneValidator;
  final bool disabled;

  void _handleCountryChange(ReceiverPhoneCountry? next) {
    if (next == null || next == country) return;
    final national = extractReceiverNationalDigits(country, phoneController.text);
    onCountryChanged(next);
    phoneController.text =
        national.isNotEmpty ? formatReceiverPhoneInput(next, national) : '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<ReceiverPhoneCountry>(
          key: ValueKey(country),
          isExpanded: true,
          initialValue: country,
          decoration: InputDecoration(
            labelText: countryLabel,
            errorText: countryError,
          ),
          items: [
            DropdownMenuItem(value: ReceiverPhoneCountry.tm, child: Text(countryTmLabel)),
            DropdownMenuItem(value: ReceiverPhoneCountry.tr, child: Text(countryTrLabel)),
          ],
          onChanged: disabled ? null : _handleCountryChange,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          readOnly: disabled,
          decoration: InputDecoration(
            labelText: phoneLabel,
            hintText: phonePlaceholder,
          ),
          onChanged: disabled
              ? null
              : (value) {
                  final formatted = formatReceiverPhoneInput(country, value);
                  if (formatted != value) {
                    phoneController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
          validator: phoneValidator,
        ),
      ],
    );
  }
}
