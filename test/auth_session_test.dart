import 'package:flutter_test/flutter_test.dart';
import 'package:hanpay_mobil/shared/models/auth_session.dart';
import 'package:hanpay_mobil/shared/models/role.dart';

void main() {
  test('AuthSession roundtrip json', () {
    const session = AuthSession(
      token: 'abc',
      email: 'a@b.com',
      fullName: 'Test User',
      role: AppRole.agentUser,
      userId: 1,
    );

    final decoded = AuthSession.decode(session.encode());
    expect(decoded?.email, 'a@b.com');
    expect(decoded?.role, AppRole.agentUser);
  });
}
