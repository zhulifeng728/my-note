class AppConstants {
  // 同步服务器配置
  static const int syncServerPort = 45678;
  static const String mdnsServiceType = '_notes-sync._tcp';

  // 配对码配置
  static const int pairingCodeLength = 6;
  static const int pairingCodeExpirySeconds = 60;

  // 同步配置
  static const int syncDebounceMilliseconds = 2000;
  static const int syncRetryAttempts = 3;
  static const int syncRetryDelaySeconds = 5;
  static const int backgroundSyncIntervalMinutes = 5;

  // 冲突检测配置
  static const int conflictTimeWindowMilliseconds = 5000;

  // 图片配置
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int imageQuality = 80;
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB

  // 搜索配置
  static const int searchDebounceMilliseconds = 300;

  // 编辑器配置
  static const int autoSaveDebounceMilliseconds = 500;
}
