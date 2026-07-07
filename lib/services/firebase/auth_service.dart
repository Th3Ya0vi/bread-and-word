import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../profile_prefs.dart';

/// Auth for Bread & Word.
///
/// A visitor is signed in *anonymously* the moment they open the app, so they
/// can read everything and post a prayer request immediately ("just look
/// around"). Doing anything communal — praying for others, starting a reading
/// plan, gathering or speaking in a room — requires becoming a **member** by
/// creating an account (Apple, Google, or email), which is *linked* onto the
/// anonymous user so their journey carries over.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;
  String get uid => _auth.currentUser?.uid ?? '';

  /// The name shown across the community. Respects anonymous mode.
  String get displayName {
    final u = _auth.currentUser;
    if (ProfilePrefs.instance.anonymous.value) {
      return _pseudonym(u?.uid ?? 'anon');
    }
    return u?.displayName ?? 'Friend in Christ';
  }

  /// The account's real name, ignoring anonymous mode (for the profile screen).
  String get accountName =>
      _auth.currentUser?.displayName ?? 'Friend in Christ';

  bool get isSignedIn => _auth.currentUser != null;

  /// A real account, not the anonymous visitor.
  bool get isMember {
    final u = _auth.currentUser;
    return u != null && !u.isAnonymous;
  }

  Stream<User?> authChanges() => _auth.authStateChanges();

  /// Ensure there is a signed-in user (anonymous if needed) with a pseudonym.
  Future<User> ensureSignedIn() async {
    var current = _auth.currentUser;
    current ??= (await _auth.signInAnonymously()).user;
    if (current!.displayName == null || current.displayName!.isEmpty) {
      await current.updateDisplayName(_pseudonym(current.uid));
      await current.reload();
      current = _auth.currentUser;
    }
    return current!;
  }

  // ── Email ──

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = EmailAuthProvider.credential(email: email, password: password);
    await _upgradeOrSignIn(cred, displayName: name.trim());
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ── Google ──
  // Uses Firebase's built-in OAuth (ASWebAuthenticationSession) rather than the
  // google_sign_in SDK, which avoids the GoogleSignIn↔Firebase pod conflict.
  // Requires the REVERSED_CLIENT_ID URL scheme in Info.plist.

  Future<void> signInWithGoogle() async {
    await _upgradeOrSignInProvider(GoogleAuthProvider());
  }

  // ── Apple ──

  Future<void> signInWithApple() async {
    final rawNonce = _rawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final cred = OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      rawNonce: rawNonce,
    );

    final name = [apple.givenName, apple.familyName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    await _upgradeOrSignIn(cred, displayName: name.isEmpty ? null : name);
  }

  // ── Shared upgrade/sign-in ──

  /// Link the credential onto the anonymous visitor (preserving their data);
  /// if it already belongs to an existing member, sign in as that member.
  Future<void> _upgradeOrSignIn(
    AuthCredential cred, {
    String? displayName,
  }) async {
    final current = _auth.currentUser;
    UserCredential result;
    try {
      if (current != null && current.isAnonymous) {
        result = await current.linkWithCredential(cred);
      } else {
        result = await _auth.signInWithCredential(cred);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        result = await _auth.signInWithCredential(cred);
      } else {
        rethrow;
      }
    }
    final u = result.user;
    if (u != null &&
        displayName != null &&
        displayName.isNotEmpty &&
        (u.displayName == null || u.displayName!.isEmpty)) {
      await u.updateDisplayName(displayName);
      await u.reload();
    }
  }

  /// Federated (web-OAuth) variant for providers like Google — link onto the
  /// anonymous visitor, or sign in as the existing member.
  Future<void> _upgradeOrSignInProvider(AuthProvider provider) async {
    final current = _auth.currentUser;
    try {
      if (current != null && current.isAnonymous) {
        await current.linkWithProvider(provider);
      } else {
        await _auth.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        await _auth.signInWithProvider(provider);
      } else {
        rethrow;
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await ensureSignedIn(); // drop back to an anonymous visitor
  }

  /// Permanently delete the account and profile. May throw
  /// 'requires-recent-login' for members who signed in a while ago.
  Future<void> deleteAccount() async {
    final u = _auth.currentUser;
    if (u == null) return;
    final uid = u.uid;
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (_) {}
    await u.delete();
    await ensureSignedIn(); // fresh anonymous visitor
  }

  /// Rename the account. Updates Firebase Auth and the public profile doc so
  /// the new name shows everywhere the member appears (unless anonymous).
  Future<void> updateName(String name) async {
    final u = _auth.currentUser;
    final n = name.trim();
    if (u == null || n.isEmpty) return;
    await u.updateDisplayName(n);
    await u.reload();
    await _db.collection('users').doc(u.uid).set({
      'displayName': n,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Profile (journey answers) ──

  Future<void> saveProfile({
    String? journeyStage,
    List<String>? seeking,
  }) async {
    final u = _auth.currentUser;
    if (u == null) return;
    await _db.collection('users').doc(u.uid).set({
      'journeyStage': ?journeyStage,
      'seeking': ?seeking,
      'displayName': displayName,
      'isMember': isMember,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Helpers ──

  static String _rawNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  static String _pseudonym(String uid) {
    final h = uid.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
    final first = _firstNames[h % _firstNames.length];
    final last = _lastInitials[(h ~/ 7) % _lastInitials.length];
    return '$first $last.';
  }

  static const _firstNames = [
    'Ruth', 'Caleb', 'Mary', 'Silas', 'Hannah', 'Amos', 'Lydia', 'Josiah',
    'Naomi', 'Elias', 'Tabitha', 'Gideon', 'Esther', 'Levi', 'Phoebe', 'Asa',
  ];
  static const _lastInitials = [
    'A', 'B', 'C', 'D', 'E', 'G', 'H', 'J', 'K', 'M', 'N', 'P', 'R', 'S', 'T',
  ];
}
