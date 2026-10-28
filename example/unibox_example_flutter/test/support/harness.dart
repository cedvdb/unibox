import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unibox_example_flutter/main.dart';

/// Pumps the example on a surface tall enough for the whole card.
///
/// The wide test font makes every line taller than the real font the card is
/// designed for, so the default 800x600 surface is too short.
///
/// [surface] is the window the app is given, which is what the tree is drawn on:
/// the harness sets it to a wide window by default, and a test that cares about
/// the breakpoint asks for its own.
Future<void> pumpApp(
  WidgetTester tester, {
  Size surface = const Size(900, 1000),
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ExampleApp());
  // The dialog asks for its layer on the frame after it mounts.
  await tester.pump();
}

/// The name field of the card.
Finder nameField() => find.byType(TextField).first;

/// The email field of the card.
Finder emailField() => find.byType(TextField).last;

/// The navigation item labelled [label].
///
/// The page below the dialog can carry the same label as the item that opens it
/// (the apartments heading, for one), and the bar comes first in the tree, so
/// the first match is the item.
Finder navItem(String label) => find.text(label).first;

/// Dismisses the sign-up dialog, which leaves the listings behind it.
Future<void> closeDialog(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pump();
  await tester.pump();
}

/// Opens the destination labelled [label] through the navigation bar.
Future<void> openPage(WidgetTester tester, String label) async {
  await tester.tap(navItem(label));
  await tester.pump();
  // Opening the dialog puts its layer up on the frame after the tap.
  await tester.pump();
}
