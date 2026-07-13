import 'package:flutter_test/flutter_test.dart';
import 'package:sendsar_chat/sendsar_chat.dart';

void main() {
  test('normalizeApiUrl strips trailing slash', () {
    expect(normalizeApiUrl('http://localhost:3001/v1/'), 'http://localhost:3001/v1');
  });

  test('socketOriginFromApiUrl returns origin without path', () {
    expect(socketOriginFromApiUrl('http://localhost:3001/v1'), 'http://localhost:3001');
  });
}
