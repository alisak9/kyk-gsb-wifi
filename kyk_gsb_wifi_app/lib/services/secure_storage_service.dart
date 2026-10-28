import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı kimlik ve oturum verilerini cihazın donanımsal güvenlik
/// kasasında (iOS Keychain / Android Keystore) saklayan servis.
class SecureStorageService {
  static const _keyTcKimlik = 'gsb_tc_kimlik';
  static const _keyPassword = 'gsb_password';
  static const _keyAutoConnect = 'gsb_auto_connect';
  static const _keyCustomPortal = 'gsb_custom_portal';
  static const _keyLastLoginDate = 'gsb_last_login_date';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// T.C. Kimlik Numarasını şifrelenmiş olarak kaydeder
  Future<void> saveCredentials(String tcKimlik, String password) async {
    await _secureStorage.write(key: _keyTcKimlik, value: tcKimlik.trim());
    await _secureStorage.write(key: _keyPassword, value: password);
  }

  /// Kayıtlı T.C. Kimlik Numarasını okur
  Future<String?> getTcKimlik() async {
    return await _secureStorage.read(key: _keyTcKimlik);
  }

  /// Kayıtlı şifreyi okur
  Future<String?> getPassword() async {
    return await _secureStorage.read(key: _keyPassword);
  }

  /// Bilgileri siler (Çıkış veya sıfırlama durumunda)
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _keyTcKimlik);
    await _secureStorage.delete(key: _keyPassword);
  }

  /// Otomatik giriş tercihini kaydeder
  Future<void> setAutoConnect(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoConnect, enabled);
  }

  /// Otomatik giriş tercihini okur (varsayılan: false)
  Future<bool> isAutoConnectEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoConnect) ?? false;
  }

  /// Özel portal adresi kaydetme (Varsayılan haricinde yurt içi özel IP kullanan yerler için)
  Future<void> setPortalUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomPortal, url.trim());
  }

  /// Portal adresini okur (Varsayılan: https://wifi.gsb.gov.tr)
  Future<String> getPortalUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomPortal) ?? 'https://wifi.gsb.gov.tr';
  }

  /// Son başarılı giriş zamanını kaydeder
  Future<void> recordLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastLoginDate, DateTime.now().toIso8601String());
  }

  /// Son başarılı giriş zamanını getirir
  Future<String?> getLastLoginDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastLoginDate);
  }
}
