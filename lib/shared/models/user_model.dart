import 'package:hanpay_mobil/shared/models/json_helpers.dart';

class AppUserDto {
  const AppUserDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.phone,
    this.agentName,
    this.distributorName,
  });

  final int id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final String? phone;
  final String? agentName;
  final String? distributorName;

  factory AppUserDto.fromJson(Map<String, dynamic> json) => AppUserDto(
        id: jsonInt(json['id']),
        email: jsonStr(json['email'] ?? json['userName']),
        fullName: jsonStr(json['fullName']),
        role: jsonStr(json['role']),
        isActive: json['isActive'] == true,
        phone: json['phone'] as String?,
        agentName: json['agentName'] as String?,
        distributorName: json['distributorName'] as String?,
      );
}
