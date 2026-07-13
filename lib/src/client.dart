import 'dart:async';
import 'dart:typed_data';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'event_emitter.dart';
import 'file_access_cache.dart';
import 'rest_client.dart';
import 'socket_events.dart';
import 'types.dart';
import 'uploads.dart';
import 'url.dart';

class SendsarClient extends EventEmitter {
  SendsarClient(SendsarInitOptions options)
      : apiUrl = options.apiUrl,
        _rest = RestClient(options.apiUrl);

  final String apiUrl;
  final RestClient _rest;
  final FileAccessCache _fileAccessCache = FileAccessCache();
  io.Socket? _socket;
  String? _connectedUserId;
  final Map<String, String> _joinedRooms = {};

  String? get currentUserId => _connectedUserId;

  bool get isConnected => _socket?.connected ?? false;

  RestClient get rest => _rest;

  void updateSessionToken(String token) {
    _rest.setSessionToken(token);
  }

  Future<void> connect(ConnectOptions options) async {
    await _teardownSocket();

    emit(SendsarEventMap.connecting, ConnectedUser(userId: options.userId));

    _connectedUserId = options.userId;
    _rest.setSessionToken(options.token);

    final origin = socketOriginFromApiUrl(apiUrl);
    final socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': options.token})
          .enableAutoConnect()
          .build(),
    );

    _socket = socket;
    _bindSocket(socket);

    final completer = Completer<void>();
    Timer? timeout;

    void cleanup() {
      timeout?.cancel();
      socket.off('connect');
      socket.off(SocketEvent.error);
      socket.off('connect_error');
    }

    timeout = Timer(Duration(milliseconds: options.connectTimeoutMs), () {
      if (completer.isCompleted) return;
      cleanup();
      socket.disconnect();
      _socket = null;
      _connectedUserId = null;
      _rest.setSessionToken(null);
      final err = SendsarSocketError(
        'Sendsar WebSocket connect timed out after ${options.connectTimeoutMs}ms',
      );
      emit(SocketEvent.error, SocketErrorPayload(message: err.message));
      completer.completeError(err);
    });

    socket.on('connect', (_) {
      if (completer.isCompleted) return;
      cleanup();
      emit(SendsarEventMap.connected, ConnectedUser(userId: options.userId));
      completer.complete();
    });

    socket.on(SocketEvent.error, (payload) {
      if (completer.isCompleted) return;
      cleanup();
      final message = _socketMessage(payload);
      emit(SocketEvent.error, SocketErrorPayload(message: message));
      completer.completeError(Exception(message));
    });

    socket.on('connect_error', (err) {
      if (completer.isCompleted) return;
      cleanup();
      final message = err?.toString() ?? 'WebSocket connection failed';
      emit(SocketEvent.error, SocketErrorPayload(message: message));
      completer.completeError(Exception(message));
    });

