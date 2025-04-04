import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../device/bluetooth/ble_manager.dart';

class DeviceConnectionScreen extends StatefulWidget {
  @override
  _DeviceConnectionScreenState createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  final BleManager _bleManager = BleManager();
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bleManager.connectionStateStream.listen((state) {
      setState(() {
        _connectionState = state;
      });
    });
    _checkBluetoothState();
  }

  Future<void> _checkBluetoothState() async {
    final isAvailable = await _bleManager.isBluetoothAvailable();
    if (!isAvailable) {
      setState(() {
        _errorMessage = 'Bluetooth is not available or turned off. Please enable Bluetooth and try again.';
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices = [];
      _errorMessage = null;
    });

    try {
      final devices = await _bleManager.startScan(timeout: const Duration(seconds: 10));
      setState(() {
        _devices = devices;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkBluetoothState,
          ),
        ],
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
          
          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.orange,
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Scan button
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isScanning || _errorMessage != null ? null : _startScan,
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
            child: _devices.isEmpty
                ? Center(
                    child: Text(
                      _isScanning 
                          ? 'Searching...' 
                          : _errorMessage != null 
                              ? 'Please fix the Bluetooth issue to scan for devices'
                              : 'No devices found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(
                            device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('ID: ${device.remoteId}'),
                          trailing: ElevatedButton(
                            child: Text('Connect'),
                            onPressed: () async {
                              try {
                                final success = await _bleManager.connectToDevice(device);
                                if (success && mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
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