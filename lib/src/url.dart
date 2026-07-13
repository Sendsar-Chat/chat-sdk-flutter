/// Strip trailing slash from API base URL.
String normalizeApiUrl(String apiUrl) {
  return apiUrl.replaceAll(RegExp(r'/$'), '');
}

/// Socket.IO connects to the gateway origin (no `/v1` path).
String socketOriginFromApiUrl(String apiUrl) {
  return Uri.parse(normalizeApiUrl(apiUrl)).origin;
}
