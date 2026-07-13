import 'client.dart';
import 'socket_events.dart';
import 'types.dart';

typedef TenantPresenceListener = void Function(Set<String> onlineUserIds);

class TenantPresenceTracker {
  TenantPresenceTracker(this._client) {
    _offSnapshot = _client.on<OnlineUserIdsSnapshot>(
      SocketEvent.tenantPresenceSnapshot,
      (snapshot) {
        onlineUserIds = snapshot.onlineUserIds.toSet();
        _notify();
      },
    );
    _offPresence = _client.on<PresenceEvent>(
      SocketEvent.tenantPresence,
      (event) {
        final next = Set<String>.from(onlineUserIds);
        if (event.online) {
          next.add(event.userId);
        } else {
          next.remove(event.userId);
        }
        onlineUserIds = next;
        _notify();
      },
    );
  }

  final SendsarClient _client;
  Set<String> onlineUserIds = {};
  final _listeners = <TenantPresenceListener>{};
  late final void Function() _offSnapshot;
  late final void Function() _offPresence;

  Set<String> getOnlineUserIds() => Set<String>.from(onlineUserIds);

  void Function() subscribe(TenantPresenceListener listener) {
    _listeners.add(listener);
    listener(onlineUserIds);
    return () => _listeners.remove(listener);
  }

  void destroy() {
    _offSnapshot();
    _offPresence();
    _listeners.clear();
  }

  void _notify() {
    final snapshot = onlineUserIds;
    for (final listener in Set<TenantPresenceListener>.from(_listeners)) {
      listener(snapshot);
    }
  }
}

TenantPresenceTracker createTenantPresenceTracker(SendsarClient client) =>
    TenantPresenceTracker(client);
