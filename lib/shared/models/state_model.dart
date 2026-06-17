import 'package:hanpay_mobil/shared/models/json_helpers.dart';

class StateDto {
  const StateDto({required this.id, required this.name, required this.code});

  final int id;
  final String name;
  final String code;

  factory StateDto.fromJson(Map<String, dynamic> json) => StateDto(
        id: jsonInt(json['id']),
        name: jsonStr(json['name']),
        code: jsonStr(json['code']),
      );
}
