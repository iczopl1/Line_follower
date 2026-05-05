import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'pid_parameters.dart';

class PidConfigManager {
  static const String _pidConfigsKey = 'pidConfigs';
  static const int maxConfigs = 5;

  Future<List<PidParameters>> loadPidConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configsString = prefs.getString(_pidConfigsKey);

    if (configsString != null) {
      final List<dynamic> jsonList = jsonDecode(configsString);
      return jsonList.map((json) => PidParameters.fromJson(json)).toList();
    }
    return List.generate(maxConfigs, (index) => PidParameters());
  }

  Future<void> savePidConfigs(List<PidParameters> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final String configsString = jsonEncode(configs.map((config) => config.toJson()).toList());
    await prefs.setString(_pidConfigsKey, configsString);
  }

  Future<void> savePidConfig(PidParameters config, int index) async {
    List<PidParameters> configs = await loadPidConfigs();
    if (index >= 0 && index < maxConfigs) {
      configs[index] = config;
      await savePidConfigs(configs);
    }
  }

  Future<PidParameters> loadPidConfig(int index) async {
    List<PidParameters> configs = await loadPidConfigs();
    if (index >= 0 && index < maxConfigs) {
      return configs[index];
    }
    return PidParameters(); // Return a default one if index is out of bounds
  }
}
