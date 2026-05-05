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

  @override
  void initState() {
    super.initState();
    _loadAllPidConfigs();
    _messageSubscription = _udpService.messages.listen((message) {
      setState(() {
        _lastReceivedMessage = message;
      });
    }, onError: (error) {
      setState(() {
        _lastReceivedMessage = 'Error: $error';
      });
      _showSnackbar('UDP Error: $error');
    });
  }

  @override
  void dispose() {
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
    _messageSubscription?.cancel();
    _udpService.dispose();
    super.dispose();
  }

  Future<void> _loadAllPidConfigs() async {
    _pidConfigs = await _configManager.loadPidConfigs();
    _loadPidConfig(_currentConfigIndex); // Load the first config by default
  }

  void _loadPidConfig(int index) {
    if (index >= 0 && index < PidConfigManager.maxConfigs) {
      setState(() {
        _currentConfigIndex = index;
        final config = _pidConfigs[_currentConfigIndex];
        _kpController.text = config.kp.toString();
        _kiController.text = config.ki.toString();
        _kdController.text = config.kd.toString();
        _maxController.text = config.max.toString();
        _baseController.text = config.base.toString();
        _turnController.text = config.turn.toString();
        _lostThController.text = config.lostTh.toString();
      });
    }
  }

  void _saveCurrentPidConfig() {
    try {
      final newConfig = PidParameters(
        kp: double.tryParse(_kpController.text) ?? 0.0,
        ki: double.tryParse(_kiController.text) ?? 0.0,
        kd: double.tryParse(_kdController.text) ?? 0.0,
        max: double.tryParse(_maxController.text) ?? 0.0,
        base: double.tryParse(_baseController.text) ?? 0.0,
        turn: double.tryParse(_turnController.text) ?? 0.0,
        lostTh: double.tryParse(_lostThController.text) ?? 0.0,
      );
      _configManager.savePidConfig(newConfig, _currentConfigIndex);
      setState(() {
        _pidConfigs[_currentConfigIndex] = newConfig; // Update local list
      });
      _showSnackbar('Configuration ${_currentConfigIndex + 1} saved!');
    } catch (e) {
      _showSnackbar('Error saving configuration: $e');
    }
  }

  Future<void> _startUdpCommunication() async {
    final listenPort = int.tryParse(_appPortController.text) ?? 4211;
    setState(() {
      _connectionStatus = 'Connecting...';
    });
    bool success = await _udpService.startListening('0.0.0.0', listenPort);
    if (success) {
      setState(() {
        _connectionStatus = 'Connected to port $listenPort';
      });
      _showSnackbar('UDP Listener started on port $listenPort');
    } else {
      setState(() {
        _connectionStatus = 'Failed to connect';
      });
      _showSnackbar('Failed to start UDP listener.');
    }
  }

  Future<void> _stopUdpCommunication() async {
    await _udpService.stopListening();
    setState(() {
      _connectionStatus = 'Disconnected';
    });
    _showSnackbar('UDP Communication stopped.');
  }

  Future<void> _sendPidParameters() async {
    final robotIp = _robotIpController.text;
    final robotPort = int.tryParse(_robotPortController.text) ?? 4210;

    final pidParams = PidParameters(
      kp: double.tryParse(_kpController.text) ?? 0.0,
      ki: double.tryParse(_kiController.text) ?? 0.0,
      kd: double.tryParse(_kdController.text) ?? 0.0,
      max: double.tryParse(_maxController.text) ?? 0.0,
      base: double.tryParse(_baseController.text) ?? 0.0,
      turn: double.tryParse(_turnController.text) ?? 0.0,
      lostTh: double.tryParse(_lostThController.text) ?? 0.0,
    );

    String message = 'SET_PID:${pidParams.toJson()}'; // Example message format
    bool sent = await _udpService.sendMessage(message, robotIp, robotPort);
    if (sent) {
      _showSnackbar('PID parameters sent to $robotIp:$robotPort');
    } else {
      _showSnackbar('Failed to send PID parameters.');
    }
  }

  Future<void> _requestPidParameters() async {
    final robotIp = _robotIpController.text;
    final robotPort = int.tryParse(_robotPortController.text) ?? 4210;
    String message = 'REQ_PID'; // Example message format
    bool sent = await _udpService.sendMessage(message, robotIp, robotPort);
    if (sent) {
      _showSnackbar('Requested PID parameters from $robotIp:$robotPort');
    } else {
      _showSnackbar('Failed to request PID parameters.');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            // Connection Status Section
            _buildSectionTitle('Connection Settings'),
            _buildConnectionSettings(),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8.0),
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

            // PID Configurations Section
            _buildSectionTitle('PID Configurations'),
            _buildPidConfigSelectors(),
            const SizedBox(height: 20),

            // Control Buttons Section
            _buildSectionTitle('Control Buttons'),
            _buildControlButtons(),
            const SizedBox(height: 20),

            // PID Parameters Input Section
            _buildSectionTitle('PID Parameters'),
            _buildPidParameterInputs(),
            const SizedBox(height: 20),

            // Sensor Visualization Section
            _buildSectionTitle('Sensor Visualization'),
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Center(child: Text('Sensor data will be displayed here')),
            ),
            const SizedBox(height: 20),

            // Debugging Values Section
            _buildSectionTitle('Debugging Values'),
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Center(child: Text('Debug data will be displayed here')),
            ),
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
        ElevatedButton(
          onPressed: _saveCurrentPidConfig,
          child: const Text('Save Current Config'),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 2.5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ElevatedButton(onPressed: _startUdpCommunication, child: const Text('Start Comms')),
        ElevatedButton(onPressed: _stopUdpCommunication, child: const Text('Stop Comms')),
        ElevatedButton(onPressed: () {}, child: const Text('Start Calib')),
        ElevatedButton(onPressed: () {}, child: const Text('Start Robot')),
        ElevatedButton(onPressed: () {}, child: const Text('Stop Robot')),
        ElevatedButton(onPressed: () {}, child: const Text('Reset Robot')),
        ElevatedButton(onPressed: _sendPidParameters, child: const Text('Send Params')),
        ElevatedButton(onPressed: _requestPidParameters, child: const Text('Request Params')),
        ElevatedButton(onPressed: () {}, child: const Text('Reset App')),
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

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.number}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
        ),
      ),
    );
  }
}

