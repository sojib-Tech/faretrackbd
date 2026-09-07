import 'package:flutter/material.dart';

// App-wide navigator key so background/global services (like Shake-SOS) can
// show dialogs regardless of which screen is currently on top.
final rootNavigatorKey = GlobalKey<NavigatorState>();