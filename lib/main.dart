import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'services/tracking_manager.dart';
import 'screens/pairing_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  TrackingManager.initCommunicationPort();
  runApp(const FamilyLocatorApp());
}

class FamilyLocatorApp extends StatelessWidget {
  const FamilyLocatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Locator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const StartupRouter(),
    );
  }
}

/// Decides where to land on launch: pair this phone first if it hasn't been,
/// otherwise go straight to the status screen.
class StartupRouter extends StatefulWidget {
  const StartupRouter({super.key});
  @override
  State<StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<StartupRouter> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final paired = await ApiClient.isPaired();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => paired ? const HomeScreen() : const PairingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
