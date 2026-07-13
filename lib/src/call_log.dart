import 'types.dart';

const callLogPartType = 'data-call';

typedef CallLogOutcome = String; // completed | missed | declined | cancelled

class CallLogData {
  const CallLogData({
    required this.callId,
    required this.callType,
    required this.outcome,
    required this.initiatedByUserId,
    required this.isGroup,
    this.durationSeconds,
  });

  final String callId;
  final String callType;
  final CallLogOutcome outcome;
  final String initiatedByUserId;
  final bool isGroup;
  final int? durationSeconds;
}

class CallLogPart {
  const CallLogPart({required this.data});

  final CallLogData data;

  Map<String, Object?> toJson() => {
        'type': callLogPartType,
        'data': {
          'callId': data.callId,
          'callType': data.callType,
          'outcome': data.outcome,
          'initiatedByUserId': data.initiatedByUserId,
          'isGroup': data.isGroup,
          if (data.durationSeconds != null) 'durationSeconds': data.durationSeconds,
        },
      };
}

CallLogData? parseCallLogData(Object? raw) {
  if (raw is! Map) return null;
  final json = Map<String, dynamic>.from(raw);
  final callId = json['callId'];
  final callType = json['callType'];
  final outcome = json['outcome'];
  final initiatedByUserId = json['initiatedByUserId'];
  final isGroup = json['isGroup'];
  final durationSeconds = json['durationSeconds'];
  if (callId is! String || callId.isEmpty) return null;
  if (callType != 'audio' && callType != 'video') return null;
  if (outcome != 'completed' &&
      outcome != 'missed' &&
      outcome != 'declined' &&
      outcome != 'cancelled') {
    return null;
  }
  if (initiatedByUserId is! String || initiatedByUserId.isEmpty) return null;
  if (isGroup is! bool) return null;
  if (durationSeconds != null && (durationSeconds is! num || durationSeconds < 0)) {
    return null;
  }
  return CallLogData(
    callId: callId,
    callType: callType as String,
    outcome: outcome as String,
    initiatedByUserId: initiatedByUserId,
    isGroup: isGroup,
    durationSeconds: durationSeconds is num ? durationSeconds.round() : null,
  );
}

CallLogData? parseCallLogPart(List<MessagePart> parts) {
  for (final part in parts) {
    if (part.type == callLogPartType) {
      return parseCallLogData(part.data);
    }
  }
  return null;
}

String formatCallDuration(int totalSeconds) {
  if (totalSeconds < 60) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    return '0:${s.toString().padLeft(2, '0')}';
  }
  final minutes = (totalSeconds / 60).round().clamp(1, 1 << 30);
  return '$minutes min';
}

String formatCallLogPreview(CallLogData data, [String? selfUserId]) {
  final media = data.callType == 'video' ? 'Video call' : 'Voice call';
  final groupPrefix = data.isGroup ? 'Group ' : '';
  final initiatedBySelf = selfUserId != null && data.initiatedByUserId == selfUserId;

  if (data.outcome == 'completed') {
    final duration = data.durationSeconds;
    return duration != null
        ? '$groupPrefix$media · ${formatCallDuration(duration)}'
        : '$groupPrefix$media';
  }
  if (data.outcome == 'declined') {
    return initiatedBySelf
        ? '$groupPrefix$media declined'
        : 'Declined ${data.callType == 'video' ? 'video' : 'voice'} call';
  }
  if (data.outcome == 'cancelled') {
    return initiatedBySelf
        ? 'Call cancelled'
        : 'Missed ${data.callType == 'video' ? 'video' : 'voice'} call';
  }
  return initiatedBySelf
      ? 'No answer'
      : 'Missed ${data.callType == 'video' ? 'video' : 'voice'} call';
}

bool isMissedCallLog(CallLogData data, String selfUserId) {
  return data.outcome == 'missed' ||
      (data.outcome == 'declined' && data.initiatedByUserId != selfUserId) ||
      (data.outcome == 'cancelled' && data.initiatedByUserId != selfUserId);
}
