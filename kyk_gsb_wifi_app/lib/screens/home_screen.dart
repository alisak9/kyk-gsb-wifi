import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/connection_state.dart';
import '../services/gsb_wifi_service.dart';
import '../services/network_monitor_service.dart';
import '../services/secure_storage_service.dart';
import 'settings_screen.dart';
import 'webview_portal_screen.dart';
import 'troubleshoot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String? _lastLoginTime;

  @override
  void initState() {
    super.initState();
    _loadLastLogin();
  }

  Future<void> _loadLastLogin() async {
    final storage = context.read<SecureStorageService>();
    final lastTime = await storage.getLastLoginDate();
    if (lastTime != null) {
      final dt = DateTime.tryParse(lastTime);
      if (dt != null) {
        setState(() {
          _lastLoginTime = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        });
      }
    }
  }

  /// Tek Dokunuşla Giriş Yap Fonksiyonu
  Future<void> _handleLogin() async {
    final storage = context.read<SecureStorageService>();
    final wifiService = context.read<GsbWifiService>();
    final monitor = context.read<NetworkMonitorService>();

    final tc = await storage.getTcKimlik();
    final pass = await storage.getPassword();

    if (tc == null || pass == null || tc.isEmpty || pass.isEmpty) {
      _showSnackBar(
        'Lütfen önce Ayarlar bölümünden T.C. Kimlik No ve Şifrenizi kaydedin.',
        isError: true,
      );
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final portalUrl = await storage.getPortalUrl();
      final result = await wifiService.login(
        tcKimlik: tc,
        password: pass,
        portalUrl: portalUrl,
      );

      if (result.isSuccess) {
        await storage.recordLastLogin();
        await _loadLastLogin();
        await monitor.checkCurrentStatus();
        _showSnackBar(result.message, isError: false);
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      _showSnackBar('Beklenmeyen bir hata oluştu: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Tek Dokunuşla Oturumu Kapat / Çıkış Yap Fonksiyonu
  Future<void> _handleLogout() async {
    final storage = context.read<SecureStorageService>();
    final wifiService = context.read<GsbWifiService>();
    final monitor = context.read<NetworkMonitorService>();

    setState(() => _isLoading = true);

    try {
      final portalUrl = await storage.getPortalUrl();
      final result = await wifiService.logout(portalUrl: portalUrl);

      await monitor.checkCurrentStatus();
      _showSnackBar(result.message, isError: !result.isSuccess);
    } catch (e) {
      _showSnackBar('Çıkış yapılırken hata oluştu: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<NetworkMonitorService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_tethering, color: Color(0xFFE53935)),
            SizedBox(width: 8),
            Text('GSB Wi-Fi Kolay Bağlantı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Sorun Çözüm Rehberi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TroubleshootScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ayarlar',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadLastLogin();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => monitor.checkCurrentStatus(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Durum Kartı (Network Status Card)
              _buildStatusCard(monitor.status, monitor.currentSsid, monitor.ipAddress),

              const SizedBox(height: 24),

              // 2. Ana İşlem Butonları (Big Action Buttons)
              _buildActionButtons(),

              const SizedBox(height: 24),

              // 3. Bilgi & Uyarı Kartı (Hücresel Veri ve Portal Bilgisi)
              _buildInfoSection(monitor.status),

              const SizedBox(height: 20),

              // 4. Son Giriş ve Hızlı İpuçları
              if (_lastLoginTime != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Son Başarılı Giriş: $_lastLoginTime',
                        style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Durum Kartı Bileşeni
  Widget _buildStatusCard(NetworkStatus status, String ssid, String? ip) {
    Color cardColor;
    Color textColor;
    IconData iconData;
    String statusTitle;
    String statusSubtitle;

    switch (status) {
      case NetworkStatus.gsbAuthenticated:
        cardColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF1B5E20);
        iconData = Icons.wifi_lock;
        statusTitle = 'GSB WiFi Bağlı & Aktif';
        statusSubtitle = 'İnternet erişiminiz açık. Rahatça kullanabilirsiniz.';
        break;
      case NetworkStatus.gsbCaptivePending:
        cardColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        iconData = Icons.wifi_protected_setup;
        statusTitle = 'GSB WiFi Ağı Algılandı';
        statusSubtitle = 'Giriş bekleniyor. Aşağıdaki butondan tek tıkla bağlanın.';
        break;
      case NetworkStatus.connectedOtherWifi:
        cardColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF0D47A1);
        iconData = Icons.wifi;
        statusTitle = 'Farklı Bir Wi-Fi Ağı';
        statusSubtitle = 'Şu an GSB WiFi dışındaki bir ağa bağlısınız.';
        break;
      case NetworkStatus.disconnected:
        cardColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFB71C1C);
        iconData = Icons.wifi_off;
        statusTitle = 'Wi-Fi Bağlantısı Yok';
        statusSubtitle = 'Lütfen cihazınızın Wi-Fi ayarlarından GSB_WIFI ağına bağlanın.';
        break;
      case NetworkStatus.checking:
        cardColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
        iconData = Icons.sync;
        statusTitle = 'Ağ Kontrol Ediliyor...';
        statusSubtitle = 'Wi-Fi sinyali ve portal durumu taranıyor.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: textColor.withOpacity(0.2), blurRadius: 6),
                  ],
                ),
                child: Icon(iconData, size: 32, color: textColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusSubtitle,
                      style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.router, size: 16, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text('Ağ: $ssid', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                ],
              ),
              if (ip != null)
                Row(
                  children: [
                    const Icon(Icons.numbers, size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text('IP: $ip', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Ana Eylem Butonları
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Tek Tıkla Giriş Yap Butonu (Büyük ve Gösterişli)
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, size: 26),
                    SizedBox(width: 10),
                    Text(
                      'GSB WiFi\'ye Hızlı Bağlan',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 14),

        // 2. Oturumu Kapat / Çıkış Yap Butonu (Oturum hakkı dolduğunda hayat kurtarır)
        OutlinedButton(
          onPressed: _isLoading ? null : _handleLogout,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD32F2F),
            side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 8),
              Text(
                'Oturumu Kapat (Çıkış Yap)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Akıllı Web Girişi Butonu (Captcha / Doğrulama Kodu Gereken Durumlar)
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WebviewPortalScreen()),
          ),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.open_in_browser, size: 18),
              SizedBox(width: 6),
              Text(
                'Akıllı Web Girişi (Güvenlik Kodu / SMS ile Giriş)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bilgilendirme ve Kritik Uyarı Kartı
  Widget _buildInfoSection(NetworkStatus status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Color(0xFFE53935)),
              SizedBox(width: 8),
              Text(
                'KYK Öğrencileri İçin Önemli İpucu',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Giriş yaparken hata alıyorsanız, lütfen telefonunuzun Hücresel Verisini (Mobil Veri) geçici olarak kapatıp sadece GSB WiFi ağına bağlı kalın.\n'
            '• "Aktif bir oturumunuz bulunmaktadır" hatası alırsanız, yukarıdaki "Oturumu Kapat" butonuna basarak eski cihazınızın oturumunu düşürebilirsiniz.',
            style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.45),
          ),
        ],
      ),
    );
  }
}
