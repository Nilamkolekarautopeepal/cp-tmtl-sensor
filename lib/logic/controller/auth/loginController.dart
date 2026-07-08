// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:cp_tmtl_sensor_zig/AppPreferences/app_areferences.dart';
// import 'package:cp_tmtl_sensor_zig/api/app_envirments.dart';
// import 'package:cp_tmtl_sensor_zig/api/app_urls.dart';
// import 'package:cp_tmtl_sensor_zig/api/dev/dev_service.dart';
// import 'package:cp_tmtl_sensor_zig/logic/controller/dashboard/testRecipeController.dart';
// import 'package:cp_tmtl_sensor_zig/routes/routes_string.dart';
// import 'package:flutter/material.dart';
// import 'package:cp_tmtl_sensor_zig/services/log_file.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;

// class LoginController extends GetxController {
//   // 1. Controllers for TextFields
//   final usernameController = TextEditingController();
//   final passwordController = TextEditingController();

//   final hidePassword = true.obs;
//   final isLoading = false.obs;
//   void togglePasswordVisibility() {
//     hidePassword.value = !hidePassword.value;
//   }

//   @override
//   void onInit() {
//     super.onInit();
//     _loadSavedCredentials(); // ✅ Load on init
//   }

//   Future<void> _loadSavedCredentials() async {
//     final String? savedUser = await AppPreferences.getSavedUsername();
//     final String? savedPass = await AppPreferences.getSavedPassword();

//     if (savedUser != null && savedUser.isNotEmpty) {
//       usernameController.text = savedUser;
//     }
//     if (savedPass != null && savedPass.isNotEmpty) {
//       passwordController.text = savedPass;
//     }
//     print("📖 [LOGIN] Loaded saved credentials for: $savedUser");
//     LogFile.write("📖 [LOGIN] Loaded saved credentials for: $savedUser");
//   }

//   void login() async {
//     String user = usernameController.value.text;
//     String pass = passwordController.value.text;

//     if (user.isEmpty || pass.isEmpty) {
//       Get.snackbar(
//         "Error",
//         "Please enter credentials",
//         backgroundColor: Colors.redAccent,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     try {
//       isLoading.value = true;

//       print("🚀 [LOGIN START] Authenticating: $user");
//       LogFile.write("🚀 [LOGIN START] Authenticating: $user");

//       print("password: $pass");
//       LogFile.write("password: $pass");

//       final String baseUrl = AppEnvironment.baseUrl;
//       final String loginUrl = "$baseUrl${AppURLs.login}";
//       print("🌐 [API] Hitting: $loginUrl");
//       LogFile.write("🌐 [API] Hitting: $loginUrl");

//       // ✅ Use form encoding — Django REST expects this by default
//       final response = await http.post(
//         Uri.parse(loginUrl),
//         headers: {
//           "Content-Type": "application/x-www-form-urlencoded",
//           "Accept": "application/json",
//         },
//         body: {
//           "username": user,
//           "password": pass,
//         },
//       );

//       print("📡 [RESPONSE] Status: ${response.statusCode}");
//       print("📡 [RESPONSE] Body: ${response.body}");
//       LogFile.write("📡 [RESPONSE] Status: ${response.statusCode}");
//       LogFile.write("📡 [RESPONSE] Body: ${response.body}");

//       Map<String, dynamic> parsedResponse = {};
//       try {
//         parsedResponse = jsonDecode(response.body);
//       } catch (_) {
//         parsedResponse = {"raw": response.body};
//       }
//       parsedResponse['statusCode'] = response.statusCode;

//       DevService.instance.insertAPICall(AppAPIsCall(
//         id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
//         type: 'POST ${response.statusCode}',
//         path: AppURLs.login,
//         dateTime: DateTime.now(),
//         data: {"username": user, "password": "***"}, // ✅ password masked
//         response: parsedResponse,
//       ));

//       if (response.statusCode == 200) {
//         await AppPreferences.saveUsername(user);
//         await AppPreferences.savePassword(pass);
//         print("💾 [LOGIN] Credentials saved for: $user");
//         LogFile.write("💾 [LOGIN] Credentials saved for: $user");
//         final Map<String, dynamic> data = jsonDecode(response.body);

//         // final String? token = data['data']['accessToken'];
//         //  final String? token = data['data']['auth_token']['access'];
//         //   if (token != null) {
//         //     await AppPreferences.setToken(token);
//         //     print("🔑 [TOKEN] Saved: $token");
//         //     LogFile.write("🔑 [TOKEN] Saved: $token");

