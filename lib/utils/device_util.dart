import 'package:device_info_plus/device_info_plus.dart';

String androidInfoId = "BP2A.250605.031.A2";
Future<String?> getAndroidID() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  return androidInfo.id;
}
