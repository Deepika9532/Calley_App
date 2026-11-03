import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calley_app/core/api.dart';
import 'package:calley_app/core/demo_data.dart';
import 'package:calley_app/core/session.dart';
import 'package:calley_app/core/theme.dart';
import 'package:calley_app/screens/dashboard_screen.dart';

const userId = '68626f9497757cb741f449b0';

/// Fake server; [lists] is what GET /api/list returns for the user.
MockClient fakeServer({required Object lists, Object? detail, List<Uri>? log, int status = 200, Completer<void>? hold}) =>
    MockClient((req) async {
      log?.add(req.url);
      if (hold != null) await hold.future;
      final body = req.url.path == '/api/list' ? lists : (detail ?? demoListDetailResponse);
      return http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
    });

Future<void> openApp(WidgetTester t) async {
  SharedPreferences.setMockInitialValues({});
  await Session.init();
  await Session.saveUser({'_id': userId, 'username': 'Swati', 'email': 'swati@cstech.in'});
  t.view.physicalSize = const Size(720, 1500);
  t.view.devicePixelRatio = 1.875;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(theme: appTheme(), home: const DashboardScreen()));
  await t.pumpAndSettle();
}

Future<void> openCallingLists(WidgetTester t) async {
  await t.tap(find.byTooltip('Menu'));
  await t.pumpAndSettle();
  await t.tap(find.text('Settings'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('fetch with userId, select list, dashboard shows API counts', (t) async {
    final log = <Uri>[];
    Api.client = fakeServer(
      lists: {'_id': 'L1', 'name': 'Diwali Leads', 'agents': [], 'clientId': userId},
      detail: {'pending': 3, 'called': 2, 'rescheduled': 1, 'calls': []},
      log: log,
    );
    await openApp(t);
    expect(find.text('LOAD NUMBER TO CALL'), findsOneWidget);
    expect(find.byTooltip('WhatsApp'), findsOneWidget);

    await openCallingLists(t);
    expect(log.first.path, '/api/list');
    expect(log.first.queryParameters['userId'], userId);
    expect(find.text('Diwali Leads'), findsOneWidget, reason: 'name comes from the API, not hardcoded');

    await t.tap(find.text('Diwali Leads'));
    await t.pumpAndSettle();
    expect(log.last.path, '/api/list/L1');
    // 3 pending + 2 called = 5 total; 1 of the called was rescheduled.
    expect(find.text('Diwali Leads'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('03'), findsOneWidget); // pending
    expect(find.text('01'), findsNWidgets(2)); // done (2-1) and schedule (1)
    expect(t.takeException(), isNull);
  });

  testWidgets('selected list is marked and switching lists updates the dashboard', (t) async {
    Api.client = fakeServer(lists: {
      'lists': [
        {'_id': 'A', 'name': 'List A'},
        {'_id': 'B', 'name': 'List B'},
      ]
    }, detail: demoListDetailResponse);
    await openApp(t);
    await openCallingLists(t);
    await t.tap(find.text('List A'));
    await t.pumpAndSettle();
    expect(find.text('List A'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);

    await openCallingLists(t);
    expect(find.byIcon(Icons.check_circle), findsOneWidget, reason: 'List A shows as selected');
    await t.tap(find.text('List B'));
    await t.pumpAndSettle();
    expect(find.text('List B'), findsOneWidget);
  });

  testWidgets('repeated Refresh taps send only one request', (t) async {
    final log = <Uri>[];
    final hold = Completer<void>();
    Api.client = fakeServer(lists: demoListResponse, log: log, hold: hold);
    await openApp(t);
    await t.tap(find.byTooltip('Menu'));
    await t.pumpAndSettle();
    await t.tap(find.text('Settings'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100)); // stay well under the 15 s timeout
    }
    expect(find.byType(CircularProgressIndicator), findsWidgets, reason: 'loading indicator while fetching');
    for (var i = 0; i < 5; i++) {
      await t.tap(find.text('Refresh'), warnIfMissed: false);
      await t.pump();
    }
    hold.complete();
    await t.pumpAndSettle();
    expect(log.where((u) => u.path == '/api/list').length, 1);
    expect(find.text('Test List'), findsOneWidget);
  });

  testWidgets('empty response shows the empty state', (t) async {
    Api.client = fakeServer(lists: {'lists': []});
    await openApp(t);
    await openCallingLists(t);
    expect(find.textContaining('No calling lists yet'), findsOneWidget);
  });

  testWidgets('API error shows a message and Try again', (t) async {
    Api.client = fakeServer(lists: {'message': 'User not found'}, status: 400);
    await openApp(t);
    await openCallingLists(t);
    expect(find.text('User not found'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('network down falls back to documented sample data, clearly labelled', (t) async {
    Api.client = MockClient((_) async => throw const SocketExceptionLike());
    await openApp(t);
    await openCallingLists(t);
    expect(find.textContaining('Server unreachable'), findsOneWidget);
    expect(find.text('Test List'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}

class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}
