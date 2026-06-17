import 'dart:convert';

import 'package:hanpay_mobil/shared/models/role.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.email,
    required this.fullName,
    required this.role,
    required this.userId,
    this.permissions = const [],
    this.agentId,
    this.distributorId,
    this.agentName,
    this.distributorName,
  });

  final String token;
  final String email;
  final String fullName;
  final AppRole role;
  final int userId;
  final List<String> permissions;
  final int? agentId;
  final int? distributorId;
  final String? agentName;
  final String? distributorName;

  Map<String, dynamic> toJson() => {
        'token': token,
        'email': email,
        'fullName': fullName,
        'role': role.apiValue,
        'userId': userId,
        'permissions': permissions,
        'agentId': agentId,
        'distributorId': distributorId,
        'agentName': agentName,
        'distributorName': distributorName,
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: parseAppRole(json['role']) ?? AppRole.agentUser,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      agentId: (json['agentId'] as num?)?.toInt(),
      distributorId: (json['distributorId'] as num?)?.toInt(),
      agentName: json['agentName'] as String?,
      distributorName: json['distributorName'] as String?,
    );
  }

  static AuthSession fromApiResponse(Map<String, dynamic> data) {
    final token = _extractToken(data);
    final jwt = token.isNotEmpty ? _decodeJwtPayload(token) : null;

    final roleRaw = data['role'] ??
        (data['user'] as Map<String, dynamic>?)?['role'] ??
        (data['data'] as Map<String, dynamic>?)?['role'] ??
        jwt?['role'] ??
        jwt?['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];

    final permissions = _stringList(
      data['permissions'] ?? jwt?['permissions'] ?? jwt?['permission'],
    );

    int? pickInt(Object? value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    T? pick<T>(List<Object?> values) {
      for (final v in values) {
        if (v != null && (v is! String || v.isNotEmpty)) return v as T;
      }
      return null;
    }

    return AuthSession(
      token: token,
      email: pick<String>([
            data['email'],
            (data['user'] as Map?)?['email'],
          ]) ??
          '',
      fullName: pick<String>([
            data['fullName'],
            data['name'],
            (data['user'] as Map?)?['fullName'],
          ]) ??
          '',
      role: parseAppRole(roleRaw) ?? AppRole.agentUser,
      userId: pickInt(data['userId'] ?? data['id'] ?? (data['user'] as Map?)?['id']) ?? 0,
      permissions: permissions,
      agentId: pickInt(data['agentId'] ?? jwt?['scope_agent_id']),
      distributorId: pickInt(data['distributorId'] ?? jwt?['scope_distributor_id']),
      agentName: pick<String>([data['agentName'], jwt?['scope_agent_name']]),
      distributorName: pick<String>([data['distributorName'], jwt?['scope_distributor_name']]),
    );
  }

  String encode() => jsonEncode(toJson());

  static AuthSession? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

List<String> _stringList(Object? value) {
  if (value is List) return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  if (value is String) {
    return value.split(RegExp(r'[,\s]+')).where((e) => e.isNotEmpty).toList();
  }
  return const [];
}

String _extractToken(Map<String, dynamic> data) {
  final nested = data['data'] as Map<String, dynamic>?;
  final user = data['user'] as Map<String, dynamic>?;
  final nestedUser = nested?['user'] as Map<String, dynamic>?;

  final raw = data['token'] ??
      data['accessToken'] ??
      data['jwtToken'] ??
      user?['token'] ??
      nested?['token'] ??
      nested?['accessToken'] ??
      nestedUser?['token'];

  return raw?.toString().replaceFirst(RegExp(r'^Bearer\s+', caseSensitive: false), '').trim() ?? '';
}

Map<String, dynamic>? _decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    var payload = parts[1];
    payload = payload.padRight(payload.length + (4 - payload.length % 4) % 4, '=');
    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
