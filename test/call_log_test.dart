import 'package:flutter_test/flutter_test.dart';
import 'package:sendsar_chat/sendsar_chat.dart';

void main() {
  test('parseCallLogPart reads data-call part', () {
    final data = parseCallLogPart([
      MessagePart(type: 'text', text: 'hi'),
      MessagePart(
        type: callLogPartType,
        data: {
          'callId': 'c1',
          'callType': 'video',
          'outcome': 'completed',
          'initiatedByUserId': 'u1',
          'isGroup': false,
          'durationSeconds': 90,
        },
      ),
    ]);
    expect(data?.callId, 'c1');
    expect(formatCallLogPreview(data!, 'u1'), 'Video call · 2 min');
  });

  test('isMissedCallLog detects missed for callee', () {
    const data = CallLogData(
      callId: 'c1',
      callType: 'audio',
      outcome: 'missed',
      initiatedByUserId: 'u1',
      isGroup: false,
    );
    expect(isMissedCallLog(data, 'u2'), isTrue);
  });
}
