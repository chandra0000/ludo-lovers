import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';

const String _appBuildSha = String.fromEnvironment(
  'APP_BUILD_SHA',
  defaultValue: 'unknown',
);

void main() {
  // Keep initialization and runApp in the same guarded zone so asynchronous
  // startup failures are reported instead of disappearing behind a blank UI.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('[LudoLovers][FlutterError] ${details.exception}');
        if (details.stack != null) {
          debugPrintStack(stackTrace: details.stack);
        }
      };
      ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
        debugPrint('[LudoLovers][UncaughtPlatformError] $error');
        debugPrintStack(stackTrace: stackTrace);
        // The error is logged. Keep the process alive so Flutter can display
        // its recovery UI where possible instead of silently terminating.
        return true;
      };

      debugPrint(
        '[LudoLovers][BuildInfo] commit=$_appBuildSha '
        'mode=${kDebugMode ? 'debug' : 'release'}',
      );
      debugPrint('[LudoLovers] App startup entered');
      await SystemChrome.setPreferredOrientations(
        const <DeviceOrientation>[DeviceOrientation.portraitUp],
      );
      debugPrint('[LudoLovers] Portrait orientation configured; calling runApp');
      runApp(const LudoLoversApp());
    },
    (error, stackTrace) {
      debugPrint('[LudoLovers][UncaughtZoneError] $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}
