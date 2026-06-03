import 'package:cp_tmtl_sensor_zig/logic/controller/dashboard/testRecipeController.dart';
import 'package:cp_tmtl_sensor_zig/logic/controller/dashboard/testingController.dart';
import 'package:get/get.dart';
import 'package:cp_tmtl_sensor_zig/logic/controller/dashboard/dasboardController.dart';

class TestingBinding extends Bindings {
  @override
  void dependencies() {
      Get.put(DashboardController(), permanent: true);
    Get.put(ESNController(), permanent: true);
    Get.put(TestRecipeController(), permanent: true); // Your PLC controller
  }
}