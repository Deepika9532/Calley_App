import 'package:flutter/material.dart';
import '../core/theme.dart';

/// The mock API has no notifications endpoint, so this shows the empty state.
/// Pass [items] once a notifications source exists.
class NotificationsScreen extends StatelessWidget {
  final List<String> items;
  const NotificationsScreen({super.key, this.items = const []});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(titleSpacing: 0, title: const Text('Notifications')),
        body: items.isEmpty
            ? const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_off_outlined, size: 48, color: C.muted),
                  SizedBox(height: 12),
                  Text("You're all caught up", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('No new notifications', style: TextStyle(color: C.muted)),
                ]),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => Card(
                  elevation: 0,
                  child: ListTile(leading: const Icon(Icons.notifications_none), title: Text(items[i])),
                ),
              ),
      );
}
