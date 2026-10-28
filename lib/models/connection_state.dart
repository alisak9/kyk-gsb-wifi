/// KYK GSB WiFi Bağlantı Durumu Modelleri
enum NetworkStatus {
  disconnected,       // Wi-Fi kapalı veya herhangi bir ağa bağlı değil
  connectedOtherWifi, // GSB dışı normal bir Wi-Fi ağına bağlı (Ev, kafe vb.)
  gsbCaptivePending,  // GSB_WIFI ağına bağlı ama oturum açılmamış (Portal bekliyor)
  gsbAuthenticated,   // GSB_WIFI oturumu açık, internet aktif
  checking,           // Bağlantı durumu kontrol ediliyor
}

class LoginResult {
  final bool isSuccess;
  final String message;
  final int? statusCode;
  final bool isSessionLimitReached;

  LoginResult({
    required this.isSuccess,
    required this.message,
    this.statusCode,
    this.isSessionLimitReached = false,
  });

  factory LoginResult.success([String message = 'Oturum başarıyla açıldı!']) {
    return LoginResult(isSuccess: true, message: message);
  }

  factory LoginResult.failure(String message, {int? statusCode, bool isSessionLimitReached = false}) {
    return LoginResult(
      isSuccess: false,
      message: message,
      statusCode: statusCode,
      isSessionLimitReached: isSessionLimitReached,
    );
  }
}
