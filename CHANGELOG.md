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
