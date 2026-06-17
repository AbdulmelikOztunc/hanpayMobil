import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current JWT for Dio interceptors (avoids circular provider deps).
class AuthTokenHolder {
  String? token;
}

final authTokenHolderProvider = Provider<AuthTokenHolder>((ref) => AuthTokenHolder());
