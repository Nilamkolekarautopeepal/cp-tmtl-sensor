import 'package:cp_tmtl_sensor_zig/app.dart';

class AtomURLType {
  static const String LOCAL = "LOCAL";
  static const String DEV = 'DEV';
  static const String PROD = 'PROD';
}

// class AppEnvironment {
//   static const String _localUrl = "http://139.59.76.174:8080/api/v1/";
//   static const String _devUrl = 'http://139.59.76.174:8080/api/v1/';
//   static const String _prodUrl = 'http://139.59.76.174:8080/api/v1/';

class AppEnvironment {
  static const String _localUrl = "https://uatalw4siite.tmtl.net/";
  static const String _devUrl = "https://uatalw4siite.tmtl.net/";
  static const String _prodUrl = "https://uatalw4siite.tmtl.net/";


  static bool get baseProdInstance {
    if (baseUrl == _prodUrl) {
      return true;
    } else {
      return false;
    }
  }

  static String get baseUrl {
    switch (App.instance.baseURLType) {
      case AtomURLType.DEV:
        return _devUrl;
      case AtomURLType.PROD:
        return _prodUrl;
      case AtomURLType.LOCAL:
        return _localUrl;
    }

    return "https://uatalw4siite.tmtl.net/";
  }
}