//         //   }
//         final String? token = data['data']['auth_token']['access'];
//         final String? refreshToken = data['data']['auth_token']['refresh'];

//         if (token != null) {
//           await AppPreferences.setToken(token);
//           print("🔑 [TOKEN] Saved: $token");
//           LogFile.write("🔑 [TOKEN] Saved: $token");
//         }

//         if (refreshToken != null) {
//           await AppPreferences.setRefreshToken(
//               refreshToken); // add this method if not exists
//         }

//         await AppPreferences.setActiveUser(user);
//         print("👤 [SESSION] Active User set: $user");
//         LogFile.write("👤 [SESSION] Active User set: $user");

//         if (Get.isRegistered<TestRecipeController>()) {
//           final testController = Get.find<TestRecipeController>();
//           await testController.loadStoredRecipes();
//           print("🔄 [SYNC] Recipes: ${testController.recipeList.length}");
//           LogFile.write(
//               "🔄 [SYNC] Recipes: ${testController.recipeList.length}");
//         }

//         isLoading.value = false;
//         Get.offAllNamed(Routes.dashboardScreen);
//       } else if (response.statusCode == 400) {
//         isLoading.value = false;
//         final Map<String, dynamic> errData = jsonDecode(response.body);
//         final String errMsg =
//             errData['error'] ?? errData['detail'] ?? "Invalid request";
//         print("❌ [LOGIN 400] $errMsg");
//         LogFile.write("❌ [LOGIN 400] $errMsg");
//         Get.snackbar("Login Failed", errMsg,
//             backgroundColor: Colors.redAccent, colorText: Colors.white);
//       } else if (response.statusCode == 401) {
//         isLoading.value = false;
//         Get.snackbar("Login Failed", "Invalid email or password",
//             backgroundColor: Colors.redAccent, colorText: Colors.white);
//       } else {
//         isLoading.value = false;
//         Get.snackbar(
//             "Server Error", "Something went wrong. (${response.statusCode})",
//             backgroundColor: Colors.orange, colorText: Colors.white);
//       }
//     } on SocketException {
//       DevService.instance.insertAPICall(AppAPIsCall(
//         id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
//         type: 'POST ERROR',
//         path: AppURLs.login,
//         dateTime: DateTime.now(),
//         data: {"username": user, "password": "***"},
//         response: {
//           "error": "SocketException",
//           "message": "No internet connection"
//         },
//       ));
//       isLoading.value = false;
//       Get.snackbar("No Connection", "Check your internet and try again",
//           backgroundColor: Colors.redAccent, colorText: Colors.white);
//     } on TimeoutException {
//       DevService.instance.insertAPICall(AppAPIsCall(
//         id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
//         type: 'POST TIMEOUT',
//         path: AppURLs.login,
//         dateTime: DateTime.now(),
//         data: {"username": user, "password": "***"},
//         response: {"error": "TimeoutException", "message": "Request timed out"},
//       ));
//       isLoading.value = false;
//       Get.snackbar("Timeout", "Server took too long to respond",
//           backgroundColor: Colors.orange, colorText: Colors.white);
//     } catch (e) {
//       DevService.instance.insertAPICall(AppAPIsCall(
//         id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
//         type: 'POST TIMEOUT',
//         path: AppURLs.login,
//         dateTime: DateTime.now(),
//         data: {"username": user, "password": "***"},
//         response: {"error": "TimeoutException", "message": "Request timed out"},
//       ));
//       isLoading.value = false;
//       print("❌ [LOGIN ERROR] $e");
//       LogFile.write("❌ [LOGIN ERROR] $e");
//       Get.snackbar("Login Failed", "An error occurred during login");
//     }
//   }

//   void login1() async {
//     String user = usernameController.value.text;
//     String pass = passwordController.value.text;

//     if (user.isEmpty || pass.isEmpty) {
//       Get.snackbar(
//         "Error",
//         "Please enter credentials",
//         backgroundColor: Colors.redAccent,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     try {
//       isLoading.value = true;
//       print("🚀 [LOGIN START] Authenticating: $user");
//       LogFile.write("🚀 [LOGIN START] Authenticating: $user");

//       final String loginUrl = "${AppEnvironment.baseUrl}${AppURLs.login}";
//       print("🌐 [API] Hitting: $loginUrl");
//       LogFile.write("🌐 [API] Hitting: $loginUrl");

//       final response = await http.post(
//         Uri.parse(loginUrl),
//         headers: {
//           "Content-Type": "application/x-www-form-urlencoded",
//           "Accept": "application/json",
//         },
//         body: {
//           "username": user,
//           "password": pass,
//         },
//       ).timeout(const Duration(seconds: 30));

