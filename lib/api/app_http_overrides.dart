import 'dart:io';
 
import 'package:flutter/foundation.dart';
 
/// TEMPORARY: bypasses SSL certificate validation for every HttpClient
/// created in the app (works for the `http` package and for Dio).
///
/// Remove this once the server certificate is fixed or the company CA is
/// installed on the PC. Do NOT ship to production.
class AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        debugPrint('🟡 [AppHttpOverrides] Bypassing bad certificate '
            'for $host:$port');
        return true;
      };
  }
}
 