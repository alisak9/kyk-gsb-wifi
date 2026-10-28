import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/connection_state.dart';
import 'gsb_wifi_service.dart';
import 'secure_storage_service.dart';

/// Cihazın Wi-Fi durumunu, bağlı olduğu SSID'yi ve GSB Portal durumunu canlı izleyen servis.
class NetworkMonitorService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();
  final GsbWifiService _wifiService;
  final SecureStorageService _storageService;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicCheckTimer;

  NetworkStatus _status = NetworkStatus.checking;
  String _currentSsid = 'Bilinmiyor';
  String? _ipAddress;
  bool _isAutoConnecting = false;
  String? _lastError;

  NetworkStatus get status => _status;
  String get currentSsid => _currentSsid;
  String? get ipAddress => _ipAddress;
  bool get isAutoConnecting => _isAutoConnecting;
  String? get lastError => _lastError;

  NetworkMonitorService({
    required GsbWifiService wifiService,
    required SecureStorageService storageService,
  })  : _wifiService = wifiService,
        _storageService = storageService {
    _init();
  }

  void _init() {
    // Ağ değişikliklerini dinle
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      checkCurrentStatus();
    });

    // İlk kontrol
    checkCurrentStatus();

    // 15 saniyede bir periyodik kontrol (Bağlantı düştüğünde yakalamak için)
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      checkCurrentStatus();
    });
  }

  /// Mevcut ağ durumunu analiz eder
  Future<void> checkCurrentStatus() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();

      final isWifi = connectivityResults.contains(ConnectivityResult.wifi);
      if (!isWifi) {
        _status = NetworkStatus.disconnected;
        _currentSsid = 'Wi-Fi Bağlı Değil';
        _ipAddress = null;
        notifyListeners();
        return;
      }

      // Wi-Fi SSID ve IP tespit et
      try {
        final ssid = await _networkInfo.getWifiName();
        _currentSsid = ssid?.replaceAll('"', '') ?? 'Wi-Fi (İsim Alınamadı)';
        _ipAddress = await _networkInfo.getWifiIP();
      } catch (_) {
        _currentSsid = 'Wi-Fi';
      }

      // SSID'nin GSB / KYK olup olmadığını tespit et
      final cleanSsid = _currentSsid.toUpperCase();
      final isGsbSsid = cleanSsid.contains('GSB') || 
                         cleanSsid.contains('KYK') || 
                         cleanSsid.contains('YURT');

      // Gerçek internet bağlantısı var mı? (Google 204 testi)
      final hasRealInternet = await _wifiService.checkRealInternet(timeoutSeconds: 3);

      if (hasRealInternet) {
        if (isGsbSsid) {
          _status = NetworkStatus.gsbAuthenticated;
        } else {
          _status = NetworkStatus.connectedOtherWifi;
        }
      } else {
        // İnternet yoksa: Portal yönlendirmesi mi var?
        final isCaptive = await _wifiService.isCaptivePortalPending();
        if (isCaptive || isGsbSsid) {
          _status = NetworkStatus.gsbCaptivePending;

          // Eğer otomatik giriş açıksa ve henüz bağlanılmıyorsa otomatik giriş yap
          final autoConnect = await _storageService.isAutoConnectEnabled();
          if (autoConnect && !_isAutoConnecting) {
            _triggerAutoConnect();
          }
        } else {
          _status = NetworkStatus.connectedOtherWifi;
        }
      }

      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Otomatik Giriş Tetikleyici
  Future<void> _triggerAutoConnect() async {
    final tc = await _storageService.getTcKimlik();
    final pass = await _storageService.getPassword();

    if (tc == null || pass == null || tc.isEmpty || pass.isEmpty) {
      return;
    }

    _isAutoConnecting = true;
    notifyListeners();

    final portalUrl = await _storageService.getPortalUrl();
    final result = await _wifiService.login(
      tcKimlik: tc,
      password: pass,
      portalUrl: portalUrl,
    );

    _isAutoConnecting = false;

    if (result.isSuccess) {
      await _storageService.recordLastLogin();
      await checkCurrentStatus();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }
}
