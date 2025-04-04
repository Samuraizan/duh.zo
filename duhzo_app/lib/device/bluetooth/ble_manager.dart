import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/constants.dart';

enum DeviceConnectionState { disconnected, connecting, connected, disconnecting }

class BleManager {
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  final StreamController<DeviceConnectionState> _connectionStateController = 
      StreamController<DeviceConnectionState>.broadcast();
  
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;

  Stream<DeviceConnectionState> get connectionStateStream => 
      _connectionStateController.stream;

  Future<List<ScanResult>> startScan({Duration timeout = const Duration(seconds: 4)}) async {
    if (_isScanning) return [];
    
    _isScanning = true;
    print('Starting BLE scan...');
    
    try {
      await _flutterBlue.startScan(timeout: timeout);
      final results = await _flutterBlue.scanResults.first;
      print('Scan completed. Found ${results.length} devices:');
      
      for (var result in results) {
        print('Device: ${result.device.name} (${result.device.id})');
        print('  RSSI: ${result.rssi}');
        if (result.advertisementData.manufacturerData.isNotEmpty) {
          print('  Manufacturer Data: ${result.advertisementData.manufacturerData}');
        }
        if (result.advertisementData.serviceUuids.isNotEmpty) {
          print('  Service UUIDs: ${result.advertisementData.serviceUuids}');
        }
      }
      
      return results;
    } catch (e) {
      print('Error during scan: $e');
      return [];
    } finally {
      await _flutterBlue.stopScan();
      _isScanning = false;
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (_connectedDevice != null) {
      await disconnectFromDevice();
    }
    
    _connectionStateController.add(DeviceConnectionState.connecting);
    print('Attempting to connect to device: ${device.name} (${device.id})');
    
    try {
      await device.connect(autoConnect: false);
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
    print('Disconnecting from device: ${_connectedDevice!.name}');
    
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