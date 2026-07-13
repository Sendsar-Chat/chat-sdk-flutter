import 'dart:convert';

import 'package:http/http.dart' as http;

import 'errors.dart';
import 'types.dart';
import 'url.dart';

class RestClient {
  RestClient(this.apiUrl);

  final String apiUrl;
  String? _sessionToken;

  void setSessionToken(String? token) {
    _sessionToken = token;
  }

  Map<String, String> _headers([Map<String, String>? extra]) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = _sessionToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  String _path(String suffix) {
    final normalized = suffix.startsWith('/') ? suffix : '/$suffix';
    return '${normalizeApiUrl(apiUrl)}$normalized';
  }

  final _http = http.Client();

  Future<T> fetchJson<T>(
    String path, {
    String method = 'GET',
    Object? body,
    String action = 'request',
    T Function(JsonMap json)? fromJson,
  }) async {
    final uri = Uri.parse(_path(path));
    final encoded = body == null ? null : jsonEncode(body);
    final http.Response response;
    switch (method) {
      case 'POST':
        response = await _http.post(uri, headers: _headers(), body: encoded);
      case 'PATCH':
        response = await _http.patch(uri, headers: _headers(), body: encoded);
      case 'DELETE':
        response = await _http.delete(uri, headers: _headers(), body: encoded);
      case 'PUT':
        response = await _http.put(uri, headers: _headers(), body: encoded);
      default:
        response = await _http.get(uri, headers: _headers());
    }
    assertOk(response.statusCode, response.body, action);
    if (response.body.isEmpty) {
      if (fromJson != null) return fromJson(<String, dynamic>{});
      return null as T;
    }
    final decoded = jsonDecode(response.body);
    if (fromJson != null) return fromJson(decoded as JsonMap);
    return decoded as T;
  }

  Future<void> fetchVoid(
    String path, {
    String method = 'GET',
    Object? body,
    String action = 'request',
  }) async {
    await fetchJson<Object?>(
      path,
      method: method,
      body: body,
      action: action,
    );
  }

  Future<RoomsResponse> listRooms([ListRoomsParams params = const ListRoomsParams()]) {
    final search = <String, String>{};
    if (params.participantId != null) search['participantId'] = params.participantId!;
    if (params.externalId != null) search['externalId'] = params.externalId!;
    if (params.customTypesFilter != null && params.customTypesFilter!.isNotEmpty) {
      search['customTypesFilter'] = params.customTypesFilter!.join(',');
    }
    if (params.limit != null) search['limit'] = '${params.limit}';
    if (params.cursor != null) search['cursor'] = params.cursor!;
    final qs = Uri(queryParameters: search.isEmpty ? null : search).query;
    return fetchJson(
      '/chat/rooms${qs.isEmpty ? '' : '?$qs'}',
      fromJson: RoomsResponse.fromJson,
      action: 'list rooms',
    );
  }

  Future<MessagesResponse> listMessages(
    String roomId, [
    ListMessagesParams params = const ListMessagesParams(),
  ]) {
    final search = <String, String>{};
    if (params.viewerId != null) search['viewerId'] = params.viewerId!;
    if (params.cursor != null) search['cursor'] = params.cursor!;
    if (params.limit != null) search['limit'] = '${params.limit}';
    final qs = Uri(queryParameters: search.isEmpty ? null : search).query;
    return fetchJson(
      '/chat/rooms/${Uri.encodeComponent(roomId)}/messages${qs.isEmpty ? '' : '?$qs'}',
      fromJson: MessagesResponse.fromJson,
      action: 'list messages',
    );
  }

  Future<Message> sendMessage(String roomId, SendMessageParams body) => fetchJson(
        '/chat/rooms/${Uri.encodeComponent(roomId)}/messages',
        method: 'POST',
        body: body.toJson(),
        fromJson: Message.fromJson,
        action: 'send message',
      );

