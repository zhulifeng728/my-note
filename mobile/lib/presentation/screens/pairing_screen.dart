import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/services/mdns_service.dart';
import '../../data/services/pairing_service.dart';
import '../providers/database_providers.dart';
import 'package:dio/dio.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final MdnsService _mdnsService = MdnsService();
  String? _serverUrl;
  bool _isDiscovering = false;
  bool _isPairing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _discoverServer();
  }

  Future<void> _discoverServer() async {
    setState(() {
      _isDiscovering = true;
      _errorMessage = null;
    });

    try {
      final service = await _mdnsService.discoverDesktopService();
      if (service != null) {
        final url = _mdnsService.getServerUrl();
        setState(() {
          _serverUrl = url;
          _isDiscovering = false;
        });
      } else {
        setState(() {
          _errorMessage = '未找到桌面端服务，请确保桌面端已启动';
          _isDiscovering = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '服务发现失败: $e';
        _isDiscovering = false;
      });
    }
  }

  Future<void> _handleQrCode(String code) async {
    if (_isPairing || _serverUrl == null) return;

    setState(() {
      _isPairing = true;
      _errorMessage = null;
    });

    try {
      final dio = Dio();
      final devicesDao = ref.read(devicesDaoProvider);
      final pairingService = PairingService(dio, devicesDao);

      await pairingService.pairDevice(
        serverUrl: _serverUrl!,
        code: code,
        deviceName: 'Flutter Mobile',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配对成功！')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isPairing = false;
      });
    }
  }

  @override
  void dispose() {
    // mdns service cleanup handled internally
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配对设备'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isDiscovering) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在搜索桌面端...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _serverUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _discoverServer,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_serverUrl == null) {
      return const Center(
        child: Text('未找到服务器'),
      );
    }

    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red[100],
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.qr_code_scanner, size: 64),
              const SizedBox(height: 16),
              Text(
                '已找到服务器: $_serverUrl',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '请扫描桌面端显示的配对码',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isPairing
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在配对...'),
                    ],
                  ),
                )
              : MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _handleQrCode(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
        ),
      ],
    );
  }
}
