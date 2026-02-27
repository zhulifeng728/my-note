import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/devices_table.dart';

part 'devices_dao.g.dart';

@DriftAccessor(tables: [Devices])
class DevicesDao extends DatabaseAccessor<AppDatabase> with _$DevicesDaoMixin {
  DevicesDao(AppDatabase db) : super(db);

  // 获取所有受信任的设备
  Future<List<Device>> getTrustedDevices() {
    return (select(devices)..where((t) => t.isTrusted.equals(1))).get();
  }

  // 根据 token 获取设备
  Future<Device?> getDeviceByToken(String token) {
    return (select(devices)
          ..where((t) => t.token.equals(token) & t.isTrusted.equals(1)))
        .getSingleOrNull();
  }

  // 添加设备
  Future<void> addDevice({
    required String id,
    required String deviceName,
    required String token,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(devices).insert(
      DevicesCompanion.insert(
        id: id,
        deviceName: deviceName,
        token: token,
        lastSeenAt: Value(now),
        isTrusted: const Value(1),
      ),
    );
  }

  // 更新设备最后活跃时间
  Future<void> updateLastSeen(String deviceId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(devices)..where((t) => t.id.equals(deviceId))).write(
      DevicesCompanion(lastSeenAt: Value(now)),
    );
  }

  // 删除设备
  Future<void> removeDevice(String deviceId) async {
    await (delete(devices)..where((t) => t.id.equals(deviceId))).go();
  }
}
