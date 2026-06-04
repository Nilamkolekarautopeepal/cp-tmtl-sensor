
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cp_tmtl_sensor_zig/AppPreferences/app_areferences.dart';
import 'package:cp_tmtl_sensor_zig/api/dev/dev_service.dart';
import 'package:cp_tmtl_sensor_zig/services/log_file.dart';

class DashboardController extends GetxController {
  // =====================================================
  // APP INFO
  // =====================================================

  RxString appName = ''.obs;
  RxString version = ''.obs;
  RxString buildNumber = ''.obs;

  // =====================================================
  // LOADING
  // =====================================================

  RxBool isLoading = false.obs;

  // =====================================================
  // MODEL DATA
  // =====================================================

  final RxList<Map<String, dynamic>> engineModels =
      <Map<String, dynamic>>[].obs;

  final RxInt selectedModelIndex = 0.obs;

  final RxMap<String, dynamic> selectedModel = <String, dynamic>{}.obs;

  // =====================================================
  // STATIC MODELS
  // =====================================================

  List<Map<String, String>> allModels = [
    {"model": "MOD-2024", "kup": "12345678"},
    {"model": "TD 2.2 L3", "kup": "25790211"},
    {"model": "TD 2.2 ", "kup": "25790212"}, // same model, different KUP
    {"model": "TCD 2.2 ", "kup": "25790213"},
    {"model": "D 2.2 L3", "kup": "25790215"},
    {"model": "TD 2.9 L4", "kup": "25790210"},
    {"model": "TCD 2.9 L4", "kup": "25790223"},
  ];

  @override
  void onInit() {
    super.onInit();

    loadAppInfo();

    fetchDashboardData();
  }

  // =====================================================
  // APP INFO
  // =====================================================

  Future<void> loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();

      appName.value = info.appName;
      version.value = info.version;
      buildNumber.value = info.buildNumber;
    } catch (e) {
      appName.value = "ATPL Tool";
      version.value = "1.0.0";
      buildNumber.value = "1";
    }
  }

  // =====================================================
  // SELECT MODEL
  // =====================================================

  void selectModel(int index) {
    selectedModelIndex.value = index;

    if (index < engineModels.length) {
      selectedModel.assignAll(engineModels[index]); // ✅ assignAll not .value =
    }
  }
  // =====================================================
  // FETCH DASHBOARD DATA
  // =====================================================

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
 
      // =================================================
      // TOKEN
      // =================================================
 
      final token = await AppPreferences.getToken();
      print("...............................$token");
 
      // =================================================
      // URL
      // =================================================
 
      const url = "http://139.59.76.174:8080/api/v1/support/traceability/test";
 
      // =================================================
      // DATE
      // =================================================
 
      final now = DateTime.now();
      final fromDate = now.subtract(const Duration(days: 30));
 
      String formatDate(DateTime d) =>
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
 
      // =================================================
      // UNIQUE MODEL NAMES FOR API (no KUP, no duplicates)
      // =================================================
 
      final List<String> apiModelNames =
          allModels.map((e) => e["model"]!).toSet().toList();
 
      // =================================================
      // REQUEST BODY
      // =================================================
 
      final requestBody = {
        "type": "SENSOR_TEST",
        "stationId": "SENSOR_1",
        "fromDate": formatDate(fromDate),
        "toDate": formatDate(now),
        "modelNo": apiModelNames, // ✅ only model names, no duplicates
      };
 
      print("🌐 URL => $url");
      print("📤 BODY => ${jsonEncode(requestBody)}");
      LogFile.write("📤 BODY => ${jsonEncode(requestBody)}");
 
      // =================================================
      // API CALL
      // =================================================
 
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "JWT $token",
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 20));
 
      // =================================================
      // RESPONSE LOG
      // =================================================
 
      print("📡 STATUS => ${response.statusCode}");
      print("📡 RESPONSE => ${response.body}");
      LogFile.write("📡 STATUS => ${response.statusCode}");
      LogFile.write("📡 RESPONSE => ${response.body}");
 
      // =================================================
      // DEV LOGGER
      // =================================================
 
      Map<String, dynamic> parsedResponse = {};
      try {
        parsedResponse = jsonDecode(response.body);
      } catch (_) {
        parsedResponse = {"raw": response.body};
      }
      parsedResponse['statusCode'] = response.statusCode;
 
      DevService.instance.insertAPICall(
        AppAPIsCall(
          id: "${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().toIso8601String()}",
          type: 'POST ${response.statusCode}',
          path: '/api/v1/support/traceability/test',
          dateTime: DateTime.now(),
          data: requestBody,
          response: parsedResponse,
        ),
      );
 
      // =================================================
      // SUCCESS
      // =================================================
 
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
 
        if (data["responseStatus"] == "SUCCESS") {
          final list = data["data"] ?? [];
 
          // ✅ Convert API response into a map keyed by modelId
          final Map<String, dynamic> apiDataMap = {};
          for (var item in list) {
            apiDataMap[item["modelId"]] = item;
          }
 
          engineModels.clear();
 
          // ✅ Loop allModels — each entry = one card (model + kup)
          // Same model with different KUP = two separate cards, same data
          for (var entry in allModels) {
            final modelName = entry["model"]!;
            final kupNumber = entry["kup"]!;
            final item = apiDataMap[modelName];
 
            engineModels.add({
              "name": modelName,
              "kup": kupNumber,
              "total": item?["totalTested"] ?? 0,
              "today": item?["todayTested"] ?? 0,
              "pass": item?["totalTestPass"] ?? 0,
              "fail": item?["totalTestFail"] ?? 0,
            });
          }
 
          if (engineModels.isNotEmpty) {
            selectedModelIndex.value = 0;
            selectedModel.assignAll(engineModels.first);
          }
 
          Get.snackbar(
            "Success",
            data["messages"]?[0]?["message"] ?? "Dashboard Loaded",
          );
 
          // =================================================
          // API RETURNED FAILURE STATUS
          // =================================================
        } else {
          // _loadEmptyModels();
 
          Get.snackbar(
            "Failed",
            data["messages"]?[0]?["message"] ?? "API Failed",
          );
        }
 
        // =================================================
        // SERVER ERROR
        // =================================================
      } else {
        //_loadEmptyModels();
 
        Get.snackbar(
          "Server Error",
          "Status : ${response.statusCode}",
        );
      }
    } catch (e) {
      print("❌ ERROR => $e");
      LogFile.write("❌ ERROR => $e");
 
      //  _loadEmptyModels();
 
      Get.snackbar(
        "Error",
        "Something went wrong",
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =====================================================
  // REFRESH
  // =====================================================

  Future<void> refreshDashboard() async {
    await fetchDashboardData();
  }
}
