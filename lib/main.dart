import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cp_tmtl_sensor_zig/api/app_envirments.dart';
import 'package:cp_tmtl_sensor_zig/app.dart';
import 'package:cp_tmtl_sensor_zig/services/log_file.dart';

 // ✅ FIXED PATH

import 'package:cp_tmtl_sensor_zig/api/app_http_overrides.dart';

void main() async {

  
   // TEMPORARY: bypass bad/untrusted server certificate (UAT only).
  // Set before anything makes a network call.
  HttpOverrides.global = AppHttpOverrides();

  // add new code for bypassing SSL certificate validation for every HttpClient created in the app (works for the `http` package and for Dio).
  WidgetsFlutterBinding.ensureInitialized();

  await LogFile.init();

  App.instance.initAndRunApp(
    devMode: true,
    appLog: true,
    apiLog: false,
    setDefault: true,
    samplePayment: true,
    baseURLType: AtomURLType.PROD,
  );
}