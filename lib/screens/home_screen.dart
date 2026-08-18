import 'package:flutter/material.dart';
import '../services/tracking_manager.dart';
import '../services/connectivity_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _running = false;
  bool _loading = true;
  bool? _gpsOn;
  bool? _netOn;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final running = await TrackingManager.isRunning();
    final status = await ConnectivityService.checkAndNotify();
    if (!mounted) return;
    setState(() {
      _running = running;
      _gpsOn = status.gpsEnabled;
      _netOn = status.internetConnected;
      _loading = false;
    });
  }

  Future<void> _toggle() async {
    setState(() => _loading = true);
    if (_running) {
      await TrackingManager.stop();
    } else {
      await TrackingManager.start();
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Locator')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _running ? Icons.gps_fixed : Icons.gps_off,
                      size: 72,
                      color: _running ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _running ? 'Tracking is ON' : 'Tracking is OFF',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A persistent notification is shown any time tracking is active.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    _StatusChip(label: 'GPS', ok: _gpsOn),
                    const SizedBox(height: 8),
                    _StatusChip(label: 'Internet', ok: _netOn),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _running ? Colors.red : Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _toggle,
                        child: Text(_running ? 'Pause tracking' : 'Start tracking', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool? ok;
  const _StatusChip({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok == null ? Colors.grey : (ok! ? Colors.green : Colors.red);
    final text = ok == null ? '$label: unknown' : '$label: ${ok! ? "ON" : "OFF"}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
