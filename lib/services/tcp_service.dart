import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../models/live_data.dart';

typedef OnDataReceived = void Function(LiveData data);
typedef OnStatusChanged = void Function(String status);

class TcpService {
  Socket? _socket;
  final String ipAddress;
  final int port;

  TcpService({required this.ipAddress, required this.port});

  void connect(OnDataReceived onData, OnStatusChanged onStatus) async {
    try {
      _socket = await Socket.connect(ipAddress, port, timeout: const Duration(seconds: 5));
      _socket!.write('HELLO\n');

      onStatus("✅ Connected to $ipAddress:$port");

      utf8.decoder.bind(_socket!.cast<Uint8List>()).transform(const LineSplitter()).listen((line) {
        try {
          final Map<String, dynamic> json = jsonDecode(line.trim());
          final liveData = LiveData.fromJson(json);
          onData(liveData);
        } catch (_) {}
      }, onError: (_) => disconnect(onStatus), onDone: () => disconnect(onStatus));
    } catch (e) {
      onStatus("❌ Connection failed: $e");
    }
  }

  void disconnect(OnStatusChanged onStatus) {
    _socket?.destroy();
    onStatus("❌ Disconnected");
  }

  void dispose() {
    _socket?.destroy();
  }
}
