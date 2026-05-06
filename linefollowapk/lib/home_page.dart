import 'dart:async';
import 'package:flutter/material.dart';
import 'pid_config_manager.dart';
import 'pid_parameters.dart';
import 'udp_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PidConfigManager _configManager = PidConfigManager();
  final UdpService _udpService = UdpService();
  List<PidParameters> _pidConfigs = [];
  int _currentConfigIndex = 0;

  // TextEditingControllers for PID parameters
  final TextEditingController _kpController = TextEditingController();
  final TextEditingController _kiController = TextEditingController();
  final TextEditingController _kdController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  final TextEditingController _baseController = TextEditingController();
  final TextEditingController _turnController = TextEditingController();
  final TextEditingController _lostThController = TextEditingController();

  // TextEditingControllers for UDP communication
  final TextEditingController _robotIpController = TextEditingController(text: '192.168.4.1'); // Default IP
  final TextEditingController _robotPortController = TextEditingController(text: '4210'); // Default Port
  final TextEditingController _appPortController = TextEditingController(text: '4211'); // Default Port

  String _connectionStatus = 'Disconnected';
  String _lastReceivedMessage = 'No messages yet.';
  StreamSubscription? _messageSubscription;
  StreamSubscription? _statusSubscription;

  String? _robotLastKnownState; // To track the robot's last known state
  List<int> _rawSensorValues = List.filled(16, 0);
  List<bool> _lineDetectionStatus = List.filled(16, false);
  String _debuggingValues = 'No debug data yet.';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _pidConfigs = await _configManager.loadPidConfigs();
    if (_pidConfigs.isNotEmpty) {
      _loadPidConfig(0);
    }
  }

  void _loadPidConfig(int index) {
    if (index < 0 || index >= _pidConfigs.length) return;
    setState(() {
      _currentConfigIndex = index;
      final config = _pidConfigs[index];
      _kpController.text = config.kp.toString();
      _kiController.text = config.ki.toString();
      _kdController.text = config.kd.toString();
      _maxController.text = config.max.toString();
      _baseController.text = config.base.toString();
      _turnController.text = config.turn.toString();
      _lostThController.text = config.lostTh.toString();
    });
  }

  Future<void> _saveCurrentPidConfig() async {
    final updatedConfig = PidParameters(
      kp: double.tryParse(_kpController.text) ?? 0.0,
      ki: double.tryParse(_kiController.text) ?? 0.0,
      kd: double.tryParse(_kdController.text) ?? 0.0,
      max: double.tryParse(_maxController.text) ?? 0.0,
      base: double.tryParse(_baseController.text) ?? 0.0,
      turn: double.tryParse(_turnController.text) ?? 0.0,
      lostTh: double.tryParse(_lostThController.text) ?? 0.0,
    );

    if (_currentConfigIndex < _pidConfigs.length) {
      _pidConfigs[_currentConfigIndex] = updatedConfig;
      await _configManager.savePidConfig(updatedConfig, _currentConfigIndex);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Config ${_currentConfigIndex + 1} saved locally.')),
        );
      }
    }
  }

  void _startUdpCommunication() async {
    final appPort = int.tryParse(_appPortController.text) ?? 4211;
    bool started = await _udpService.startListening('0.0.0.0', appPort);

    if (started) {
      _messageSubscription = _udpService.messages.listen((message) {
        if (mounted) {
          setState(() {
            _lastReceivedMessage = message;
            _parseRobotMessage(message);
          });
        }
      });

      _statusSubscription = _udpService.connectionStatus.listen((isConnected) {
        if (mounted) {
          setState(() {
            _connectionStatus = isConnected ? 'Connected' : 'Disconnected';
          });
        }
      });

      if (mounted) {
        setState(() {
          _connectionStatus = 'Listening on port $appPort';
        });
      }
    }
  }

  void _stopUdpCommunication() async {
    await _udpService.stopListening();
    await _messageSubscription?.cancel();
    await _statusSubscription?.cancel();
    if (mounted) {
      setState(() {
        _connectionStatus = 'Disconnected';
      });
    }
  }

  void _parseRobotMessage(String message) {
    if (message.startsWith('DEBUG:')) {
      _debuggingValues = message;
    } else if (message.startsWith('SENSORS:')) {
      final values = message.substring(8).split(',');
      for (int i = 0; i < values.length && i < 16; i++) {
        _rawSensorValues[i] = int.tryParse(values[i]) ?? 0;
        _lineDetectionStatus[i] = _rawSensorValues[i] > 500;
      }
    }
  }

  Future<void> _sendUdpCommand(String command) async {
    final ip = _robotIpController.text;
    final port = int.tryParse(_robotPortController.text) ?? 4210;
    await _udpService.sendMessage(command, ip, port);
  }

  void _sendPidParameters() async {
    final message = 'SET_PID:${_kpController.text},${_kiController.text},${_kdController.text},'
        '${_maxController.text},${_baseController.text},${_turnController.text},${_lostThController.text}';
    await _sendUdpCommand(message);
  }

  void _requestPidParameters() async {
    await _sendUdpCommand('REQ_PID');
  }

  void _resetApp() {
    setState(() {
      _lastReceivedMessage = 'App state reset.';
      _debuggingValues = 'No debug data yet.';
      _rawSensorValues = List.filled(16, 0);
      _lineDetectionStatus = List.filled(16, false);
      _loadPidConfig(0);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App state reset to Config 1')),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _udpService.dispose();
    _kpController.dispose();
    _kiController.dispose();
    _kdController.dispose();
    _maxController.dispose();
    _baseController.dispose();
    _turnController.dispose();
    _lostThController.dispose();
    _robotIpController.dispose();
    _robotPortController.dispose();
    _appPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Line Follower Robot Control'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Connection Settings
            _buildSectionTitle('Connection Settings'),
            _buildConnectionSettings(),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: $_connectionStatus'),
                  Text('Last Message: $_lastReceivedMessage'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Control Buttons Section
            _buildSectionTitle('Control Buttons'),
            _buildControlButtons(),
            const SizedBox(height: 20),

            // 3. PID Parameters Input Section
            _buildSectionTitle('PID Parameters'),
            _buildPidParameterInputs(),
            const SizedBox(height: 20),

            // 4. Sensor Visualization Section
            _buildSectionTitle('Sensor Visualization'),
            _buildSensorVisualization(),
            const SizedBox(height: 20),

            // 5. Debugging Values Section
            _buildSectionTitle('Debugging Values'),
            Container(
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(_debuggingValues),
            ),
            const SizedBox(height: 20),

            // 6. PID Configurations Section
            _buildSectionTitle('Saved PID Configurations'),
            _buildPidConfigSelectors(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildConnectionSettings() {
    return Column(
      children: [
        _buildTextField(_robotIpController, 'Robot IP Address', keyboardType: TextInputType.text),
        _buildTextField(_robotPortController, 'Robot Port', keyboardType: TextInputType.number),
        _buildTextField(_appPortController, 'App Listen Port', keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildPidConfigSelectors() {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: PidConfigManager.maxConfigs,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text('Config ${index + 1}'),
                  selected: _currentConfigIndex == index,
                  onSelected: (selected) {
                    if (selected) {
                      _loadPidConfig(index);
                    }
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveCurrentPidConfig,
            icon: const Icon(Icons.save),
            label: const Text('Save to Current Slot'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 2.2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ElevatedButton(onPressed: _startUdpCommunication, child: const Text('Start Comms')),
        ElevatedButton(onPressed: _stopUdpCommunication, child: const Text('Stop Comms')),
        ElevatedButton(onPressed: () => _sendUdpCommand('START_CALIB'), child: const Text('Start Calib')),
        ElevatedButton(onPressed: () => _sendUdpCommand('START_ROBOT'), child: const Text('Start Robot')),
        ElevatedButton(onPressed: () => _sendUdpCommand('STOP_ROBOT'), child: const Text('Stop Robot')),
        ElevatedButton(onPressed: () => _sendUdpCommand('RESET_ROBOT'), child: const Text('Reset Robot')),
        ElevatedButton(onPressed: _sendPidParameters, child: const Text('Send Params')),
        ElevatedButton(onPressed: _requestPidParameters, child: const Text('Request Params')),
        ElevatedButton(onPressed: _resetApp, child: const Text('Reset App')),
      ],
    );
  }

  Widget _buildPidParameterInputs() {
    return Column(
      children: [
        _buildTextField(_kpController, 'Kp'),
        _buildTextField(_kiController, 'Ki'),
        _buildTextField(_kdController, 'Kd'),
        _buildTextField(_maxController, 'Max'),
        _buildTextField(_baseController, 'Base'),
        _buildTextField(_turnController, 'Turn'),
        _buildTextField(_lostThController, 'Lost_th'),
      ],
    );
  }

  Widget _buildSensorVisualization() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _rawSensorValues.map((value) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text('$value', style: const TextStyle(fontSize: 12)),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _lineDetectionStatus.map((isDetecting) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isDetecting ? Colors.black : Colors.white,
                border: Border.all(color: Colors.grey),
                shape: BoxShape.circle,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.number}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          isDense: true,
        ),
      ),
    );
  }
}
