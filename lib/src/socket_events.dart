/// Socket.IO event names shared by gateway and client.
abstract final class SocketEvent {
  static const error = 'error';
  static const newMessage = 'new-message';
  static const messageUpdated = 'message-updated';
  static const tenantPresence = 'tenant-presence';
  static const tenantPresenceSnapshot = 'tenant-presence-snapshot';
  static const presence = 'presence';
  static const presenceSnapshot = 'presence-snapshot';
  static const typing = 'typing';
  static const roomRead = 'room-read';
  static const joinedRoom = 'joined-room';
  static const leftRoom = 'left-room';
  static const joinRoom = 'join-room';
  static const leaveRoom = 'leave-room';
  static const callInvite = 'call-invite';
  static const callAccepted = 'call-accepted';
  static const callDeclined = 'call-declined';
  static const callEnded = 'call-ended';
}
