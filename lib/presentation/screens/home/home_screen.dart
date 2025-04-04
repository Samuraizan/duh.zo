import 'package:flutter/material.dart';
import '../../../device/bluetooth/ble_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleManager _bleManager = BleManager();
  bool _isPlaying = false;
  int _batteryLevel = 0;
  double _volume = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('duh.zo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () {
              Navigator.pushNamed(context, '/connect');
            },
          ),
        ],
      ),
      body: StreamBuilder<DeviceConnectionState>(
        stream: _bleManager.connectionStateStream,
        builder: (context, snapshot) {
          if (snapshot.data == DeviceConnectionState.connected) {
            return _buildConnectedView();
          } else {
            return _buildDisconnectedView();
          }
        },
      ),
    );
  }

  Widget _buildConnectedView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Device Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Connected to OMI Device',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.battery_full,
                        color: _batteryLevel > 20 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text('$_batteryLevel%'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Audio Controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Volume Slider
                  Row(
                    children: [
                      const Icon(Icons.volume_down),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                            });
                            // TODO: Send volume change to device
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Playback Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: () {
                          // TODO: Previous track
                        },
                        iconSize: 48,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          setState(() {
                            _isPlaying = !_isPlaying;
                          });
                          // TODO: Play/Pause
                        },
                        iconSize: 64,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: () {
                          // TODO: Next track
                        },
                        iconSize: 48,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Additional Controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.equalizer),
                    label: const Text('Equalizer'),
                    onPressed: () {
                      // TODO: Open equalizer
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.surround_sound),
                    label: const Text('Sound Modes'),
                    onPressed: () {
                      // TODO: Open sound modes
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bluetooth_disabled,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Not connected to any device',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Connect to Device'),
            onPressed: () {
              Navigator.pushNamed(context, '/connect');
            },
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