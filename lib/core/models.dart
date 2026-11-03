import 'api.dart';

/// One calling list, parsed from `GET /api/list` and `GET /api/list/{id}`.
///
/// The API's counts overlap: `rescheduled` calls are a subset of `called`
/// calls (they have status "called" and a `rescheduledAt` date). To keep the
/// dashboard consistent, calls are split into three non-overlapping groups:
///   pending   = status "pending"
///   scheduled = called and rescheduled
///   done      = called and not rescheduled
/// so pending + done + scheduled == total.
class CallList {
  final String id, name;
  final int total, pending, done, scheduled;

  /// Every call made, rescheduled or not (the API's `called` figure).
  final int called;
  final List<Map<String, dynamic>> calls;
  CallList(this.id, this.name, this.total, this.pending, this.done, this.scheduled, this.calls, {int? called})
      : called = called ?? done + scheduled;

  factory CallList.fromJson(Map<String, dynamic> j, [List<Map<String, dynamic>> calls = const []]) {
    final id = pick(j, ['_id', 'id', 'listId']);
    final name = pick(j, ['name', 'listName', 'title'], 'Calling List');

    if (calls.isNotEmpty) {
      var pending = 0, done = 0, scheduled = 0;
      for (final c in calls) {
        switch (callGroup(c)) {
          case CallGroup.pending:
            pending++;
          case CallGroup.done:
            done++;
          case CallGroup.scheduled:
            scheduled++;
        }
      }
      return CallList(id, name, calls.length, pending, done, scheduled, calls);
    }

    // No call rows: use the summary counts.
    final pending = pickInt(j, ['pending', 'pendingCalls']);
    final called = pickInt(j, ['called', 'done', 'calledCalls']);
    final rescheduled = pickInt(j, ['rescheduled', 'scheduled']).clamp(0, called);
    var total = pickInt(j, ['totalCalls', 'total', 'count']);
    if (total == 0) total = pending + called;
    return CallList(id, name, total, pending, called - rescheduled, rescheduled, calls, called: called);
  }

  /// Fetches the list's details and merges them with the summary.
  Future<CallList> withDetails() async {
    final res = await Api.listDetail(id);
    return CallList.fromJson({...res, 'name': name, '_id': id}, extractList(res));
  }
}

enum CallGroup { pending, done, scheduled }

/// Which of the three dashboard groups a call belongs to.
CallGroup callGroup(Map<String, dynamic> c) {
  final s = pick(c, ['status', 'callStatus']).toLowerCase();
  final rescheduled = c['rescheduledAt'] != null || s.contains('sched');
  if (rescheduled) return CallGroup.scheduled;
  if (s == 'called' || s.contains('done') || s.contains('complet')) return CallGroup.done;
  return CallGroup.pending;
}
