import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/gsb_wifi_service.dart';
import 'services/network_monitor_service.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final secureStorage = SecureStorageService();
  final wifiService = GsbWifiService();

  runApp(
    MultiProvider(
      providers: [
        Provider<SecureStorageService>.value(value: secureStorage),
        Provider<GsbWifiService>.value(value: wifiService),
        ChangeNotifierProvider<NetworkMonitorService>(
          create: (_) => NetworkMonitorService(
            wifiService: wifiService,
            storageService: secureStorage,
          ),
        ),
      ],
      child: const KykGsbWifiApp(),
    ),
  );
}

class KykGsbWifiApp extends StatelessWidget {
  const KykGsbWifiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GSB WiFi Kolay Bağlantı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          primary: const Color(0xFFE53935),
          secondary: const Color(0xFF1E88E5),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
