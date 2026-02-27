import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../database/daos/notes_dao.dart';
import '../models/note_model.dart';
import 'pairing_service.dart';

class WebSocketService {
  final NotesDao _notesDao;
  final PairingService _pairingService;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;

  // 回调函数
  Function(bool)? onConnectionChanged;
  Function(NoteModel)? onNoteUpdate;
  Function(String)? onError;

  WebSocketService(this._notesDao, this._pairingService);

  /// 连接 WebSocket
  Future<void> connect() async {
    if (_isConnected) return;

    final serverUrl = await _pairingService.getServerUrl();
    final token = await _pairingService.getToken();

    if (serverUrl == null || token == null) {
      onError?.call('未配对设备');
      return;
    }

    try {
      // 将 http:// 替换为 ws://
      final wsUrl = serverUrl.replaceFirst('http://', 'ws://');
      final uri = Uri.parse('$wsUrl/ws?token=$token');

      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _reconnectAttempts = 0;
      onConnectionChanged?.call(true);

      // 监听消息
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // 启动心跳
      _startPing();
    } catch (e) {
      _isConnected = false;
      onConnectionChanged?.call(false);
      onError?.call('连接失败: $e');
      _scheduleReconnect();
    }
  }

  /// 处理接收到的消息
  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String?;

      if (type == 'pong') {
        // 心跳响应，忽略
        return;
      }

      if (type == 'note_update') {
        final noteData = message['note'] as Map<String, dynamic>;
        final noteModel = NoteModel.fromJson(noteData);

        // 更新本地数据库
        _notesDao.upsertNoteFromSync(
          _convertToNote(noteModel),
        );

        // 通知回调
        onNoteUpdate?.call(noteModel);
      }
    } catch (e) {
      onError?.call('消息处理失败: $e');
    }
  }

  /// 处理错误
  void _handleError(dynamic error) {
    _isConnected = false;
    onConnectionChanged?.call(false);
    onError?.call('WebSocket 错误: $error');
    _scheduleReconnect();
  }

  /// 处理断开连接
  void _handleDisconnect() {
    _isConnected = false;
    onConnectionChanged?.call(false);
    _stopPing();
    _scheduleReconnect();
  }

  /// 启动心跳
  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _send({'type': 'ping'});
      }
    });
  }

  /// 停止心跳
  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// 发送消息
  void _send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  /// 安排重连
  void _scheduleReconnect() {
    if (!_shouldReconnect) return;

    _reconnectTimer?.cancel();

    // 指数退避：1s, 2s, 4s, 8s, 最多 30s
    final delay = Duration(
      seconds: (1 << _reconnectAttempts).clamp(1, 30),
    );

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect();
    });
  }

  /// 断开连接
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _stopPing();

    await _subscription?.cancel();
    await _channel?.sink.close();

    _channel = null;
    _subscription = null;
    _isConnected = false;
    onConnectionChanged?.call(false);
  }

  /// 重新连接
  Future<void> reconnect() async {
    await disconnect();
    _shouldReconnect = true;
    _reconnectAttempts = 0;
    await connect();
  }

  /// 检查连接状态
  bool get isConnected => _isConnected;

  dynamic _convertToNote(NoteModel model) {
    // 简化处理，实际应该转换为 Drift Note 对象
    return model;
  }

  /// 清理资源
  void dispose() {
    disconnect();
  }
}