    await completer.future;
    _rejoinTrackedRooms();
  }

  Future<void> disconnect() async {
    await _teardownSocket();
    _connectedUserId = null;
    _rest.setSessionToken(null);
    _joinedRooms.clear();
    emit(SendsarEventMap.disconnected, null);
  }

  Future<RoomsResponse> listRooms([ListRoomsParams params = const ListRoomsParams()]) =>
      _rest.listRooms(params);

  Future<MessagesResponse> getMessages(
    String roomId, [
    ListMessagesParams params = const ListMessagesParams(),
  ]) async {
    final response = await _rest.listMessages(roomId, params);
    cacheAccessUrlsFromMessages(_fileAccessCache, response.messages);
    return response;
  }

  Future<Message> sendMessage(String roomId, SendMessageParams params) async {
    final senderId = params.senderId ?? _requireUserId();
    final message = await _rest.sendMessage(roomId, SendMessageParams(
      senderId: senderId,
      parts: params.parts,
      clientMessageId: params.clientMessageId,
      parentMessageId: params.parentMessageId,
    ));
    cacheAccessUrlsFromMessages(_fileAccessCache, [message]);
    return message;
  }

  Future<PresignUploadResult> presignUpload(PresignUploadParams params) =>
      _rest.presignUpload(params);

  Future<void> completeUpload(String uploadId) => _rest.completeUpload(uploadId);

  Future<void> abortUpload(String uploadId) => _rest.abortUpload(uploadId);

  Future<FileAccessUrl> getFileAccessUrl(String uploadId) async {
    final cached = _fileAccessCache.get(uploadId);
    if (cached != null) {
      return FileAccessUrl(
        uploadId: uploadId,
        accessUrl: cached.accessUrl,
        accessUrlExpiresAt: cached.accessUrlExpiresAt,
      );
    }
    final fresh = await _rest.getFileAccessUrl(uploadId);
    _fileAccessCache.set(uploadId, CachedFileAccess(
      accessUrl: fresh.accessUrl,
      accessUrlExpiresAt: fresh.accessUrlExpiresAt,
    ));
    return fresh;
  }

  Future<List<FileAccessUrl>> batchFileAccessUrls(List<String> uploadIds) async {
    final missing = _fileAccessCache.missingUploadIds(uploadIds);
    if (missing.isNotEmpty) {
      final urls = await _rest.batchFileAccessUrls(missing);
      _fileAccessCache.setMany(urls);
    }
    return uploadIds.map((uploadId) {
      final cached = _fileAccessCache.get(uploadId);
      return cached == null
          ? null
          : FileAccessUrl(
              uploadId: uploadId,
              accessUrl: cached.accessUrl,
              accessUrlExpiresAt: cached.accessUrlExpiresAt,
            );
    }).whereType<FileAccessUrl>().toList();
  }

  Future<UploadFileResult> uploadFile(UploadFileParams params) =>
      uploadFileToStorage(_rest, params);

  Future<Message> sendFileMessage(
    String roomId, {
    required Uint8List bytes,
    required String filename,
    required String mediaType,
    String? clientMessageId,
    String? parentMessageId,
    String? senderId,
  }) async {
    final uploaded = await uploadFile(UploadFileParams(
      bytes: bytes,
      filename: filename,
      mediaType: mediaType,
      roomId: roomId,
    ));
    return sendMessage(
      roomId,
      SendMessageParams(
        senderId: senderId,
        clientMessageId: clientMessageId,
        parentMessageId: parentMessageId,
        parts: [
          MessagePart(
            type: 'file',
            uploadId: uploaded.uploadId,
            mediaType: uploaded.mediaType,
            filename: uploaded.filename,
          ),
        ],
      ),
    );
  }

  Future<List<Message>> hydrateFileAccessUrls(List<Message> messages) async {
    final uploadIds = collectUploadIdsFromMessages(messages)
        .where((id) => _fileAccessCache.get(id) == null)
        .toList();
    if (uploadIds.isNotEmpty) {
      await batchFileAccessUrls(uploadIds);
    }
    return messages.map((m) => hydrateMessageFileParts(_fileAccessCache, m)).toList();
  }

  Future<TenantStorageStats> getTenantStorage() => _rest.getTenantStorage();

  Future<Message> updateMessage(
    String roomId,
    String messageId,
    UpdateMessageParams params,
  ) {
    final userId = params.userId ?? _requireUserId();
    return _rest.updateMessage(
      roomId,
      messageId,
      UpdateMessageParams(userId: userId, parts: params.parts),
    );
  }

  Future<Message> deleteMessage(String roomId, String messageId, [String? userId]) =>
      _rest.deleteMessage(roomId, messageId, userId ?? _requireUserId());

  Future<Message> toggleReaction(
    String roomId,
    String messageId,
    ToggleReactionParams params,
  ) {
    final userId = params.userId ?? _requireUserId();
    return _rest.toggleReaction(
      roomId,
      messageId,
      ToggleReactionParams(userId: userId, emoji: params.emoji),
    );
  }

  Future<JsonMap> markRoomRead(
    String roomId, [
    String? lastReadMessageId,
    String? userId,
  ]) =>
      _rest.markRoomRead(roomId, userId ?? _requireUserId(), lastReadMessageId);

  Future<JsonMap> markRoomDelivered(
    String roomId, [
    String? lastDeliveredMessageId,
    String? userId,
  ]) =>
      _rest.markRoomDelivered(
        roomId,
        userId ?? _requireUserId(),
        lastDeliveredMessageId,
      );

  Future<DeviceTokenRecord> registerDeviceToken(RegisterDeviceTokenParams params) {
    _requireUserId();
    return _rest.registerDeviceToken(params);
  }

  Future<void> unregisterDeviceToken(String token) {
    _requireUserId();
    return _rest.unregisterDeviceToken(token);
  }

  void joinRoom(JoinRoomParams params) {
    _assertSocket();
    final userId = params.userId ?? _requireUserId();
    _joinedRooms[params.roomId] = userId;
    _socket!.emit(SocketEvent.joinRoom, {'roomId': params.roomId, 'userId': userId});
  }

  void leaveRoom(String roomId, [String? userId]) {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    _joinedRooms.remove(roomId);
    final resolvedUserId = userId ?? _connectedUserId;
    if (resolvedUserId != null) {
      socket.emit(SocketEvent.leaveRoom, {'roomId': roomId, 'userId': resolvedUserId});
    } else {
      socket.emit(SocketEvent.leaveRoom, roomId);
    }
  }

  void setTyping(TypingParams params) {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    final userId = params.userId ?? _requireUserId();
    socket.emit(SocketEvent.typing, {
      'roomId': params.roomId,
      'userId': userId,
      'isTyping': params.isTyping,
    });
  }

  String _requireUserId() {
    final userId = _connectedUserId;
    if (userId == null) {
      throw StateError('Not connected — call connect() first');
    }
    return userId;
  }

  void _assertSocket() {
    if (!isConnected) {
      throw StateError('Not connected — call connect() first');
    }
  }

  Future<void> _teardownSocket() async {
    final socket = _socket;
    if (socket == null) return;
    _socket = null;
    if (!socket.connected) {
      socket.clearListeners();
      socket.dispose();
      return;
    }
    final completer = Completer<void>();
    socket.once('disconnect', (_) {
      socket.clearListeners();
      socket.dispose();
      completer.complete();
    });
    socket.disconnect();
    await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      socket.clearListeners();
      socket.dispose();
    });
  }

  void _rejoinTrackedRooms() {
    final socket = _socket;
    if (socket == null || !socket.connected || _joinedRooms.isEmpty) return;
    for (final entry in _joinedRooms.entries) {
      socket.emit(SocketEvent.joinRoom, {'roomId': entry.key, 'userId': entry.value});
    }
  }

  void _bindSocket(io.Socket socket) {
    socket.on(SocketEvent.error, (payload) {
      emit(SocketEvent.error, SocketErrorPayload(message: _socketMessage(payload)));
    });
    socket.on(SocketEvent.newMessage, (payload) {
      final message = Message.fromJson(Map<String, dynamic>.from(payload as Map));
      cacheAccessUrlsFromMessages(_fileAccessCache, [message]);
      emit(SocketEvent.newMessage, message);
    });
    socket.on(SocketEvent.messageUpdated, (payload) {
      final message = Message.fromJson(Map<String, dynamic>.from(payload as Map));
      cacheAccessUrlsFromMessages(_fileAccessCache, [message]);
      emit(SocketEvent.messageUpdated, message);
    });
    socket.on(SocketEvent.presence, (payload) {
      emit(SocketEvent.presence, PresenceEvent.fromJson(Map<String, dynamic>.from(payload as Map)));
    });
    socket.on(SocketEvent.tenantPresence, (payload) {
      emit(SocketEvent.tenantPresence, PresenceEvent.fromJson(Map<String, dynamic>.from(payload as Map)));
    });
    socket.on(SocketEvent.tenantPresenceSnapshot, (payload) {
      emit(
        SocketEvent.tenantPresenceSnapshot,
        OnlineUserIdsSnapshot.fromJson(Map<String, dynamic>.from(payload as Map)),
      );
    });
    socket.on(SocketEvent.presenceSnapshot, (payload) {
      emit(
        SocketEvent.presenceSnapshot,
        OnlineUserIdsSnapshot.fromJson(Map<String, dynamic>.from(payload as Map)),
      );
    });
    socket.on(SocketEvent.typing, (payload) {
      emit(SocketEvent.typing, TypingEvent.fromJson(Map<String, dynamic>.from(payload as Map)));
    });
    socket.on(SocketEvent.roomRead, (payload) {
      emit(SocketEvent.roomRead, RoomReadEvent.fromJson(Map<String, dynamic>.from(payload as Map)));
    });
    socket.on(SocketEvent.joinedRoom, (payload) {
      emit(SocketEvent.joinedRoom, RoomIdPayload.fromJson(Map<String, dynamic>.from(payload as Map)));
    });
    socket.on(SocketEvent.leftRoom, (payload) {
      emit(SocketEvent.leftRoom, RoomIdPayload.fromJson(Map<String, dynamic>.from(payload as Map)));
    });
    socket.on(SocketEvent.callInvite, (payload) {
      emit(SocketEvent.callInvite, CallInviteEvent.fromJson(Map<String, dynamic>.from(payload as Map)));
    });
    socket.on(SocketEvent.callAccepted, (payload) {
      emit(SocketEvent.callAccepted, CallAcceptedEvent.fromJson(Map<String, dynamic>.from(payload as Map)));
    });
    socket.on(SocketEvent.callDeclined, (payload) {
      emit(SocketEvent.callDeclined, CallDeclinedEvent.fromJson(Map<String, dynamic>.from(payload as Map)));
    });
    socket.on(SocketEvent.callEnded, (payload) {
      emit(SocketEvent.callEnded, CallEndedEvent.fromJson(Map<String, dynamic>.from(payload as Map)));
    });
  }

  String _socketMessage(Object? payload) {
    if (payload is Map && payload['message'] is String) return payload['message'] as String;
    return payload?.toString() ?? 'Unknown error';
  }
}

class SendsarSocketError implements Exception {
  SendsarSocketError(this.message);
  final String message;
  @override
  String toString() => message;
}

SendsarClient createSendsarClient(SendsarInitOptions options) => SendsarClient(options);

abstract final class Sendsar {
  static SendsarClient init(SendsarInitOptions options) => createSendsarClient(options);
}
