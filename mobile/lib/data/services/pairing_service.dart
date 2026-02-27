import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../models/pairing_model.dart';
import '../database/daos/devices_dao.dart';

class PairingService {
  final Dio _dio;
  final DevicesDao _devicesDao;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'device_token';
  static const String _deviceIdKey = 'device_id';
  static const String _serverUrlKey = 'server_url';

  PairingService(this._dio, this._devicesDao);

  /// 配对设备
  Future<PairingResponse> pairDevice({
    required String serverUrl,
    required String code,
    required String deviceName,
  }) async {
    try {
      final response = await _dio.post(
        '$serverUrl/api/pair',
        data: PairingRequest(
          code: code,
          deviceName: deviceName,
        ).toJson(),
      );

      final pairingResponse = PairingResponse.fromJson(response.data);

      // 保存配对信息到安全存储
      await _secureStorage.write(key: _tokenKey, value: pairingResponse.token);
      await _secureStorage.write(key: _deviceIdKey, value: pairingResponse.deviceId);
      await _secureStorage.write(key: _serverUrlKey, value: serverUrl);

      // 保存到数据库
      await _devicesDao.addDevice(
        id: pairingResponse.deviceId,
        deviceName: deviceName,
        token: pairingResponse.token,
      );

      return pairingResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('配对码无效或已过期');
      }
      throw Exception('配对失败: ${e.message}');
    }
  }

  /// 获取已保存的 token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// 获取已保存的设备 ID
  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: _deviceIdKey);
  }

  /// 获取已保存的服务器地址
  Future<String?> getServerUrl() async {
    return await _secureStorage.read(key: _serverUrlKey);
  }

  /// 检查是否已配对
  Future<bool> isPaired() async {
    final token = await getToken();
    final deviceId = await getDeviceId();
    final serverUrl = await getServerUrl();
    return token != null && deviceId != null && serverUrl != null;
  }

  /// 清除配对信息
  Future<void> unpair() async {
    final deviceId = await getDeviceId();

    // 从安全存储中删除
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _deviceIdKey);
    await _secureStorage.delete(key: _serverUrlKey);

    // 从数据库中删除
    if (deviceId != null) {
      await _devicesDao.removeDevice(deviceId);
    }
  }

  /// 验证配对是否有效
  Future<bool> validatePairing() async {
    try {
      final token = await getToken();
      final serverUrl = await getServerUrl();

      if (token == null || serverUrl == null) {
        return false;
      }

      // 尝试获取笔记列表来验证 token
      final response = await _dio.get(
        '$serverUrl/api/notes',
        options: Options(
          headers: {'x-device-token': token},
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
