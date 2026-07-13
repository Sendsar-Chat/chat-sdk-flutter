import 'dart:async';

import 'client.dart';
import 'socket_events.dart';
import 'types.dart';

class RoomSubscriptionOptions {
  const RoomSubscriptionOptions({
    required this.roomId,
    required this.userId,
    this.limit = 50,
    this.onInitialMessages,
    this.onMessage,
    this.onMessageUpdated,
    this.onPeerLastReadAt,
    this.autoMarkRead = true,
  });

  final String roomId;
  final String userId;
  final int limit;
  final void Function(List<Message> messages, String? peerLastReadAt)? onInitialMessages;
  final void Function(Message message)? onMessage;
  final void Function(Message message)? onMessageUpdated;
  final void Function(String lastReadAt)? onPeerLastReadAt;
  final bool autoMarkRead;
}

class RoomSubscription {
  RoomSubscription._({required this.destroy});

  final void Function() destroy;
}

RoomSubscription createRoomSubscription(
  SendsarClient client,
  RoomSubscriptionOptions options,
) {
  var cancelled = false;
  void Function()? offConnected;
  var activated = false;

  Future<void> loadInitialMessages() async {
    if (cancelled || !client.isConnected) return;
    final response = await client.getMessages(options.roomId, ListMessagesParams(limit: options.limit));
    if (cancelled) return;
    options.onInitialMessages?.call(response.messages.reversed.toList(), response.peerLastReadAt);
    final lastId = response.messages.isNotEmpty ? response.messages.first.id : null;
    if (lastId != null) {
      unawaited(client.markRoomRead(options.roomId, lastId));
    }
  }

  void activate() {
    if (cancelled || activated || !client.isConnected) return;
    activated = true;
    client.joinRoom(JoinRoomParams(roomId: options.roomId));
    unawaited(loadInitialMessages());
  }

  if (client.isConnected) {
    activate();
  } else {
    offConnected = client.on<ConnectedUser>(SendsarEventMap.connected, (_) {
      offConnected?.call();
      offConnected = null;
      activate();
    });
  }

  final offNew = client.on<Message>(SocketEvent.newMessage, (msg) {
    if (msg.roomId != options.roomId) return;
    options.onMessage?.call(msg);
    if (options.autoMarkRead && msg.senderId != options.userId) {
      unawaited(client.markRoomRead(options.roomId, msg.id));
    }
  });

  final offUpdated = client.on<Message>(SocketEvent.messageUpdated, (msg) {
    if (msg.roomId != options.roomId) return;
    options.onMessageUpdated?.call(msg);
  });

  final offRoomRead = client.on<RoomReadEvent>(SocketEvent.roomRead, (event) {
    if (event.roomId != options.roomId || event.userId == options.userId) return;
    options.onPeerLastReadAt?.call(event.lastReadAt);
  });

  return RoomSubscription._(
    destroy: () {
      cancelled = true;
      offConnected?.call();
      offConnected = null;
      offNew();
      offUpdated();
      offRoomRead();
      if (client.isConnected) {
        client.leaveRoom(options.roomId);
      }
    },
  );
}
