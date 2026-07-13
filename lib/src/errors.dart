import 'dart:convert';

class SendsarErrorPayload {
  const SendsarErrorPayload({this.error, this.message, this.statusCode});

  final String? error;
  final String? message;
  final int? statusCode;

  static SendsarErrorPayload? parse(String body) {
    final trimmed = body.trim();
    if (!trimmed.startsWith('{')) return null;
    try {
      final json = jsonDecode(trimmed) as Map<String, dynamic>;
      return SendsarErrorPayload(
        error: json['error'] as String?,
        message: json['message'] as String?,
        statusCode: json['statusCode'] as int?,
      );
    } catch (_) {
      return null;
    }
  }
}

class SendsarError implements Exception {
  SendsarError(this.message, this.status, this.body)
      : payload = SendsarErrorPayload.parse(body);

  final String message;
  final int status;
  final String body;
  final SendsarErrorPayload? payload;

  @override
  String toString() {
    final detail = payload?.error ?? payload?.message;
    return detail != null ? '$message: $detail' : message;
  }
}

void assertOk(int statusCode, String body, String action) {
  if (statusCode < 200 || statusCode >= 300) {
    throw SendsarError('Sendsar $action failed: $statusCode', statusCode, body);
  }
}
