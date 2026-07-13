typedef JsonMap = Map<String, dynamic>;

class MessagePart {
  const MessagePart({
    required this.type,
    this.text,
    this.mediaType,
    this.url,
    this.uploadId,
    this.filename,
    this.accessUrl,
    this.accessUrlExpiresAt,
    this.data,
    this.state,
    this.extra = const {},
  });

  final String type;
  final String? text;
  final String? mediaType;
  final String? url;
  final String? uploadId;
  final String? filename;
  final String? accessUrl;
  final String? accessUrlExpiresAt;
  final Object? data;
  final String? state;
  final Map<String, Object?> extra;

  factory MessagePart.fromJson(JsonMap json) {
    final known = <String>{
      'type',
      'text',
      'mediaType',
      'url',
      'uploadId',
      'filename',
      'accessUrl',
      'accessUrlExpiresAt',
      'data',
      'state',
    };
    final extra = <String, Object?>{};
    json.forEach((key, value) {
      if (!known.contains(key)) extra[key] = value;
    });
    return MessagePart(
      type: json['type'] as String,
      text: json['text'] as String?,
      mediaType: json['mediaType'] as String?,
      url: json['url'] as String?,
      uploadId: json['uploadId'] as String?,
      filename: json['filename'] as String?,
      accessUrl: json['accessUrl'] as String?,
      accessUrlExpiresAt: json['accessUrlExpiresAt'] as String?,
      data: json['data'],
      state: json['state'] as String?,
      extra: extra,
    );
  }

  JsonMap toJson() => {
        'type': type,
        if (text != null) 'text': text,
        if (mediaType != null) 'mediaType': mediaType,
        if (url != null) 'url': url,
        if (uploadId != null) 'uploadId': uploadId,
        if (filename != null) 'filename': filename,
        if (accessUrl != null) 'accessUrl': accessUrl,
        if (accessUrlExpiresAt != null) 'accessUrlExpiresAt': accessUrlExpiresAt,
        if (data != null) 'data': data,
        if (state != null) 'state': state,
        ...extra,
      };
}

class MessageReaction {
  const MessageReaction({required this.userId, required this.emoji});

  final String userId;
  final String emoji;

  factory MessageReaction.fromJson(JsonMap json) => MessageReaction(
        userId: json['userId'] as String,
        emoji: json['emoji'] as String,
      );
}

class ParentMessagePreview {
  const ParentMessagePreview({
    required this.id,
    required this.senderId,
    required this.parts,
    required this.previewText,
    required this.deleted,
  });

  final String id;
  final String senderId;
  final List<MessagePart> parts;
  final String? previewText;
  final bool deleted;

  factory ParentMessagePreview.fromJson(JsonMap json) => ParentMessagePreview(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        parts: (json['parts'] as List<dynamic>)
            .map((e) => MessagePart.fromJson(e as JsonMap))
            .toList(),
        previewText: json['previewText'] as String?,
        deleted: json['deleted'] as bool? ?? false,
      );
}

class Message {
  const Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.parts,
    required this.previewText,
    required this.createdAt,
    this.clientMessageId,
    this.parentMessageId,
    this.parentMessage,
    this.deletedAt,
    this.deletedHidden,
    this.editedAt,
    this.reactions,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String? clientMessageId;
  final List<MessagePart> parts;
  final String? previewText;
  final String createdAt;
  final String? parentMessageId;
  final ParentMessagePreview? parentMessage;
  final String? deletedAt;
  final bool? deletedHidden;
  final String? editedAt;
  final List<MessageReaction>? reactions;

  factory Message.fromJson(JsonMap json) => Message(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        senderId: json['senderId'] as String,
        clientMessageId: json['clientMessageId'] as String?,
        parts: (json['parts'] as List<dynamic>)
            .map((e) => MessagePart.fromJson(e as JsonMap))
            .toList(),
        previewText: json['previewText'] as String?,
        createdAt: json['createdAt'] as String,
        parentMessageId: json['parentMessageId'] as String?,
        parentMessage: json['parentMessage'] == null
            ? null
            : ParentMessagePreview.fromJson(json['parentMessage'] as JsonMap),
        deletedAt: json['deletedAt'] as String?,
        deletedHidden: json['deletedHidden'] as bool?,
        editedAt: json['editedAt'] as String?,
        reactions: (json['reactions'] as List<dynamic>?)
            ?.map((e) => MessageReaction.fromJson(e as JsonMap))
            .toList(),
      );
}

