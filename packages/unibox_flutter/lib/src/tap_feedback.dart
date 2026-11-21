import 'dart:async';

import 'package:flutter/widgets.dart';

/// Plays the platform's own feedback for a press: a click on Android, a light tap on iOS.
///
/// A control in an application does this through [Feedback], and a box that draws its own
/// press has no class to ask, so the renderer asks here. It is behaviour and not paint, which
/// is why it may be the platform's while the look stays the tree's — the same line the field
/// draws when it renders a `TextField` instead of a `<input>` drawn from boxes.
///
/// The web renderer has no counterpart and needs none: a browser plays nothing for a div,
/// and the feedback it does have belongs to the link or the button it was handed.
void playTapFeedback(BuildContext context) =>
    unawaited(Feedback.forTap(context));
