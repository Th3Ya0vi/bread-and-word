import 'package:cloud_firestore/cloud_firestore.dart';

/// A member's public profile, read from `users/{uid}`.
///
/// The counts (fellowship/following/rooms) are not stored on the doc; they're
/// filled live from the follow graph and rooms by [FellowshipRepository].
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.bio,
    required this.journeyStage,
    this.fellowshipCount = 0,
    this.followingCount = 0,
    this.roomsHosted = 0,
  });

  final String uid;
  final String displayName;
  final String bio;
  final String journeyStage;
  final int fellowshipCount; // followers — those who walk with them
  final int followingCount; // those they walk with
  final int roomsHosted;

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return UserProfile(
      uid: d.id,
      displayName: (m['displayName'] ?? 'Friend in Christ').toString(),
      bio: (m['bio'] ?? '').toString(),
      journeyStage: (m['journeyStage'] ?? '').toString(),
    );
  }

  UserProfile copyWith({
    int? fellowshipCount,
    int? followingCount,
    int? roomsHosted,
  }) =>
      UserProfile(
        uid: uid,
        displayName: displayName,
        bio: bio,
        journeyStage: journeyStage,
        fellowshipCount: fellowshipCount ?? this.fellowshipCount,
        followingCount: followingCount ?? this.followingCount,
        roomsHosted: roomsHosted ?? this.roomsHosted,
      );
}
