import 'types.dart';

const typingStopMs = 2000;
const typingDmLabel = 'Typing…';

typedef TypingByRoom = Map<String, Set<String>>;

TypingByRoom applyTypingEvent(TypingByRoom prev, TypingEvent event) {
  final next = Map<String, Set<String>>.from(prev);
  final roomTyping = Set<String>.from(next[event.roomId] ?? {});
  if (event.isTyping) {
    roomTyping.add(event.userId);
  } else {
    roomTyping.remove(event.userId);
  }
  if (roomTyping.isEmpty) {
    next.remove(event.roomId);
  } else {
    next[event.roomId] = roomTyping;
  }
  return next;
}

TypingByRoom clearUserTyping(TypingByRoom prev, String roomId, String userId) {
  final roomTyping = prev[roomId];
  if (roomTyping == null || !roomTyping.contains(userId)) return prev;
  final next = Map<String, Set<String>>.from(prev);
  final set = Set<String>.from(next[roomId]!);
  set.remove(userId);
  if (set.isEmpty) {
    next.remove(roomId);
  } else {
    next[roomId] = set;
  }
  return next;
}

List<String> otherTypingUserIds(
  TypingByRoom typingByRoom,
  String roomId,
  String selfUserId,
) {
  return (typingByRoom[roomId] ?? {}).where((id) => id != selfUserId).toList();
}

String formatTypingLabel(
  List<String> typingUserIds,
  Map<String, String> displayNames, {
  bool directMessage = false,
}) {
  if (typingUserIds.isEmpty) return '';
  if (directMessage) return typingDmLabel;

  final names = typingUserIds.map((id) => displayNames[id] ?? 'Someone').toList();
  if (names.length == 1) return '${names[0]} is typing…';
  if (names.length == 2) return '${names[0]} and ${names[1]} are typing…';
  return '${names[0]}, ${names[1]} and ${names.length - 2} others are typing…';
}

String? inboxSubtitleForPeer({
  String? typingLabel,
  String? lastMessagePreview,
}) {
  if (typingLabel != null && typingLabel.isNotEmpty) return typingLabel;
  return lastMessagePreview;
}
