import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/connection_state.dart';

/// GSB / KYK Wi-Fi Doğrulama ve Ağ Servisi
/// Captive Portal kimlik doğrulama, oturum sonlandırma ve internet testi işlemlerini yönetir.
class GsbWifiService {
  late final http.Client _client;

  GsbWifiService() {
    // Captive portal ağlarında yaşanan SSL sertifika ve yönlendirme
    // problemlerini atlamak için özel HTTP istemcisi tanımlanır.
    final ioClient = HttpClient()
      ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true)
      ..connectionTimeout = const Duration(seconds: 8);

    _client = IOClient(ioClient);
  }

  /// GSB Wi-Fi Portallarına Doğrudan Hızlı Giriş (HTTP POST)
  Future<LoginResult> login({
    required String tcKimlik,
    required String password,
    String portalUrl = 'https://wifi.gsb.gov.tr',
  }) async {
    final cleanUrl = portalUrl.endsWith('/') ? portalUrl.substring(0, portalUrl.length - 1) : portalUrl;
    final loginEndpoint = Uri.parse('$cleanUrl/j_spring_security_check');

    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': '$cleanUrl/login.html',
      'Origin': cleanUrl,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    };

    final body = {
      'j_username': tcKimlik.trim(),
      'j_password': password,
    };

    try {
      final response = await _client.post(
        loginEndpoint,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      final responseBody = response.body.toLowerCase();
      final statusCode = response.statusCode;

      // 1. Zaten açık olan aktif oturum kontrolü
      if (responseBody.contains('aktif bir oturum') || 
          responseBody.contains('aktif oturumunuz') ||
          responseBody.contains('başka bir cihazda') ||
          responseBody.contains('cihaz limit')) {
        return LoginResult.failure(
          'Giriş Başarısız: Başka bir cihazda aktif oturumunuz bulunuyor. Lütfen önce "Oturumu Kapat" butonunu kullanın.',
          statusCode: statusCode,
          isSessionLimitReached: true,
        );
      }

      // 2. Hatalı Şifre / TC Kontrolü
      if (responseBody.contains('hatalı') || 
          responseBody.contains('kullanıcı adı veya şifre') || 
          responseBody.contains('geçersiz')) {
        return LoginResult.failure(
          'T.C. Kimlik Numarası veya Şifreniz hatalı. Lütfen e-Devlet şifrenizi kontrol edin.',
          statusCode: statusCode,
        );
      }

      // 3. Başarılı Giriş Kontrolü
      // Portal çoğunlukla oturum açıldığında 302 ile anasayfaya yönlendirir veya "başarılı" döner.
      if (statusCode == 200 || statusCode == 302 || statusCode == 301) {
        // Eğer geri dönen sayfada hala login formu yoksa ve hata içermiyorsa oturum açılmıştır.
        final hasSuccessIndicator = responseBody.contains('oturum') && 
            (responseBody.contains('açıldı') || responseBody.contains('başarılı') || responseBody.contains('kalan kota'));

        if (hasSuccessIndicator || statusCode == 302) {
          // Gerçek internet bağlantısını teyit et
          final hasInternet = await checkRealInternet(timeoutSeconds: 3);
          if (hasInternet) {
            return LoginResult.success('GSB WiFi oturumu başarıyla açıldı! İnternet aktif.');
          }
        }
      }

      // 4. Captcha veya Özel Durum Varsa
      if (responseBody.contains('güvenlik kodu') || responseBody.contains('captcha')) {
        return LoginResult.failure(
          'Yurdunuzda Güvenlik Kodu (Captcha) zorunlu kılınmış. Lütfen uygulamadaki "Akıllı Web Girişi" seçeneğini kullanın.',
          statusCode: statusCode,
        );
      }

      // Genel başarılı kabul etme (Örn: HTTP 200/302 döndüyse ve hata yakalanmadıysa)
      if (statusCode == 200 || statusCode == 302) {
        return LoginResult.success('Giriş isteği gönderildi. İnternetiniz kontrol ediliyor...');
      }

      return LoginResult.failure('Sunucudan beklenmeyen yanıt alındı (Kod: $statusCode).');
    } on SocketException catch (_) {
      return LoginResult.failure(
        'GSB Wi-Fi sunucusuna erişilemedi. GSB_WIFI ağına bağlı olduğunuzdan ve Hücresel Verinin kapalı olduğundan emin olun.',
      );
    } on TimeoutException catch (_) {
      return LoginResult.failure('Bağlantı zaman aşımına uğradı. Ağ sinyali zayıf olabilir.');
    } catch (e) {
      return LoginResult.failure('Giriş sırasında hata oluştu: $e');
    }
  }

  /// GSB Wi-Fi Oturumunu Kapatma (HTTP GET/POST)
  /// "Aktif oturumunuz var" hatasını çözmek için diğer cihazın oturumunu sonlandırır.
  Future<LoginResult> logout({
    String portalUrl = 'https://wifi.gsb.gov.tr',
  }) async {
    final cleanUrl = portalUrl.endsWith('/') ? portalUrl.substring(0, portalUrl.length - 1) : portalUrl;
    final logoutEndpoint = Uri.parse('$cleanUrl/logout');

    try {
      final response = await _client.get(
        logoutEndpoint,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': cleanUrl,
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 302) {
        return LoginResult.success('Mevcut oturumunuz başarıyla kapatıldı. Şimdi tekrar giriş yapabilirsiniz.');
      }

      return LoginResult.failure('Oturum kapatılamadı (Durum: ${response.statusCode}).');
    } catch (e) {
      // Birçok yurtta /logoff endpoint'i de kullanılır, yedek deneme
      try {
        final fallbackEndpoint = Uri.parse('$cleanUrl/logoff');
        final fbResponse = await _client.get(fallbackEndpoint).timeout(const Duration(seconds: 5));
        if (fbResponse.statusCode == 200 || fbResponse.statusCode == 302) {
          return LoginResult.success('Oturum kapatıldı.');
        }
      } catch (_) {}

      return LoginResult.failure('Çıkış işlemi başarısız oldu: $e');
    }
  }

  /// Gerçek internet erişimi olup olmadığını test eder (Captive portal tuzağını kontrol eder)
  Future<bool> checkRealInternet({int timeoutSeconds = 3}) async {
    try {
      // Google 204 endpoint'i: İnternet varsa HTTP 204 No Content döner.
      // Eğer captive portal yönlendirmesi varsa 302 veya HTML 200 döner.
      final url = Uri.parse('http://connectivitycheck.gstatic.com/generate_204');
      final response = await _client.get(url).timeout(Duration(seconds: timeoutSeconds));
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// Captive portalın açık olup olmadığını (Giriş yapılmayı bekleyip beklemediğini) tespit eder
  Future<bool> isCaptivePortalPending() async {
    try {
      final url = Uri.parse('http://connectivitycheck.gstatic.com/generate_204');
      final response = await _client.get(url).timeout(const Duration(seconds: 3));
      // 204 dışında bir yanıt (örn: 302, 200 HTML) alıyorsak portal yönlendiriyor demektir
      return response.statusCode != 204;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
