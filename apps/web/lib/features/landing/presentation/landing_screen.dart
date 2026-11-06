import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'landing_theme.dart';
import 'sections/cost_next_sections.dart';
import 'sections/header_footer.dart';
import 'sections/hero_section.dart';
import 'sections/join_section.dart';
import 'sections/story_sections.dart';

/// The public landing page (WP70, decision 50): the anonymous root of the app.
/// Static copy and bundled screenshots only; no network calls.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scroll = ScrollController();
  final _joinKey = GlobalKey();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 4;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _signIn() => context.go('/login');

  /// "Request an invitation" brings the form into view.
  Future<void> _showJoin() async {
    final target = _joinKey.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      alignment: 0.1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = LandingPalette.of(context);
    final w = LandingWidth.of(context);
    final gap = SizedBox(height: w.sectionGap);
    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          LandingHeader(
            scrolled: _scrolled,
            onRequestInvitation: _showJoin,
            onSignIn: _signIn,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HeroSection(
                    key: const Key('landing-hero'),
                    onRequestInvitation: _showJoin,
                    onSignIn: _signIn,
                  ),
                  gap,
                  const WhySection(),
                  SizedBox(height: w.sectionGap * 0.75),
                  const FeaturesSection(),
                  gap,
                  const RolesSection(),
                  gap,
                  const CostSection(),
                  gap,
                  const NextSection(),
                  gap,
                  KeyedSubtree(key: _joinKey, child: const JoinSection()),
                  gap,
                  LandingFooter(onSignIn: _signIn),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
