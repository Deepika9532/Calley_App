import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calley_app/core/session.dart';
import 'package:calley_app/core/theme.dart';
import 'package:calley_app/screens/dashboard_screen.dart';
import 'package:calley_app/screens/calls_screen.dart';
import 'package:calley_app/core/api.dart';
import 'package:calley_app/core/demo_data.dart';

Future<void> _pumpDashboard(WidgetTester t, {String? listId}) async {
  SharedPreferences.setMockInitialValues({'listId': ?listId});
  await Session.init();
  await Session.saveUser({'_id': '68626f9497757cb741f449b0', 'username': 'Swati', 'email': 's@cstech.in'});
  t.view.physicalSize = const Size(720, 1500); // Samsung A07 class phone
  t.view.devicePixelRatio = 1.875;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(theme: appTheme(), home: const DashboardScreen()));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('empty dashboard renders its cards without layout errors', (t) async {
    await _pumpDashboard(t);
    expect(t.takeException(), isNull);
    expect(find.text('Welcome to Calley!'), findsOneWidget);
    expect(find.text('LOAD NUMBER TO CALL'), findsOneWidget);
    expect(find.text('Star Calling Now'), findsOneWidget);
  });

  testWidgets('hamburger opens the drawer', (t) async {
    await _pumpDashboard(t);
    await t.tap(find.byTooltip('Menu'));
    await t.pumpAndSettle();
    expect(find.text('Getting Started'), findsOneWidget);
    expect(find.text('App Info'), findsOneWidget);
    await t.tap(find.text('Gamification'));
    await t.pumpAndSettle();
    expect(find.text('Getting Started'), findsNothing, reason: 'drawer closes after a selection');
    expect(t.takeException(), isNull);
  });

  testWidgets('bell opens notifications with an empty state', (t) async {
    await _pumpDashboard(t);
    await t.tap(find.byTooltip('Notifications'));
    await t.pumpAndSettle();
    expect(find.text('No new notifications'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('support button responds without crashing', (t) async {
    await _pumpDashboard(t);
    await t.tap(find.byTooltip('Support'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('every bottom-bar item responds', (t) async {
    await _pumpDashboard(t);
    for (final (tip, title) in [('Contacts', 'Contacts'), ('Call log', 'Call Log'), ('Schedule', 'Schedule')]) {
      await t.tap(find.byTooltip(tip));
      await t.pumpAndSettle();
      expect(find.text(title), findsWidgets);
      expect(find.text('No calling list loaded'), findsOneWidget);
    }
    await t.tap(find.byTooltip('Home'));
    await t.pumpAndSettle();
    expect(find.text('Welcome to Calley!'), findsOneWidget);

    // Play with no list: explains and opens Settings.
    await t.tap(find.byTooltip('Start calling'));
    await t.pumpAndSettle();
    expect(find.text('CALLING LISTS'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Android back on a tab returns to Home first', (t) async {
    await _pumpDashboard(t);
    await t.tap(find.byTooltip('Schedule'));
    await t.pumpAndSettle();
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    await nav.maybePop();
    await t.pumpAndSettle();
    expect(find.text('Welcome to Calley!'), findsOneWidget);
  });

  testWidgets('with a list selected, tabs still respond when the server fails', (t) async {
    await _pumpDashboard(t, listId: '68626fb697757cb741f449b9');
    expect(t.takeException(), isNull);
    for (final tip in ['Contacts', 'Call log', 'Schedule', 'Home']) {
      await t.tap(find.byTooltip(tip));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
  });

  testWidgets('contacts / call log / schedule render the 50 sample calls', (t) async {
    final calls = extractList(demoListDetailResponse);
    expect(calls.length, 50);
    for (final f in CallFilter.values) {
      await t.pumpWidget(MaterialApp(theme: appTheme(), home: Scaffold(body: CallTiles(calls: filterCalls(calls, f), showSchedule: f == CallFilter.scheduled))));
      await t.pump();
      expect(t.takeException(), isNull);
    }
    await t.pumpWidget(MaterialApp(theme: appTheme(), home: Scaffold(body: CallTiles(calls: calls))));
    expect(find.text('Mrs. Danielle Johnson'), findsOneWidget);
  });
}
