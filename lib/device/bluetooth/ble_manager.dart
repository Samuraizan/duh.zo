import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/constants.dart';

enum DeviceConnectionState { disconnected, connecting, connected, disconnecting }

class BleManager {
  final StreamController<DeviceConnectionState> _connectionStateController = 
      StreamController<DeviceConnectionState>.broadcast();
  
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;

  Stream<DeviceConnectionState> get connectionStateStream => 
      _connectionStateController.stream;

  Future<bool> isBluetoothAvailable() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      print('Error checking Bluetooth state: $e');
      return false;
    }
  }

  Future<List<BluetoothDevice>> startScan({Duration timeout = const Duration(seconds: 4)}) async {
    if (_isScanning) return [];
    
    // Check if Bluetooth is available and turned on
    if (!await isBluetoothAvailable()) {
      throw Exception('Bluetooth is not available or turned off. Please enable Bluetooth and try again.');
    }
    
    _isScanning = true;
    print('Starting BLE scan...');
    
    try {
      // Start scanning
      await FlutterBluePlus.startScan(timeout: timeout);
      
      // Wait for the scan to complete
      await Future.delayed(timeout);
      await FlutterBluePlus.stopScan();
      
      // Get discovered devices
      final scanResults = await FlutterBluePlus.scanResults.first;
      final devices = scanResults.map((result) => result.device).toList();
      print('Scan completed. Found ${devices.length} devices:');
      
      for (var device in devices) {
        print('Device: ${device.platformName} (${device.remoteId})');
      }
      
      return devices;
    } catch (e) {
      print('Error during scan: $e');
      rethrow; // Rethrow to let the UI handle the error
    } finally {
      _isScanning = false;
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (!await isBluetoothAvailable()) {
      throw Exception('Bluetooth is not available or turned off. Please enable Bluetooth and try again.');
    }

    if (_connectedDevice != null) {
      await disconnectFromDevice();
    }
    
    _connectionStateController.add(DeviceConnectionState.connecting);
    print('Attempting to connect to device: ${device.platformName} (${device.remoteId})');
    
    try {
      await device.connect(timeout: const Duration(seconds: 30));
      _connectedDevice = device;
      _connectionStateController.add(DeviceConnectionState.connected);
      
      print('Connected successfully. Discovering services...');
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      print('Found ${services.length} services:');
      
      for (var service in services) {
        print('Service: ${service.uuid}');
        for (var characteristic in service.characteristics) {
          print('  Characteristic: ${characteristic.uuid}');
          print('    Properties: ');
          print('      Read: ${characteristic.properties.read}');
          print('      Write: ${characteristic.properties.write}');
          print('      Notify: ${characteristic.properties.notify}');
        }
      }
      
      // Set up disconnect listener
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          print('Device disconnected: ${device.platformName}');
          _connectedDevice = null;
          _connectionStateController.add(DeviceConnectionState.disconnected);
        }
      });
      
      return true;
    } catch (e) {
      print('Connection error: $e');
      _connectionStateController.add(DeviceConnectionState.disconnected);
      return false;
    }
  }

  Future<void> disconnectFromDevice() async {
    if (_connectedDevice == null) return;
    
    _connectionStateController.add(DeviceConnectionState.disconnecting);
    print('Disconnecting from device: ${_connectedDevice!.platformName}');
    
    try {
      await _connectedDevice!.disconnect();
    } catch (e) {
      print('Error during disconnect: $e');
    } finally {
      _connectedDevice = null;
      _connectionStateController.add(DeviceConnectionState.disconnected);
    }
  }
  
  void dispose() {
    _connectionStateController.close();
  }
} 