//       print("📡 [RESPONSE] Status: ${response.statusCode}");
//       LogFile.write("📡 [RESPONSE] Status: ${response.statusCode}");
//       print("📡 [RESPONSE] Body: ${response.body}");
//       LogFile.write("📡 [RESPONSE] Body: ${response.body}");
//       Map<String, dynamic> parsedResponse = {};
//       try {
//         parsedResponse = jsonDecode(response.body);
//       } catch (_) {
//         parsedResponse = {"raw": response.body};
//       }
//       parsedResponse['statusCode'] = response.statusCode;

//       DevService.instance.insertAPICall(AppAPIsCall(
//         id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
//         type: 'POST ${response.statusCode}',
//         path: AppURLs.login,
//         dateTime: DateTime.now(),
//         data: {"username": user, "password": "***"}, // ✅ password masked
//         response: parsedResponse,
//       ));

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> body = jsonDecode(response.body);

//         // ✅ Check responseStatus from your API structure
//         final String? responseStatus = body['responseStatus'];
//         if (responseStatus != 'SUCCESS') {
//           isLoading.value = false;
//           final String errMsg =
//               body['messages']?[0]?['message'] ?? "Login failed";
//           print("❌ [LOGIN] responseStatus: $responseStatus | $errMsg");
//           LogFile.write("❌ [LOGIN] responseStatus: $responseStatus | $errMsg");
//           Get.snackbar("Login Failed", errMsg,
//               backgroundColor: Colors.redAccent, colorText: Colors.white);
//           return;
//         }

//         // ✅ Extract from data object
//         final Map<String, dynamic> data = body['data'];

//         final String? accessToken = data['accessToken'];
//         final int? userId = data['userId'];
//         final String? firstName = data['firstName'];
//         final String? lastName = data['lastName'];
//         final String? userName = data['userName'];

//         print("🔑 [TOKEN] accessToken: $accessToken");
//         LogFile.write("🔑 [TOKEN] accessToken: $accessToken");
//         print("👤 [USER] userId: $userId | name: $firstName $lastName");
//         LogFile.write("👤 [USER] userId: $userId | name: $firstName $lastName");

//         // ✅ Save token
//         if (accessToken != null) {
//           await AppPreferences.setToken(accessToken);
//           print("✅ [PREFS] Token saved");
//         } else {
//           isLoading.value = false;
//           Get.snackbar("Login Failed", "Token not received",
//               backgroundColor: Colors.redAccent, colorText: Colors.white);
//           return;
//         }

//         // ✅ Save credentials & session
//         await AppPreferences.saveUsername(user);
//         await AppPreferences.savePassword(pass);
//         await AppPreferences.setActiveUser(userName ?? user);

//         print("💾 [PREFS] Credentials saved for: $user");
//         LogFile.write("💾 [PREFS] Credentials saved for: $user");
//         print("👤 [SESSION] Active User set: ${userName ?? user}");
//         LogFile.write("👤 [SESSION] Active User set: ${userName ?? user}");
//         // ✅ Sync recipes if controller exists
//         if (Get.isRegistered<TestRecipeController>()) {
//           final testController = Get.find<TestRecipeController>();
//           await testController.loadStoredRecipes();
//           print("🔄 [SYNC] Recipes: ${testController.recipeList.length}");
//         }

