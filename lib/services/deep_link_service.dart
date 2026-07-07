import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../features/rooms/room_screen.dart';
import 'firebase/rooms_repository.dart';

/// Opens incoming links into the app. Handles both universal links
/// (https://breadandword.com/r/{id}) and the custom scheme
/// (breadandword://r/{id}), routing room links straight into the room.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  final navigatorKey = GlobalKey<NavigatorState>();
  bool _started = false;

  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      // Cold start (app opened by a link).
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
      // Warm links while the app is running.
      _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
    } catch (_) {}
  }

  void _handle(Uri uri) {
    final roomId = _roomIdFrom(uri);
    if (roomId != null) _openRoom(roomId);
  }

  /// Accepts /r/{id} (universal link path) or host 'r' (custom scheme).
  String? _roomIdFrom(Uri uri) {
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.length >= 2 && segs[0] == 'r') return segs[1];
    // breadandword://r/{id}  → host 'r', first path segment is the id
    if (uri.host == 'r' && segs.isNotEmpty) return segs.first;
    return null;
  }

  Future<void> _openRoom(String roomId) async {
    final room = await RoomsRepository.instance.getRoom(roomId);
    final nav = navigatorKey.currentState;
    if (room == null || nav == null) return;
    nav.push(MaterialPageRoute<void>(builder: (_) => RoomScreen(room: room)));
  }
}
