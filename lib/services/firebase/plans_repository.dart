import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

/// A member's progress through one reading plan.
class PlanProgress {
  const PlanProgress({
    required this.started,
    required this.completedDays,
  });

  final bool started;
  final Set<int> completedDays;

  bool isDayDone(int index) => completedDays.contains(index);

  /// The next unread day, or the last day if all are done.
  int nextDay(int totalDays) {
    for (var i = 0; i < totalDays; i++) {
      if (!completedDays.contains(i)) return i;
    }
    return totalDays - 1;
  }

  bool isComplete(int totalDays) => completedDays.length >= totalDays;

  static const empty = PlanProgress(started: false, completedDays: {});
}

/// Per-user reading-plan progress, stored at
/// `users/{uid}/plan_progress/{planId}`. Works for anonymous visitors and
/// members alike (both have a uid), so anyone can follow a plan.
class PlansRepository {
  PlansRepository._();
  static final PlansRepository instance = PlansRepository._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db
      .collection('users')
      .doc(AuthService.instance.uid)
      .collection('plan_progress');

  PlanProgress _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    if (!d.exists) return PlanProgress.empty;
    final m = d.data() ?? const {};
    final days = (m['completedDays'] as List<dynamic>? ?? const [])
        .map((e) => (e as num).toInt())
        .toSet();
    return PlanProgress(started: m['started'] == true, completedDays: days);
  }

  /// Live progress for one plan.
  Stream<PlanProgress> watch(String planId) =>
      _col.doc(planId).snapshots().map(_fromDoc);

  /// The ids of every plan this user has started, newest first.
  Stream<Set<String>> watchStarted() => _col
      .where('started', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());

  /// Begin a plan (idempotent).
  Future<void> start(String planId) async {
    await _col.doc(planId).set({
      'started': true,
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Mark a day complete and ensure the plan is started.
  Future<void> markDay(String planId, int dayIndex) async {
    await _col.doc(planId).set({
      'started': true,
      'completedDays': FieldValue.arrayUnion([dayIndex]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Undo a day (in case it was marked by mistake).
  Future<void> unmarkDay(String planId, int dayIndex) async {
    await _col.doc(planId).set({
      'completedDays': FieldValue.arrayRemove([dayIndex]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