//         isLoading.value = false;
//         Get.offAllNamed(Routes.dashboardScreen);
//       } else if (response.statusCode == 400) {
//         isLoading.value = false;
//         final Map<String, dynamic> errData = jsonDecode(response.body);
//         final String errMsg =
//             errData['error'] ?? errData['detail'] ?? "Invalid request";
//         print("❌ [LOGIN 400] $errMsg");
//         Get.snackbar("Login Failed", errMsg,
//             backgroundColor: Colors.redAccent, colorText: Colors.white);
//       } else if (response.statusCode == 401) {
//         isLoading.value = false;
//         Get.snackbar("Login Failed", "Invalid username or password",
//             backgroundColor: Colors.redAccent, colorText: Colors.white);
//       } else {
//         isLoading.value = false;
//         Get.snackbar(
//             "Server Error", "Something went wrong. (${response.statusCode})",
//             backgroundColor: Colors.orange, colorText: Colors.white);
//       }
//     } on SocketException {
//       DevService.instance.insertAPICall(AppAPIsCall(
//         id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
//         type: 'POST TIMEOUT',
//         path: AppURLs.login,
//         dateTime: DateTime.now(),
//         data: {"username": user, "password": "***"},
//         response: {"error": "TimeoutException", "message": "Request timed out"},
//       ));
//       isLoading.value = false;
//       Get.snackbar("No Connection", "Check your internet and try again",
//           backgroundColor: Colors.redAccent, colorText: Colors.white);
//     } on TimeoutException {
//       DevService.instance.insertAPICall(AppAPIsCall(
//         id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
//         type: 'POST TIMEOUT',
//         path: AppURLs.login,
//         dateTime: DateTime.now(),
//         data: {"username": user, "password": "***"},
//         response: {"error": "TimeoutException", "message": "Request timed out"},
//       ));
//       isLoading.value = false;
//       Get.snackbar("Timeout", "Server took too long to respond",
//           backgroundColor: Colors.orange, colorText: Colors.white);
//     } catch (e) {
//       DevService.instance.insertAPICall(AppAPIsCall(
//         id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
//         type: 'POST TIMEOUT',
//         path: AppURLs.login,
//         dateTime: DateTime.now(),
//         data: {"username": user, "password": "***"},
//         response: {"error": "TimeoutException", "message": "Request timed out"},
//       ));
//       isLoading.value = false;
//       print("❌ [LOGIN ERROR] $e");
//       LogFile.write("❌ [LOGIN ERROR] $e");
//       Get.snackbar("Login Failed", "An error occurred during login",
//           backgroundColor: Colors.redAccent, colorText: Colors.white);
//     }
//   }

//   // Create a reusable header helper
//   static Future<Map<String, String>> getAuthHeaders() async {
//     final token = await AppPreferences.getToken();
//     return {
//       'Authorization': 'Bearer $token', // ✅ Bearer not JWT
//       'Content-Type': 'application/json',
//     };
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cp_tmtl_sensor_zig/routes/routes_string.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:cp_tmtl_sensor_zig/AppPreferences/app_areferences.dart';
import 'package:cp_tmtl_sensor_zig/api/app_urls.dart';
import 'package:cp_tmtl_sensor_zig/api/dev/dev_service.dart';

class LoginController extends GetxController {
  /// =========================================
  /// CONTROLLERS
  /// =========================================

  final usernameController = TextEditingController();

  final passwordController = TextEditingController();

  /// =========================================
  /// OBS VARIABLES
  /// =========================================

  final isLoading = false.obs;

  final hidePassword = true.obs;

  /// =========================================
  /// TOGGLE PASSWORD
  /// =========================================

  void togglePasswordVisibility() {
    hidePassword.value = !hidePassword.value;
  }

  /// =========================================
  /// LOGIN API
  /// =========================================

  Future<void> login() async {
    final String user = usernameController.text.trim();

    final String pass = passwordController.text.trim();

    /// =========================================
    /// VALIDATION
    /// =========================================

    if (user.isEmpty || pass.isEmpty) {
      Get.defaultDialog(
        title: "Error",
        middleText: "Please enter username & password",
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back();
        },
      );

      return;
    }

