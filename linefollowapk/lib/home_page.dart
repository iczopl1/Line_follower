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

  String? _robotLastKnownState; // To track the robot's last known state
  List<int> _rawSensorValues = List.filled(16, 0);
  List<bool> _lineDetectionStatus = List.filled(16, false);
  String _debuggingValues = 'No debug data yet.';
  
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
            _buildSensorVisualization(),
            const SizedBox(height: 20),

            // Debugging Values Section
            _buildSectionTitle('Debugging Values'),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(_debuggingValues),
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

  Widget _buildSensorVisualization() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Raw sensor values
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
        // Line detection visualization
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _lineDetectionStatus.map((isDetecting) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Container(
              width: 20,
              height: 20,
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

