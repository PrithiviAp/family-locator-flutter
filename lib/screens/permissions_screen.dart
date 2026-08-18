import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'home_screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});
  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _requesting = false;

  Future<void> _requestAll() async {
    setState(() => _requesting = true);

    // Location: foreground first, then background (Android requires this order).
    await Geolocator.requestPermission();
    await Permission.locationAlways.request();
    await Permission.notification.request();
    await Permission.photos.request();
    // PACKAGE_USAGE_STATS can't be granted via a normal dialog — it opens a
    // system settings page. We deep-link to it and let the user flip it on.
    await openAppSettings();

    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions needed')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Family Locator needs the following to work. You\'ll always see a '
              'notification while tracking is active, and you can pause it anytime '
              'from the Home screen.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            const _PermRow(icon: Icons.location_on, text: 'Location (incl. background) — for the finder map'),
            const _PermRow(icon: Icons.photo, text: 'Photos — to back up your gallery'),
            const _PermRow(icon: Icons.notifications, text: 'Notifications — to alert you if GPS/internet drops'),
            const _PermRow(icon: Icons.bar_chart, text: 'Usage access — for screen-time summaries (Settings toggle)'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _requesting ? null : _requestAll,
                child: _requesting ? const CircularProgressIndicator() : const Text('Grant permissions'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PermRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [Icon(icon, color: Colors.blue), const SizedBox(width: 12), Expanded(child: Text(text))]),
    );
  }
}
