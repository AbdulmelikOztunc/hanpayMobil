import 'package:flutter_test/flutter_test.dart';
import 'package:hanpay_mobil/shared/models/role.dart';

void main() {
  test('parseAppRole handles api strings', () {
    expect(parseAppRole('AgentManager'), AppRole.agentManager);
    expect(parseAppRole('DistributorUser'), AppRole.distributorUser);
    expect(parseAppRole('Admin'), AppRole.admin);
  });

  test('postLoginPath routes by role', () {
    expect(postLoginPath(AppRole.agentUser), '/agent/dashboard');
    expect(postLoginPath(AppRole.distributorManager), '/distributor/dashboard');
    expect(postLoginPath(AppRole.admin), '/admin/dashboard');
  });
}
