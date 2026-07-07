import 'package:share_plus/share_plus.dart';

import '../../services/firebase/models.dart';

/// The deep-link host. Universal links (https) need this domain to serve an
/// apple-app-site-association file; the custom scheme works app-to-app today.
const kRoomLinkBase = 'https://breadandword.com/r';

String roomLink(String roomId) => '$kRoomLinkBase/$roomId';

/// Share a room outside the app via the native share sheet.
Future<void> shareRoom(RoomDoc room) async {
  final kind = room.kind.toLowerCase();
  final text =
      'Join me in "${room.title}" — a live $kind room on Bread & Word.\n\n'
      '${roomLink(room.id)}';
  await SharePlus.instance.share(
    ShareParams(text: text, subject: 'Bread & Word — ${room.title}'),
  );
}
