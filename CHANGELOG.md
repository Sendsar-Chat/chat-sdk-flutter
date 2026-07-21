## 0.2.0

- Call log parity with protocol 0.2.x: `formatCallTimer`, `formatCallLogInboxPreview`, `callDurationSeconds`, `buildCallLogPart`, `kCallLogPartType`; completed thread previews use precise timer (`3:42` not coarse duration)
- Call REST on `RestClient` / `SendsarClient`: `getActiveCall`, `startCall`, `acceptCall`, `declineCall`, `endCall`, `leaveCall`, `refreshCallToken`
- `createCallSignaling()` + `CallSignaling` interface for `sendsar_call` (404 on active call → `null`)
- `ComposerTypingController` for debounced composer typing
- Requires Dart SDK `^3.6.0` / Flutter `>=3.27.0` (aligns with `sendsar_call` / `livekit_client`)

## 0.1.3

- `createRoomSubscription` `onInitialMessages` now includes optional `nextCursor` so UI kits can paginate without a duplicate first-page fetch

## 0.1.2

- CI: OIDC-only publish (tag push); remove broken credentials check

## 0.1.1

- CI publish workflow: pub.dev OIDC (no interactive browser login)
- Public GitHub mirror: CometChat-style landing page (no `lib/` on GitHub)

## 0.1.0

- Initial release: `SendsarClient` connect, REST, Socket.IO events
- Helpers: session manager, room subscription, presence, typing, call log, uploads
