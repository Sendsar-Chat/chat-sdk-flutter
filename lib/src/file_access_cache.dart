import 'types.dart';

class CachedFileAccess {
  const CachedFileAccess({
    required this.accessUrl,
    required this.accessUrlExpiresAt,
  });

  final String accessUrl;
  final String accessUrlExpiresAt;
}

class FileAccessCache {
  final _cache = <String, CachedFileAccess>{};

  CachedFileAccess? get(String uploadId) {
    final entry = _cache[uploadId];
    if (entry == null) return null;
    final expires = DateTime.tryParse(entry.accessUrlExpiresAt);
    if (expires != null && expires.isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
      _cache.remove(uploadId);
      return null;
    }
    return entry;
  }

  void set(String uploadId, CachedFileAccess value) {
    _cache[uploadId] = value;
  }

  void setMany(Iterable<FileAccessUrl> urls) {
    for (final url in urls) {
      set(url.uploadId, CachedFileAccess(
        accessUrl: url.accessUrl,
        accessUrlExpiresAt: url.accessUrlExpiresAt,
      ));
    }
  }

  List<String> missingUploadIds(Iterable<String> uploadIds) {
    return uploadIds.where((id) => get(id) == null).toList();
  }
}

Set<String> collectUploadIdsFromMessageParts(Iterable<MessagePart> parts) {
  final ids = <String>{};
  for (final part in parts) {
    if (part.type == 'file' && part.uploadId != null) {
      ids.add(part.uploadId!);
    }
  }
  return ids;
}

Set<String> collectUploadIdsFromMessages(Iterable<Message> messages) {
  final ids = <String>{};
  for (final message in messages) {
    ids.addAll(collectUploadIdsFromMessageParts(message.parts));
    final parent = message.parentMessage;
    if (parent != null) {
      ids.addAll(collectUploadIdsFromMessageParts(parent.parts));
    }
  }
  return ids;
}

void cacheAccessUrlsFromMessages(FileAccessCache cache, Iterable<Message> messages) {
  final urls = <FileAccessUrl>[];
  for (final message in messages) {
    for (final part in [...message.parts, ...?message.parentMessage?.parts]) {
      if (part.type == 'file' &&
          part.uploadId != null &&
          part.accessUrl != null &&
          part.accessUrlExpiresAt != null) {
        urls.add(FileAccessUrl(
          uploadId: part.uploadId!,
          accessUrl: part.accessUrl!,
          accessUrlExpiresAt: part.accessUrlExpiresAt!,
        ));
      }
    }
  }
  if (urls.isNotEmpty) cache.setMany(urls);
}

Message hydrateMessageFileParts(FileAccessCache cache, Message message) {
  List<MessagePart> hydrateParts(List<MessagePart> parts) {
    return parts.map((part) {
      if (part.type != 'file' || part.uploadId == null) return part;
      if (part.accessUrl != null && part.accessUrlExpiresAt != null) return part;
      final cached = cache.get(part.uploadId!);
      if (cached == null) return part;
      return MessagePart(
        type: part.type,
        text: part.text,
        mediaType: part.mediaType,
        url: part.url,
        uploadId: part.uploadId,
        filename: part.filename,
        accessUrl: cached.accessUrl,
        accessUrlExpiresAt: cached.accessUrlExpiresAt,
        data: part.data,
        state: part.state,
        extra: part.extra,
      );
    }).toList();
  }

  final parent = message.parentMessage;
  return Message(
    id: message.id,
    roomId: message.roomId,
    senderId: message.senderId,
    clientMessageId: message.clientMessageId,
    parts: hydrateParts(message.parts),
    previewText: message.previewText,
    createdAt: message.createdAt,
    parentMessageId: message.parentMessageId,
    parentMessage: parent == null
        ? null
        : ParentMessagePreview(
            id: parent.id,
            senderId: parent.senderId,
            parts: hydrateParts(parent.parts),
            previewText: parent.previewText,
            deleted: parent.deleted,
          ),
    deletedAt: message.deletedAt,
    deletedHidden: message.deletedHidden,
    editedAt: message.editedAt,
    reactions: message.reactions,
  );
}
