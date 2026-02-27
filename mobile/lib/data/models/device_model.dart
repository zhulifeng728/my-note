class DeviceModel {
  final String id;
  final String deviceName;
  final String token;
  final int? lastSeenAt;
  final int isTrusted;

  DeviceModel({
    required this.id,
    required this.deviceName,
    required this.token,
    this.lastSeenAt,
    required this.isTrusted,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      deviceName: json['device_name'] as String,
      token: json['token'] as String,
      lastSeenAt: json['last_seen_at'] as int?,
      isTrusted: json['is_trusted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_name': deviceName,
      'token': token,
      'last_seen_at': lastSeenAt,
      'is_trusted': isTrusted,
    };
  }
}
