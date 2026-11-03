import 'package:flutter_test/flutter_test.dart';
import 'package:calley_app/core/api.dart';
import 'package:calley_app/core/demo_data.dart';
import 'package:calley_app/core/models.dart';

void main() {
  test('GET /api/list single object is treated as one list', () {
    final lists = extractList(demoListResponse);
    expect(lists.length, 1);
    expect(lists.first['name'], 'Test List');
  });

  test('list detail uses server counts', () {
    final l = CallList.fromJson(
        {...demoListDetailResponse, 'name': 'Test List', '_id': 'x'}, extractList(demoListDetailResponse));
    expect(l.total, 50);
    expect(l.pending, 27);
    expect(l.done, 12, reason: '23 called minus the 11 of them that were rescheduled');
    expect(l.scheduled, 11);
    expect(l.called, 23);
    expect(l.pending + l.done + l.scheduled, l.total);
  });

  test('summary-only response keeps groups consistent with the total', () {
    final l = CallList.fromJson({'_id': 'x', 'name': 'L', 'pending': 27, 'called': 23, 'rescheduled': 11});
    expect([l.total, l.pending, l.done, l.scheduled], [50, 27, 12, 11]);
  });
}