class RoomSummary {
  const RoomSummary({
    required this.id,
    required this.name,
    required this.externalId,
    required this.customType,
    required this.metadata,
    required this.isFrozen,
    required this.lastMessage,
    required this.createdAt,
    this.avatarUrl,
    this.unreadCount,
    this.lastReadMessageId,
  });

  final String id;
  final String? name;
  final String? avatarUrl;
  final String? externalId;
  final String? customType;
  final Map<String, dynamic>? metadata;
  final bool isFrozen;
  final ({String? previewText, String createdAt})? lastMessage;
  final int? unreadCount;
  final String? lastReadMessageId;
  final String createdAt;

  factory RoomSummary.fromJson(JsonMap json) {
    final last = json['lastMessage'] as JsonMap?;
    return RoomSummary(
      id: json['id'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      externalId: json['externalId'] as String?,
      customType: json['customType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isFrozen: json['isFrozen'] as bool? ?? false,
      lastMessage: last == null
          ? null
          : (
              previewText: last['previewText'] as String?,
              createdAt: last['createdAt'] as String,
            ),
      unreadCount: json['unreadCount'] as int?,
      lastReadMessageId: json['lastReadMessageId'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}

class MessagesResponse {
  const MessagesResponse({
    required this.messages,
    required this.nextCursor,
    required this.peerLastReadAt,
    this.peerLastDeliveredAt,
  });

  final List<Message> messages;
  final String? nextCursor;
  final String? peerLastReadAt;
  final String? peerLastDeliveredAt;

  factory MessagesResponse.fromJson(JsonMap json) => MessagesResponse(
        messages: (json['messages'] as List<dynamic>)
            .map((e) => Message.fromJson(e as JsonMap))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
        peerLastReadAt: json['peerLastReadAt'] as String?,
        peerLastDeliveredAt: json['peerLastDeliveredAt'] as String?,
      );
}

class RoomsResponse {
  const RoomsResponse({required this.rooms, required this.nextCursor});

  final List<RoomSummary> rooms;
  final String? nextCursor;

  factory RoomsResponse.fromJson(JsonMap json) => RoomsResponse(
        rooms: (json['rooms'] as List<dynamic>)
            .map((e) => RoomSummary.fromJson(e as JsonMap))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
      );
}

class ConnectedUser {
  const ConnectedUser({required this.userId});

  final String userId;
}

class SendsarInitOptions {
  const SendsarInitOptions({required this.apiUrl});

  final String apiUrl;
}

class ConnectOptions {
  const ConnectOptions({
    required this.userId,
    required this.token,
    this.connectTimeoutMs = 30000,
  });

  final String userId;
  final String token;
  final int connectTimeoutMs;
}

typedef DeletedMessageDisplay = String; // 'placeholder' | 'hidden'

class TenantChatSettings {
  const TenantChatSettings({
    required this.deletedMessageDisplay,
    required this.deletedMessagePlaceholder,
  });

  final DeletedMessageDisplay deletedMessageDisplay;
  final String deletedMessagePlaceholder;

  factory TenantChatSettings.fromJson(JsonMap json) => TenantChatSettings(
        deletedMessageDisplay: json['deletedMessageDisplay'] as String,
        deletedMessagePlaceholder: json['deletedMessagePlaceholder'] as String,
      );
}

class SessionResponse {
  const SessionResponse({
    required this.token,
    required this.expiresAt,
    required this.apiUrl,
    required this.chatUserId,
    required this.displayName,
    this.impersonating,
    this.chatSettings,
  });

  final String token;
  final String expiresAt;
  final String apiUrl;
  final String chatUserId;
  final String displayName;
  final bool? impersonating;
  final TenantChatSettings? chatSettings;

  factory SessionResponse.fromJson(JsonMap json) => SessionResponse(
        token: json['token'] as String,
        expiresAt: json['expiresAt'] as String,
        apiUrl: json['apiUrl'] as String,
        chatUserId: json['chatUserId'] as String,
        displayName: json['displayName'] as String,
        impersonating: json['impersonating'] as bool?,
        chatSettings: json['chatSettings'] == null
            ? null
            : TenantChatSettings.fromJson(json['chatSettings'] as JsonMap),
      );
}

class ListRoomsParams {
  const ListRoomsParams({
    this.participantId,
    this.customTypesFilter,
    this.externalId,
    this.limit,
    this.cursor,
  });

  final String? participantId;
  final List<String>? customTypesFilter;
  final String? externalId;
  final int? limit;
  final String? cursor;
}

class ListMessagesParams {
  const ListMessagesParams({this.viewerId, this.cursor, this.limit});

  final String? viewerId;
  final String? cursor;
  final int? limit;
}

class SendMessageParams {
  const SendMessageParams({
    this.senderId,
    required this.parts,
    this.clientMessageId,
    this.parentMessageId,
  });

  final String? senderId;
  final List<MessagePart> parts;
  final String? clientMessageId;
  final String? parentMessageId;

  JsonMap toJson() => {
        if (senderId != null) 'senderId': senderId,
        'parts': parts.map((p) => p.toJson()).toList(),
        if (clientMessageId != null) 'clientMessageId': clientMessageId,
        if (parentMessageId != null) 'parentMessageId': parentMessageId,
      };
}

class UpdateMessageParams {
  const UpdateMessageParams({this.userId, required this.parts});

  final String? userId;
  final List<MessagePart> parts;

  JsonMap toJson() => {
        if (userId != null) 'userId': userId,
        'parts': parts.map((p) => p.toJson()).toList(),
      };
}

class ToggleReactionParams {
  const ToggleReactionParams({this.userId, required this.emoji});

  final String? userId;
  final String emoji;

  JsonMap toJson() => {
        if (userId != null) 'userId': userId,
        'emoji': emoji,
      };
}

class JoinRoomParams {
  const JoinRoomParams({required this.roomId, this.userId});

  final String roomId;
  final String? userId;
}

class TypingParams {
  const TypingParams({
    required this.roomId,
    this.userId,
    required this.isTyping,
  });

  final String roomId;
  final String? userId;
  final bool isTyping;
}

typedef PushProvider = String; // FCM | ONESIGNAL | PUSHY | APNS

class RegisterDeviceTokenParams {
  const RegisterDeviceTokenParams({
    required this.provider,
    required this.token,
    this.platform,
  });

  final PushProvider provider;
  final String token;
  final String? platform;

  JsonMap toJson() => {
        'provider': provider,
        'token': token,
        if (platform != null) 'platform': platform,
      };
}

class DeviceTokenRecord {
  const DeviceTokenRecord({
    required this.id,
    required this.provider,
    required this.token,
    required this.createdAt,
  });

  final String id;
  final String provider;
  final String token;
  final String createdAt;

  factory DeviceTokenRecord.fromJson(JsonMap json) => DeviceTokenRecord(
        id: json['id'] as String,
        provider: json['provider'] as String,
        token: json['token'] as String,
        createdAt: json['createdAt'] as String,
      );
}

class PresignUploadParams {
  const PresignUploadParams({
    required this.filename,
    required this.mediaType,
    required this.sizeBytes,
    this.roomId,
  });

  final String filename;
  final String mediaType;
  final int sizeBytes;
  final String? roomId;

  JsonMap toJson() => {
        'filename': filename,
        'mediaType': mediaType,
        'sizeBytes': sizeBytes,
        if (roomId != null) 'roomId': roomId,
      };
}

class PresignUploadResult {
  const PresignUploadResult({
    required this.uploadId,
    required this.uploadUrl,
    required this.method,
    required this.uploadUrlExpiresAt,
  });

  final String uploadId;
  final String uploadUrl;
  final String method;
  final String uploadUrlExpiresAt;

  factory PresignUploadResult.fromJson(JsonMap json) => PresignUploadResult(
        uploadId: json['uploadId'] as String,
        uploadUrl: json['uploadUrl'] as String,
        method: json['method'] as String? ?? 'PUT',
        uploadUrlExpiresAt: json['uploadUrlExpiresAt'] as String,
      );
}

class FileAccessUrl {
  const FileAccessUrl({
    required this.uploadId,
    required this.accessUrl,
    required this.accessUrlExpiresAt,
  });

  final String uploadId;
  final String accessUrl;
  final String accessUrlExpiresAt;

  factory FileAccessUrl.fromJson(JsonMap json) => FileAccessUrl(
        uploadId: json['uploadId'] as String,
        accessUrl: json['accessUrl'] as String,
        accessUrlExpiresAt: json['accessUrlExpiresAt'] as String,
      );
}

class TenantStorageStats {
  const TenantStorageStats({
    required this.bytesUsed,
    required this.fileCount,
    required this.pendingBytes,
  });

  final int bytesUsed;
  final int fileCount;
  final int pendingBytes;

  factory TenantStorageStats.fromJson(JsonMap json) => TenantStorageStats(
        bytesUsed: json['bytesUsed'] as int,
        fileCount: json['fileCount'] as int,
        pendingBytes: json['pendingBytes'] as int,
      );
}

typedef CallType = String; // audio | video

class CallRecord {
  const CallRecord({
    required this.id,
    required this.roomId,
    required this.type,
    required this.status,
    required this.livekitRoomName,
    required this.createdByUserId,
    this.startedAt,
    this.endedAt,
    this.endReason,
  });

  final String id;
  final String roomId;
  final CallType type;
  final String status;
  final String livekitRoomName;
  final String createdByUserId;
  final String? startedAt;
  final String? endedAt;
  final String? endReason;

  factory CallRecord.fromJson(JsonMap json) => CallRecord(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        type: json['type'] as String,
        status: json['status'] as String,
        livekitRoomName: json['livekitRoomName'] as String,
        createdByUserId: json['createdByUserId'] as String,
        startedAt: json['startedAt'] as String?,
        endedAt: json['endedAt'] as String?,
        endReason: json['endReason'] as String?,
      );
}

class PresenceEvent {
  const PresenceEvent({required this.userId, required this.online});

  final String userId;
  final bool online;

  factory PresenceEvent.fromJson(JsonMap json) => PresenceEvent(
        userId: json['userId'] as String,
        online: json['online'] as bool,
      );
}

class TypingEvent {
  const TypingEvent({
    required this.roomId,
    required this.userId,
    required this.isTyping,
  });

  final String roomId;
  final String userId;
  final bool isTyping;

  factory TypingEvent.fromJson(JsonMap json) => TypingEvent(
        roomId: json['roomId'] as String,
        userId: json['userId'] as String,
        isTyping: json['isTyping'] as bool,
      );
}

class RoomReadEvent {
  const RoomReadEvent({
    required this.roomId,
    required this.userId,
    required this.lastReadAt,
    required this.lastReadMessageId,
  });

  final String roomId;
  final String userId;
  final String lastReadAt;
  final String? lastReadMessageId;

  factory RoomReadEvent.fromJson(JsonMap json) => RoomReadEvent(
        roomId: json['roomId'] as String,
        userId: json['userId'] as String,
        lastReadAt: json['lastReadAt'] as String,
        lastReadMessageId: json['lastReadMessageId'] as String?,
      );
}

class OnlineUserIdsSnapshot {
  const OnlineUserIdsSnapshot({required this.onlineUserIds});

  final List<String> onlineUserIds;

  factory OnlineUserIdsSnapshot.fromJson(JsonMap json) => OnlineUserIdsSnapshot(
        onlineUserIds: (json['onlineUserIds'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
      );
}

class RoomIdPayload {
  const RoomIdPayload({required this.roomId});

  final String roomId;

  factory RoomIdPayload.fromJson(JsonMap json) =>
      RoomIdPayload(roomId: json['roomId'] as String);
}

class SocketErrorPayload {
  const SocketErrorPayload({required this.message});

  final String message;
}

class CallInviteEvent {
  const CallInviteEvent({
    required this.callId,
    required this.roomId,
    required this.type,
    required this.createdByUserId,
    required this.livekitRoomName,
  });

  final String callId;
  final String roomId;
  final CallType type;
  final String createdByUserId;
  final String livekitRoomName;

  factory CallInviteEvent.fromJson(JsonMap json) => CallInviteEvent(
        callId: json['callId'] as String,
        roomId: json['roomId'] as String,
        type: json['type'] as String,
        createdByUserId: json['createdByUserId'] as String,
        livekitRoomName: json['livekitRoomName'] as String,
      );
}

class CallAcceptedEvent {
  const CallAcceptedEvent({
    required this.callId,
    required this.roomId,
    required this.userId,
  });

  final String callId;
  final String roomId;
  final String userId;

  factory CallAcceptedEvent.fromJson(JsonMap json) => CallAcceptedEvent(
        callId: json['callId'] as String,
        roomId: json['roomId'] as String,
        userId: json['userId'] as String,
      );
}

class CallDeclinedEvent {
  const CallDeclinedEvent({
    required this.callId,
    required this.roomId,
    required this.userId,
  });

  final String callId;
  final String roomId;
  final String userId;

  factory CallDeclinedEvent.fromJson(JsonMap json) => CallDeclinedEvent(
        callId: json['callId'] as String,
        roomId: json['roomId'] as String,
        userId: json['userId'] as String,
      );
}

class CallEndedEvent {
  const CallEndedEvent({
    required this.callId,
    required this.roomId,
    this.reason,
  });

  final String callId;
  final String roomId;
  final String? reason;

  factory CallEndedEvent.fromJson(JsonMap json) => CallEndedEvent(
        callId: json['callId'] as String,
        roomId: json['roomId'] as String,
        reason: json['reason'] as String?,
      );
}

typedef SendsarEvent = String;

abstract class SendsarEventMap {
  static const connecting = 'connecting';
  static const connected = 'connected';
  static const disconnected = 'disconnected';
}
