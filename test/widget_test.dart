import 'package:flutter_test/flutter_test.dart';
import 'package:calley_app/core/api.dart';

void main() {
  test('extractList finds nested lists', () {
    expect(extractList({'data': {'lists': [{'_id': '1'}]}}).length, 1);
  });
}
