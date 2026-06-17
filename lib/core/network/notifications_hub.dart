import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/env.dart';
import 'package:hanpay_mobil/core/network/auth_token_holder.dart';
import 'package:hanpay_mobil/features/auth/presentation/auth_controller.dart';
import 'package:hanpay_mobil/features/notifications/data/notification_repository.dart';
import 'package:hanpay_mobil/features/notifications/presentation/notifications_screen.dart';
import 'package:hanpay_mobil/shared/models/notification_model.dart';
import 'package:signalr_netcore/signalr_client.dart';

typedef NotificationHandler = void Function(AppNotificationDto notification);

class NotificationsHubService {
  HubConnection? _connection;
  int _connectGeneration = 0;
  final _handlers = <NotificationHandler>{};

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  void onNotification(NotificationHandler handler) => _handlers.add(handler);

  void removeNotificationHandler(NotificationHandler handler) => _handlers.remove(handler);

  Future<void> connect(String? Function() getToken) async {
    if (_connection?.state == HubConnectionState.Connected) return;

    final token = getToken();
    if (token == null || token.isEmpty) return;

    final generation = ++_connectGeneration;
    await _stopConnection();

    final connection = HubConnectionBuilder()
        .withUrl(
          Env.notificationsHubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => getToken() ?? '',
            transport: HttpTransportType.WebSockets,
          ),
        )
        .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000, 30000])
        .build();

    connection.on('ReceiveNotification', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      final raw = arguments.first;
      if (raw is! Map) return;
      final notification = AppNotificationDto.fromJson(Map<String, dynamic>.from(raw));
      if (notification.id <= 0) return;
      for (final handler in List<NotificationHandler>.from(_handlers)) {
        try {
          handler(notification);
        } catch (err, st) {
          debugPrint('notification handler error: $err\n$st');
        }
      }
    });

    _connection = connection;
    try {
      await connection.start();
      if (generation != _connectGeneration) {
        await connection.stop();
      }
    } catch (err) {
      if (generation == _connectGeneration && !_isBenignConnectAbort(err)) {
        debugPrint('[notificationsHub] connect failed: $err');
      }
    }
  }

  Future<void> disconnect() async {
    _connectGeneration++;
    await _stopConnection();
  }

  Future<void> _stopConnection() async {
    final connection = _connection;
    _connection = null;
    if (connection == null) return;
    try {
      await connection.stop();
    } catch (err) {
      if (!_isBenignConnectAbort(err)) {
        debugPrint('[notificationsHub] disconnect failed: $err');
      }
    }
  }

  bool _isBenignConnectAbort(Object err) {
    final message = err.toString();
    return message.contains('AbortError') ||
        message.contains('stopped during negotiation') ||
        message.contains('connection was stopped');
  }
}

final notificationsHubServiceProvider = Provider<NotificationsHubService>((ref) {
  final service = NotificationsHubService();
  void handler(AppNotificationDto _) {
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidate(notificationsListProvider);
  }
  service.onNotification(handler);
  ref.onDispose(() {
    service.removeNotificationHandler(handler);
    service.disconnect();
  });
  return service;
});

/// Watches auth state and keeps the SignalR hub connected while logged in.
final notificationsHubConnectionProvider = Provider<void>((ref) {
  final auth = ref.watch(authControllerProvider);
  final hub = ref.read(notificationsHubServiceProvider);
  final tokenHolder = ref.read(authTokenHolderProvider);

  if (auth.isAuthenticated) {
    Future.microtask(() => hub.connect(() => tokenHolder.token));
  } else {
    Future.microtask(hub.disconnect);
  }
});

/// Wrap app content to activate SignalR lifecycle.
class NotificationsHubListener extends ConsumerWidget {
  const NotificationsHubListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationsHubConnectionProvider);
    return child;
  }
}
