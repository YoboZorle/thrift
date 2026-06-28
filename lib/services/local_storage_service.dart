import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over SharedPreferences for reading/writing JSON lists & values.
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  List<Map<String, dynamic>> readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  String? readString(String key) => _prefs.getString(key);

  Future<void> writeString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  bool readBool(String key) => _prefs.getBool(key) ?? false;

  Future<void> writeBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  Future<void> clearAll() async => _prefs.clear();
}
