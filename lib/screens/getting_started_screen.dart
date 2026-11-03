import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';

/// First screen after login: intro text + "2 minute challenge" video.
class GettingStartedScreen extends StatelessWidget {
  const GettingStartedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(children: [
              const GreetingCard(headline: 'Calley Personal'),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 12, 18, 10),
                    child: Text(
                      'If you are here for the first time then ensure that you have uploaded the list to call '
                      'from calley Web Panel hosted on https://app.getcalley.com',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12, height: 1.45),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse('https://www.youtube.com/watch?v=bP4U-L4EHcg'),
                        mode: LaunchMode.externalApplication),
                    child: const _VideoThumb(),
                  ),
                ]),
              ),
              const Spacer(),
              CallActionRow(
                onStart: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const DashboardScreen())),
              ),
            ]),
          ),
        ),
      );
}

/// "2 MINUTE CHALLENGE" thumbnail from the Figma design.
class _VideoThumb extends StatelessWidget {
  const _VideoThumb();
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14), bottom: Radius.circular(14)),
        child: AspectRatio(
          aspectRatio: 764 / 500,
          child: Image.asset('assets/images/video_thumb.png', fit: BoxFit.cover),
        ),
      );
}
