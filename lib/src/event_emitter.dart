typedef EventHandler<T> = void Function(T payload);

class EventEmitter {
  final _listeners = <String, Set<EventHandler<Object?>>>{};

  void Function() on<T>(String event, EventHandler<T> handler) {
    final set = _listeners.putIfAbsent(event, () => <EventHandler<Object?>>{});
    final wrapped = (Object? payload) => handler(payload as T);
    set.add(wrapped);
    return () => off(event, wrapped);
  }

  void off(String event, EventHandler<Object?> handler) {
    _listeners[event]?.remove(handler);
  }

  void emit<T>(String event, T payload) {
    final set = _listeners[event];
    if (set == null) return;
    for (final handler in Set<EventHandler<Object?>>.from(set)) {
      handler(payload);
    }
  }

  void removeAllListeners() {
    _listeners.clear();
  }
}
