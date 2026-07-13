import 'types.dart';

String textFromMessageParts(List<MessagePart> parts) {
  return parts
      .where((p) => p.type == 'text' && p.text != null)
      .map((p) => p.text!)
      .join('\n');
}

int _messageTime(HasMessageId message) {
  if (message.createdAt == null) return 0;
  final t = DateTime.tryParse(message.createdAt!);
  return t?.millisecondsSinceEpoch ?? 0;
}

abstract class HasMessageId {
  String get id;
  String? get createdAt;
}

List<T> mergeMessagesById<T extends HasMessageId>(
  List<T> existing,
  List<T> incoming,
) {
  final byId = <String, T>{for (final m in existing) m.id: m};
  for (final msg in incoming) {
    byId[msg.id] = msg;
  }
  return byId.values.toList()
    ..sort((a, b) => _messageTime(a).compareTo(_messageTime(b)));
}

typedef IsOptimisticSend<T> = bool Function(T message, T serverMessage);

List<T> reconcileSelfSentMessage<T extends HasMessageId>(
  List<T> existing,
  T serverMessage, {
  IsOptimisticSend<T>? isOptimisticSend,
}) {
  bool defaultIsOptimistic(T message, T server) => message.id == server.id;

  final isOptimistic = isOptimisticSend ?? defaultIsOptimistic;
  final filtered = existing.where((m) => !isOptimistic(m, serverMessage)).toList();
  return mergeMessagesById(filtered, [serverMessage]);
}

int _roomActivityTime(RoomSummary room) {
  final createdAt = room.lastMessage?.createdAt;
  if (createdAt == null) return 0;
  return DateTime.tryParse(createdAt)?.millisecondsSinceEpoch ?? 0;
}

List<RoomSummary> sortRoomsByLatestActivity(List<RoomSummary> rooms) {
  final copy = [...rooms];
  copy.sort((a, b) {
    final diff = _roomActivityTime(b).compareTo(_roomActivityTime(a));
    if (diff != 0) return diff;
    return a.id.compareTo(b.id);
  });
  return copy;
}

bool isMessageReadByPeer({
  required String messageCreatedAt,
  required String messageSenderId,
  String? messageDeletedAt,
  required String selfUserId,
  String? peerLastReadAt,
}) {
  if (messageDeletedAt != null) return false;
  if (messageSenderId != selfUserId) return false;
  if (peerLastReadAt == null) return false;
  final readAt = DateTime.tryParse(peerLastReadAt);
  final createdAt = DateTime.tryParse(messageCreatedAt);
  if (readAt == null || createdAt == null) return false;
  return !readAt.isBefore(createdAt);
}
