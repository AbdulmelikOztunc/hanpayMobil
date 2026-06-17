enum AppRole {
  admin,
  assistantAdmin,
  agentManager,
  agentUser,
  distributorManager,
  distributorUser,
}

extension AppRoleX on AppRole {
  String get apiValue => switch (this) {
        AppRole.admin => 'Admin',
        AppRole.assistantAdmin => 'AssistantAdmin',
        AppRole.agentManager => 'AgentManager',
        AppRole.agentUser => 'AgentUser',
        AppRole.distributorManager => 'DistributorManager',
        AppRole.distributorUser => 'DistributorUser',
      };

  bool get isAgent => this == AppRole.agentManager || this == AppRole.agentUser;

  bool get isDistributor =>
      this == AppRole.distributorManager || this == AppRole.distributorUser;

  bool get isAdmin => this == AppRole.admin || this == AppRole.assistantAdmin;

  String get label => switch (this) {
        AppRole.admin => 'Admin',
        AppRole.assistantAdmin => 'Assistant Admin',
        AppRole.agentManager => 'Agent Manager',
        AppRole.agentUser => 'Agent User',
        AppRole.distributorManager => 'Distributor Manager',
        AppRole.distributorUser => 'Distributor User',
      };
}

AppRole? parseAppRole(Object? raw) {
  if (raw == null) return null;
  if (raw is int) {
    return switch (raw) {
      0 => AppRole.admin,
      1 => AppRole.assistantAdmin,
      2 => AppRole.agentManager,
      3 => AppRole.agentUser,
      4 => AppRole.distributorManager,
      5 => AppRole.distributorUser,
      _ => null,
    };
  }

  final value = raw.toString().toLowerCase().trim();
  if (value.isEmpty) return null;

  if (value.contains('assistantadmin')) return AppRole.assistantAdmin;
  if (value.contains('admin')) return AppRole.admin;
  if (value.contains('agentmanager')) return AppRole.agentManager;
  if (value.contains('agentuser')) return AppRole.agentUser;
  if (value.contains('distributormanager')) return AppRole.distributorManager;
  if (value.contains('distributoruser')) return AppRole.distributorUser;

  return switch (value) {
    '0' => AppRole.admin,
    '1' => AppRole.assistantAdmin,
    '2' => AppRole.agentManager,
    '3' => AppRole.agentUser,
    '4' => AppRole.distributorManager,
    '5' => AppRole.distributorUser,
    _ => null,
  };
}

String postLoginPath(AppRole role) {
  if (role.isAgent) return '/agent/dashboard';
  if (role.isDistributor) return '/distributor/dashboard';
  if (role.isAdmin) return '/admin/dashboard';
  return '/agent/dashboard';
}