    try {
      isLoading.value = true;

      print("=================================");
      print("🚀 LOGIN API START");
      print("=================================");

      /// =========================================
      /// LOGIN API URL
      /// =========================================

      const String loginUrl =
          "https://uatalw4siite.tmtl.net/itracex-configservice/v1/api/auth/login";

      print("🌐 URL : $loginUrl");

      /// =========================================
      /// REQUEST BODY
      /// =========================================

      final Map<String, dynamic> requestBody = {
        "userName": user,
        "password": pass,
      };

      print("📤 REQUEST BODY :");

      print(jsonEncode(requestBody));

      /// =========================================
      /// API CALL
      /// =========================================

      final response = await http
          .post(
            Uri.parse(loginUrl),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      print("=================================");
      print("📥 API RESPONSE");
      print("=================================");

      print("✅ STATUS CODE : ${response.statusCode}");

      print("📦 RESPONSE BODY :");

      print(response.body);

      /// =========================================
      /// JSON RESPONSE
      /// =========================================

      final Map<String, dynamic> body = jsonDecode(response.body);

      /// =========================================
      /// DEV SERVICE LOG
      /// =========================================

      DevService.instance.insertAPICall(
        AppAPIsCall(
          id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
          type: 'POST ${response.statusCode}',
          path: AppURLs.login,
          dateTime: DateTime.now(),
          data: requestBody,
          response: body,
        ),
      );

      /// =========================================
      /// SUCCESS RESPONSE
      /// =========================================

      if (response.statusCode == 200 && body['responseStatus'] == "SUCCESS") {
        print("=================================");
        print("✅ LOGIN SUCCESS");
        print("=================================");

        final Map<String, dynamic> data = body['data'];

        final String accessToken = data['accessToken'];

        final String refreshToken = data['refreshToken'];

        final int userId = data['userId'];

        final String firstName = data['firstName'];

        final String lastName = data['lastName'];

        final String userName = data['userName'];
        final String? stationId = data['stationId']?.toString();

        /// =========================================
        /// PRINT USER INFO
        /// =========================================

        print("👤 USER ID : $userId");

        print("👤 FIRST NAME : $firstName");

        print("👤 LAST NAME : $lastName");

        print("👤 USERNAME : $userName");

        print("🔑 ACCESS TOKEN :");

        print(accessToken);

        print("🔄 REFRESH TOKEN :");

        print(refreshToken);

        /// =========================================
        /// SAVE TOKEN
        /// =========================================

        await AppPreferences.setToken(
          accessToken,
        );
        await AppPreferences.setActiveUser(user);

        print("👤 [SESSION] Active User set: $user");

        if (stationId != null && stationId.isNotEmpty) {
          await AppPreferences.saveStationId(stationId);

          // ✅ Verify what was actually saved
          final String? savedStationId = await AppPreferences.getStationId();
          print("✅ Saved StationId: $savedStationId");
        } else {
          print("⚠️ stationId is null or empty in API response");
        }

        print("✅ TOKEN SAVED SUCCESSFULLY");

        /// =========================================
        /// SUCCESS DIALOG
        /// =========================================

        Get.defaultDialog(
          title: "Success",
          middleText: "Login Successful",
          textConfirm: "OK",
          confirmTextColor: Colors.white,
          onConfirm: () {
            Get.back();

            /// NAVIGATION

            Get.offAllNamed(Routes.dashboardScreen);
          },
        );
      }

      /// =========================================
      /// LOGIN FAILED
      /// =========================================

      else {
        print("=================================");
        print("❌ LOGIN FAILED");
        print("=================================");

        print(body);

        final String errorMessage =
            body['messages']?[0]?['message'] ?? "Login Failed";

        Get.defaultDialog(
          title: "Login Failed",
          middleText: errorMessage,
          textConfirm: "OK",
          confirmTextColor: Colors.white,
          onConfirm: () {
            Get.back();
          },
        );
      }
    }

    /// =========================================
    /// SOCKET ERROR
    /// =========================================

    on SocketException catch (e) {
      DevService.instance.insertAPICall(
        AppAPIsCall(
          id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
          type: 'POST SOCKET ERROR',
          path: AppURLs.login,
          dateTime: DateTime.now(),
          data: {
            "userName": user,
            "password": "***",
          },
          response: {
            "error": "SocketException",
            "message": e.message,
            "address": e.address.toString(),
            "port": e.port,
          },
        ),
      );

      print("=================================");
      print("❌ SOCKET ERROR");
      print("=================================");

      print("MESSAGE : ${e.message}");

      print("ADDRESS : ${e.address}");

      print("PORT : ${e.port}");

      Get.defaultDialog(
        title: "Connection Error",
        middleText: "Unable to connect server",
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back();
        },
      );
    }

    /// =========================================
    /// TIMEOUT ERROR
    /// =========================================

    on TimeoutException {
      DevService.instance.insertAPICall(
        AppAPIsCall(
          id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
          type: 'POST TIMEOUT',
          path: AppURLs.login,
          dateTime: DateTime.now(),
          data: {
            "userName": user,
            "password": "***",
          },
          response: {
            "error": "TimeoutException",
            "message": "Request timed out",
          },
        ),
      );

      print("=================================");
      print("❌ TIMEOUT ERROR");
      print("=================================");

      Get.defaultDialog(
        title: "Timeout",
        middleText: "Server not responding",
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back();
        },
      );
    }

    /// =========================================
    /// COMMON ERROR
    /// =========================================

    catch (e) {
      DevService.instance.insertAPICall(
        AppAPIsCall(
          id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
          type: 'POST ERROR',
          path: AppURLs.login,
          dateTime: DateTime.now(),
          data: {
            "userName": user,
            "password": "***",
          },
          response: {
            "error": "Exception",
            "message": e.toString(),
          },
        ),
      );

      print("=================================");
      print("❌ COMMON ERROR");
      print("=================================");

      print(e.toString());

      Get.defaultDialog(
        title: "Error",
        middleText: e.toString(),
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back();
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// =========================================
  /// AUTH HEADERS
  /// =========================================

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await AppPreferences.getToken();

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }
}
