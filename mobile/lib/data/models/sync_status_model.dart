enum SyncConnectionStatus {
  waiting,
  connected,
  error,
}

class SyncStatusModel {
  final SyncConnectionStatus connection;
  final int pendingCount;
  final int? lastSyncAt;
  final String? connectedDevice;

  SyncStatusModel({
    required this.connection,
    required this.pendingCount,
    this.lastSyncAt,
    this.connectedDevice,
  });

  factory SyncStatusModel.fromJson(Map<String, dynamic> json) {
    return SyncStatusModel(
      connection: SyncConnectionStatus.values.firstWhere(
        (e) => e.name == json['connection'],
        orElse: () => SyncConnectionStatus.waiting,
      ),
      pendingCount: json['pendingCount'] as int? ?? 0,
      lastSyncAt: json['lastSyncAt'] as int?,
      connectedDevice: json['connectedDevice'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connection': connection.name,
      'pendingCount': pendingCount,
      'lastSyncAt': lastSyncAt,
      'connectedDevice': connectedDevice,
    };
  }

  SyncStatusModel copyWith({
    SyncConnectionStatus? connection,
    int? pendingCount,
    int? lastSyncAt,
    String? connectedDevice,
  }) {
    return SyncStatusModel(
      connection: connection ?? this.connection,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      connectedDevice: connectedDevice ?? this.connectedDevice,
    );
  }
}
