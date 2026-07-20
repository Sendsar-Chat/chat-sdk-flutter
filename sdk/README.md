# sendsar_chat

Flutter client for Sendsar realtime chat.

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  sendsar_chat: ^0.1.3
```

```bash
flutter pub add sendsar_chat
```

## Connect

```dart
import 'package:sendsar_chat/sendsar_chat.dart';

final client = Sendsar.init(SendsarInitOptions(apiUrl: 'https://api.example.com/v1'));

await client.connect(ConnectOptions(
  userId: session.chatUserId,
  token: session.token,
));
```

## Documentation

https://docs.sendsar.com/sdk/flutter/