  Future<Message> updateMessage(
    String roomId,
    String messageId,
    UpdateMessageParams body,
  ) =>
      fetchJson(
        '/chat/rooms/${Uri.encodeComponent(roomId)}/messages/${Uri.encodeComponent(messageId)}',
        method: 'PATCH',
        body: body.toJson(),
        fromJson: Message.fromJson,
        action: 'update message',
      );

  Future<Message> deleteMessage(String roomId, String messageId, [String? userId]) {
    final qs = userId == null ? '' : '?userId=${Uri.encodeQueryComponent(userId)}';
    return fetchJson(
      '/chat/rooms/${Uri.encodeComponent(roomId)}/messages/${Uri.encodeComponent(messageId)}$qs',
      method: 'DELETE',
      fromJson: Message.fromJson,
      action: 'delete message',
    );
  }

  Future<Message> toggleReaction(
    String roomId,
    String messageId,
    ToggleReactionParams body,
  ) =>
      fetchJson(
        '/chat/rooms/${Uri.encodeComponent(roomId)}/messages/${Uri.encodeComponent(messageId)}/reactions',
        method: 'POST',
        body: body.toJson(),
        fromJson: Message.fromJson,
        action: 'toggle reaction',
      );

  Future<JsonMap> markRoomRead(
    String roomId,
    String userId, [
    String? lastReadMessageId,
  ]) =>
      fetchJson(
        '/chat/rooms/${Uri.encodeComponent(roomId)}/read',
        method: 'POST',
        body: {'userId': userId, 'lastReadMessageId': lastReadMessageId},
        action: 'mark room read',
      );

  Future<JsonMap> markRoomDelivered(
    String roomId,
    String userId, [
    String? lastDeliveredMessageId,
  ]) =>
      fetchJson(
        '/chat/rooms/${Uri.encodeComponent(roomId)}/delivery',
        method: 'POST',
        body: {'userId': userId, 'lastDeliveredMessageId': lastDeliveredMessageId},
        action: 'mark room delivered',
      );

  Future<DeviceTokenRecord> registerDeviceToken(RegisterDeviceTokenParams params) =>
      fetchJson(
        '/users/me/device-tokens',
        method: 'POST',
        body: params.toJson(),
        fromJson: DeviceTokenRecord.fromJson,
        action: 'register device token',
      );

  Future<void> unregisterDeviceToken(String token) => fetchVoid(
        '/users/me/device-tokens/${Uri.encodeComponent(token)}',
        method: 'DELETE',
        action: 'unregister device token',
      );

  Future<PresignUploadResult> presignUpload(PresignUploadParams body) => fetchJson(
        '/chat/uploads/presign',
        method: 'POST',
        body: body.toJson(),
        fromJson: PresignUploadResult.fromJson,
        action: 'presign upload',
      );

  Future<void> completeUpload(String uploadId) => fetchVoid(
        '/chat/uploads/${Uri.encodeComponent(uploadId)}/complete',
        method: 'POST',
        body: const {},
        action: 'complete upload',
      );

  Future<void> abortUpload(String uploadId) => fetchVoid(
        '/chat/uploads/${Uri.encodeComponent(uploadId)}',
        method: 'DELETE',
        action: 'abort upload',
      );

  Future<FileAccessUrl> getFileAccessUrl(String uploadId) => fetchJson(
        '/chat/uploads/${Uri.encodeComponent(uploadId)}/access',
        fromJson: FileAccessUrl.fromJson,
        action: 'get file access url',
      );

  Future<List<FileAccessUrl>> batchFileAccessUrls(List<String> uploadIds) async {
    final result = await fetchJson<JsonMap>(
      '/chat/uploads/access',
      method: 'POST',
      body: {'uploadIds': uploadIds},
      action: 'batch file access urls',
    );
    return (result['urls'] as List<dynamic>)
        .map((e) => FileAccessUrl.fromJson(e as JsonMap))
        .toList();
  }

  Future<TenantStorageStats> getTenantStorage() => fetchJson(
        '/tenant/storage',
        fromJson: TenantStorageStats.fromJson,
        action: 'get tenant storage',
      );
}
