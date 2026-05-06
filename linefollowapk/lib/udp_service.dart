import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:udp/udp.dart';

class UdpService {
  UDP? _sender;
  StreamSubscription? _receiverSubscription;
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  Timer? _heartbeatTimer;
  DateTime _lastReceivedTime = DateTime.now();

  Stream<String> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  static const Duration _heartbeatInterval = Duration(seconds: 2);
  static const Duration _connectionTimeout = Duration(seconds: 5);

  Future<bool> startListening(String listenAddress, int listenPort) async {
    try {
      _sender = await UDP.bind(Endpoint.any(port: Port(listenPort)));
      _receiverSubscription = _sender?.asStream().listen((Datagram? datagram) {
        if (datagram != null) {
          final message = String.fromCharCodes(datagram.data);
          _messageController.add(message);
          _lastReceivedTime = DateTime.now();
          _connectionStatusController.add(true); // Connected
        }
      }, onError: (error) {
        _messageController.addError('UDP listening error: $error');
        _connectionStatusController.add(false); // Disconnected
      });

      _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
        _checkConnection();
      });
      _connectionStatusController.add(true); // Initially connected
      return true;
    } catch (e) {
      _messageController.addError('Error starting UDP listener: $e');
      _connectionStatusController.add(false); // Disconnected
      return false;
    }
  }

  void _checkConnection() {
    if (_sender == null) {
      _connectionStatusController.add(false);
      return;
    }
    if (DateTime.now().difference(_lastReceivedTime) > _connectionTimeout) {
      _connectionStatusController.add(false); // Lost connection
    } else {
      _connectionStatusController.add(true); // Still connected
    }
  }

  Future<bool> sendMessage(String message, String remoteAddress, int remotePort) async {
    if (_sender == null) {
      _messageController.addError('UDP sender not initialized.');
      _connectionStatusController.add(false);
      return false;
    }
    try {
      var data = Uint8List.fromList(message.codeUnits);
      await _sender?.send(
        data,
        Endpoint.unicast(InternetAddress(remoteAddress), port: Port(remotePort)),
      );
      return true;
    } catch (e) {
      _messageController.addError('Error sending UDP message: $e');
      _connectionStatusController.add(false);
      return false;
    }
  }

  Future<void> stopListening() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _receiverSubscription?.cancel();
    _receiverSubscription = null;
    _sender?.close();
    _sender = null;
    _messageController.add('UDP connection stopped.');
    _connectionStatusController.add(false); // Explicitly disconnected
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _receiverSubscription?.cancel();
    _sender?.close();
    _messageController.close();
    _connectionStatusController.close();
  }
}
