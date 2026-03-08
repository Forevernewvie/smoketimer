import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/pen_design_widgets.dart';

/// Full-screen reader that exposes the app privacy policy from the bundled document.
class PrivacyPolicyScreen extends StatelessWidget {
  /// Creates the privacy policy screen.
  const PrivacyPolicyScreen({super.key});

  static const String assetPath = 'docs/privacy_policy_ko.md';

  /// Builds the scrollable privacy policy document viewer.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);

    return Scaffold(
      backgroundColor: ui.background,
      appBar: AppBar(
        backgroundColor: ui.background,
        foregroundColor: ui.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('개인정보처리방침'),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '개인정보처리방침을 불러오지 못했어요.',
                  style: TextStyle(
                    color: ui.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: SelectableText(
                snapshot.data!,
                style: TextStyle(
                  color: ui.textPrimary,
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
