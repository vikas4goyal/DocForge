/// Helpers shared by the per-feature screen builders.
///
/// Everything here is presentation plumbing that more than one feature's
/// builder needs. It deliberately holds no feature logic: a builder that needed
/// a rule would be putting it in the wrong layer.
library;

import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:flutter/material.dart';

/// Shows [message] in a snackbar over [context].
///
/// The single way a composition-root callback reports an outcome the user has
/// to see. Centralised so a refusal from a use case looks the same wherever it
/// was triggered from.
void report(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

/// A labelled stand-in for a screen that has not been built yet.
///
/// Preferred to an inert control: a button that does nothing when tapped reads
/// as a bug, where a message reads as a boundary.
class PlaceholderScreen extends StatelessWidget {
  /// Creates a placeholder titled [title].
  const PlaceholderScreen(this.title, {super.key});

  /// What the missing screen would have been.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppEmptyState(
        title: title,
        message: 'This screen has not been built yet.',
        icon: Icons.construction_outlined,
      ),
    );
  }
}
