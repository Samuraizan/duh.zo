import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../device/bluetooth/ble_manager.dart';

class DeviceConnectionScreen extends StatefulWidget {
  @override
  _DeviceConnectionScreenState createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  final BleManager _bleManager = BleManager();
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;

  @override
  void initState() {
    super.initState();
    _bleManager.connectionStateStream.listen((state) {
      setState(() {
        _connectionState = state;
      });
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    try {
      final results = await _bleManager.startScan(timeout: const Duration(seconds: 10));
      setState(() {
        _scanResults = results;
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect to Device'),
      ),
      body: Column(
        children: [
          // Connection status
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: _connectionState == DeviceConnectionState.connected ? Colors.green : Colors.red,
            child: Text(
              _connectionState == DeviceConnectionState.connected 
                  ? 'Connected to device' 
                  : 'Not connected',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Scan button
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isScanning ? null : _startScan,
              child: _isScanning
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Scanning...'),
                      ],
                    )
                  : Text('Scan for Devices'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ),
          
          // Results list
          Expanded(
            child: _scanResults.isEmpty
                ? Center(
                    child: Text(
                      _isScanning ? 'Searching...' : 'No devices found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      final device = result.device;
                      
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(
                            device.name.isNotEmpty ? device.name : 'Unknown Device',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${device.id}'),
                              Text('Signal Strength: ${result.rssi} dBm'),
                            ],
                          ),
                          trailing: ElevatedButton(
                            child: Text('Connect'),
                            onPressed: () async {
                              final success = await _bleManager.connectToDevice(device);
                              if (success && mounted) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bleManager.dispose();
    super.dispose();
  }
} 