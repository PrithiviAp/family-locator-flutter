import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import 'permissions_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});
  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
final _urlController = TextEditingController(
  text: 'https://family-locator-api-1.onrender.com',
);
  final _keyController = TextEditingController();
  bool _verifying = false;
  String? _error;

  Future<void> _pair() async {
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();
    if (url.isEmpty || key.isEmpty) {
      setState(() => _error = 'Enter both the server URL and pairing key.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      // Verify the key works before saving it, so a typo doesn't silently
      // leave the app "paired" to a device that will never sync.
      final dio = Dio(BaseOptions(baseUrl: url, connectTimeout: const Duration(seconds: 8)));
      dio.options.headers['x-device-key'] = key;
      final resp = await dio.post('/api/devices/heartbeat', data: {});

      if (resp.statusCode != null && resp.statusCode! < 300) {
        await ApiClient.saveConfig(baseUrl: url, deviceKey: key);
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PermissionsScreen()));
        }
      } else {
        setState(() => _error = 'Server rejected the pairing key.');
      }
    } catch (e) {
      setState(() => _error = 'Could not reach the server. Check the URL and that it\'s running.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pair this phone')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Open the Family Locator dashboard on your computer, pair a new '
              'device, and copy the key it gives you into this screen.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'Server URL', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(labelText: 'Pairing key', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifying ? null : _pair,
                child: _verifying ? const CircularProgressIndicator() : const Text('Pair device'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
