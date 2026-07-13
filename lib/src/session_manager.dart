import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'client.dart';
import 'types.dart';

typedef SessionManagerStatus = String; // idle | loading | ready | offline | error

class SessionManagerState {
  const SessionManagerState({
    required this.status,
    required this.client,
    required this.session,
    this.error,
  });

  final SessionManagerStatus status;
  final SendsarClient? client;
  final SessionResponse? session;
  final String? error;
}

class ParseSessionResult {
  const ParseSessionResult._({required this.ok, this.session, this.status, this.error});

  final bool ok;
  final SessionResponse? session;
  final SessionManagerStatus? status;
  final String? error;

  factory ParseSessionResult.success(SessionResponse session) =>
      ParseSessionResult._(ok: true, session: session);

  factory ParseSessionResult.failure({
    required SessionManagerStatus status,
    String? error,
  }) =>
      ParseSessionResult._(ok: false, status: status, error: error);
}

const defaultRefreshBeforeExpiryMs = 5 * 60 * 1000;

int msUntilTokenRefresh(
  String expiresAt,
  int refreshBeforeExpiryMs, [
  DateTime? now,
]) {
  final current = now ?? DateTime.now();
  final expiry = DateTime.parse(expiresAt);
  return expiry.difference(current).inMilliseconds - refreshBeforeExpiryMs;
}

Future<ParseSessionResult> parseSessionResponse(http.Response response) async {
  if (response.statusCode == 503) {
    return ParseSessionResult.failure(status: 'offline');
  }
  if (response.statusCode == 401) {
    return ParseSessionResult.failure(
      status: 'error',
      error: 'Unauthorized — log in to use chat',
    );
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    Map<String, dynamic> errBody = {};
    try {
      errBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    return ParseSessionResult.failure(
      status: 'error',
      error: errBody['error'] as String? ?? 'Failed to connect to Sendsar',
    );
  }
  final session = SessionResponse.fromJson(
    jsonDecode(response.body) as Map<String, dynamic>,
  );
  return ParseSessionResult.success(session);
}

typedef FetchSession = Future<Object> Function();
typedef ParseSession = Future<ParseSessionResult> Function(http.Response response);
typedef SessionStateListener = void Function(SessionManagerState state);

class CreateSessionManagerOptions {
  const CreateSessionManagerOptions({
    required this.fetchSession,
    this.refreshBeforeExpiryMs = defaultRefreshBeforeExpiryMs,
    this.parseSession = parseSessionResponse,
    this.onStateChange,
  });

  final FetchSession fetchSession;
  final int refreshBeforeExpiryMs;
  final ParseSession parseSession;
  final SessionStateListener? onStateChange;
}

class SessionManager {
  SessionManager(this._options);

  final CreateSessionManagerOptions _options;
  SessionManagerState _state = const SessionManagerState(
    status: 'idle',
    client: null,
    session: null,
  );
  SendsarClient? _client;
  Timer? _refreshTimer;
  bool _stopped = false;

  SessionManagerState getState() => _state;

  Future<void> start() async {
    _stopped = false;
    await _loadSession();
  }

  Future<void> stop() async {
    _stopped = true;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _client?.disconnect();
    _client = null;
    _setState(const SessionManagerState(status: 'idle', client: null, session: null));
  }

  Future<void> restart() async {
    await stop();
    await start();
  }

  Future<void> _loadSession() async {
    _setState(SessionManagerState(
      status: 'loading',
      client: _client,
      session: _state.session,
    ));

    try {
      final raw = await _options.fetchSession();
      late final ParseSessionResult parsed;
      if (raw is http.Response) {
        parsed = await _options.parseSession(raw);
      } else if (raw is SessionResponse) {
        parsed = ParseSessionResult.success(raw);
      } else if (raw is Map<String, dynamic>) {
        parsed = ParseSessionResult.success(SessionResponse.fromJson(raw));
      } else {
        parsed = ParseSessionResult.failure(
          status: 'error',
          error: 'fetchSession must return Response or SessionResponse',
        );
      }

      if (_stopped) return;
      if (!parsed.ok) {
        _setState(SessionManagerState(
          status: parsed.status ?? 'error',
          client: null,
          session: null,
          error: parsed.error,
        ));
        return;
      }

      final session = parsed.session!;
      _client ??= SendsarClient(SendsarInitOptions(apiUrl: session.apiUrl));
      _client!.updateSessionToken(session.token);
      await _client!.connect(ConnectOptions(
        userId: session.chatUserId,
        token: session.token,
      ));

      if (_stopped) return;
      _setState(SessionManagerState(
        status: 'ready',
        client: _client,
        session: session,
      ));
      _scheduleRefresh(session.expiresAt);
    } catch (e) {
      if (_stopped) return;
      _setState(SessionManagerState(
        status: 'error',
        client: _client,
        session: _state.session,
        error: e.toString(),
      ));
    }
  }

  void _scheduleRefresh(String expiresAt) {
    _refreshTimer?.cancel();
    final delay = msUntilTokenRefresh(expiresAt, _options.refreshBeforeExpiryMs);
    _refreshTimer = Timer(
      Duration(milliseconds: delay <= 0 ? 0 : delay),
      () {
        if (!_stopped) unawaited(_loadSession());
      },
    );
  }

  void _setState(SessionManagerState next) {
    _state = next;
    _options.onStateChange?.call(next);
  }
}

SessionManager createSessionManager(CreateSessionManagerOptions options) =>
    SessionManager(options);
