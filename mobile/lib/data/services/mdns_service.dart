import 'package:nsd/nsd.dart';
import '../../core/constants/app_constants.dart';

class MdnsService {
  Service? _discoveredService;

  /// 开始发现桌面端服务
  Future<Service?> discoverDesktopService({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final discovery = await startDiscovery(AppConstants.mdnsServiceType);

      // 等待发现服务
      Service? foundService;

      // 监听服务发现
      discovery.addListener(() {
        if (discovery.services.isNotEmpty) {
          foundService = discovery.services.first;
        }
      });

      // 等待超时
      await Future.delayed(timeout);

      await stopDiscovery(discovery);
      _discoveredService = foundService;
      return foundService;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取已发现的服务
  Service? getDiscoveredService() {
    return _discoveredService;
  }

  /// 获取服务器地址
  String? getServerUrl() {
    if (_discoveredService == null) return null;
    final host = _discoveredService!.host;
    final port = _discoveredService!.port ?? AppConstants.syncServerPort;
    return 'http://$host:$port';
  }

  /// 停止发现
  Future<void> stopDiscovery(dynamic discovery) async {
    try {
      await stopDiscovery(discovery);
    } catch (e) {
      // 忽略停止错误
    }
  }

  /// 清除已发现的服务
  void clearDiscoveredService() {
    _discoveredService = null;
  }
}
